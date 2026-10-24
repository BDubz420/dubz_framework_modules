-- Dubz Temp Ranks: give a player a user group (VIP ...) for a limited time; it reverts when the time is up.
-- Settings live in lua/dubz_temp_ranks/sh_config.lua and the Dubz Framework admin menu (!dubzconfig). Staff open the
-- grant window with !tempranks. Other addons (the credits shop) call DubzTempRanks:AddTempRank(ply, group, seconds).
DubzTempRanks = DubzTempRanks or {}

local files = {"sh_config.lua", "sh_framework.lua", "sv_core.lua", "sv_net.lua", "cl_menu.lua"}

local function needed(name)
	local prefix = string.sub(name, 1, 2)
	if prefix == "sv" then return SERVER end
	if prefix == "cl" then return true end   -- the server needs it to send it to clients
	return true
end

for _, name in ipairs(files) do
	if needed(name) and not file.Exists("dubz_temp_ranks/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzTempRanks] ", color_white, "lua/dubz_temp_ranks/" .. name .. " is missing. Upload the whole lua/dubz_temp_ranks/ folder (not just the autorun). Not loaded.\n")
		return
	end
end

if SERVER then
	AddCSLuaFile("dubz_temp_ranks/sh_config.lua")
	AddCSLuaFile("dubz_temp_ranks/sh_framework.lua")
	AddCSLuaFile("dubz_temp_ranks/cl_menu.lua")
end

include("dubz_temp_ranks/sh_config.lua")

if SERVER then
	for _, name in ipairs({"sv_core.lua", "sv_net.lua"}) do
		local ok, err = pcall(include, "dubz_temp_ranks/" .. name)
		if not ok then ErrorNoHalt("[DubzTempRanks] " .. name .. " failed to load: " .. tostring(err) .. "\n") end
	end
else
	include("dubz_temp_ranks/cl_menu.lua")
end

-- Dubz Framework: hand the framework a manifest so Temp Ranks shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_temp_ranks",
	name = "Dubz Temp Ranks",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_temp_ranks/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
