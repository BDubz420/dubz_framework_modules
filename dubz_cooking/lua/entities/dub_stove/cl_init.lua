include( "shared.lua" )

function ENT:Initialize( )
end

surface.CreateFont("DRP_StoveTitle", {
    font = "Trebuchet MS",
    size = 15,
    weight = 700,
    antialias = true
})

surface.CreateFont("DRP_StoveText", {
    font = "Trebuchet18",
    size = 10,
    weight = 200,
    antialias = true
})

function ENT:Draw( )
	self:DrawModel( )

	if ( LocalPlayer( ):GetPos( ):Distance( self:GetPos( ) ) < 256 ) then
		local Pos = self:GetPos() + ((self:GetAngles():Up()* 15) + (self:GetAngles():Forward() *19.17) + (self:GetAngles():Right()* 21.8))
		local Ang = self:GetAngles()

		Ang:RotateAroundAxis( Ang:Up( ), 90 )
		Ang:RotateAroundAxis( Ang:Forward( ), 90 )

		cam.Start3D2D( Pos + Ang:Up() * -5, Ang, 0.25 )

		draw.RoundedBox(3, 0, 0, 80, 49, Color(10, 10, 10, 180))
		draw.RoundedBox(3, 1, 40, 77, 5, Color( 10, 10, 10, 180 ))
		draw.SimpleText( "Cooking Stove", "DRP_StoveTitle", 40, 18, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )

		if self:GetTimer( ) < 0 then
			draw.SimpleText( "Waiting for ingredients", "DRP_StoveText", 40, 29, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end

		if self:GetTimer( ) > 0 then
			draw.RoundedBox(3, 2, 41, math.Round( self:GetTimer( ) *2.5 ), 3, Color( 255, 0, 0, 255 ))
			draw.SimpleText( "Cooking...", "DRP_StoveText", 40, 29, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end

		if self:GetTimer( ) == 0 then
			draw.SimpleText( "Done!", "DRP_StoveText", 40, 29, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end

		draw.RoundedBox(3, 114, 0, 46, 30, Color(10, 10, 10, 180))

		if self:GetIngAmount( ) <= 0 then
			draw.SimpleText( "ingredients", "DRP_StoveText", 137, 19, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end
		if self:GetIngAmount( ) > 0 then
			draw.SimpleText( "ingredients", "DRP_StoveText", 137, 19, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end

		draw.RoundedBox(3, 114, 40, 46, 30, Color(10, 10, 10, 180))

		if self:GetMilkAmount( ) <= 0 then
			draw.SimpleText( "Milk", "DRP_StoveText", 137, 59, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end
		if self:GetMilkAmount( ) > 0 then
			draw.SimpleText( "Milk", "DRP_StoveText", 137, 59, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 25, 25, 25, 0 ) )
		end
		cam.End3D2D( )
	end
end