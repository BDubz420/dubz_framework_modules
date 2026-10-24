-- Dubz Laws: the city's laws in two lists, LEGAL and ILLEGAL, so a mayor can say weed is legal (or not) and everyone can see both.
-- Commands for the mayor (they replace DarkRP's /addlaw and /removelaw):
--     /addlegal <law>      /addillegal <law>      /removelegal <number>      /removeillegal <number>      /resetlaws
-- The F1 laws panel, the F4 laws tab and the laws billboards (/placelaws) all show the two lists. Settings and the starting (fixed) laws:
-- Dubz Framework admin menu (!dubzconfig > Laws).
--
-- Something wrong? Run  dubz_laws_check  in the server console: it lists which files are there.
DubzLaws = DubzLaws or {}
DubzLaws.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_laws.lua", "cl_laws.lua"}

local function exists(name) return file.Exists("dubz_laws/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_laws_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzLaws] lua/dubz_laws/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzLaws] loaded: " .. tostring(DubzLaws.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzLaws] ", color_white, "missing file(s) in lua/dubz_laws/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Run dubz_laws_check for the list.\n")
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "cl_laws.lua"}) do
		if exists(name) then AddCSLuaFile("dubz_laws/" .. name) end
	end
end

local function load(name)
	if SERVER and not exists(name) then return false end

	local ok, err = pcall(include, "dubz_laws/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzLaws] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")

if SERVER then good = load("sv_laws.lua") and good else good = load("cl_laws.lua") and good end

DubzLaws.Loaded = good

-- Dubz Framework: hand the framework a manifest so Laws shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_laws",
	name = "Dubz Laws",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_laws/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
