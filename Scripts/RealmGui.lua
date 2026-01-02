-- @description IFLS: RealmGui shim (ReaImGui adapter)
-- @version 1.0.1
-- @author IFLS_IDM_Toolbar (repo fix)
-- @about
--   Compatibility shim used by some legacy IFLS scripts.
--   Returns 'reaper' as the ImGui API table if ReaImGui is available, else nil.

local r = reaper
if not r or not r.ImGui_CreateContext then return nil end
return r
