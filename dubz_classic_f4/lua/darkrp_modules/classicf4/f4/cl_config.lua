-- F4 colour tables (the menu's settings are in lua/dubz_f4/sh_config.lua).
local F4 = DubzF4

-- The settings (header, mayor, gang leaders, tabs) live in lua/dubz_f4/sh_config.lua and the admin menu.

-- Colours follow the Dubz Framework theme (switch the theme in the admin menu and F4 follows). F4.C.<name> is read
-- every time it is drawn, so a theme change shows the next time you open F4. The greys are mixed from the theme's
-- text colour over its background, which reproduces the original look on the default theme.
local function theme()
	return DFW and DFW.UI and DFW.UI.GetTheme and DFW.UI.GetTheme() or nil
end

local function mix( base, over, amount )
	return Color(
		base.r + ( over.r - base.r ) * amount,
		base.g + ( over.g - base.g ) * amount,
		base.b + ( over.b - base.b ) * amount,
		255
	)
end

local FALLBACK = {
	surface = Color( 0, 0, 0, 120 ), background = Color( 0, 0, 0, 160 ), text = Color( 255, 255, 255 ),
	cat = Color( 70, 70, 70 ), cat2 = Color( 60, 60, 60 ), row = Color( 40, 40, 40 ), row2 = Color( 45, 45, 45 ),
	dark = Color( 20, 20, 20 ), dark2 = Color( 5, 5, 5 ), grey = Color( 80, 80, 80 ), grey2 = Color( 90, 90, 90 ),
	header = Color( 140, 0, 0 ), laws = Color( 255, 20, 20 ), darkAlpha = Color( 20, 20, 20, 200 ),
}

F4.C = setmetatable( {}, {
	__index = function( _, key )
		local t = theme()
		if not t then return FALLBACK[key] end

		local base = Color( t.background.r, t.background.g, t.background.b, 255 )

		if key == "surface" then return t.surface end
		if key == "background" then return t.background end
		if key == "text" then return t.text end
		if key == "cat" then return mix( base, t.text, 0.27 ) end
		if key == "cat2" then return mix( base, t.text, 0.235 ) end
		if key == "row" then return mix( base, t.text, 0.157 ) end
		if key == "row2" then return mix( base, t.text, 0.176 ) end
		if key == "dark" then return mix( base, t.text, 0.08 ) end
		if key == "dark2" then return mix( base, t.text, 0.02 ) end
		if key == "grey" then return mix( base, t.text, 0.31 ) end
		if key == "grey2" then return mix( base, t.text, 0.35 ) end
		if key == "header" then return mix( base, t.accent, 0.55 ) end
		if key == "laws" then return t.accent end
		if key == "darkAlpha" then return Color( t.track.r, t.track.g, t.track.b, 200 ) end

		return FALLBACK[key]
	end,
} )

local COLORS = setmetatable( {}, {
	__index = function( _, key )
		if key == "Header" then return F4.C.header end
		if key == "Balance" then return F4.C.row2 end
		if key == "TextWhite" then return F4.C.text end

		return ( {
			Conversion = Color( 200, 200, 200 ),
			Boost      = Color( 0, 140, 60 ),
			Event      = Color( 200, 140, 0 ),
			TextDark   = Color( 20, 20, 20 ),
		} )[key]
	end,
} )

local RARITY_COLORS = {
    common = Color(120,120,120),
    uncommon = Color(80,160,80),
    rare = Color(80,120,255),
    epic = Color(180,80,200),
    legendary = Color(255,140,0)
}
