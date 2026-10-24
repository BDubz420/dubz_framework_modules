-- Dubz City Worker: a repair job. A worker is sent to a broken machine and has to do the work in steps with the wrench and the pliers (pull the machine
-- out, take the back plate off, swap the circuit board, put it all back), then is paid and gets a piece of scrap. The first task is the vending machine
-- (the Dubz Vending Machine addon); more tasks are added the same way. The job is created for DarkRP here and its NPC (the foreman) is the Dubz Jobs addon's.
-- Settings: Dubz Framework admin menu (!dubzconfig > City Worker).
--
-- Something wrong? Run  dubz_cityworker_check  in the server console: it lists which files are there.
DubzCW = DubzCW or {}
DubzCW.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sh_job.lua", "sv_cityworker.lua", "sv_spots.lua", "sv_task_vending.lua", "sv_task_spots.lua", "sv_task_bench.lua", "sv_foreman.lua", "cl_cityworker.lua"}

local function exists(name) return file.Exists("dubz_cityworker/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_cityworker_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzCityWorker] lua/dubz_cityworker/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzCityWorker] loaded: " .. tostring(DubzCW.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}

	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzCityWorker] ", color_white, "missing file(s) in lua/dubz_cityworker/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Not loaded." .. string.char(10))
		return
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "sh_job.lua", "cl_cityworker.lua"}) do
		AddCSLuaFile("dubz_cityworker/" .. name)
	end
end

local function load(name)
	local ok, err = pcall(include, "dubz_cityworker/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzCityWorker] ", color_white, name .. " failed to load: " .. tostring(err) .. string.char(10))
		return false
	end

	return true
end

local good = load("sh_config.lua")
good = load("sh_job.lua") and good

if SERVER then
	good = load("sv_cityworker.lua") and good
	good = load("sv_spots.lua") and good
	good = load("sv_task_vending.lua") and good
	good = load("sv_task_spots.lua") and good
	good = load("sv_task_bench.lua") and good
	good = load("sv_foreman.lua") and good
else
	good = load("cl_cityworker.lua") and good
end

DubzCW.Loaded = good

-- Dubz Framework: hand the framework a manifest so City Worker shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_cityworker",
	name = "Dubz City Worker",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_cityworker/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
