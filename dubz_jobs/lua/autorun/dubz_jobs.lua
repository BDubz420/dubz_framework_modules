-- Dubz Jobs: changing job without being respawned. DarkRP normally kills or respawns a player when their job changes,
-- which wipes their position, health, weapons and ammo. This keeps the player where they are and carries over what they
-- hold (everything except the old job's own tools, with the ammo in each gun), while the new job's outfit goes on and
-- its loadout is given. Settings: Dubz Framework admin menu (!dubzconfig > Jobs). Outfits per job are the "Job Outfits"
-- table in the Cosmetics page.
DubzJobs = DubzJobs or {}

local files = {"sh_config.lua", "sh_items.lua", "sh_jobs.lua", "sh_framework.lua", "sv_jobs.lua", "sv_dialog.lua", "cl_dialog.lua"}

for _, name in ipairs(files) do
	-- the server file is never sent to clients, so only the server checks for it
	local needed = string.sub(name, 1, 2) ~= "sv" or SERVER
	if needed and not file.Exists("dubz_jobs/" .. name, "LUA") then
		MsgC(Color(255, 80, 80), "[DubzJobs] ", color_white, "lua/dubz_jobs/" .. name .. " is missing. Upload the whole lua/dubz_jobs/ folder (not just the autorun). Not loaded.\n")
		return
	end
end

if SERVER then
	for _, name in ipairs({"sh_config.lua", "sh_items.lua", "sh_jobs.lua", "sh_framework.lua", "cl_dialog.lua"}) do
		AddCSLuaFile("dubz_jobs/" .. name)
	end
end

include("dubz_jobs/sh_config.lua")
include("dubz_jobs/sh_items.lua")
include("dubz_jobs/sh_jobs.lua")

if SERVER then
	for _, name in ipairs({"sv_jobs.lua", "sv_dialog.lua"}) do
		local ok, err = pcall(include, "dubz_jobs/" .. name)
		if not ok then ErrorNoHalt("[DubzJobs] " .. name .. " failed to load: " .. tostring(err) .. "\n") end
	end
else
	include("dubz_jobs/cl_dialog.lua")
end

-- Dubz Framework: hand the framework a manifest so Jobs shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_jobs",
	name = "Dubz Jobs",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_jobs/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
