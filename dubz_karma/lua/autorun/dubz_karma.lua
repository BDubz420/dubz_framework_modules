-- Dubz Karma loader: karma value, its rules, and player commends (reputation).
-- Files live in lua/dubz_karma/. Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
DubzKarma = DubzKarma or {}

local modules = {
	"sh_config.lua",
	"sh_api.lua",
	"sv_karma.lua",
	"sv_commends.lua",
}

local missing = {}
for _, name in ipairs(modules) do
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_karma/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	MsgC(Color(255, 80, 80), "[DubzKarma] ", color_white,
		#missing .. " file(s) missing from lua/dubz_karma/ (first: " .. missing[1] .. "). Upload the whole folder. Not loaded.\n")
	return
end

for _, name in ipairs(modules) do
	local path = "dubz_karma/" .. name
	local realm = string.sub(name, 1, 2)

	if realm ~= "sv" and SERVER then AddCSLuaFile(path) end

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		local ok, err = pcall(include, path)
		if not ok then ErrorNoHalt("[DubzKarma] " .. name .. " failed to load: " .. tostring(err) .. "\n") end
		if not ok and realm == "sh" then return end
	end
end

-- Dubz Framework: hand the framework a manifest so Dubz Karma shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework it still runs with the sh_config.lua values.
if SERVER then AddCSLuaFile("dubz_karma/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_karma",
	name = "Dubz Karma",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_karma/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
