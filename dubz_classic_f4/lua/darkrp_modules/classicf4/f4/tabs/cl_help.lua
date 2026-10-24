-- How to Play tab: the keys and commands, read live from the admin menu's "How To Play" table. Tokens in the text
-- ({laws_key} {skills_key} {pocket_key} {bag_key} {cinematic_key} {surrender_key} {thirdperson_key} {shoulder_key}) show the real key from each
-- addon's own settings, so it never goes out of date. Not a tutorial - players can ignore it or close the menu any
-- time. The first time someone joins, a short popup points them here (once; it goes away on its own).
local F4 = DubzF4

-- Name of a key bound by an addon's config (falls back to the default if that addon isn't installed)
local function keyName( config, field, fallback )
	local code = config and config[field]
	local name = code and input.GetKeyName( code )
	return string.upper( name or fallback )
end

local function tokens()
	local hud = BHUD and BHUD.Config
	local skills = DubzSkills and DubzSkills.Config
	local pocket = DubzInv and DubzInv.Config
	local surrender = HandiesSurrender and HandiesSurrender.Config

	-- The first / third person key: the player's own choice (their third person settings) or the server's
	local thirdKey = DubzThirdPerson and DubzThirdPerson.Config
	local own = GetConVar( "dtp_key" )
	local thirdperson = ( own and own:GetInt() < 0 ) and "(no key)" or ( ( own and own:GetInt() > 0 ) and string.upper( input.GetKeyName( own:GetInt() ) or "F7" ) or keyName( thirdKey, "toggleKey", "F7" ) )
	local ownShoulder = GetConVar( "dtp_shoulder_key" )
	local shoulder
	local ownCode = ownShoulder and ownShoulder:GetInt() or 0

	if ownCode < 0 or ( ownCode == 0 and thirdKey and thirdKey.shoulderKeyEnabled == false ) then
		shoulder = "(no key)"   -- turned off
	elseif ownCode > 0 then
		shoulder = string.upper( input.GetKeyName( ownCode ) or "V" )
	else
		shoulder = keyName( thirdKey, "shoulderKey", "V" )
	end

	return {
		laws_key = keyName( hud, "lawsKey", "F1" ),
		skills_key = keyName( skills, "openKey", "F6" ),
		pocket_key = keyName( pocket, "openKey", "I" ),
		bag_key = keyName( pocket, "dropBagKey", "B" ),
		cinematic_key = keyName( hud, "cinematicKey", "F8" ),
		surrender_key = keyName( surrender, "key", "F3" ),
		thirdperson_key = thirdperson,
		shoulder_key = shoulder,
	}
end

local function expand( text, map )
	return ( string.gsub( tostring( text or "" ), "{([%w_]+)}", function( name ) return map[name] end ) )
end

-- The rows grouped in the order the table lists them
local function groups()
	local map = tokens()
	local list, byName = {}, {}

	for _, row in ipairs( F4.Help or {} ) do
		local name = expand( row.group, map )

		if not byName[name] then
			byName[name] = { name, {} }
			list[#list + 1] = byName[name]
		end

		table.insert( byName[name][2], { expand( row.key, map ), expand( row.text, map ) } )
	end

	return list
end

-- For other addons (the welcome screen): the How To Play rows grouped, with the real keys filled in
function F4.HelpGroups() return groups() end

function F4.Menu.Tabs.Help( parent )

	local frame = F4.Frame

	local panel = vgui.Create( "DPanel", parent )
	panel:SetSize( frame:GetWide(), frame:GetTall() - 70 )
	panel.Paint = function( self, w, h ) end

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:SetPos( 0, 0 )
	scroll:SetSize( panel:GetWide(), panel:GetTall() )
	scroll:GetVBar():SetWide( 0 )

	for _, group in ipairs( groups() ) do

		local cat = vgui.Create( "DCollapsibleCategory" )
		cat:SetLabel( group[1] )
		cat:Dock( TOP )
		cat:DockMargin( 0, 5, 0, 5 )
		cat.Paint = function( self, w, h ) draw.RoundedBox( 6, 0, 0, w, h, F4.C.cat ) end

		local list = vgui.Create( "DPanelList" )
		list:SetSpacing( 0 )
		list:EnableHorizontal( false )
		list:EnableVerticalScrollbar( true )

		for _, row in ipairs( group[2] ) do

			local line = list:Add( "DLabel" )
			line:SetText( "  [" .. row[1] .. "]   " .. row[2] )
			line:SetTextColor( F4.C.text )
			line:SetTall( 22 )
			line:Dock( TOP )
			line.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, F4.C.row ) end

		end

		cat:SetContents( list )
		scroll:AddItem( cat )

	end

	parent:AddSheet( "How to Play", panel, "icon16/help.png" )
end

-- One-time pointer for new players (shown through the Blackout HUD popups when it is installed). It waits for the
-- character start screen to be finished first.
local function showHint()
	if cookie.GetNumber( "dubz_help_hint_seen", 0 ) == 1 then return end
	if not ( BHUD and BHUD.ShowPopup ) then return end

	if DubzChars and DubzChars.IsChoosing and DubzChars.IsChoosing() then
		timer.Simple( 5, showHint )
		return
	end

	cookie.Set( "dubz_help_hint_seen", "1" )

	BHUD.ShowPopup( {
		key = "help_hint",
		title = "New here?",
		text = "Press F4 and open the How to Play tab for the controls.",
		duration = 15,
		anchor = "topcenter",
	} )
end

hook.Add( "InitPostEntity", "DubzF4_HelpHint", function()
	timer.Simple( 25, showHint )
end )
