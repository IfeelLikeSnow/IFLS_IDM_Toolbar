-- IFLS_FXParamIndex.lua (shim)
-- Allows: require("IFLS_FXParamIndex") using default REAPER package.path
-- Loads the library installed at Scripts/IFLS_IDM_Toolbar/lib/IFLS_FXParamIndex.lua

local r = reaper
local resource = (r.GetResourcePath() or ""):gsub("\\","/")
local lib = resource .. "/Scripts/IFLS_IDM_Toolbar/lib/IFLS_FXParamIndex.lua"

local f = io.open(lib, "rb")
if not f then
  r.ShowMessageBox(
    "IFLS_FXParamIndex library not found:\n" .. lib .. "\n\nReinstall IFLS_IDM_Toolbar via ReaPack or run the builder once.",
    "IFLS FX Param Index", 0
  )
  return nil
end
f:close()

return dofile(lib)
