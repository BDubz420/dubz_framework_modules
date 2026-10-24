-- Hands: DarkRP's keys and the fists in one weapon.
--   R toggles your fists ready / put away.
--   Fists put away (default): works like the keys. Left click locks, right click unlocks the door or vehicle
--   you are looking at (or knocks on it if it isn't yours).
--   Fists ready: left click punches.
--   Right click at a player (either way): a light push.
-- Surrendering is separate (F3, see the handies addon).
--
-- Put "dubz_hands" in your DarkRP default weapons instead of "keys" and "weapon_fists".
AddCSLuaFile()

SWEP.PrintName = "Hands"
SWEP.Author = "BDubz420"
SWEP.Instructions = "R: ready / put away your fists\nLeft click: punch (fists ready) or lock\nRight click: push a player, or unlock"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IsDarkRPKeys = true

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.UseHands = true

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Dubz"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

-- Tuning comes from DubzHands.Config (lua/dubz_hands/sh_config.lua, edited live in the Dubz Framework admin menu).
-- If that file didn't load, these are the built-in defaults.
local DEFAULTS = {
	punching = true, punchDelay = 0.45, punchRange = 75, punchDamageMin = 6, punchDamageMax = 10,
	pushing = true, pushRange = 85, pushPower = 280, pushLift = 90, pushDelay = 1.0, toggleDelay = 0.6,
	lockSound = "doors/door_latch3.wav", viewModelOffset = {x = -2.5, y = 0, z = -1},
}

local function C() return (DubzHands and DubzHands.Config) or DEFAULTS end
local function on() return not (DubzHands and DubzHands.Enabled) or DubzHands.Enabled() end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Ready")
end

function SWEP:Initialize()
	self:SetHoldType("normal")
	self.NextToggle = 0
	self.HoldApplied = "normal"
end

local function playViewModel(self, name)
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end

	local vm = owner:GetViewModel()
	if not IsValid(vm) then return end

	local seq = vm:LookupSequence(name)
	if seq and seq > 0 then vm:SendViewModelMatchingSequence(seq) end
end

function SWEP:Deploy()
	if SERVER and IsValid(self:GetOwner()) then
		self:GetOwner():DrawWorldModel(false)
		self:GetOwner():DrawViewModel(true)   -- another weapon (or surrendering) may have turned the viewmodel off
	end

	playViewModel(self, self:GetReady() and "fists_draw" or "fists_idle_01")
	return true
end

function SWEP:Holster()
	return true
end

-- The viewmodel (arms) only shows while the fists are ready; otherwise it's invisible like the keys.
function SWEP:PreDrawViewModel()
	return not self:GetReady()
end

-- Keep the hold type in sync with the ready state on both server and client
function SWEP:Think()
	local want = self:GetReady() and "fist" or "normal"

	if self.HoldApplied ~= want then
		self.HoldApplied = want
		self:SetHoldType(want)
	end
end

-- Reload: ready / put away the fists ------------------------------------------------------------------

function SWEP:Reload()
	if CurTime() < (self.NextToggle or 0) then return end
	self.NextToggle = CurTime() + C().toggleDelay

	if SERVER then
		self:SetReady(not self:GetReady())
		self:EmitSound("physics/cardboard/cardboard_box_impact_soft1.wav", 55, self:GetReady() and 110 or 90)
	end

	playViewModel(self, "fists_draw")
end

-- Keys behaviour (fists put away) -----------------------------------------------------------------------------

local function lookingAtLockable(ply, ent, hitpos)
	local eyepos = ply:EyePos()
	return IsValid(ent)
		and ent.isKeysOwnable and ent:isKeysOwnable()
		and (
			ent:isDoor() and eyepos:DistToSqr(hitpos) < 2000
			or
			ent:IsVehicle() and eyepos:DistToSqr(hitpos) < 4000
		)
end

local function lockUnlockAnimation(ply, snd)
	ply:EmitSound("npc/metropolice/gear" .. math.random(1, 6) .. ".wav")
	timer.Simple(0.9, function() if IsValid(ply) then ply:EmitSound(snd) end end)

	umsg.Start("anim_keys")
		umsg.Entity(ply)
		umsg.String("usekeys")
	umsg.End()

	ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_ITEM_PLACE, true)
end

local function doKnock(ply, sound)
	ply:EmitSound(sound, 100, math.random(90, 110))

	umsg.Start("anim_keys")
		umsg.Entity(ply)
		umsg.String("knocking")
	umsg.End()

	ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true)
end

local function keysLock(self, owner, trace)
	self:SetNextPrimaryFire(CurTime() + 0.3)
	if CLIENT then return end

	if owner:canKeysLock(trace.Entity) then
		trace.Entity:keysLock() -- lock immediately so it won't annoy people
		lockUnlockAnimation(owner, C().lockSound)
	elseif trace.Entity:IsVehicle() then
		DarkRP.notify(owner, 1, 3, DarkRP.getPhrase("do_not_own_ent"))
	else
		doKnock(owner, "physics/wood/wood_crate_impact_hard2.wav")
	end
end

local function keysUnlock(self, owner, trace)
	self:SetNextSecondaryFire(CurTime() + 0.3)
	if CLIENT then return end

	if owner:canKeysUnlock(trace.Entity) then
		trace.Entity:keysUnLock()
		lockUnlockAnimation(owner, C().lockSound)
	elseif trace.Entity:IsVehicle() then
		DarkRP.notify(owner, 1, 3, DarkRP.getPhrase("do_not_own_ent"))
	else
		doKnock(owner, "physics/wood/wood_crate_impact_hard3.wav")
	end
end

-- Fists --------------------------------------------------------------------------------------------------------

function SWEP:Punch()
	local owner = self:GetOwner()
	self:SetNextPrimaryFire(CurTime() + C().punchDelay)

	owner:SetAnimation(PLAYER_ATTACK1)

	self.PunchLeft = not self.PunchLeft
	playViewModel(self, self.PunchLeft and "fists_left" or "fists_right")

	if not SERVER then return end

	owner:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 60, math.random(95, 110))

	-- Land the hit slightly after the swing starts
	timer.Simple(0.12, function()
		if not IsValid(self) or not IsValid(owner) or not owner:Alive() then return end

		local start = owner:GetShootPos()
		local tr = util.TraceHull({
			start = start,
			endpos = start + owner:GetAimVector() * C().punchRange,
			filter = owner,
			mins = Vector(-8, -8, -8),
			maxs = Vector(8, 8, 8),
			mask = MASK_SHOT_HULL,
		})

		if not tr.Hit then return end

		local ent = tr.Entity
		if IsValid(ent) then
			local dmg = DamageInfo()
			dmg:SetAttacker(owner)
			dmg:SetInflictor(self)
			dmg:SetDamage(math.random(C().punchDamageMin, math.max(C().punchDamageMin, C().punchDamageMax)))
			dmg:SetDamageType(DMG_CLUB)
			dmg:SetDamageForce(owner:GetAimVector() * 3500)
			dmg:SetDamagePosition(tr.HitPos)
			ent:TakeDamageInfo(dmg)
		end

		local living = IsValid(ent) and (ent:IsPlayer() or ent:IsNPC())
		owner:EmitSound(living and ("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav") or "physics/flesh/flesh_impact_hard1.wav", 70, math.random(95, 110))
	end)
end

-- The shove pushes along a direction for PUSH_TIME seconds with the push easing out, so the target glides away and
-- slows down instead of being flung. Runs in the shared movement hook so the client predicts it too (no jitter).
local PUSH_TIME = 0.35

hook.Add("SetupMove", "DubzHands_Push", function(ply, mv)
	local start = ply:GetNWFloat("DubzPushStart", 0)
	if start == 0 then return end

	local t = CurTime() - start
	if t < 0 or t > PUSH_TIME then return end

	local dir = ply:GetNWVector("DubzPushDir", vector_origin)
	local power = (DubzHands and DubzHands.Config and DubzHands.Config.pushPower) or 280

	-- Easing: strongest at the start, fading to nothing; the area under it adds up to roughly `power` of speed
	local accel = (power * 1.4) * 2 / PUSH_TIME * (1 - t / PUSH_TIME)
	local velocity = mv:GetVelocity() + dir * accel * FrameTime()

	-- A tiny lift only at the very start, so ground friction doesn't grab the target
	if t < 0.05 and ply:OnGround() then velocity.z = math.max(velocity.z, math.min((DubzHands and DubzHands.Config and DubzHands.Config.pushLift or 0) * 0.2, 25)) end

	mv:SetVelocity(velocity)
end)

-- A light shove: no damage, just enough to move someone out of the way.
function SWEP:Push(target)
	local owner = self:GetOwner()
	self:SetNextSecondaryFire(CurTime() + C().pushDelay)

	owner:SetAnimation(PLAYER_ATTACK1)

	if not SERVER then return end

	local dir = owner:GetAimVector()
	dir.z = 0
	dir:Normalize()

	-- Not an instant kick (that makes the target stutter and snap as the client corrects it): the shove is a short
	-- push built up over PUSH_TIME inside the movement code (see the SetupMove hook below), on both client and server.
	target:SetNWVector("DubzPushDir", dir)
	target:SetNWFloat("DubzPushStart", CurTime())
	owner:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 65, math.random(90, 105))
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if self:GetReady() then
		if C().punching and on() then return self:Punch() end
		return
	end

	-- Left click on an item (or a backpack) picks it up, just like the pocket SWEP; otherwise it locks
	if SERVER and DubzInv and DubzInv.TryPickup and DubzInv.TryPickup(owner, true) then
		self:SetNextPrimaryFire(CurTime() + 0.3)
		return
	end

	local trace = owner:GetEyeTrace()
	if lookingAtLockable(owner, trace.Entity, trace.HitPos) then keysLock(self, owner, trace) end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local trace = owner:GetEyeTrace()
	local ent = trace.Entity

	-- A player in reach gets pushed, whether or not the fists are ready
	if IsValid(ent) and ent:IsPlayer() and owner:GetShootPos():Distance(trace.HitPos) <= C().pushRange then
		if not (C().pushing and on()) then return end
		return self:Push(ent)
	end

	if not self:GetReady() and lookingAtLockable(owner, ent, trace.HitPos) then keysUnlock(self, owner, trace) end
end

-- First-person arms position (offset in the config): pulling them back toward the camera keeps the untextured
-- back of the arms model out of view while swinging.
function SWEP:GetViewModelPosition(pos, ang)
	local offset = C().viewModelOffset
	return pos + ang:Forward() * offset.x + ang:Right() * offset.y + ang:Up() * offset.z, ang
end
