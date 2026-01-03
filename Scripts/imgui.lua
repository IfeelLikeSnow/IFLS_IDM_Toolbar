-- imgui.lua (IFLS shim)
-- Provides a minimal 'imgui' Lua module for ReaImGui.
-- Many IFLS hubs do: local ok, imgui = pcall(require, "imgui"); local ig = imgui
-- This shim maps ig.Text(ctx, ...) -> reaper.ImGui_Text(ctx, ...) etc.

local r = reaper

-- Hard fail with a helpful message if ReaImGui isn't installed/loaded
if type(r) ~= "userdata" and type(r) ~= "table" then
  error("reaper global not found")
end

if not r.ImGui_CreateContext then
  -- ReaImGui extension not installed or not loaded
  return nil
end

local M = {}

-- Precompute the few constants used by the IFLS hubs
if r.ImGui_Cond_FirstUseEver then
  M.Cond_FirstUseEver = r.ImGui_Cond_FirstUseEver()
end
if r.ImGui_Col_Text then
  M.Col_Text = r.ImGui_Col_Text()
end

setmetatable(M, {
  __index = function(_, key)
    local fn = r["ImGui_" .. key]
    if type(fn) == "function" then
      return fn
    end
    return nil
  end
})

return M
