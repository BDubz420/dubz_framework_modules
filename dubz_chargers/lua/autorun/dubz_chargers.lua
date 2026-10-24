-- Dubz Chargers: health and armor chargers a medic can own and profit from.
-- Settings live in lua/dubz_chargers/sh_config.lua and the Dubz Framework admin menu (!dubzconfig).
DubzChargers = DubzChargers or {}

-- Two parts: this autorun and the lua/dubz_chargers/ folder (plus the two entity folders). If the folder didn't
-- upload, say so instead of failing with several confusing errors.
for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "sv_chargers.lua"}) do
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_chargers/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzChargers] ", color_white, "lua/dubz_chargers/" .. name .. " is missing. Upload the whole lua/dubz_chargers/ folder. Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_chargers/sh_config.lua")
	AddCSLuaFile("dubz_chargers/sh_framework.lua")
end

include("dubz_chargers/sh_config.lua")

if SERVER then
	local ok, err = pcall(include, "dubz_chargers/sv_chargers.lua")
	if not ok then ErrorNoHalt("[DubzChargers] sv_chargers.lua failed to load: " .. tostring(err) .. "\n") end

	hook.Add("InitPostEntity", "DubzChargers_CheckEntities", function()
		for _, class in ipairs({"dubz_health_charger", "dubz_armor_charger"}) do
			if not scripted_ents.Get(class) then
				MsgC(Color(255, 80, 80), "[DubzChargers] ", color_white, "entity " .. class .. " is NOT registered. Check that lua/entities/" .. class .. "/ is uploaded and has no Lua errors above.\n")
			end
		end
	end)
end

-- Dubz Framework: hand the framework a manifest so the chargers show up in the admin config menu.
-- Works whichever autorun runs first; without the framework they run with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_chargers",
	name = "Dubz Chargers",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_chargers/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
