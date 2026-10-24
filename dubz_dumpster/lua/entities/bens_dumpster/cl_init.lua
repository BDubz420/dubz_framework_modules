include("shared.lua")
surface.CreateFont( "Fontdump", {
	font = "Simpleness-Regular", 
	size = ScreenScale(10),
	weight = 500,
	blursize = 0,
	scanlines = 0,
	bold = true
});

surface.CreateFont( "Fontdump1", {
	font = "Simpleness-Regular", 
	size = ScreenScale(10),
	weight = 500,
	blursize = 0,
	scanlines = 0,
	bold = true
});
function ENT:Initialize()
	self.Time = 0
	self.ShowTime = 0
	net.Receive("Bens_DumpsterSendTime",function()
		net.ReadEntity().Time = CurTime()+net.ReadInt(32)
	end)
end

function ENT:Think()
	if self.Time > 0 then
		self.ShowTime = self.Time - CurTime()
	end
end

function ENT:Draw()
	self:DrawModel()
	local pos2 = self:GetPos() + ( self:GetAngles():Forward() * 23.46 ) + ( self:GetAngles():Up() *10.4  ) + (self:GetAngles():Right() *25.3)
	local ang2 = self:GetAngles()
	local eyetrace = LocalPlayer():GetEyeTrace()
	ang2:RotateAroundAxis(ang2:Up(), 90)
 	cam.Start3D2D(pos2,Angle(ang2.p,ang2.y,ang2.r+97), 0.113)
  	--draw.RoundedBox(0,-5,0,455,100, Color(32,32,37,255))
  	--draw.RoundedBox(0,-5,0,455,5, Color(248,42,74,255))
  	if LocalPlayer():GetEyeTrace().Entity then
        if LocalPlayer():GetEyeTrace().Entity == self then
            local tr = self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)
			  	if self.ShowTime == nil or self.ShowTime <= 0 then
			  		draw.SimpleText("Press 'e' to search.","Fontdump",455/2,100/2,Color(255, 255, 255, 255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			  	else
			  		draw.SimpleText(math.Round(self.ShowTime),"Fontdump",455/2,100/2,Color(255, 255, 255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			   	end
        end
    end

 	cam.End3D2D()
end



 