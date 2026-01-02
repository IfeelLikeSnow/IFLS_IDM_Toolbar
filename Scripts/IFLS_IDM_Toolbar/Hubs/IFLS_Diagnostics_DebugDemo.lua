-- @description IFLS_IDM_Toolbar: Dev / Debug
-- @version 1.0.2
-- @author IFLS_IDM_Toolbar
-- @about Launches the local IFLS diagnostics debug demo script bundled with IFLS_IDM_Toolbar.

local RT = dofile((debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*[/])') or '') .. "../lib/ifls_runtime.lua")
local scripts = RT.resource_scripts()

RT.run_abs(scripts .. "IFLS_IDM_Toolbar/Domain/IFLS_Diagnostics_DebugDemo.lua")
