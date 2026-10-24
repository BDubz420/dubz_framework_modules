-- Dubz Scoreboard (based on the Elegant DarkRP Scoreboard): the TAB scoreboard.
-- Settings live in lua/dubz_scoreboard/sh_config.lua and appear in the Dubz Framework admin menu (!dubzconfig).
-- It is built from framework controls, so it needs the Dubz Framework addon; without it the default scoreboard shows.
DubzScoreboard = DubzScoreboard or {}

if SERVER then
	AddCSLuaFile("dubz_scoreboard/sh_config.lua")
	AddCSLuaFile("dubz_scoreboard/sh_framework.lua")
	AddCSLuaFile("dubz_scoreboard/cl_scoreboard.lua")
end

include("dubz_scoreboard/sh_config.lua")

if CLIENT then
	local ok, err = pcall(include, "dubz_scoreboard/cl_scoreboard.lua")
	if not ok then ErrorNoHalt("[DubzScoreboard] cl_scoreboard.lua failed to load: " .. tostring(err) .. "\n") end
end

-- Dubz Framework: hand the framework a manifest so the scoreboard shows up in the admin config menu.
-- Works whichever autorun runs first.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_scoreboard",
	name = "Dubz Scoreboard",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_scoreboard/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
