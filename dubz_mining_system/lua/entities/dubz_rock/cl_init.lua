include("shared.lua")

function ENT:Draw()
	if self:GetMined() then return end

	self:DrawModel()

	local distance = LocalPlayer():GetPos():Distance(self:GetPos())
	if distance > DubzMining.Config.rockDrawDistance then return end

	local max = math.max(self:GetRockMax(), 1)
	local percent = math.Clamp(self:GetRockHP() / max, 0, 1)

	cam.Start3D2D(self:GetPos() + Vector(0, 0, 30), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
		draw.RoundedBox(8, -110, -10, 220, 44, Color(0, 0, 0, 170))
		draw.SimpleTextOutlined("Rock " .. math.Round(percent * 100) .. "%", "HUDNumber5", 0, -8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
		draw.RoundedBox(4, -90, 20, 180, 8, Color(40, 40, 40))
		draw.RoundedBox(4, -90, 20, 180 * percent, 8, Color(255, 90, 60))
	cam.End3D2D()
end
