-- @description IFLS: Root shim for IFLS_Diagnostics
-- @version 1.0.1
-- @author IFLS_IDM_Toolbar (repo fix)
-- @about
--   Compatibility shim. Loads the real IFLS_Diagnostics.lua from Scripts/IFLS/IFLS/Domain.

local r = reaper
local function path_join(a,b)
  if a:sub(-1) == "/" or a:sub(-1) == "\" then return a .. b end
  return a .. "/" .. b
end

local target = path_join(r.GetResourcePath(), "Scripts/IFLS/IFLS/Domain/IFLS_Diagnostics.lua")
local chunk, err = loadfile(target)
if not chunk then
  r.MB("Missing IFLS diagnostics file:\n\n" .. target .. "\n\n" .. tostring(err), "IFLS", 0)
  return nil
end
return chunk()
