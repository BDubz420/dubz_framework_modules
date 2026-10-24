-- Dying drops every weapon the player has except the ones in cfg.weaponBlacklist (physgun, tool gun, keys ...).
-- Dropped weapons become normal DarkRP weapon pickups, with their ammo.
local cfg = DubzInv.Config

-- Read live from the config, so editing the blacklist in the admin menu applies without a restart.
-- (Lookups go through a tiny wrapper so the code below can keep using blacklist[class].)
-- These never drop, whatever the admin table says (a saved table from before a weapon was added to the defaults, or one edited by mistake,
-- would otherwise let the tool gun fall on death)
local ALWAYS_KEEP = {
	gmod_tool = true, weapon_physgun = true, weapon_physcannon = true, gmod_camera = true, keys = true, pocket = true,
	dubz_pocket = true, dubz_hands = true, dubz_work = true, weapon_fists = true,
}

local blacklist = setmetatable({}, {
	__index = function(_, class)
		class = string.lower(tostring(class))

		return ALWAYS_KEEP[class] == true or table.HasValue(cfg.weaponBlacklist, class)
	end
})

-- DarkRP also drops the weapon you are holding when you die. Make sure it never drops a blacklisted weapon
-- (this is what was dropping the tool gun): both through DarkRP's own "canDropWeapon" hook and by wrapping
-- dropDRPWeapon itself in case a DarkRP version doesn't ask the hook.
-- Is this weapon one the player's job (or the default loadout) hands out?
function DubzInv.IsJobWeapon(ply, class)
	class = string.lower(tostring(class))

	local job = RPExtraTeams and RPExtraTeams[ply:Team()]
	for _, weapon in ipairs(job and job.weapons or {}) do
		if string.lower(weapon) == class then return true end
	end

	for _, weapon in ipairs((GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.DefaultWeapons) or {}) do
		if string.lower(weapon) == class then return true end
	end

	return false
end

local function bound(ply, weapon)
	return cfg.jobWeaponsBound and IsValid(weapon) and DubzInv.IsJobWeapon(ply, weapon:GetClass())
end

hook.Add("canDropWeapon", "DubzInv_NoDropBlacklisted", function(ply, weapon)
	if not DubzInv.Enabled() then return end
	if IsValid(weapon) and blacklist[weapon:GetClass()] then return false end
	if bound(ply, weapon) then return false end
end)

hook.Add("InitPostEntity", "DubzInv_WrapDropWeapon", function()
	local meta = FindMetaTable("Player")
	if not meta.dropDRPWeapon or meta.DubzOriginalDropDRPWeapon then return end

	meta.DubzOriginalDropDRPWeapon = meta.dropDRPWeapon

	meta.dropDRPWeapon = function(self, weapon, ...)
		if IsValid(weapon) and blacklist[weapon:GetClass()] then return end
		if DubzInv.Enabled() and bound(self, weapon) then return end
		return meta.DubzOriginalDropDRPWeapon(self, weapon, ...)
	end
end)

-- Last line of defence: whatever dropped it (DarkRP, the engine's own active-weapon drop, another addon),
-- a blacklisted weapon that appears on the floor around a corpse is removed a moment after death.
local function purgeBlacklistedDrops(pos)
	for _, ent in ipairs(ents.FindInSphere(pos, 200)) do
		if not IsValid(ent) or IsValid(ent:GetOwner()) then continue end

		local class = ent:GetClass()
		local held = ent.GetWeaponClass and ent:GetWeaponClass() or ent.weaponclass

		if blacklist[class] or (class == "spawned_weapon" and held and blacklist[held]) then
			ent:Remove()
		end
	end
end

hook.Add("DoPlayerDeath", "DubzInv_NoEngineDrop", function(ply)
	if not DubzInv.Enabled() then return end
	ply:ShouldDropWeapon(false)
end)

hook.Add("PlayerDeath", "DubzInv_PurgeDrops", function(ply)
	local pos = ply:GetPos()
	for _, delay in ipairs({0, 0.1, 0.5}) do
		timer.Simple(delay, function() purgeBlacklistedDrops(pos) end)
	end
end)

hook.Add("PlayerDeath", "DubzInv_DropWeapons", function(ply)
	if not DubzInv.Enabled() then return end   -- switched off: DarkRP's own death behaviour
	if not cfg.dropWeaponsOnDeath or not ply.dropDRPWeapon then return end

	for _, weapon in ipairs(ply:GetWeapons()) do
		if IsValid(weapon) and not blacklist[weapon:GetClass()] and not bound(ply, weapon) then
			ply:dropDRPWeapon(weapon)
		end
	end
end)
