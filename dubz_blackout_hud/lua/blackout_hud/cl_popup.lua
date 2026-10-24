-- Popup cards (wanted, arrests, lockdown, surrender, ...). They are placed by the layout manager
-- (cl_layout.lua), so popups in the same anchor stack instead of overlapping, and they sit below the
-- agenda / laws cards in the corner anchors.
--
-- Server side: BHUD.Popup() in sv_events.lua. Client side (other addons can call these directly):
--   BHUD.ShowPopup{key, title, text, color, duration (0 = until cleared), countdown, anchor, width}
--   BHUD.ClearPopup(key)
local popups = {}

local DEFAULT_WIDTH = 330
local FADE_IN, FADE_OUT = 0.25, 0.4

function BHUD.ClearPopup(key)
	if not key or key == "" then return end

	for i = #popups, 1, -1 do
		if popups[i].key == key then table.remove(popups, i) end
	end
end

function BHUD.ShowPopup(def)
	-- A new popup with the same key replaces the old one
	BHUD.ClearPopup(def.key)

	local width = def.width or DEFAULT_WIDTH
	local pad = BHUD.Config.panel.pad
	local duration = def.duration or 6

	table.insert(popups, {
		key = def.key,
		title = def.title or "",
		lines = BHUD.Wrap(def.text or "", BHUD.Config.font, width - pad * 2),
		color = def.color,
		anchor = (def.anchor and def.anchor ~= "") and def.anchor or "topcenter",
		width = width,
		born = CurTime(),
		finish = duration > 0 and (CurTime() + duration) or nil,
		countdown = def.countdown and duration > 0,
	})
end

net.Receive("BHUD_Popup", function()
	local key = net.ReadString()
	local clear = net.ReadBool()
	local title = net.ReadString()
	local text = net.ReadString()
	local color = net.ReadColor()
	local duration = net.ReadFloat()
	local countdown = net.ReadBool()
	local anchor = net.ReadString()

	if clear then
		BHUD.ClearPopup(key)
		return
	end

	BHUD.ShowPopup({key = key, title = title, text = text, color = color, duration = duration, countdown = countdown, anchor = anchor})
end)

function BHUD.DrawPopups()
	local cfg = BHUD.Config
	local pad = cfg.panel.pad
	local lineH = BHUD.LineHeight(cfg.font)
	local now = CurTime()

	for i = #popups, 1, -1 do
		if popups[i].finish and popups[i].finish <= now then table.remove(popups, i) end
	end

	for _, popup in ipairs(popups) do
		local alpha = math.Clamp((now - popup.born) / FADE_IN, 0, 1)
		if popup.finish then alpha = math.min(alpha, math.Clamp((popup.finish - now) / FADE_OUT, 0, 1)) end

		local title = popup.title
		if popup.countdown then title = title .. " (" .. math.ceil(popup.finish - now) .. "s)" end

		local h = 28 + #popup.lines * lineH + 10
		local x, y = BHUD.Place(popup.anchor, popup.width, h)

		local contentY = BHUD.DrawCard(x, y, popup.width, h, title, alpha, popup.color, true)
		BHUD.DrawLines(popup.lines, x + popup.width / 2, contentY, lineH, y + h, alpha, true)
	end
end
