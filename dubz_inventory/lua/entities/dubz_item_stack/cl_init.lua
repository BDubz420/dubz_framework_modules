include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local distance = LocalPlayer():GetPos():Distance(self:GetPos())
	if distance > 300 then return end

	local alpha = math.Clamp(255 * (1 - distance / 300), 0, 255)
	local qty = self:GetNWInt("StackQty", 1)
	local text = self:GetNWString("StackName", "Item") .. (qty > 1 and (" x" .. qty) or "")

	cam.Start3D2D(self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 8), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.08)
		draw.WordBox(6, 0, 0, text, "DermaLarge", Color(0, 0, 0, 150 * alpha / 255), Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
