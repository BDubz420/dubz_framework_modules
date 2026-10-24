include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local processing = self:GetNWBool("Processing", false)

	-- Smoke while it smelts, from the back left corner (the same corner whichever way the forge faces), at the chimney's height
	if processing and CurTime() >= (self.NextSmoke or 0) then
		self.NextSmoke = CurTime() + 0.1

		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local pos = self:LocalToWorld(Vector(mins.x + 12, maxs.y - 12, 120))
		local emitter = ParticleEmitter(pos)

		if emitter then
			local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
			if p then
				p:SetVelocity(Vector(0, 0, 60) + VectorRand() * 5)
				p:SetDieTime(1.5)
				p:SetStartAlpha(80)
				p:SetEndAlpha(0)
				p:SetStartSize(12)
				p:SetEndSize(25)
				p:SetColor(100, 100, 100)
				p:SetGravity(Vector(0, 0, 15))
				p:SetAirResistance(80)
			end

			emitter:Finish()
		end
	end

	if LocalPlayer():GetPos():Distance(self:GetPos()) > 300 then return end

	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 180)

	local powered = self:GetNWBool("PoweredOn", false)

	cam.Start3D2D(self:GetPos() + self:GetForward() * 15.8 + self:GetUp() * 50, ang, 0.1)
		draw.RoundedBox(8, -125, -30, 250, processing and 150 or 90, Color(20, 20, 20, 200))

		draw.SimpleText("Forge", "HUDNumber5", 0, -12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(powered and "Power on" or "Power off", "HUDNumber5", 0, 18, powered and Color(0, 255, 0) or Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- The ingot it is about to put out, then the time left on this one
		if processing then
			local ore = self:GetNWString("CurrentIngot", "")
			local material = DubzMining.FindMaterial(ore)
			local left = math.max(self:GetNWFloat("ForgeEndTime", 0) - CurTime(), 0)

			draw.SimpleText(ore .. " Ingot", "HUDNumber5", 0, 52, material and material.color or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(math.ceil(left) .. "s", "HUDNumber5", 0, 86, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end
