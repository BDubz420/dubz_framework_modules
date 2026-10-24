-- Dubz Exchange: the Bank Teller (a private item vault for each character) and the Exchange Clerk (a market where anyone can list items for
-- any player on the server to buy, even while the seller is offline). Both are NPCs: spawn them from the entities tab (Dubz Exchange)
-- and keep them with a perma-props tool. Settings: Dubz Framework admin menu (!dubzconfig > Exchange).
--
-- Something wrong? Run  dubz_exchange_check  in the server console: it lists which files are there.
DubzExchange = DubzExchange or {}
DubzExchange.Loaded = false

local FILES = {"sh_config.lua", "sh_framework.lua", "sv_exchange.lua", "cl_exchange.lua"}

local function exists(name) return file.Exists("dubz_exchange/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_exchange_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzExchange] lua/dubz_exchange/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzExchange] loaded: " .. tostring(DubzExchange.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzExchange] ", color_white, "missing file(s) in lua/dubz_exchange/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Run dubz_exchange_check for the list.\n")
	end

	for _, name in ipairs({"sh_config.lua", "sh_framework.lua", "cl_exchange.lua"}) do
		if exists(name) then AddCSLuaFile("dubz_exchange/" .. name) end
	end
end

local function load(name)
	-- (the server checks the file is there; a client just includes it and reports a problem, since what the server sent may not show in file.Exists)
	if SERVER and not exists(name) then return false end

	local ok, err = pcall(include, "dubz_exchange/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzExchange] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")

if SERVER then good = load("sv_exchange.lua") and good else good = load("cl_exchange.lua") and good end

DubzExchange.Loaded = good

-- Dubz Framework: hand the framework a manifest so Exchange shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_exchange",
	name = "Dubz Exchange",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_exchange/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
