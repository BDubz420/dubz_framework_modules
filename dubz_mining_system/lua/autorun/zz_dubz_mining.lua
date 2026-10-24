-- Dubz Mining: rocks to break with a pickaxe, gems and ore chunks that go in the pocket (and show their colour there), a forge that
-- turns ore into ingots, a crafting table, a buyer and a minecart. Two skills in the Dubz Skills menu drive it: Mining (pickaxe
-- swing damage, speed and bonus ore) and Crafting (which recipes you can make). Everything, including the gems, ingots, rocks, recipes
-- is edited live in the Dubz Framework admin menu (!dubzconfig > Mining). The entities are spawn-menu
-- entities (Dubz Mining System): place them and make them permanent with a perma-props tool.
--
-- Replaces the old mining addon: delete these from the server (they would load the old system on top of this one):
--   lua/autorun/dubz_mining_config.lua, dubz_mining_config_editor.lua, dubz_mining_init.lua,
--   lua/autorun/client/cl_dubz_mining_system_init.lua, and lua/dubz_mining/core.lua, levels.lua, pickaxes.lua, utils.lua, weapons.lua
--
-- This file is named zz_ on purpose: autorun files load alphabetically, and the old mining files (dubz_mining_*.lua) reset the
-- DubzMining table. Loading last keeps the new system from being wiped by them.
--
-- Something wrong? Run  dubz_mining_check  in the server console: it lists which files are there.
DubzMining = DubzMining or {}
DubzMining.Loaded = false

local FILES = {"sh_config.lua", "sh_mining.lua", "sh_framework.lua", "sv_mining.lua", "cl_mining.lua"}

local function exists(name) return file.Exists("dubz_mining/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_mining_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzMining] lua/dubz_mining/" .. name .. ": " .. (exists(name) and "found" or "MISSING") .. (file.Size("lua/dubz_mining/" .. name, "GAME") == 0 and " (EMPTY)" or "")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzMining] loaded: " .. tostring(DubzMining.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	-- Say which files are missing, then carry on with what is there (a missing one must not hide the rest)
	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	for _, name in ipairs({"autorun/dubz_mining_config.lua", "autorun/dubz_mining_config_editor.lua", "autorun/dubz_mining_init.lua", "autorun/client/cl_dubz_mining_system_init.lua", "dubz_mining/core.lua", "dubz_mining/levels.lua", "dubz_mining/pickaxes.lua", "dubz_mining/utils.lua", "dubz_mining/weapons.lua"}) do
		if file.Exists(name, "LUA") then MsgC(Color(255, 80, 80), "[DubzMining] ", color_white, "OLD mining file still on the server, delete it: lua/" .. name .. "\n") end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzMining] ", color_white, "missing file(s) in lua/dubz_mining/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Run dubz_mining_check for the list.\n")
	end

	-- Send the files clients need (only those that exist)
	for _, name in ipairs({"sh_config.lua", "sh_mining.lua", "sh_framework.lua", "cl_mining.lua"}) do
		if exists(name) then AddCSLuaFile("dubz_mining/" .. name) end
	end

	-- The pickaxe's models
	for _, ext in ipairs({".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"}) do
		resource.AddFile("models/dubz_mining/v_pickaxe" .. ext)
		resource.AddFile("models/dubz_mining/w_pickaxe" .. ext)
	end
	resource.AddFile("models/dubz_mining/w_pickaxe.phy")
end

-- Load in order; a file that errors says so
local function load(name)
	if not exists(name) then return false end

	local ok, err = pcall(include, "dubz_mining/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzMining] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")
good = load("sh_mining.lua") and good

if SERVER then good = load("sv_mining.lua") and good else good = load("cl_mining.lua") and good end

DubzMining.Loaded = good

-- Dubz Framework: hand the framework a manifest so Mining shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_mining",
	name = "Dubz Mining",
	version = "3.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_mining/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
