-- Dubz Characters: the first thing a player sees. A full-screen start menu (Continue / Create Character / Discord /
-- Server Rules) where they pick or create a character: a name, a model (look) and a starting outfit. Until one is
-- chosen they can't move, be hurt, be seen or chat. Settings live in lua/dubz_characters/sh_config.lua and the Dubz
-- Framework admin menu (!dubzconfig). Needs the Dubz Cosmetics addon (it owns the looks and clothing).
DubzChars = DubzChars or {}

local files = {"sh_config.lua", "sh_framework.lua", "sv_characters.lua", "cl_menu.lua", "cl_welcome.lua"}

for _, name in ipairs(files) do
	-- the server file is never sent to clients, so only the server checks for it
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_characters/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzChars] ", color_white, "lua/dubz_characters/" .. name .. " is missing. Upload the whole lua/dubz_characters/ folder (not just the autorun). Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_characters/sh_config.lua")
	AddCSLuaFile("dubz_characters/sh_framework.lua")
	AddCSLuaFile("dubz_characters/cl_menu.lua")
	AddCSLuaFile("dubz_characters/cl_welcome.lua")
end

include("dubz_characters/sh_config.lua")

if SERVER then
	local ok, err = pcall(include, "dubz_characters/sv_characters.lua")
	if not ok then ErrorNoHalt("[DubzChars] sv_characters.lua failed to load: " .. tostring(err) .. "\n") end
else
	include("dubz_characters/cl_menu.lua")
	include("dubz_characters/cl_welcome.lua")
end

-- Dubz Framework: hand the framework a manifest so Characters shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_characters",
	name = "Dubz Characters",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_characters/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
