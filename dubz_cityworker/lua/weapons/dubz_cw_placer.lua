-- The City Worker Placer (superadmins): puts down the spots of the street jobs (gas leaks, fire hydrants, rubble, electrical faults, benches) where you point,
-- saved for the map. Left click: a menu of what to put down. Right click: take away the spot nearest to where you point. Reload: refresh the list.
-- While you hold it every spot of the map is drawn with its number and kind.
SWEP.Base = "weapon_base"

SWEP.PrintName = "City Worker Placer"
SWEP.Author = "BDubz420"
SWEP.Category = "Dubz City Worker"
SWEP.Instructions = "Left click: place a job spot. Right click: remove the nearest one. Reload: refresh."
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Slot = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.HoldType = "revolver"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	if SERVER then DubzCW.SendSpots(self:GetOwner()) end

	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.4)

	if CLIENT and IsFirstTimePredicted() then
		if IsValid(self.PlaceMenu) then self.PlaceMenu:Remove() end

		local menu = DermaMenu()

		for _, entry in ipairs(DubzCW.SpotKinds) do
			menu:AddOption(entry.name, function()
				net.Start("DubzCW_PlaceAdd")
					net.WriteString(entry.id)
				net.SendToServer()
			end)
		end

		menu.OnRemove = function() gui.EnableScreenClicker(false) end
		menu:Open(ScrW() / 2, ScrH() / 2)
		gui.EnableScreenClicker(true)

		self.PlaceMenu = menu
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.4)

	if CLIENT and IsFirstTimePredicted() then
		net.Start("DubzCW_PlaceRemove")
		net.SendToServer()
	end
end

function SWEP:Reload()
	if SERVER and (self.NextRefresh or 0) < CurTime() then
		self.NextRefresh = CurTime() + 1
		DubzCW.SendSpots(self:GetOwner())
	end
end

if CLIENT then
	local spots = {}

	net.Receive("DubzCW_SpotList", function()
		spots = util.JSONToTable(net.ReadString()) or {}
	end)

	local NAMES = {}

	for _, entry in ipairs(DubzCW.SpotKinds) do NAMES[entry.id] = entry.name end

	-- Where a click would put a spot (the same trace the server uses: props count)
	local function aimPoint()
		local ply = LocalPlayer()

		return util.TraceLine({start = ply:GetShootPos(), endpos = ply:GetShootPos() + ply:GetAimVector() * 8000, filter = ply, mask = MASK_SHOT})
	end

	-- Every spot of the map, with its number and what it is
	function SWEP:DrawHUD()
		for _, spot in ipairs(spots) do
			local screen = Vector(spot.x, spot.y, spot.z):ToScreen()

			if screen.visible then
				draw.SimpleTextOutlined("#" .. spot.id, "DermaDefaultBold", screen.x, screen.y - 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
				draw.SimpleTextOutlined(NAMES[spot.kind] or spot.kind, "DermaDefault", screen.x, screen.y, Color(255, 215, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
			end
		end

		-- The point a click would use
		local hit = aimPoint().HitPos:ToScreen()

		if hit.visible then
			surface.SetDrawColor(80, 255, 120, 255)
			surface.DrawRect(hit.x - 4, hit.y - 1, 8, 2)
			surface.DrawRect(hit.x - 1, hit.y - 4, 2, 8)
		end
	end

	-- In the world: a small ball on every spot with a line the way it faces (a leak sprays along it), and a marker where a click would put one
	hook.Add("PostDrawTranslucentRenderables", "DubzCW_PlacerWorld", function()
		local ply = LocalPlayer()
		local weapon = IsValid(ply) and ply:GetActiveWeapon()

		if not (IsValid(weapon) and weapon:GetClass() == "dubz_cw_placer") then return end

		render.SetColorMaterial()

		for _, spot in ipairs(spots) do
			local pos = Vector(spot.x, spot.y, spot.z)
			local forward = Angle(spot.p or 0, spot.yaw or 0, spot.r or 0):Forward()

			render.DrawSphere(pos, 2.5, 10, 10, Color(255, 215, 80, 200))
			render.DrawLine(pos, pos + forward * 24, Color(255, 120, 60), false)
		end

		local trace = aimPoint()

		render.DrawSphere(trace.HitPos, 1.5, 8, 8, Color(80, 255, 120, 230))
		render.DrawLine(trace.HitPos, trace.HitPos + trace.HitNormal * 16, Color(80, 255, 120), false)
	end)
end
