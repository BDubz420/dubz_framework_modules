-- The base of the City Worker's hand tools (the wrench, pliers, shovel and hammer are this with their own name, model and DubzCWTool). A tool does nothing by
-- itself: the City Worker addon watches a worker who holds or clicks left click with the right tool on the right spot (sv_cityworker.lua). The tool's own model is
-- the view model (held out in front), and in the world it sits in the right hand. No bobbing: the tool is still, except for the swing of a tool that has a
-- SwingStyle (the shovel scoops). Both views use the same motion, so what you see is what the others see.
SWEP.Base = "weapon_base"

SWEP.PrintName = "City Worker Tool"
SWEP.Author = "BDubz420"
SWEP.Category = "Dubz City Worker"
SWEP.Instructions = "Left click on the glowing spot of a job."
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.HoldType = "passive"                    -- (arms held forward and still: the tool is carried, not swung like a weapon)

SWEP.ViewModel = "models/props_c17/tools_wrench01a.mdl"
SWEP.WorldModel = "models/props_c17/tools_wrench01a.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DubzCWTool = "wrench"                   -- what the repair job calls this tool
SWEP.ConfigKey = nil                         -- "Shovel": the hand position of the tool is dialled in the settings (ShovelHandX, ShovelHandY ...)
SWEP.SwingStyle = nil                        -- "scoop": a click moves the tool
SWEP.SwingTime = 0.8
SWEP.ClickDelay = 0.6

-- Where the tool sits: in front of the view (forward, right, up) and how it is turned; and in the hand in the world
SWEP.ViewOffset = Vector(18, 9, -9)
SWEP.ViewTurn = Angle(90, -90, 0)            -- (turned about the view's right axis, then its up axis, then its forward axis)
SWEP.HandOffset = Vector(3, 1, -2)           -- (forward, right, up from the right hand)
SWEP.HandTurn = Angle(0, 180, 90)

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.ClickDelay)

	local owner = self:GetOwner()

	-- (the swing is told to everyone through the weapon itself)
	if SERVER and IsValid(owner) then
		self:SetNWFloat("SwingAt", CurTime())

		-- (a single click is a step of its own: snipping a wire, a scoop of the shovel)
		if DubzCW and DubzCW.ToolClick then DubzCW.ToolClick(owner, self.DubzCWTool) end
	end
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

-- The tool's own position values: the settings when the tool has a ConfigKey (dialled in the admin menu), else the ones above
function SWEP:HandValues()
	local cfg = DubzCW and DubzCW.Config

	if self.ConfigKey and cfg and cfg[self.ConfigKey .. "HandX"] then
		local key = self.ConfigKey

		return Vector(cfg[key .. "HandX"], cfg[key .. "HandY"], cfg[key .. "HandZ"]), Angle(cfg[key .. "HandP"], cfg[key .. "HandYaw"], cfg[key .. "HandR"])
	end

	return self.HandOffset, self.HandTurn
end

if CLIENT then
	local function ease(t) return t * t * (3 - 2 * t) end

	-- The swing: how far into it (0 to 1), or nil. Returns forward, up and pitch to add.
	function SWEP:SwingValues()
		if not self.SwingStyle then return 0, 0, 0 end

		local t = (CurTime() - self:GetNWFloat("SwingAt", -100)) / self.SwingTime
		if t < 0 or t > 1 then return 0, 0, 0 end

		-- Scoop: dig in (forward and down, blade tipped down), then lift and tip the load away, then settle
		local dig = t < 0.4 and ease(t / 0.4) or 1 - ease((t - 0.4) / 0.6)
		local lift = t > 0.4 and math.sin(math.pi * (t - 0.4) / 0.6) or 0

		return 9 * dig, -9 * dig + 7 * lift, 20 * dig - 30 * lift
	end

	function SWEP:GetViewModelPosition(pos, ang)
		local owner = self:GetOwner()

		-- (the tool is somewhere else for now: the wrench sits on the hydrant)
		if IsValid(owner) and owner:GetNWBool("dcw_hide") then return pos + ang:Forward() * -200 + ang:Up() * -200, ang end

		local forward, up, pitch = self:SwingValues()

		pos = pos + ang:Forward() * (self.ViewOffset.x + forward) + ang:Right() * self.ViewOffset.y + ang:Up() * (self.ViewOffset.z + up)

		ang:RotateAroundAxis(ang:Right(), self.ViewTurn.p + pitch)
		ang:RotateAroundAxis(ang:Up(), self.ViewTurn.y)
		ang:RotateAroundAxis(ang:Forward(), self.ViewTurn.r)

		return pos, ang
	end

	function SWEP:DrawWorldModel()
		local owner = self:GetOwner()

		if not IsValid(owner) then
			self:DrawModel()
			return
		end

		if owner:GetNWBool("dcw_hide") then return end

		local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if not bone then return end

		local pos, ang = owner:GetBonePosition(bone)
		local offset, turn = self:HandValues()

		pos = pos + ang:Forward() * offset.x + ang:Right() * offset.y + ang:Up() * offset.z

		ang:RotateAroundAxis(ang:Right(), turn.p)
		ang:RotateAroundAxis(ang:Forward(), turn.r)
		ang:RotateAroundAxis(ang:Up(), turn.y)

		-- The same swing as the first person view, about the player's own sideways axis
		local forward, up, pitch = self:SwingValues()

		if pitch ~= 0 or forward ~= 0 or up ~= 0 then
			local flat = Angle(0, owner:EyeAngles().y, 0)

			pos = pos + flat:Forward() * forward + flat:Up() * up
			ang:RotateAroundAxis(flat:Right(), pitch)
		end

		self:SetRenderOrigin(pos)
		self:SetRenderAngles(ang)
		self:DrawModel()
	end
end
