-- @description IFLS_IDM_Toolbar: Diagnostics / Inspector
-- @version 1.0.2
-- @author IFLS_IDM_Toolbar
-- @about Launches the local DF95 diagnostics inspector script bundled with IFLS_IDM_Toolbar.

local RT = dofile((debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*[/])') or '') .. "../lib/ifls_runtime.lua")
local scripts = RT.resource_scripts()

-- Local canonical target inside IFLS_IDM_Toolbar
RT.run_abs(scripts .. "IFLS_IDM_Toolbar/DF95/DF95_Diagnostics_Insight_Run.lua")
