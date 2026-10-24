include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local distance = LocalPlayer():GetPos():Distance(self:GetPos())
	if distance > 350 then return end

	local alpha = math.Clamp(255 * (1 - distance / 350), 0, 255)

	cam.Start3D2D(self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 12), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.115)
		draw.SimpleTextOutlined(DubzMining.Config.craftingTitle, "HUDNumber5", 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, alpha))
		draw.SimpleTextOutlined("press E to craft", "DermaDefault", 0, 4, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha))
	cam.End3D2D()
end
