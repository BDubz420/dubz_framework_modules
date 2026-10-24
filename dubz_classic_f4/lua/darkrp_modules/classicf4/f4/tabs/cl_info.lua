-- Info tab: one button per row of the admin menu's "Info Buttons" table (title + web address).
local F4 = DubzF4

function F4.Menu.Tabs.Info( parent )

	local frame = F4.Frame

	local info = vgui.Create( "DCollapsibleCategory" )
	info:SetLabel( F4.Config.InfoHeading or "Info" )
	info:Dock( TOP )
	info:DockMargin( 10, 5, 10, 5 )
	info.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, F4.C.cat2 ) end

	local infopanel = vgui.Create( "DPanelList" )
	infopanel:SetSpacing( 0 )
	infopanel:EnableHorizontal( false )
	infopanel:EnableVerticalScrollbar( true )

	for _, link in ipairs( F4.InfoLinks or {} ) do

		local title, url = tostring( link.title or "" ), tostring( link.url or "" )

		-- Only web addresses open
		if title ~= "" and ( string.StartWith( url, "https://" ) or string.StartWith( url, "http://" ) ) then

			local button = infopanel:Add( "DButton" )
			button:SetText( " " )
			button:Dock( TOP )
			button:SetTall( 28 )
			button.Paint = function( self, w, h )
				draw.RoundedBox( 0, 0, 0, w, h, self:IsHovered() and F4.C.row2 or F4.C.row )
				draw.SimpleTextOutlined( title, "DermaDefault", w * 0.5, h * 0.5, F4.C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color( 0, 0, 0 ) )
			end
			button.DoClick = function() gui.OpenURL( url ) end

		end

	end

	info:SetContents( infopanel )

	parent:AddSheet( "Info", info, "icon16/cog.png" )
end
