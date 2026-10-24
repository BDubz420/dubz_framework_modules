-- Dubz Weapon Stance: makes other weapon packs (M9K) hold their guns the way DarkRP's own guns do. DarkRP's guns are carried LOWERED until you
-- aim (or have just fired), and only then raised to the aiming pose; M9K's guns are held in the aiming pose all the time. This lowers them
-- when you are not aiming, with the same lowered poses DarkRP uses (rifles and submachine guns "passive", pistols and shotguns "normal").
-- Nothing in M9K is edited: the hold type is changed from here, so it keeps working when M9K is updated.
-- Settings: Dubz Framework admin menu (!dubzconfig > Weapon Stance).
DubzStance = DubzStance or {}

DubzStance.Config = DubzStance.Config or {
	-- Weapon classes that start with one of these are handled (comma separated in the admin menu)
	prefixes = {"m9k_"},
	-- Single classes too (weapons from other packs)
	classes = {},

	raiseSeconds = 1.0,       -- stays raised this long after firing (DarkRP's guns use 1 second)
	raiseOnFire = true,       -- pressing fire raises the gun at once (otherwise only aiming does)
	raiseOnReload = true,     -- raised while reloading
	reloadSeconds = 4,        -- the longest a reload keeps the gun raised (it lowers sooner once the magazine is full)

	-- In third person the crosshair stays when you aim (first person hides it down the sights). A simple cross, drawn where the shots go.
	thirdPersonCrosshair = true,
	crosshairSize = 7,        -- length of each line
	crosshairGap = 5,         -- the gap in the middle
	crosshairThickness = 2,

	-- The lowered pose for each raised one (the weapon's own hold type -> what it is lowered to). DarkRP: rifles and submachine guns
	-- "passive", pistols and shotguns "normal".
	lowerRifle = "passive",   -- ar2, smg, crossbow, rpg ...
	lowerPistol = "normal",   -- pistol, revolver
	lowerShotgun = "normal",  -- shotgun
}

function DubzStance.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("weapon_stance")
end

if SERVER then
	local missing = {}

	for _, name in ipairs({"sh_framework.lua", "sh_stance.lua", "cl_stance.lua"}) do
		if not file.Exists("dubz_weapon_stance/" .. name, "LUA") then missing[#missing + 1] = name end
	end

	if #missing > 0 then
		MsgC(Color(255, 80, 80), "[DubzStance] ", color_white, "missing file(s) in lua/dubz_weapon_stance/: " .. table.concat(missing, ", ") .. ". Upload the whole addon folder (lua/autorun AND lua/dubz_weapon_stance). Not loaded." .. string.char(10))
		return
	end

	AddCSLuaFile("dubz_weapon_stance/sh_framework.lua")
	AddCSLuaFile("dubz_weapon_stance/sh_stance.lua")
	AddCSLuaFile("dubz_weapon_stance/cl_stance.lua")
end

-- The pose logic runs on the server and on every client (see sh_stance.lua)
include("dubz_weapon_stance/sh_stance.lua")

if CLIENT then include("dubz_weapon_stance/cl_stance.lua") end

-- Dubz Framework: hand the framework a manifest so Weapon Stance shows up in the admin config menu.
DFW = DFW or {}
DFW.PendingPackages = DFW.PendingPackages or {}

local manifest = {
	id = "dubz_weapon_stance",
	name = "Dubz Weapon Stance",
	version = "1.0.0",
	api = 1,
	dependencies = {"dubz_framework"},
	files = {"dubz_weapon_stance/sh_framework.lua"},
}

if DFW.Packages and DFW.Packages.Submit then
	DFW.Packages.Submit(manifest)
else
	DFW.PendingPackages[#DFW.PendingPackages + 1] = manifest
end
