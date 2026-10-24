include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	--[[
	local pos = self:GetPos()
	local ang = self:GetAngles()

	surface.SetFont("Fontdump3")
	local text = "Ingredients"
	local TextWidth = surface.GetTextSize(text)
	local drawdistance = 245

	ang:RotateAroundAxis(ang:Up(), 90)

	if LocalPlayer():GetPos():Distance(self:GetPos()) < drawdistance then
		cam.Start3D2D(pos + ang:Up(), Angle(0, LocalPlayer():EyeAngles().y-90, 90), 0.13)
			--draw.RoundedBox( 0, -70, -100, 140, 35, Color(0,0,0,170) )
			--draw.RoundedBox( 0, -70, -65, 140, 2, Color(255,25,0,170) )
			--draw.SimpleTextOutlined( text, "ScoreboardDefault", -TextWidth *0.5, -95, Color(255,255,255,255), 0, 0, 1, Color(0,0,0) )
		cam.End3D2D()
	end
	--]]
end