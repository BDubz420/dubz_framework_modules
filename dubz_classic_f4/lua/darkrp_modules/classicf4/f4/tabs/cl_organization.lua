-- Organization tab: shows the Gang12 gang menu (create a gang, or manage yours) inside the F4.
-- Gang12 keeps its own panels (DRPGangPanel / DRPCreateGangPanel); this tab just hosts them and
-- swaps between them when you join or leave a gang while the menu is open.
local F4 = DubzF4

function F4.Menu.Tabs.Organization( parent )

	local frame = F4.Frame

	local container = vgui.Create( "DPanel", parent )
	container:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	container.Paint = function( self, w, h ) end

	-- Gang12 not installed / not loaded: say so instead of erroring
	if not ( gangs and vgui.GetControlTable( "DRPGangPanel" ) ) then
		local label = vgui.Create( "DLabel", container )
		label:Dock( TOP )
		label:DockMargin( 10, 10, 10, 0 )
		label:SetText( "The organization system isn't available right now." )
		label:SizeToContents()

		parent:AddSheet( "Organization", container, "icon16/gun.png" )
		return
	end

	local currentGang

	local function build()
		container:Clear()

		currentGang = LocalPlayer():getGang()

		local class = currentGang ~= "" and "DRPGangPanel" or "DRPCreateGangPanel"

		local panel = vgui.Create( class, container )
		panel:Dock( FILL )
		if derma.GetNamedSkin( "DarkRP" ) then panel:SetSkin( "DarkRP" ) end
		panel:Refresh()
	end

	build()

	-- Joined, left or created a gang: show the matching panel
	container.Think = function( self )
		if LocalPlayer():getGang() ~= currentGang then build() end
	end

	parent:AddSheet( "Organization", container, "icon16/gun.png" )
end
