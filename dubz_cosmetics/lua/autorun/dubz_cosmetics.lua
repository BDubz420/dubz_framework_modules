-- Dubz Cosmetics: wearable accessories (hats, face, neck, back) with a built-in placement editor.
-- Accessories are never lost on death. Files live in lua/dubz_cosmetics/.
-- Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
DubzCosmetics = DubzCosmetics or {}

local modules = {
	"sh_config.lua",
	"sh_registry.lua",
	"sh_items.lua",
	"sh_packs.lua",
	"sh_clothing.lua",
	"sh_virtual.lua",
	"sv_cosmetics.lua",
	"sv_npc.lua",
	"sv_admin.lua",
	"cl_render.lua",
	"cl_wardrobe.lua",
	"cl_store.lua",
	"cl_editor.lua",
	"cl_admin.lua",
}

local function needed(name)
	return string.sub(name, 1, 2) ~= "sv" or SERVER
end

local function fail(text)
	MsgC(Color(255, 80, 80), "[DubzCosmetics] ", color_white, text .. " Nothing was loaded.\n")
end

-- The shared files are required by everything else. If any is missing the addon would break chat commands
-- (its hooks run on every message), so load nothing at all and say why.
local missing = {}
for _, name in ipairs(modules) do
	if needed(name) and not file.Exists("dubz_cosmetics/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	fail("Missing file(s) in lua/dubz_cosmetics/: " .. table.concat(missing, ", ") .. ". Upload the whole folder.")
	return
end

-- Send client files first so one broken server file can't stop clients from getting them.
if SERVER then
	for _, name in ipairs(modules) do
		if string.sub(name, 1, 2) ~= "sv" then AddCSLuaFile("dubz_cosmetics/" .. name) end
	end
end

for _, name in ipairs(modules) do
	local realm = string.sub(name, 1, 2)

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		local ok, err = pcall(include, "dubz_cosmetics/" .. name)

		if not ok then
			ErrorNoHalt("[DubzCosmetics] " .. name .. " failed to load: " .. tostring(err) .. "\n")
			if realm == "sh" then fail(name .. " failed, so the rest depends on it.") return end
		end
	end
end

MsgC(Color(120, 220, 120), "[DubzCosmetics] ", color_white, "loaded (" .. (SERVER and "server" or "client") .. ")\n")

-- Dubz Framework: hand the framework a manifest so Cosmetics shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework it still runs with the sh_config.lua values.
if SERVER then AddCSLuaFile("dubz_cosmetics/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_cosmetics",
	name = "Dubz Cosmetics",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_cosmetics/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
