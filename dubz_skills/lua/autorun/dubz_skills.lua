-- Dubz Skills: a Project Zomboid style skill sheet (10 blocks per skill) plus the skills themselves.
-- Files live in lua/dubz_skills/. Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
DubzSkills = DubzSkills or {}

-- Order matters: config -> registry -> skills that register themselves -> server/client parts.
local modules = {
	"sh_config.lua",
	"sh_skills.lua",
	"sh_movement.lua",
	"sv_skills.lua",
	"sv_movement.lua",
	"sv_admin.lua",
	"cl_menu.lua",
}

local missing = {}
for _, name in ipairs(modules) do
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_skills/" .. name, "LUA") then missing[#missing + 1] = name end
end

if #missing > 0 then
	MsgC(Color(255, 80, 80), "[DubzSkills] ", color_white,
		#missing .. " file(s) missing from lua/dubz_skills/ (first: " .. missing[1] .. "). Upload the whole folder. Not loaded.\n")
	return
end

-- Send client files first so one broken server file can't stop clients from getting them.
if SERVER then
	for _, name in ipairs(modules) do
		if string.sub(name, 1, 2) ~= "sv" then AddCSLuaFile("dubz_skills/" .. name) end
	end
end

for _, name in ipairs(modules) do
	local realm = string.sub(name, 1, 2)

	if realm == "sh" or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT) then
		local ok, err = pcall(include, "dubz_skills/" .. name)
		if not ok then ErrorNoHalt("[DubzSkills] " .. name .. " failed to load: " .. tostring(err) .. "\n") end
		if not ok and realm == "sh" then return end
	end
end

-- Dubz Framework: hand the framework a manifest so Skills shows up in the admin config menu (!dubzconfig).
-- Works whichever autorun runs first; without the framework installed the skills still run with sh_config.lua values.
if SERVER then AddCSLuaFile("dubz_skills/sh_framework.lua") end

DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_skills",
	name = "Dubz Skills",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_skills/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
