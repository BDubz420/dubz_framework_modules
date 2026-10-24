surface.CreateFont("daHUDFont", {
	font = "Trebuchet18",
	size = 14,
	weight = 600,
	antialias = true,
})

surface.CreateFont("daHUDTitle", {
	font = "Trebuchet18",
	size = 15,
	weight = 800,
	antialias = true,
})

surface.CreateFont("daHUDName", {
	font = "Trebuchet18",
	size = 22,
	weight = 700,
	antialias = true,
})

surface.CreateFont("daHUDDoorTitle", {
	font = "Trebuchet24",
	size = 40,
	weight = 800,
	antialias = true,
})

surface.CreateFont("daHUDDoorText", {
	font = "Trebuchet24",
	size = 22,
	weight = 600,
	antialias = true,
})

surface.CreateFont("daHUDAmmo", {
	font = "Trebuchet18",
	size = 24,
	weight = 700,
	antialias = true,
})

surface.CreateFont("daHUDDeathBig", {
	font = "Trebuchet18",
	size = 54,
	weight = 800,
	antialias = true,
})

surface.CreateFont("daHUDDeathReason", {
	font = "Trebuchet18",
	size = 40,
	weight = 800,
	antialias = true,
})

surface.CreateFont("daHUDDeathMed", {
	font = "Trebuchet18",
	size = 26,
	weight = 700,
	antialias = true,
})

BHUD.Config.font = "daHUDFont"
BHUD.Config.titleFont = "daHUDTitle"

-- Card colours follow the Dubz Framework theme (background, text ...), so switching theme restyles the HUD.
-- `accent` stays the muted red used for text highlights on the death screen. Without the framework the original
-- plain translucent black is used.
local fallback = {
	bg = Color(0, 0, 0, 160),
	title = Color(255, 255, 255),
	text = Color(255, 255, 255),
	muted = Color(165, 155, 155),
}

local mapping = {bg = "background", title = "text", text = "text", muted = "textMuted"}

setmetatable(BHUD.Config.panel, {
	__index = function(_, key)
		if key == "accent" then return Color(190, 86, 82) end

		local themeKey = mapping[key]
		if themeKey and DFW and DFW.UI and DFW.UI.GetTheme then return DFW.UI.GetTheme()[themeKey] end

		return fallback[key]
	end,
})
