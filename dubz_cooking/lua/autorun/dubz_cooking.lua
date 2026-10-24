-- Dubz Cooking: the cook's stove and donuts.
-- Settings live in lua/dubz_cooking/sh_config.lua and the Dubz Framework admin menu (!dubzconfig).
DubzCooking = DubzCooking or {}

for _, name in ipairs({"sh_config.lua", "sh_framework.lua"}) do
	if not file.Exists("dubz_cooking/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzCooking] ", color_white, "lua/dubz_cooking/" .. name .. " is missing. Upload the whole lua/dubz_cooking/ folder. Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_cooking/sh_config.lua")
	AddCSLuaFile("dubz_cooking/sh_framework.lua")

	hook.Add("InitPostEntity", "DubzCooking_CheckEntities", function()
		for _, class in ipairs({"dub_stove", "dubnut", "dubnut_gold", "dub_milk", "dub_ingredients"}) do
			if not scripted_ents.Get(class) then
				MsgC(Color(255, 80, 80), "[DubzCooking] ", color_white, "entity " .. class .. " is NOT registered. Check that lua/entities/" .. class .. "/ is uploaded and has no Lua errors above.\n")
			end
		end
	end)

	print("[DUBZ Cooking] - Successfully Loaded!")
end

include("dubz_cooking/sh_config.lua")

-- Dubz Framework: hand the framework a manifest so Cooking shows up in the admin config menu.
-- Works whichever autorun runs first; without the framework it runs with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_cooking",
	name = "Dubz Cooking",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_cooking/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
