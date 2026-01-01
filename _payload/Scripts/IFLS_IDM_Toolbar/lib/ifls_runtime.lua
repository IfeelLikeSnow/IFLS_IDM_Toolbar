-- lib/ifls_runtime.lua
-- Portable runtime helpers for IFLS_IDM_Toolbar
-- Goal: avoid hardcoded GetResourcePath() .. "/Scripts/IFLS/..." paths.
-- Usage:
--   local RT = dofile(script_dir .. "../lib/ifls_runtime.lua")
--   local ROOT = RT.find_root()
--   local core_path = ROOT .. "Core/"
--   local domain_path = ROOT .. "Domain/"

local M = {}

local function norm(p) return (p or ""):gsub("\\", "/") end

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
  if root then return root end
  -- fallback: assume this file is in <root>/lib/
  root = M.script_dir(2):gsub("lib/$","")
  return root
end

function M.add_package_paths(root, extra_dirs)
  root = norm(root or M.find_root())
  local add = {
    root .. "?.lua",
    root .. "?/init.lua",
    root .. "lib/?.lua",
  }
  if type(extra_dirs) == "table" then
    for _, d in ipairs(extra_dirs) do
      d = norm(d):gsub("^/*", ""):gsub("/*$", "")
      add[#add+1] = root .. d .. "/?.lua"
      add[#add+1] = root .. d .. "/?/init.lua"
    end
  end
  package.path = package.path .. ";" .. table.concat(add, ";")
  return root
end

function M.safe_dofile(path, label)
  local ok, mod = pcall(dofile, path)
  if ok then return mod end
  if reaper and reaper.ShowMessageBox then
    reaper.ShowMessageBox(
      (label or "IFLS_IDM_Toolbar") .. "\n\nKonnte Datei nicht laden:\n" .. tostring(path) .. "\n\n" .. tostring(mod),
      "IFLS Loader",
      0
    )
  end
  return nil
end

return M
