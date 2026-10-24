-- Rules tab: the server rules from the admin menu's "Rules" table, numbered, with a search box. Edit them live in
-- !dubzconfig > F4 Menu > Rules.
local F4 = DubzF4

function F4.Menu.Tabs.Rules( parent )

	local frame = F4.Frame

	local panel = vgui.Create( "DPanel", parent )
	panel:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	panel.Paint = function( self, w, h ) end

	local search = vgui.Create( "DTextEntry", panel )
	search:Dock( TOP )
	search:DockMargin( 10, 8, 10, 4 )
	search:SetTall( 24 )
	search:SetPlaceholderText( "Search the rules..." )

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:Dock( FILL )
	scroll:DockMargin( 10, 4, 10, 8 )

	local function build()

		scroll:Clear()

		local query = string.lower( string.Trim( search:GetValue() ) )
		local shown = 0

		for index, rule in ipairs( F4.Rules or {} ) do

			if query == "" or string.find( string.lower( rule ), query, 1, true ) then

				shown = shown + 1

				-- A plain list: no row backgrounds, just the number and the rule
				local line = vgui.Create( "DLabel" )
				line:Dock( TOP )
				line:DockMargin( 6, 0, 6, 8 )
				line:SetWrap( true )
				line:SetAutoStretchVertical( true )
				line:SetText( index .. ".  " .. rule )
				line:SetTextColor( F4.C.text )
				line:SetFont( "DermaDefault" )

				scroll:AddItem( line )

			end

		end

		if shown == 0 then

			local none = vgui.Create( "DLabel" )
			none:Dock( TOP )
			none:DockMargin( 4, 8, 4, 0 )
			none:SetTextColor( F4.C.text )
			none:SetText( query == "" and "No rules have been set." or "No rule matches that." )
			scroll:AddItem( none )

		end

	end

	search.OnChange = build
	build()

	parent:AddSheet( "Rules", panel, "icon16/book_addresses.png" )
end
