-- Dubz Pocket (inventory): an overhaul of DarkRP's pocket. Items you pick up are saved in slots (they don't
-- drop on death), and a worn backpack gives you more slots. The only entity it needs is dubz_backpack.
-- Files live in lua/dubz_inventory/. Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
DubzInv = DubzInv or {}

local modules = {
	"sh_config.lua",
	"sh_api.lua",
	"sv_storage.lua",
	"sv_inventory.lua",
	"sv_ownership.lua",
	"sv_held.lua",
	"sv_limits.lua",
	"sv_deathdrop.lua",
	"sv_admin.lua",
	"sv_trade.lua",
	"cl_inventory.lua",
	"cl_trade.lua",
}

local function needed(name)
	return string.sub(name, 1, 2) ~= "sv" or SERVER
end

local function fail(text)
	MsgC(Color(255, 80, 80), "[DubzInventory] ", color_white, text .. " Nothing was loaded.\n")
end

-- Everything depends on the shared files, so a missing one stops the whole addon (instead of half loading).
local missing = {}
for _, name in ipairs(modules) do
	if needed(name) and not file.Exists("dubz_inventory/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	fail("Missing file(s) in lua/dubz_inventory/: " .. table.concat(missing, ", ") .. ". Upload the whole folder.")
	return
end

-- Send client files first so one broken server file can't stop clients from getting them.
if SERVER then
	for _, name in ipairs(modules) do
		if string.sub(name, 1, 2) ~= "sv" then AddCSLuaFile("dubz_inventory/" .. name) end
	end
end

for _, name in ipairs(modules) do
	local realm = string.sub(name, 1, 2)

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		local ok, err = pcall(include, "dubz_inventory/" .. name)

		if not ok then
			ErrorNoHalt("[DubzInventory] " .. name .. " failed to load: " .. tostring(err) .. "\n")
			if realm == "sh" then fail(name .. " failed, so the rest depends on it.") return end
		end
	end
end

MsgC(Color(120, 220, 120), "[DubzInventory] ", color_white, "loaded (" .. (SERVER and "server" or "client") .. ")\n")

-- Dubz Framework: hand the framework a manifest so the inventory shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework the inventory still runs with sh_config.lua values.
if SERVER then AddCSLuaFile("dubz_inventory/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_inventory",
	name = "Dubz Pocket & Backpack",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_inventory/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
