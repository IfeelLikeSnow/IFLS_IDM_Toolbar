-- Scripts/IFLS_IDM_Toolbar/lib/ifls_runtime.lua
-- Portable path/runtime helpers for the IFLS_IDM_Toolbar repo.
-- Goal: avoid hard-coded "<REAPER>/Scripts/IFLS/..." paths.

local M = {}

local function norm(p)
  return (p or ""):gsub("\\", "/")
end

function M.script_dir(level)
  level = level or 2
  local src = debug.getinfo(level, "S").source or ""
  if src:sub(1,1) == "@" then src = src:sub(2) end
  src = norm(src)
  return src:match("^(.*[/])") or ""
end

function M.find_root(marker)
  marker = marker or "IFLS_IDM_Toolbar"
  local dir = M.script_dir(3)
  local root = dir:match("^(.*" .. marker .. "/)")
  return root or dir
end

function M.add_paths(root, extra_dirs)
  root = norm(root or M.find_root())
  local paths = {
    root .. "?.lua",
    root .. "lib/?.lua",
  }
  if type(extra_dirs) == "table" then
    for _, d in ipairs(extra_dirs) do
      d = norm(d):gsub("^/*", ""):gsub("/*$", "")
      paths[#paths+1] = root .. d .. "/?.lua"
    end
  end
  package.path = package.path .. ";" .. table.concat(paths, ";")
  return root
end

function M.run(root, relfile)
  root = norm(root or M.find_root())
  relfile = norm(relfile):gsub("^/*", "")
  local full = root .. relfile
  local chunk, err = loadfile(full)
  if not chunk then
    reaper.MB("IFLS: Kann Script nicht laden:\n\n" .. full .. "\n\n" .. tostring(err), "IFLS Loader", 0)
    return false
  end
  local ok, runerr = xpcall(chunk, debug.traceback)
  if not ok then
    reaper.MB("IFLS: Fehler beim Ausführen:\n\n" .. full .. "\n\n" .. tostring(runerr), "IFLS Loader", 0)
    return false
  end
  return true
end

return M
