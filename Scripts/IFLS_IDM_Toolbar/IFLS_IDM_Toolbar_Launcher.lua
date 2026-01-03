-- @description IFLS_IDM_Toolbar: Launcher (auto-register + hub picker)
-- @version 1.0.0
-- @author IFLS
-- @about
--   Entry point for the IFLS_IDM_Toolbar suite.
--   - Ensures ReaImGui is available (via the bundled imgui.lua shim).
--   - Optionally runs the one-time action registration.
--   - Lets you launch the main hubs from a simple menu.

local r = reaper

-- Make sure Scripts/?.lua is on the package path so require("imgui") works
local rp = r.GetResourcePath()
package.path = package.path .. ";" .. rp .. "/Scripts/?.lua;" .. rp .. "/Scripts/?/init.lua"

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

-- Dependency: ReaImGui extension + shim module
local ok_imgui, ig = pcall(require, "imgui")
if (not ok_imgui) or (not ig) then
  r.ShowMessageBox(
    "ReaImGui ist nicht verfügbar.\n\n" ..
    "Bitte installiere per ReaPack:\n" ..
    "ReaTeam Extensions -> ReaImGui\n\n" ..
    "Danach REAPER neu starten.",
    "IFLS_IDM_Toolbar Launcher",
    0
  )
  return
end

-- Optional: run action registration once (safe to re-run)
local function maybe_register_actions()
  local key = "IFLS_IDM_Toolbar"
  local done = r.GetExtState(key, "actions_registered")
  if done == "1" then return end

  local reg = rp .. "/Scripts/DF95_IFLS_Register_All_Actions.lua"
  if file_exists(reg) then
    local ret = r.ShowMessageBox(
      "Aktionen registrieren?\n\n" ..
      "Empfohlen beim ersten Start, damit alle IFLS/DF95 Scripts\n" ..
      "in der Action List erscheinen (Toolbar-Buttons etc.).",
      "IFLS_IDM_Toolbar",
      4 -- Yes/No
    )
    if ret == 6 then
      local ok, err = pcall(dofile, reg)
      if not ok then
        r.ShowMessageBox("Registration failed:\n" .. tostring(err), "IFLS_IDM_Toolbar", 0)
        return
      end
      r.SetExtState(key, "actions_registered", "1", true)
    end
  end
end

maybe_register_actions()

local hubs = {
  { "Master Hub",               "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_MasterHub_ImGui.lua" },
  { "Beat Control Center",      "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_BeatControlCenter_ImGui.lua" },
  { "Artist Hub",               "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_ArtistHub_ImGui.lua" },
  { "Sample Library Hub",       "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_SampleLibraryHub_ImGui.lua" },
  { "PolyRhythm Hub",           "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_PolyRhythmHub_ImGui.lua" },
  { "Scene Hub",                "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_SceneHub_ImGui.lua" },
  { "Diagnostics: Insight",     "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_Diagnostics_Insight_Run.lua" },
  { "Diagnostics: Debug Demo",  "Scripts/IFLS_IDM_Toolbar/Hubs/IFLS_Diagnostics_DebugDemo.lua" },
  { "File locations report",    "Scripts/IFLS_IDM_Toolbar/Tools/IFLS_IDM_Toolbar_Diagnostics_FileLocations.lua" },
}

local menu = {}
for i, h in ipairs(hubs) do
  menu[#menu+1] = string.format("%d. %s", i, h[1])
end
menu[#menu+1] = "|Cancel"
local menu_str = table.concat(menu, "|")

gfx.init("IFLS_IDM_Toolbar", 0, 0)
local sel = gfx.showmenu(menu_str)
gfx.quit()

if not sel or sel <= 0 or sel > #hubs then return end

local rel = hubs[sel][2]
local path = rp .. "/" .. rel
if not file_exists(path) then
  r.ShowMessageBox("Script nicht gefunden:\n" .. path, "IFLS_IDM_Toolbar", 0)
  return
end

local ok, err = pcall(dofile, path)
if not ok then
  r.ShowMessageBox("Fehler beim Ausführen:\n" .. path .. "\n\n" .. tostring(err), "IFLS_IDM_Toolbar", 0)
end
