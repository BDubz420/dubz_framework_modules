include("shared.lua")

local TITLES = {clothing = "Clothing", accessories = "Accessories"}

function ENT:Draw()
	self:DrawModel()

	local distance = EyePos():DistToSqr(self:GetPos())
	if distance > 350 * 350 then return end

	local alpha = math.Clamp(255 * (1 - distance / (350 * 350)), 0, 255)
	local ang = Angle(0, EyeAngles().y - 90, 90)

	cam.Start3D2D(self:GetPos() + Vector(0, 0, 82), ang, 0.115)
		draw.SimpleTextOutlined(TITLES[self:GetKind()] or "Store", "Trebuchet24", 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, alpha))
		draw.SimpleTextOutlined("press E", "DermaDefault", 0, 4, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha))
	cam.End3D2D()
end
