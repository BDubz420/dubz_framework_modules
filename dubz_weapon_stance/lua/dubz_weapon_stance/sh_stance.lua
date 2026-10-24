-- Weapon Stance (shared, runs on the server and on every client). The active weapon of a handled pack (M9K ...) is held in its RAISED pose while the
-- player aims, fires or reloads, and in the LOWERED pose the rest of the time, running included.
--
-- Why both sides: M9K sets its own hold type from code that runs on the client as well as the server (when you start or stop sprinting, aim, deploy ...).
-- Changing it only on the server loses to that. So each handled weapon gets its SetHoldType wrapped: whatever M9K asks for, the pose that is
-- really set is the one that is right for the moment (raised or lowered). The server also tells everyone whether a player is aiming right now
-- (the dubz_stance_up value), so other players' guns look right on your screen.
local cfg = DubzStance.Config

local RIFLE = {ar2 = true, smg = true, crossbow = true, rpg = true, physgun = true, grenade = true}
local PISTOL = {pistol = true, revolver = true}
local SHOTGUN = {shotgun = true}

local function handled(wep)
	local class = string.lower(wep:GetClass())

	for _, prefix in ipairs(cfg.prefixes or {}) do
		if prefix ~= "" and string.StartWith(class, string.lower(prefix)) then return true end
	end

	return table.HasValue(cfg.classes or {}, class)
end

-- The lowered pose for a raised one (nil for weapons that are left alone: melee, grenades ...)
local function loweredFor(raised)
	if PISTOL[raised] then return cfg.lowerPistol end
	if SHOTGUN[raised] then return cfg.lowerShotgun end
	if RIFLE[raised] then return cfg.lowerRifle end

	return nil
end

-- The pose it is raised to: the weapon's own hold type, remembered the first time we see it (before anything here changes it)
local function raisedHold(wep)
	if not wep.DubzStanceRaised then
		local own = wep.HoldType
		if not isstring(own) or own == "" then own = wep:GetHoldType() end

		wep.DubzStanceRaised = own
	end

	return wep.DubzStanceRaised
end

-- Aiming: the weapon's ironsights state (M9K names it differently between versions); with none, the right mouse button
local function ironsights(ply, wep)
	if wep.GetIronsights and wep:GetIronsights() == true then return true end
	if wep.GetIronSights and wep:GetIronSights() == true then return true end
	if wep:GetNWBool("Ironsights", false) or wep:GetNWBool("IronSights", false) then return true end
	if wep.GetIronsights or wep.GetIronSights then return false end   -- the weapon says it is not aiming

	return ply:KeyDown(IN_ATTACK2)
end

local function sprinting(ply)
	return ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > 160
end

-- Should this weapon be raised right now? Known exactly for the local player (and on the server); for other players on a client, the server's word.
function DubzStance.Up(ply, wep)
	local now = CurTime()

	if cfg.raiseOnReload and (ply.DubzStanceReloadUntil or 0) > now then return true end
	if cfg.raiseOnFire and ply:KeyDown(IN_ATTACK) then return true end
	if now - (ply.DubzStanceShot or 0) < cfg.raiseSeconds then return true end

	local aim = ironsights(ply, wep)

	-- Running does not aim the gun: the weapon may call a run "aiming" (its sprint pose), so only the right mouse button counts then
	if aim and sprinting(ply) and not ply:KeyDown(IN_ATTACK2) then aim = false end

	return aim
end

local function upFor(ply, wep)
	if CLIENT and ply ~= LocalPlayer() then return ply:GetNWBool("dubz_stance_up", false) end

	return DubzStance.Up(ply, wep)
end

-- Wrapping SetHoldType --------------------------------------------------------------------------------------------------------------------------

local function hijack(wep)
	if wep.DubzStanceHijacked then return end
	wep.DubzStanceHijacked = true

	raisedHold(wep)

	for _, name in ipairs({"SetHoldType", "SetWeaponHoldType"}) do
		local original = wep[name]

		if original then
			wep["DubzStanceOriginal" .. name] = original

			wep[name] = function(self, hold, ...)
				local ply = self:GetOwner()

				if not (IsValid(ply) and DubzStance.Enabled() and handled(self)) then return original(self, hold, ...) end

				-- A raised-type pose that is asked for is what this gun is raised to (the weapon may change it: a silenced one ...)
				if loweredFor(hold) then self.DubzStanceRaised = hold end

				local raised = self.DubzStanceRaised
				local lowered = raised and loweredFor(raised)
				if not lowered then return original(self, hold, ...) end

				return original(self, upFor(ply, self) and raised or lowered, ...)
			end
		end
	end
end

-- Puts the right pose on a player's active weapon now
local function enforce(ply, wep, up)
	local raised = raisedHold(wep)
	local lowered = loweredFor(raised)
	if not lowered then return end

	hijack(wep)

	local want = up and raised or lowered

	if wep:GetHoldType() ~= want then wep:SetHoldType(want) end
end

-- A reload ends when the magazine has gone up (a moment later, so the end of the animation plays too) or after Reload Seconds
local function updateReload(ply, wep, now)
	if not ply.DubzStanceReloadUntil then return end

	if ply.DubzStanceReloadClip and wep:Clip1() > ply.DubzStanceReloadClip then
		ply.DubzStanceReloadUntil = math.min(ply.DubzStanceReloadUntil, now + 0.6)
		ply.DubzStanceReloadClip = nil
	end

	if now >= ply.DubzStanceReloadUntil then ply.DubzStanceReloadUntil, ply.DubzStanceReloadClip = nil, nil end
end

-- The loop -----------------------------------------------------------------------------------------------------------------------------------------

if SERVER then
	-- A shot just went out: keeps the gun raised for a moment
	hook.Add("EntityFireBullets", "DubzStance_Fired", function(ent)
		if IsValid(ent) and ent:IsPlayer() then ent.DubzStanceShot = CurTime() end
	end)

	timer.Create("DubzStance_Think", 0.05, 0, function()
		if not DubzStance.Enabled() then return end

		local now = CurTime()

		for _, ply in ipairs(player.GetAll()) do
			local wep = ply:Alive() and ply:GetActiveWeapon()

			if IsValid(wep) and handled(wep) then
				updateReload(ply, wep, now)

				local up = DubzStance.Up(ply, wep)

				if ply:GetNWBool("dubz_stance_up", false) ~= up then ply:SetNWBool("dubz_stance_up", up) end   -- (everyone's screens follow it)

				enforce(ply, wep, up)
			elseif ply:GetNWBool("dubz_stance_up", false) then
				ply:SetNWBool("dubz_stance_up", false)
			end
		end
	end)

	-- Putting a gun away puts it back to how it came, so nothing else is left changed
	hook.Add("PlayerSwitchWeapon", "DubzStance_Restore", function(ply, old)
		if IsValid(old) and old.DubzStanceRaised then
			local set = old.DubzStanceOriginalSetHoldType or old.SetHoldType
			if old:GetHoldType() ~= old.DubzStanceRaised then set(old, old.DubzStanceRaised) end
		end
	end)
else
	-- On a client the same, for everyone's gun you can see: yours from your own input, the others' from the server's word
	timer.Create("DubzStance_ClientThink", 0.03, 0, function()
		if not DubzStance.Enabled() then return end

		local now = CurTime()

		for _, ply in ipairs(player.GetAll()) do
			local wep = ply:Alive() and ply:GetActiveWeapon()

			if IsValid(wep) and handled(wep) then
				if ply == LocalPlayer() then updateReload(ply, wep, now) end

				enforce(ply, wep, upFor(ply, wep))
			end
		end
	end)
end

-- Raised BEFORE the weapon starts to reload (or fire) -------------------------------------------------------------------------------------------
-- The third person animation for a reload is picked from the hold type at the moment it starts, and the lowered poses have no reload animation:
-- waiting for the loop above would play it in the wrong pose or not at all. StartCommand runs before the weapon handles the key (on the server and,
-- predicted, on the client), so the hold type is already the raised one when the reload begins.
hook.Add("StartCommand", "DubzStance_Early", function(ply, cmd)
	if not DubzStance.Enabled() or not IsValid(ply) or not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not handled(wep) then return end

	local raised = raisedHold(wep)
	if not loweredFor(raised) then return end

	local raise = false

	if cfg.raiseOnReload and cmd:KeyDown(IN_RELOAD) and not ply.DubzStanceReloadUntil then
		local clip, max = wep:Clip1(), wep:GetMaxClip1()

		-- A real reload: there is room in the magazine and ammo to put in it
		if max > 0 and clip >= 0 and clip < max and ply:GetAmmoCount(wep:GetPrimaryAmmoType()) > 0 then
			ply.DubzStanceReloadUntil = CurTime() + cfg.reloadSeconds
			ply.DubzStanceReloadClip = clip
			raise = true
		end
	end

	if cfg.raiseOnFire and cmd:KeyDown(IN_ATTACK) then raise = true end

	if raise then
		hijack(wep)

		if wep:GetHoldType() ~= raised then wep:SetHoldType(raised) end
	end
end)
