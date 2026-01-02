-- @description IFLS: Build FX Param Index (All-in-One)
-- @author IFLS
-- @version 1.0.1
-- @about
--   Run once:
--     1) Scans installed FX
--     2) Dumps all parameters to TSV + JSON
--     3) Writes library + require shim:
--         Scripts/IFLS_IDM_Toolbar/lib/IFLS_FXParamIndex.lua
--         Scripts/IFLS_FXParamIndex.lua  (shim for require)
--
--   WARNING:
--     Instantiating some plugins can show dialogs or be slow.
--     Best run in an empty project. Edit SKIP_PATTERNS below if needed.

local r = reaper

----------------------------------------------------------------
-- USER CONFIG
----------------------------------------------------------------
local IFLS_ROOT_REL = "Scripts/IFLS_IDM_Toolbar/"   -- keep trailing slash
local OUT_DIR_REL   = IFLS_ROOT_REL .. "_data/"
local TSV_NAME      = "fx_param_index.tsv"
local JSON_NAME     = "fx_param_index.json"

-- Skip plugins by installed name (Lua patterns, matched case-insensitive)
local SKIP_PATTERNS = {
  -- Examples:
  -- "kontakt", "omnisphere", "izotope", "serum",
}

-- Fuzzy candidate limit used by the generated library
local FUZZY_CANDIDATE_LIMIT = 4000

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
local function norm_slash(p) return (p or ""):gsub("\\", "/") end

local function ensure_dir(path)
  r.RecursiveCreateDirectory(path, 0)
  return path
end

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function file_write(path, content)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

local function json_escape(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
       :gsub("\"", "\\\"")
       :gsub("\b", "\\b")
       :gsub("\f", "\\f")
       :gsub("\n", "\\n")
       :gsub("\r", "\\r")
       :gsub("\t", "\\t")
  return s
end

local function is_array(t)
  if type(t) ~= "table" then return false end
  local n = 0
  for k,_ in pairs(t) do
    if type(k) ~= "number" then return false end
    if k > n then n = k end
  end
  for i=1,n do if t[i]==nil then return false end end
  return true
end

local function json_encode(v)
  local tv = type(v)
  if tv == "nil" then return "null" end
  if tv == "boolean" then return v and "true" or "false" end
  if tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    return tostring(v)
  end
  if tv == "string" then return "\"" .. json_escape(v) .. "\"" end
  if tv == "table" then
    if is_array(v) then
      local out = {}
      for i=1,#v do out[#out+1] = json_encode(v[i]) end
      return "[" .. table.concat(out, ",") .. "]"
    else
      local out = {}
      for k,val in pairs(v) do
        out[#out+1] = "\"" .. json_escape(k) .. "\":" .. json_encode(val)
      end
      return "{" .. table.concat(out, ",") .. "}"
    end
  end
  return "\"<unsupported>\""
end

local function should_skip(name)
  local ln = (name or ""):lower()
  for _,pat in ipairs(SKIP_PATTERNS) do
    if pat and pat ~= "" and ln:match(pat:lower()) then return true end
  end
  return false
end

----------------------------------------------------------------
-- Step 0: paths
----------------------------------------------------------------
local resource = norm_slash(r.GetResourcePath())
local root     = ensure_dir(resource .. "/" .. IFLS_ROOT_REL)
local out_dir  = ensure_dir(resource .. "/" .. OUT_DIR_REL)
local lib_dir  = ensure_dir(resource .. "/" .. IFLS_ROOT_REL .. "lib/")

local tsv_path  = out_dir .. TSV_NAME
local json_path = out_dir .. JSON_NAME
local lib_path  = lib_dir .. "IFLS_FXParamIndex.lua"
local shim_path = resource .. "/Scripts/IFLS_FXParamIndex.lua"

msg("=== IFLS FX Param Index Builder ===")
msg("Resource path: " .. resource)
msg("Output TSV : " .. tsv_path)
msg("Output JSON: " .. json_path)
msg("Library    : " .. lib_path)
msg("Shim       : " .. shim_path)

-- Refresh JSFX info on REAPER versions that support it (safe if unsupported)
pcall(function() r.EnumInstalledFX(-1) end)

----------------------------------------------------------------
-- Step 1: enumerate installed FX
----------------------------------------------------------------
local installed = {}
do
  local i = 0
  while true do
    local ok, name, ident = r.EnumInstalledFX(i)
    if not ok then break end
    if not should_skip(name) then
      installed[#installed+1] = { name = name, ident = ident or "" }
    end
    i = i + 1
  end
end
msg(("Installed FX enumerated: %d (after skip filters)"):format(#installed))

----------------------------------------------------------------
-- Step 2: create temp track and scan
----------------------------------------------------------------
local proj = 0
r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local track_idx = r.CountTracks(proj)
r.InsertTrackAtIndex(track_idx, true)
local tr = r.GetTrack(proj, track_idx)
r.GetSetMediaTrackInfo_String(tr, "P_NAME", "__IFLS_FX_SCAN_TEMP__", true)
r.SetMediaTrackInfo_Value(tr, "B_MUTE", 1)

local f_tsv = io.open(tsv_path, "wb")
if not f_tsv then
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("IFLS: Build FX Param Index (failed)", -1)
  r.ShowMessageBox("Can't write TSV:\n" .. tsv_path, "IFLS FX Param Index", 0)
  return
end

f_tsv:write("fx_index\tfx_name\tfx_ident\tparam_index\tparam_name\tparam_ident\tval\tmin\tmax\tformatted\n")

local data = {
  meta = {
    generated_unix = os.time(),
    reaper_version = r.GetAppVersion(),
    fx_count = #installed,
    tsv = norm_slash(tsv_path),
    json = norm_slash(json_path),
  },
  fx = {}
}

local has_param_ident = (r.APIExists and r.APIExists("TrackFX_GetParamIdent")) or false

local function add_fx(track, fxname)
  -- instantiate < 0 => always create new instance
  return r.TrackFX_AddByName(track, fxname, false, -1)
end

for i = 1, #installed do
  local fx = installed[i]
  if i % 50 == 1 then
    msg(("Scanning %d/%d: %s"):format(i, #installed, fx.name))
  end

  local fx_entry = {
    index = i - 1,
    name = fx.name,
    ident = fx.ident,
    params = {},
    param_count = 0
  }

  local ok_add, fx_idx = pcall(add_fx, tr, fx.name)
  if ok_add and type(fx_idx) == "number" and fx_idx >= 0 then
    local okn, actual = r.TrackFX_GetFXName(tr, fx_idx, "")
    if okn and actual and actual ~= "" then fx_entry.actual_name = actual end

    local num = r.TrackFX_GetNumParams(tr, fx_idx) or 0
    fx_entry.param_count = num

    for p = 0, num - 1 do
      local _, pname = r.TrackFX_GetParamName(tr, fx_idx, p, "")
      local val, minv, maxv = r.TrackFX_GetParamEx(tr, fx_idx, p)
      local _, formatted = r.TrackFX_GetFormattedParamValue(tr, fx_idx, p, "")
      local pident = ""

      if has_param_ident then
        local okpi, ident_out = r.TrackFX_GetParamIdent(tr, fx_idx, p, "")
        if okpi and ident_out then pident = ident_out end
      end

      val  = val  or 0.0
      minv = minv or 0.0
      maxv = maxv or 1.0

      fx_entry.params[#fx_entry.params+1] = {
        index = p,
        name = pname or "",
        ident = pident,
        val = val,
        min = minv,
        max = maxv,
        formatted = formatted or "",
      }

      local function clean_tab(s) return (tostring(s or ""):gsub("\t", " ")) end
      f_tsv:write(("%d\t%s\t%s\t%d\t%s\t%s\t%.10f\t%.10f\t%.10f\t%s\n"):format(
        i - 1,
        clean_tab(fx.name),
        clean_tab(fx.ident),
        p,
        clean_tab(pname),
        clean_tab(pident),
        val, minv, maxv,
        clean_tab(formatted)
      ))
    end

    r.TrackFX_Delete(tr, fx_idx)
  else
    fx_entry.error = "failed_to_instantiate"
  end

  data.fx[#data.fx+1] = fx_entry
end

f_tsv:close()

-- Cleanup temp track
r.DeleteTrack(tr)

r.PreventUIRefresh(-1)
r.Undo_EndBlock("IFLS: Build FX Param Index", -1)

----------------------------------------------------------------
-- Step 3: write JSON
----------------------------------------------------------------
do
  local ok = file_write(json_path, json_encode(data))
  if not ok then
    r.ShowMessageBox("Couldn't write JSON:\n" .. json_path, "IFLS FX Param Index", 0)
  end
end

----------------------------------------------------------------
-- Step 4: write library IFLS_FXParamIndex.lua + shim for require()
----------------------------------------------------------------
local lib_src = ([[
-- IFLS_FXParamIndex.lua (auto-generated)
-- Usage:
--   local FXI = require("IFLS_FXParamIndex")
--   local idx = FXI.load()
--   local p = FXI.find_param({ident="...", name="..."}, {ident="...", name="..."})
--   local near = FXI.find_nearest_param({name="..."}, "Gain")
--
local r = reaper

local M = {}
local _cache = nil

local function norm_slash(p) return (p or ""):gsub("\\", "/") end

local function script_dir(level)
  level = level or 2
  local src = debug.getinfo(level, "S").source or ""
  if src:sub(1,1) == "@" then src = src:sub(2) end
  src = norm_slash(src)
  return src:match("^(.*[/])") or ""
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function split_tsv_line(line)
  local out = {}
  local i = 1
  for field in (line .. "\t"):gmatch("([^\t]*)\t") do
    out[i] = field
    i = i + 1
  end
  return out
end

local function normalize_name(s)
  s = tostring(s or ""):lower()
  s = s:gsub("%s+", " ")
  s = s:gsub("[^%w%s]+", "")
  s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$","")
  return s
end

local function levenshtein(a, b)
  a = tostring(a or "")
  b = tostring(b or "")
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
      cur[j] = math.min(ins, del, sub)
    end
    prev, cur = cur, prev
  end
  return prev[lb]
end

local function build_index(tsv_text)
  local lines = {}
  for line in (tsv_text .. "\n"):gmatch("([^\n]*)\n") do
    if line ~= "" then lines[#lines+1] = line end
  end
  if #lines <= 1 then return nil, "TSV empty" end

  local idx = {
    by_fxident_paramident = {},
    by_fxname_paramname = {},
    rows = {},
    meta = { loaded_unix = os.time(), rows = 0, fuzzy_limit = ]] .. tostring(FUZZY_CANDIDATE_LIMIT) .. [[ }
  }

  for i=2,#lines do
    local cols = split_tsv_line(lines[i])
    local fx_name  = cols[2] or ""
    local fx_ident = cols[3] or ""
    local p_index  = tonumber(cols[4] or "") or -1
    local p_name   = cols[5] or ""
    local p_ident  = cols[6] or ""
    local val      = tonumber(cols[7] or "") or 0.0
    local minv     = tonumber(cols[8] or "") or 0.0
    local maxv     = tonumber(cols[9] or "") or 1.0
    local formatted= cols[10] or ""

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

    if fx_ident ~= "" and p_ident ~= "" then
      idx.by_fxident_paramident[fx_ident .. "::" .. p_ident] = row
    end
    if fx_name ~= "" and p_name ~= "" then
      idx.by_fxname_paramname[normalize_name(fx_name) .. "::" .. normalize_name(p_name)] = row
    end
  end

  return idx
end

function M.load(opts)
  if _cache then return _cache end
  opts = opts or {}

  -- locate TSV relative to this lib file (…/Scripts/IFLS_IDM_Toolbar/lib/)
  local libdir = script_dir(2)
  local root = libdir:gsub("/lib/$", "/")
  local tsv = norm_slash(root .. "_data/fx_param_index.tsv")

  local txt = read_file(tsv)
  if not txt then return nil, "TSV not found: " .. tsv end

  local idx, err = build_index(txt)
  if not idx then return nil, err end
  _cache = idx
  return _cache
end

local function get_fx_key(fx)
  if type(fx) == "string" then return "", normalize_name(fx) end
  fx = fx or {}
  return fx.ident or "", normalize_name(fx.name or "")
end

local function get_param_key(p)
  if type(p) == "string" then return "", normalize_name(p) end
  p = p or {}
  return p.ident or "", normalize_name(p.name or "")
end

function M.find_param(fx, param, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local p_ident, p_norm   = get_param_key(param)

  if fx_ident ~= "" and p_ident ~= "" then
    local hit = idx.by_fxident_paramident[fx_ident .. "::" .. p_ident]
    if hit then return hit end
  end

  if fx_norm ~= "" and p_norm ~= "" then
    local hit = idx.by_fxname_paramname[fx_norm .. "::" .. p_norm]
    if hit then return hit end
  end

  return nil, "not_found"
end

function M.find_nearest_param(fx, param_name, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local want = normalize_name(param_name or "")
  if want == "" then return nil, "empty_param_name" end

  local best, best_score = nil, 1e9
  local checked = 0
  local limit = tonumber((opts or {}).fuzzy_limit or idx.meta.fuzzy_limit or 4000) or 4000

  for _, row in ipairs(idx.rows) do
    local same_fx
    if fx_ident ~= "" and row.fx_ident ~= "" then
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
  return nil, "no_candidates"
end

function M.list_params(fx, opts)
  local idx, err = M.load(opts)
  if not idx then return nil, err end

  local fx_ident, fx_norm = get_fx_key(fx)
  local out = {}
  for _, row in ipairs(idx.rows) do
    if fx_ident ~= "" and row.fx_ident ~= "" then
      if row.fx_ident == fx_ident then out[#out+1] = row end
    else
      if row.n_fx == fx_norm then out[#out+1] = row end
    end
  end
  return out
end

return M
]]):gsub("\r\n", "\n")

local ok_lib = file_write(lib_path, lib_src)
if not ok_lib then
  r.ShowMessageBox("Couldn't write library:\n" .. lib_path, "IFLS FX Param Index", 0)
end

-- Shim so repo code can simply: require("IFLS_FXParamIndex")
local shim_src = ([[
-- IFLS_FXParamIndex.lua (shim)
-- Allows: require("IFLS_FXParamIndex") using default REAPER package.path
local r = reaper
local resource = (r.GetResourcePath() or ""):gsub("\\","/")
local lib = resource .. "/Scripts/IFLS_IDM_Toolbar/lib/IFLS_FXParamIndex.lua"
return dofile(lib)
]]):gsub("\r\n", "\n")

local ok_shim = file_write(shim_path, shim_src)
if not ok_shim then
  r.ShowMessageBox("Couldn't write shim:\n" .. shim_path, "IFLS FX Param Index", 0)
end

msg("\nDONE.")
msg("Wrote TSV : " .. tsv_path)
msg("Wrote JSON: " .. json_path)
msg("Wrote LIB : " .. lib_path)
msg("Wrote SHIM: " .. shim_path)

r.ShowMessageBox(
  "FX Param Index erstellt.\n\nTSV:\n" .. tsv_path ..
  "\n\nJSON:\n" .. json_path ..
  "\n\nLIB:\n" .. lib_path ..
  "\n\nShim:\n" .. shim_path ..
  "\n\nIm Repo nutzen:\n  local FXI = require('IFLS_FXParamIndex')\n  local idx = FXI.load()",
  "IFLS FX Param Index Builder", 0
)
