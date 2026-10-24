-- Dubz Hands: the hands weapon (lua/weapons/dubz_hands). This autorun holds its settings and adds them to the Dubz
-- Framework admin menu (!dubzconfig). Put "dubz_hands" in DarkRP's default weapons instead of keys / weapon_fists.
DubzHands = DubzHands or {}

for _, name in ipairs({"sh_config.lua", "sh_framework.lua"}) do
	if not file.Exists("dubz_hands/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzHands] ", color_white, "lua/dubz_hands/" .. name .. " is missing. Upload the whole lua/dubz_hands/ folder. The hands run on built-in defaults.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_hands/sh_config.lua")
	AddCSLuaFile("dubz_hands/sh_framework.lua")
end

include("dubz_hands/sh_config.lua")

-- Dubz Framework: hand the framework a manifest so the hands show up in the admin config menu.
-- Works whichever autorun runs first; without the framework the hands run with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_hands",
	name = "Dubz Hands",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_hands/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
