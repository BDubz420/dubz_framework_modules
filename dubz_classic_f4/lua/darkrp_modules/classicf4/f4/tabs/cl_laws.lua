-- Laws tab.
local F4 = DubzF4

function F4.Menu.Tabs.Laws( parent )
	
	local frame = F4.Frame

	local lawscat = vgui.Create( "DCollapsibleCategory" )
	lawscat:SetLabel( "These are the laws of the land." )
	lawscat:Dock( TOP )
	lawscat:DockMargin( 10, 5, 10, 5 )
	lawscat.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, F4.C.laws ) end
	
	local lawspanel = vgui.Create( "DPanelList" )
	lawspanel:SetSpacing( 0 )
	lawspanel:EnableVerticalScrollbar( true )

	-- Two lists (Dubz Laws): illegal first, then legal. Without that addon, DarkRP's single list.
	local function addSection( title, list, color )
		local header = lawspanel:Add( "DLabel" )
		header:SetText( " " .. title )
		header:SetTextColor( color )
		header.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, F4.C.row ) end
		header:Dock( TOP )

		if #list == 0 then
			local none = lawspanel:Add( "DLabel" )
			none:SetText( "   None." )
			none:Dock( TOP )
			return
		end

		for i, text in ipairs( list ) do
			local lawlabel = lawspanel:Add( "DLabel" )
			lawlabel:SetText( "  " .. i .. ". " .. text )
			lawlabel.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, F4.C.row ) end
			lawlabel:Dock( TOP )
		end
	end

	if DubzLaws and DubzLaws.Legal and DubzLaws.Illegal then
		addSection( "ILLEGAL", DubzLaws.Illegal, Color( 235, 100, 90 ) )
		addSection( "LEGAL", DubzLaws.Legal, Color( 110, 200, 120 ) )
	else
		local law = DarkRP.getLaws()

		for i = 1, #law do
			local lawlabel = lawspanel:Add( "DLabel" )
			lawlabel:SetText( " " .. law[i] )
			lawlabel.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, F4.C.row ) end
			lawlabel:Dock( TOP )
		end
	end

	lawscat:SetContents( lawspanel )

	parent:AddSheet( "Laws", lawscat, "icon16/star.png" )
end
