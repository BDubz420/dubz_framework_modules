-- Dubz Scrap: trash from the dumpsters that is scrapped (right click it in the pocket) into plastic, metal, cloth, leather and wood.
-- The scrap is used to craft at the crafting table (Dubz Mining), melted in the forge (metal into steel bars) or sold to other players.
-- Everything, the scrap materials and the trash that comes out of the dumpsters, is edited live in the Dubz Framework admin menu
-- (!dubzconfig > Scrap).
--
-- Something wrong? Run  dubz_scrap_check  in the server console: it lists which files are there.
DubzScrap = DubzScrap or {}
DubzScrap.Loaded = false

local FILES = {"sh_config.lua", "sh_scrap.lua", "sh_framework.lua", "sv_scrap.lua", "cl_scrap.lua"}

local function exists(name) return file.Exists("dubz_scrap/" .. name, "LUA") end

if SERVER then
	concommand.Add("dubz_scrap_check", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		for _, name in ipairs(FILES) do
			local text = "[DubzScrap] lua/dubz_scrap/" .. name .. ": " .. (exists(name) and "found" or "MISSING")
			if IsValid(ply) then ply:ChatPrint(text) else print(text) end
		end

		local text = "[DubzScrap] loaded: " .. tostring(DubzScrap.Loaded)
		if IsValid(ply) then ply:ChatPrint(text) else print(text) end
	end)

	local missing = {}
	for _, name in ipairs(FILES) do
		if not exists(name) then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzScrap] ", color_white, "missing file(s) in lua/dubz_scrap/: " .. table.concat(missing, ", ") .. ". Upload the whole folder. Run dubz_scrap_check for the list.\n")
	end

	for _, name in ipairs({"sh_config.lua", "sh_scrap.lua", "sh_framework.lua", "cl_scrap.lua"}) do
		if exists(name) then AddCSLuaFile("dubz_scrap/" .. name) end
	end
end

local function load(name)
	-- (the server checks the file is there; a client just includes it and reports a problem, since what the server sent may not show in file.Exists)
	if SERVER and not exists(name) then return false end

	local ok, err = pcall(include, "dubz_scrap/" .. name)

	if not ok then
		MsgC(Color(255, 80, 80), "[DubzScrap] ", color_white, name .. " failed to load: " .. tostring(err) .. "\n")
		return false
	end

	return true
end

local good = load("sh_config.lua")
good = load("sh_scrap.lua") and good

if SERVER then good = load("sv_scrap.lua") and good else good = load("cl_scrap.lua") and good end

DubzScrap.Loaded = good

-- Dubz Framework: hand the framework a manifest so Scrap shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_scrap",
	name = "Dubz Scrap",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_scrap/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
