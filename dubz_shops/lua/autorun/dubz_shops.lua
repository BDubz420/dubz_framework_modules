-- Dubz Shops: the shop engine. NPC shops with a Buy tab and a Sell tab that put what you buy in your pocket: the general store (it can travel
-- between spots), the furniture salesman, the starter kits (pick a path), and the dealer's wares (opened from the dealer's conversation).
-- What each shop sells and buys is a table in the Dubz Framework admin menu (!dubzconfig > Shops).
--
-- Something wrong? Run  dubz_shops_check  in the server console: it lists which files are there.
DubzShops = DubzShops or {}
DubzShops.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_shops.lua", "cl_shops.lua"}

local function exists(name) return file.Exists("dubz_shops/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_shops_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzShops] lua/dubz_shops/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzShops] loaded: " .. tostring(DubzShops.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}

	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzShops] ", color_white, "missing file(s) in lua/dubz_shops/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Not loaded." .. string.char(10))
		return
	end

	AddCSLuaFile("dubz_shops/sh_config.lua")
	AddCSLuaFile("dubz_shops/sh_framework.lua")
	AddCSLuaFile("dubz_shops/cl_shops.lua")
end

local function load(name)
	local ok, err = pcall(include, "dubz_shops/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzShops] ", color_white, name .. " failed to load: " .. tostring(err) .. string.char(10))
		return false
	end

	return true
end

local good = load("sh_config.lua")
if good then
	if SERVER then good = load("sv_shops.lua") and good else good = load("cl_shops.lua") and good end
end

DubzShops.Loaded = good

-- Dubz Framework: hand the framework a manifest so the Drug Dealer shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_shops",
	name = "Dubz Shops",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_shops/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
