-- IFLS_FXParamIndex.lua (shim)
-- Allows: require('IFLS_FXParamIndex') using default REAPER package.path
local r = reaper
local resource = (r.GetResourcePath() or ''):gsub('\\','/')
local lib = resource .. '/Scripts/IFLS_IDM_Toolbar/lib/IFLS_FXParamIndex.lua'
return dofile(lib)
