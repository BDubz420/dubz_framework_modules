-- Dubz Vending Machines: soda machines placed by staff that players RENT to earn money on sales, and sodas that take away hunger.
-- Settings: Dubz Framework admin menu (!dubzconfig > Vending Machines).
--
-- Something wrong? Run  dubz_vending_check  in the server console: it lists which files are there.
DubzVending = DubzVending or {}
DubzVending.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_vending.lua"}

local function exists(name) return file.Exists("dubz_vending/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_vending_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzVending] lua/dubz_vending/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzVending] loaded: " .. tostring(DubzVending.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}

	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzVending] ", color_white, "missing file(s) in lua/dubz_vending/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Not loaded." .. string.char(10))
		return
	end

	AddCSLuaFile("dubz_vending/sh_config.lua")
	AddCSLuaFile("dubz_vending/sh_framework.lua")
end

local function load(name)
	local ok, err = pcall(include, "dubz_vending/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzVending] ", color_white, name .. " failed to load: " .. tostring(err) .. string.char(10))
		return false
	end

	return true
end

local good = load("sh_config.lua")
if good and SERVER then good = load("sv_vending.lua") and good end

DubzVending.Loaded = good

-- Dubz Framework: hand the framework a manifest so Vending Machines shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_vending",
	name = "Dubz Vending Machines",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_vending/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
