-- Dubz Third Person: a third person camera (hold Alt to look around the player without turning them, bobbing, shoulder swap) with F7 to switch
-- between first and third person. Settings for the server: Dubz Framework admin menu (!dubzconfig > Third Person). Each player's own camera
-- settings (distance, shoulder, bobbing, keybind ...) are console variables with a ready-made panel, so the F4 settings tab can show them.
--
-- Replaces the older Dubz / Nathan third person scripts: remove those from the server (this one removes their hooks too).
-- Something wrong? Run  dubz_thirdperson_check  in the server console: it lists which files are there.
DubzThirdPerson = DubzThirdPerson or {}
DubzThirdPerson.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_thirdperson.lua", "cl_thirdperson.lua"}

local function exists(name) return file.Exists("dubz_thirdperson/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_thirdperson_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzThirdPerson] lua/dubz_thirdperson/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzThirdPerson] loaded: " .. tostring(DubzThirdPerson.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}

	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzThirdPerson] ", color_white, "missing file(s) in lua/dubz_thirdperson/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Not loaded." .. string.char(10))
		return
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "cl_thirdperson.lua"}) do AddCSLuaFile("dubz_thirdperson/" .. name) end
end

local function load(name)
	local ok, err = pcall(include, "dubz_thirdperson/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzThirdPerson] ", color_white, name .. " failed to load: " .. tostring(err) .. string.char(10))
		return false
	end

	return true
end

local good = load("sh_config.lua")

if good then
	if SERVER then good = load("sv_thirdperson.lua") and good else good = load("cl_thirdperson.lua") and good end
end

DubzThirdPerson.Loaded = good

-- Dubz Framework: hand the framework a manifest so Third Person shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_thirdperson",
	name = "Dubz Third Person",
	version = "2.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_thirdperson/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
