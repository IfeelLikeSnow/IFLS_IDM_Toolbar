-- @description IFLS_IDM_Toolbar: runtime helpers (path resolver)
-- @version 1.0.0
-- @author IFLS_IDM_Toolbar
-- @about
--   Small helper library to resolve the repo root from the current script location
--   and to run other scripts by relative path. Used by IFLS_IDM_Toolbar wrappers.

local M = {}

local function norm(p) return (p or ""):gsub("\\", "/") end

function M.script_dir(level)
  level = level or 2
  local src = debug.getinfo(level, "S").source or ""
  if src:sub(1,1) == "@" then src = src:sub(2) end
  src = norm(src)
  return src:match("^(.*[/])") or ""
end

function M.resource_scripts()
  return norm(reaper.GetResourcePath()) .. "/Scripts/"
end

function M.file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

function M.run_abs(path)
  local chunk, err = loadfile(path)
  if not chunk then
    reaper.MB("Kann Script nicht laden:\n\n" .. tostring(path) .. "\n\n" .. tostring(err),
              "IFLS_IDM_Toolbar", 0)
    return false
  end
  local ok, runerr = xpcall(chunk, debug.traceback)
  if not ok then
    reaper.MB("Fehler beim Ausführen:\n\n" .. tostring(path) .. "\n\n" .. tostring(runerr),
              "IFLS_IDM_Toolbar", 0)
    return false
  end
  return true
end

return M
