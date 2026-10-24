-- Dubz NLR (New Life Rule): a timer after death, a zone around where you died, and quiet staff alerts.
-- Files live in lua/dubz_nlr/. Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
DubzNLR = DubzNLR or {}

local modules = {
	"sh_config.lua",
	"sh_api.lua",
	"sv_nlr.lua",
}

local missing = {}
for _, name in ipairs(modules) do
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_nlr/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	MsgC(Color(255, 80, 80), "[DubzNLR] ", color_white,
		#missing .. " file(s) missing from lua/dubz_nlr/ (first: " .. missing[1] .. "). Upload the whole folder. Not loaded.\n")
	return
end

-- Send client files first so one broken server file can't stop clients from getting them.
if SERVER then
	for _, name in ipairs(modules) do
		if string.sub(name, 1, 2) ~= "sv" then AddCSLuaFile("dubz_nlr/" .. name) end
	end
end

for _, name in ipairs(modules) do
	local realm = string.sub(name, 1, 2)

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		local ok, err = pcall(include, "dubz_nlr/" .. name)
		if not ok then ErrorNoHalt("[DubzNLR] " .. name .. " failed to load: " .. tostring(err) .. "\n") end
		if not ok and realm == "sh" then return end
	end
end

-- Dubz Framework: hand the framework a manifest so Dubz NLR shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework it still runs with the sh_config.lua values.
if SERVER then AddCSLuaFile("dubz_nlr/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_nlr",
	name = "Dubz NLR",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_nlr/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
