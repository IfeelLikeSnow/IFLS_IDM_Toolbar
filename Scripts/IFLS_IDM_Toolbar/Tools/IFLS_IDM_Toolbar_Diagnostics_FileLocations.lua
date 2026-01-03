-- @description IFLS_IDM_Toolbar: Diagnostics - file locations and duplicates
-- @version 1.0.0
-- @author IFLS
-- @about
--   Prints where IFLS_IDM_Toolbar files are installed inside the REAPER resource path.
--   Also detects duplicate hub scripts (common after manual ZIP extraction).

local r = reaper
local rp = r.GetResourcePath()

local function log(s) r.ShowConsoleMsg(tostring(s) .. "\n") end
local function exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

-- Recursive enumeration using REAPER's directory functions
local function scan_dir(dir, results)
  results = results or {}
  local i = 0
  while true do
    local fn = r.EnumerateFiles(dir, i)
    if not fn then break end
    results[#results+1] = dir .. "/" .. fn
    i = i + 1
  end
  local j = 0
  while true do
    local sub = r.EnumerateSubdirectories(dir, j)
    if not sub then break end
    scan_dir(dir .. "/" .. sub, results)
    j = j + 1
  end
  return results
end

r.ClearConsole()
log("=== IFLS_IDM_Toolbar Diagnostics ===")
log("Resource path: " .. rp)
log("")

local key_paths = {
  rp .. "/Scripts/imgui.lua",
  rp .. "/Scripts/DF95_IFLS_Register_All_Actions.lua",
  rp .. "/Scripts/IFLS_IDM_Toolbar/IFLS_IDM_Toolbar_Launcher.lua",
}

for _, p in ipairs(key_paths) do
  log((exists(p) and "[OK]   " or "[MISS] ") .. p)
end

log("")
log("Scanning for hub duplicates (IFLS_*Hub*_ImGui.lua) ...")

local scripts_root = rp .. "/Scripts"
local all = scan_dir(scripts_root, {})
local hubs = {}

for _, p in ipairs(all) do
  local name = p:match("([^/]+)$") or p
  if name:match("^IFLS_.*Hub.*_ImGui%.lua$") then
    hubs[name] = hubs[name] or {}
    hubs[name][#hubs[name]+1] = p
  end
end

local dup_count = 0
for name, paths in pairs(hubs) do
  if #paths > 1 then
    dup_count = dup_count + 1
    log("")
    log("DUPLICATE: " .. name .. " (" .. #paths .. " copies)")
    table.sort(paths)
    for _, p in ipairs(paths) do
      log("  - " .. p)
    end
  end
end

if dup_count == 0 then
  log("No duplicates found. ✅")
else
  log("")
  log("Found duplicates: " .. dup_count)
  log("Empfehlung: Nur eine Installation behalten, idealerweise:")
  log("  " .. rp .. "/Scripts/IFLS_IDM_Toolbar/Hubs/")
end
