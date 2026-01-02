-- IFLS_FXParamIndex.lua
-- Library: loads TSV produced by IFLS_Build_FXParamIndex_AllInOne.lua
-- Usage:
--   local FXI = require('IFLS_FXParamIndex')   -- via shim Scripts/IFLS_FXParamIndex.lua
--   local idx, err = FXI.load()
--   local row = FXI.find_param({name='ReaEQ'}, {name='Gain'})
--   local near = FXI.find_nearest_param({name='ReaEQ'}, 'Gainn')

local r = reaper

local M = {}
local _cache = nil

local function norm_slash(p) return (p or ''):gsub('\\','/') end

local function script_dir(level)
  level = level or 2
  local src = debug.getinfo(level, 'S').source or ''
  if src:sub(1,1) == '@' then src = src:sub(2) end
  src = norm_slash(src)
  return src:match('^(.*[/])') or ''
end

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local s = f:read('*a')
  f:close()
  return s
end

local function split_tsv_line(line)
  local out = {}
  local i = 1
  for field in (line .. '\t'):gmatch('([^\t]*)\t') do
    out[i] = field
    i = i + 1
  end
  return out
end

local function normalize_name(s)
  s = tostring(s or ''):lower()
  s = s:gsub('%s+', ' ')
  s = s:gsub('[^%w%s]+', '')
  s = s:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$','')
  return s
end

local function levenshtein(a, b)
  a = tostring(a or '')
  b = tostring(b or '')
  local la, lb = #a, #b
  if la == 0 then return lb end
  if lb == 0 then return la end
  if la > 256 or lb > 256 then
    return math.abs(la - lb) + 128
  end
  local prev, cur = {}, {}
  for j=0,lb do prev[j] = j end
  for i=1,la do
    cur[0] = i
    local ca = a:sub(i,i)
    for j=1,lb do
      local cb = b:sub(j,j)
      local cost = (ca == cb) and 0 or 1
      local ins = cur[j-1] + 1
      local del = prev[j] + 1
      local sub = prev[j-1] + cost
      local m = ins
      if del < m then m = del end
      if sub < m then m = sub end
      cur[j] = m
    end
    prev, cur = cur, prev
  end
  return prev[lb]
end

local function build_index(tsv_text)
  local lines = {}
  for line in (tsv_text .. '\n'):gmatch('([^\n]*)\n') do
    if line ~= '' then lines[#lines+1] = line end
  end
  if #lines <= 1 then return nil, 'TSV empty' end

  local idx = {
    by_fxident_paramident = {},
    by_fxname_paramname = {},
    rows = {},
    meta = { loaded_unix = os.time(), rows = 0, fuzzy_limit = 4000 }
  }

  for i=2,#lines do
    local cols = split_tsv_line(lines[i])
    local fx_name  = cols[2] or ''
    local fx_ident = cols[3] or ''
    local p_index  = tonumber(cols[4] or '') or -1
    local p_name   = cols[5] or ''
    local p_ident  = cols[6] or ''
    local val      = tonumber(cols[7] or '') or 0.0
    local minv     = tonumber(cols[8] or '') or 0.0
    local maxv     = tonumber(cols[9] or '') or 1.0
    local formatted= cols[10] or ''

    local row = {
      fx_name = fx_name,
      fx_ident = fx_ident,
      param_index = p_index,
      param_name = p_name,
      param_ident = p_ident,
      val = val,
      min = minv,
      max = maxv,
      formatted = formatted,
      n_fx = normalize_name(fx_name),
      n_param = normalize_name(p_name),
    }

    idx.rows[#idx.rows+1] = row
    idx.meta.rows = idx.meta.rows + 1

    if fx_ident ~= '' and p_ident ~= '' then
      idx.by_fxident_paramident[fx_ident .. '::' .. p_ident] = row
    end
    if fx_name ~= '' and p_name ~= '' then
      idx.by_fxname_paramname[normalize_name(fx_name) .. '::' .. normalize_name(p_name)] = row
    end
  end

  return idx
end

function M.load(opts)
  if _cache then return _cache end
  opts = opts or {}

  -- locate TSV relative to this lib file (…/Scripts/IFLS_IDM_Toolbar/lib/)
  local libdir = script_dir(2)
  local root = libdir:gsub('/lib/$', '/')
  local tsv = norm_slash(root .. '_data/fx_param_index.tsv')

  local txt = read_file(tsv)
  if not txt then
    return nil, 'TSV not found. Run IFLS_Build_FXParamIndex_AllInOne.lua first:\n' .. tsv
  end

  local idx, err = build_index(txt)
  if not idx then return nil, err end
  _cache = idx
  return _cache
end

local function get_fx_key(fx)
  if type(fx) == 'string' then return '', normalize_name(fx) end
  fx = fx or {}
  return fx.ident or '', normalize_name(fx.name or '')
end

local function get_param_key(p)
  if type(p) == 'string' then return '', normalize_name(p) end
  p = p or {}
  return p.ident or '', normalize_name(p.name or '')
end

function M.find_param(fx, param, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local p_ident, p_norm   = get_param_key(param)

  if fx_ident ~= '' and p_ident ~= '' then
    local hit = idx.by_fxident_paramident[fx_ident .. '::' .. p_ident]
    if hit then return hit end
  end

  if fx_norm ~= '' and p_norm ~= '' then
    local hit = idx.by_fxname_paramname[fx_norm .. '::' .. p_norm]
    if hit then return hit end
  end

  return nil, 'not_found'
end

function M.find_nearest_param(fx, param_name, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local want = normalize_name(param_name or '')
  if want == '' then return nil, 'empty_param_name' end

  local best, best_score = nil, 1e9
  local checked = 0
  local limit = tonumber((opts or {}).fuzzy_limit or idx.meta.fuzzy_limit or 4000) or 4000

  for _, row in ipairs(idx.rows) do
    local same_fx
    if fx_ident ~= '' and row.fx_ident ~= '' then
      same_fx = (row.fx_ident == fx_ident)
    else
      same_fx = (row.n_fx == fx_norm)
    end

    if same_fx then
      checked = checked + 1
      if row.n_param == want then return row end

      local score
      if row.n_param:find(want, 1, true) or want:find(row.n_param, 1, true) then
        score = math.abs(#row.n_param - #want)
      else
        score = levenshtein(row.n_param, want)
      end

      if score < best_score then
        best_score = score
        best = row
      end

      if checked >= limit then break end
    end
  end

  if best then return best end
  return nil, 'no_candidates'
end

function M.list_params(fx, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local out = {}
  for _, row in ipairs(idx.rows) do
    if fx_ident ~= '' and row.fx_ident ~= '' then
      if row.fx_ident == fx_ident then out[#out+1] = row end
    else
      if row.n_fx == fx_norm then out[#out+1] = row end
    end
  end
  return out
end

return M
