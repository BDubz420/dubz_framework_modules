include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	if LocalPlayer():GetPos():Distance(self:GetPos()) > 300 then return end

	for _, flip in ipairs({0, 180}) do
		cam.Start3D2D(self:GetPos() + Vector(0, 0, 20), Angle(0, self:GetAngles().y + flip, 90), 0.1)
			draw.SimpleText("Ore: " .. self:GetStored() .. " / 20", "HUDNumber5", 0, -30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
