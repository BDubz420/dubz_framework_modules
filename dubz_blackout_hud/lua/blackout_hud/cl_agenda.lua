-- The agenda card, top left under the bar: the agenda's title and what it says, nothing else. The boss (the agenda's manager) can say
-- /editagenda to write it in a text box instead of typing /agenda <text> (new lines are written //).
local cachedText, cachedWidth, cachedLines

function BHUD.DrawAgenda(lp)
	if not lp.getAgendaTable then return end

	local agenda = lp:getAgendaTable()
	if not agenda then return end

	local raw = lp:getDarkRPVar("agenda")
	if not raw or raw == "" then return end

	local cfg = BHUD.Config
	local pad = cfg.panel.pad
	local w = math.max(260, ScrW() * 0.19)

	if raw ~= cachedText or w ~= cachedWidth then
		local text = raw:gsub("//", "\n"):gsub("\\n", "\n")
		cachedLines = {}

		for _, paragraph in ipairs(string.Explode("\n", text)) do
			paragraph = string.Trim(paragraph)

			if paragraph ~= "" then
				for _, line in ipairs(BHUD.Wrap(paragraph, cfg.font, w - pad * 2)) do
					cachedLines[#cachedLines + 1] = line
				end
			end
		end

		cachedText, cachedWidth = raw, w
	end

	local lineH = BHUD.LineHeight(cfg.font)
	local h = BHUD.CardHeight(BHUD.LayoutCursor("topleft"), #cachedLines, lineH)
	local x, y = BHUD.Place("topleft", w, h)

	local contentY = BHUD.DrawCard(x, y, w, h, agenda.Title or "Agenda")
	BHUD.DrawLines(cachedLines, x + pad, contentY, lineH, y + h - 4)
end

-- /editagenda: a text box with what it says now
net.Receive("BHUD_AgendaEdit", function()
	if not (DFW and DFW.UI and DFW.UI.Prompt) then return end

	local current = LocalPlayer():getDarkRPVar("agenda") or ""

	DFW.UI.Prompt("Edit the agenda", "What your team is working toward. Write // where a new line should start.", current, function(text)
		if string.Trim(text or "") ~= "" then RunConsoleCommand("say", "/agenda " .. text) end
	end)
end)
