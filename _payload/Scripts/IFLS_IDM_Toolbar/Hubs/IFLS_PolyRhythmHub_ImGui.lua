-- @description IFLS_IDM_Toolbar: Groove & Rhythm (PolyRhythm Hub) (wrapper)
-- @version 1.0.1
-- @author IFLS_IDM_Toolbar
-- @about
--   Entry point wrapper that launches the original DF95/IFLS script from its canonical location.
--   When you fully migrate scripts into Scripts/IFLS_IDM_Toolbar/, you can replace this wrapper
--   with the real implementation (same filename) without changing toolbar mappings.

local RT = dofile((debug.getinfo(1,'S').source:sub(2):gsub('\\\\','/'):match('^(.*[/])') or '') .. "../lib/ifls_runtime.lua")
local scripts = RT.resource_scripts()
local path = scripts .. "IFLS/IFLS/Hubs/IFLS_PolyRhythmHub_ImGui.lua"
RT.run_abs(path)
