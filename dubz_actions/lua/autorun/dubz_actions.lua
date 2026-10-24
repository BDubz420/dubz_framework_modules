-- Dubz Actions: first person "hands at work" for things players do over time: searching a dumpster, scrapping an item, crafting. While it
-- runs the player holds a hands-only weapon (dubz_work), the arms animate for what they are doing, the item being worked on sits in their
-- hands, sounds play on a beat that everyone nearby hears, and a bar fills. Other addons start one with DubzActions.Start (see sv_actions.lua).
-- Settings: Dubz Framework admin menu (!dubzconfig > Actions).
--
-- Something wrong? Run  dubz_actions_check  in the server console: it lists which files are there.
DubzActions = DubzActions or {}
DubzActions.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_actions.lua", "cl_actions.lua", "cl_anim.lua", "cl_editor.lua"}

local function exists(name) return file.Exists("dubz_actions/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_actions_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzActions] lua/dubz_actions/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzActions] loaded: " .. tostring(DubzActions.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzActions] ", color_white, "missing file(s) in lua/dubz_actions/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Run dubz_actions_check for the list.\n")
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "cl_actions.lua", "cl_anim.lua", "cl_editor.lua"}) do
		if exists(name) then AddCSLuaFile("dubz_actions/" .. name) end
	end
end

local function load(name)
	-- (the server checks the file is there; a client just includes it and reports a problem)
	if SERVER and not exists(name) then return false end

	local ok, err = pcall(include, "dubz_actions/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzActions] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")

if SERVER then
	good = load("sv_actions.lua") and good
else
	good = load("cl_anim.lua") and good
	good = load("cl_actions.lua") and good
	good = load("cl_editor.lua") and good
end

DubzActions.Loaded = good

-- Dubz Framework: hand the framework a manifest so Actions shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_actions",
	name = "Dubz Actions",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_actions/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
