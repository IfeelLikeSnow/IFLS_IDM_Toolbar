-- @description IFLS: Check Hubs Installed (prints missing hub scripts)
-- @version 1.0.0
-- @author IFLS
-- @about Quick sanity check: verifies that IFLS hub scripts exist at Scripts/IFLS_IDM_Toolbar/Hubs.
local r = reaper
local base = r.GetResourcePath() .. "/Scripts/IFLS_IDM_Toolbar/Hubs/"
local hubs = {
  "IFLS_BeatControlCenter_ImGui.lua",
  "IFLS_ArtistHub_ImGui.lua",
  "IFLS_SampleLibraryHub_ImGui.lua",
  "IFLS_PolyRhythmHub_ImGui.lua",
  "IFLS_SceneHub_ImGui.lua",
  "IFLS_MasterHub_ImGui.lua",
  "IFLS_Diagnostics_Insight_Run.lua",
  "IFLS_Diagnostics_DebugDemo.lua",
}
local function exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

r.ShowConsoleMsg("=== IFLS Hub Install Check ===\n")
local miss=0
for i,fn in ipairs(hubs) do
  local p = base .. fn
  if exists(p) then
    r.ShowConsoleMsg(("OK   %s\n"):format(p))
  else
    miss=miss+1
    r.ShowConsoleMsg(("MISS %s\n"):format(p))
  end
end
r.ShowConsoleMsg(("Result: %d missing\n"):format(miss))
if miss > 0 then
  r.ShowMessageBox("Es fehlen Hub-Scripts. ReaPack: Synchronize packages, dann IFLS_IDM_Toolbar_Core erneut installieren (Reinstall).", "IFLS Check", 0)
else
  r.ShowMessageBox("Alle 8 Hub-Scripts sind vorhanden.", "IFLS Check", 0)
end
