include("shared.lua")

local function font()
	return (DFW and DFW.UI and DFW.UI.Font) and DFW.UI.Font("Heading") or "Trebuchet24"
end

function ENT:Draw()
	self:DrawModel()

	local distance = EyePos():DistToSqr(self:GetPos())
	if distance > 300 * 300 then return end

	-- Text floating over the box saying what is inside it
	local ang = Angle(0, EyeAngles().y - 90, 90)
	local alpha = math.Clamp(255 * (1 - distance / (300 * 300)), 0, 255)

	cam.Start3D2D(self:GetPos() + Vector(0, 0, 16), ang, 0.09)
		draw.SimpleTextOutlined(self:GetItemName(), font(), 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, alpha))
		draw.SimpleTextOutlined("accessory", "DermaDefault", 0, 4, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha))
	cam.End3D2D()
end
