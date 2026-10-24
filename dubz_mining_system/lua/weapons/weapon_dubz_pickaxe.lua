-- The pickaxe: swing at a rock to break it. How hard and how fast it swings comes from the player's Mining skill level.
-- Everything is edited in the admin menu (!dubzconfig > Mining).
if CLIENT then
	SWEP.PrintName = "Pickaxe"
	SWEP.Slot = 1
	SWEP.SlotPos = 5
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false

	-- custom swing animation state
	SWEP.SwingActive = false
	SWEP.SwingEnd = 0

	function SWEP:StartSwing(duration)
		self.SwingActive = true
		self.SwingEnd = CurTime() + duration
	end

	-- Heavy downward swing animation
	function SWEP:GetViewModelPosition(pos, ang)
		if not self.SwingActive then return pos, ang end

		local frac = math.Clamp((self.SwingEnd - CurTime()) / 0.25, 0, 1)
		frac = frac * frac

		ang:RotateAroundAxis(ang:Right(), Lerp(frac, 0, 55))
		ang:RotateAroundAxis(ang:Up(), Lerp(frac, 0, -25))
		ang:RotateAroundAxis(ang:Forward(), Lerp(frac, 0, -15))

		pos = pos + ang:Forward() * Lerp(frac, 0, 8)
		pos = pos + ang:Right() * Lerp(frac, 0, -5)
		pos = pos + ang:Up() * Lerp(frac, 0, -3)

		if CurTime() >= self.SwingEnd then self.SwingActive = false end

		return pos, ang
	end
end

SWEP.Base = "weapon_base"

SWEP.Author = "BDubz420"
SWEP.Instructions = "Left click to mine"
SWEP.Contact = ""
SWEP.Purpose = "Break rocks."

SWEP.ViewModel = "models/dubz_mining/v_pickaxe.mdl"
SWEP.WorldModel = "models/dubz_mining/w_pickaxe.mdl"

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.HoldType = "melee"
SWEP.UseHands = true

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Dubz Mining System"

SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local REACH = 70

function SWEP:Initialize()
	self:SetHoldType("melee")
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local cfg = DubzMining.Config
	self:SetNextPrimaryFire(CurTime() + DubzMining.SwingDelay(owner))
	owner:SetAnimation(PLAYER_ATTACK1)

	-- A swing that hits nothing near looks and sounds like a miss
	local near = owner:GetShootPos():Distance(owner:GetEyeTrace().HitPos) <= REACH and owner:GetEyeTrace().Hit
	self:SendWeaponAnim(near and ACT_VM_HITCENTER or ACT_VM_MISSCENTER)
	if not near then self:EmitSound(table.Random(DubzMining.Sounds.swing), 75, math.random(95, 110)) end

	if CLIENT then
		self:StartSwing(0.15)
		return
	end

	timer.Simple(cfg.hitDelay, function()
		if not IsValid(self) or not IsValid(owner) or owner:GetActiveWeapon() ~= self then return end

		owner:LagCompensation(true)
		local trace = owner:GetEyeTrace()
		owner:LagCompensation(false)

		if owner:GetShootPos():Distance(trace.HitPos) > REACH then return end

		local ent = trace.Entity

		if IsValid(ent) and ent:GetClass() == "dubz_rock" then
			-- The Mining level decides how much health the rock loses
			ent:Mine(owner, DubzMining.Damage(owner))
			self:EmitSound(table.Random(DubzMining.Sounds.hitRock), 80, math.random(95, 110))
		elseif trace.HitWorld then
			self:EmitSound(table.Random(DubzMining.Sounds.hitWorld), 75, math.random(95, 110))
		end

		hook.Run("DubzMiningPickaxeHit", owner, trace)
	end)
end

function SWEP:Deploy() return true end
function SWEP:Holster() return true end
function SWEP:FireAnimationEvent() return true end
