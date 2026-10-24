-- Dubz Gestures: hold G for a small menu of gestures and taunts, with a live preview of the one under the mouse on your own model. Click one
-- to play it; everyone nearby sees it. Settings: Dubz Framework admin menu (!dubzconfig > Gestures).
-- Files live in lua/dubz_gestures/. Prefix = realm: sh_ shared, sv_ server only, cl_ client only.
--
-- Something wrong? Run  dubz_gestures_check  in the server console: it lists which files are there.
DubzGestures = DubzGestures or {}
DubzGestures.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_gestures.lua", "cl_gestures.lua"}

local function exists(name) return file.Exists("dubz_gestures/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_gestures_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzGestures] lua/dubz_gestures/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzGestures] loaded: " .. tostring(DubzGestures.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzGestures] ", color_white, "missing file(s) in lua/dubz_gestures/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Not loaded.\n")
		return
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "cl_gestures.lua"}) do AddCSLuaFile("dubz_gestures/" .. name) end
end

local function load(name)
	local ok, err = pcall(include, "dubz_gestures/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzGestures] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")

if good then
	if SERVER then good = load("sv_gestures.lua") and good else good = load("cl_gestures.lua") and good end
end

DubzGestures.Loaded = good

-- Dubz Framework: hand the framework a manifest so Gestures shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_gestures",
	name = "Dubz Gestures",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_gestures/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
