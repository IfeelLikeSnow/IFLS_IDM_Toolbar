-- @description IFLS_IDM_Toolbar: Diagnostics / Inspector (wrapper)
-- @version 1.0.1
-- @author IFLS_IDM_Toolbar
-- @about
--   Wrapper for DF95 diagnostics script used by the IFLS Main toolbar.

local RT = dofile((debug.getinfo(1,'S').source:sub(2):gsub('\\\\','/'):match('^(.*[/])') or '') .. "../lib/ifls_runtime.lua")
local scripts = RT.resource_scripts()
RT.run_abs(scripts .. "IFLS/DF95/DF95_Diagnostics_Insight_Run.lua")
