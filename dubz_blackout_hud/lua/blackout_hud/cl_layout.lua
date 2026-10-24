-- Screen layout manager. Every HUD card asks for a slot with BHUD.Place(anchor, w, h) and is handed a
-- position that doesn't overlap anything already placed in that anchor this frame; later cards stack
-- after earlier ones. Call order in cl_hud.lua therefore decides who sits where (agenda/laws first,
-- then popups below them).
--
-- Anchors: topleft, topcenter, topright, bottomleft, bottomcenter, bottomright
local GAP = 6
local MARGIN = 10

local cursors = {}

function BHUD.LayoutBegin()
	local cfg = BHUD.Config
	local top = BHUD.PanelTop()
	local bottom = ScrH() - MARGIN - (cfg.flip and cfg.barHeight or 0)

	cursors.topleft, cursors.topcenter, cursors.topright = top, top, top
	cursors.bottomleft, cursors.bottomcenter, cursors.bottomright = bottom, bottom, bottom
end

-- The next free y in an anchor (for sizing a card before placing it).
function BHUD.LayoutCursor(anchor)
	return cursors[anchor] or BHUD.PanelTop()
end

-- Reserves a w x h box in the anchor and returns its x, y.
function BHUD.Place(anchor, w, h)
	local cursor = cursors[anchor] or BHUD.PanelTop()
	local sw = ScrW()
	local x, y

	if string.sub(anchor, 1, 3) == "top" then
		y = cursor
		cursors[anchor] = y + h + GAP
	else
		y = cursor - h
		cursors[anchor] = y - GAP
	end

	if string.find(anchor, "left", 1, true) then
		x = MARGIN
	elseif string.find(anchor, "right", 1, true) then
		x = sw - w - MARGIN
	else
		x = (sw - w) / 2
	end

	return x, y
end
