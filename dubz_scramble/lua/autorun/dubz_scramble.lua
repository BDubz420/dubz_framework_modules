-- Dubz Scramble: a scrambled word every so often, first correct answer in chat wins cash.
-- Settings and the word list live in lua/dubz_scramble/sh_config.lua and the Dubz Framework admin menu (!dubzconfig).
DubzScramble = DubzScramble or {}

-- The addon is two parts: this autorun and the lua/dubz_scramble/ folder. If the folder didn't upload, say so
-- instead of failing with several confusing errors.
for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "sv_scramble.lua"}) do
	-- the server file is never sent to clients, so only the server checks for it
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_scramble/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzScramble] ", color_white, "lua/dubz_scramble/" .. name .. " is missing. Upload the whole lua/dubz_scramble/ folder (not just the autorun). Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_scramble/sh_config.lua")
	AddCSLuaFile("dubz_scramble/sh_framework.lua")
end

include("dubz_scramble/sh_config.lua")

if SERVER then
	local ok, err = pcall(include, "dubz_scramble/sv_scramble.lua")
	if not ok then ErrorNoHalt("[DubzScramble] sv_scramble.lua failed to load: " .. tostring(err) .. "\n") end
end

-- Dubz Framework: hand the framework a manifest so Scramble shows up in the admin config menu.
-- Works whichever autorun runs first; without the framework it runs with the sh_config.lua values.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_scramble",
	name = "Dubz Scramble",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_scramble/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
