-- @description IFLS: Print current script path (diagnostics)
-- @version 1.0
-- @author IFLS
-- @about Prints the absolute path of THIS script instance. Helpful when multiple duplicates exist in Action List.
local _, script_path = reaper.get_action_context()
reaper.ShowConsoleMsg("This script path: "..tostring(script_path).."\n")
reaper.ShowMessageBox("This script path:\n\n"..tostring(script_path), "IFLS Diagnostics", 0)
