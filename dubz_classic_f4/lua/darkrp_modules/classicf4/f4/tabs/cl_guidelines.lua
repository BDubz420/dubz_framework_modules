-- Guidelines tab (commented out below; also switched off in cl_frame.lua).
local F4 = DubzF4

--[[

function F4.Menu.Tabs.Guidelines( parent )
	
	local frame = F4.Frame

	local guidelines = vgui.Create( "DCollapsibleCategory" )
	guidelines:SetLabel( "Everything you need to know about Vintage RP!" )
	guidelines:Dock( TOP )
	guidelines:DockMargin( 10, 5, 10, 5 )
	guidelines.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, F4.C.cat2 ) end
	
	local guidelinespanel = vgui.Create( "DPanelList" )
	guidelinespanel:SetSpacing( 0 )
	guidelinespanel:EnableHorizontal( false )
	guidelinespanel:EnableVerticalScrollbar( true )

	local guidelineslabel = guidelinespanel:Add( "DLabel" )
	guidelineslabel:SetText( F4.Config.Rules )
	guidelineslabel:SetFont( "HUDNumber5" )
	guidelineslabel:Dock( FILL )

	guidelines:SetContents( guidelinespanel )

	parent:AddSheet( "Guidelines", guidelines, "icon16/book_addresses.png" )
end
--]]
