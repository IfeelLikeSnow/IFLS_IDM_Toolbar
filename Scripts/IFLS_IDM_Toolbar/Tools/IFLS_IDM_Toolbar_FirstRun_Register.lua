-- @description IFLS_IDM_Toolbar: First run - register all actions
-- @version 1.0.0
-- @author IFLS
-- @about
--   Runs the DF95/IFLS one-time bootstrap that registers scripts as Actions.
--   Safe to re-run. After running, search for "IFLS" in the Action List.

local r = reaper
local rp = r.GetResourcePath()
local reg = rp .. "/Scripts/DF95_IFLS_Register_All_Actions.lua"

local f = io.open(reg, "rb")
if not f then
  r.ShowMessageBox("Nicht gefunden:\n" .. reg .. "\n\nIst das Paket korrekt installiert?", "IFLS First Run", 0)
  return
end
f:close()

local ok, err = pcall(dofile, reg)
if not ok then
  r.ShowMessageBox("Fehler:\n" .. tostring(err), "IFLS First Run", 0)
  return
end

r.SetExtState("IFLS_IDM_Toolbar", "actions_registered", "1", true)
r.ShowMessageBox("Fertig.\n\nJetzt: Actions -> Show action list -> suche nach 'IFLS'.", "IFLS First Run", 0)
