-- Laws panel, top-right under the bar (the DarkRP laws list). F1 expands / collapses it;
-- collapsed it shrinks to a small "Laws - Press F1 to open" tab.
local expanded = BHUD.Config.lawsDefaultOpen
local anim = expanded and 1 or 0
local lastToggle = 0
local cachedKey, cachedLines

local TAB_H = 24

function BHUD.DrawLaws()
	local cfg = BHUD.Config
	local pad = cfg.panel.pad

	local target = expanded and 1 or 0
	anim = Lerp(math.min(FrameTime() * 10, 1), anim, target)
	if math.abs(anim - target) < 0.01 then anim = target end

	local w = math.max(260, ScrW() * 0.2)

	if anim <= 0 then
		-- Collapsed tab, sized to its text.
		surface.SetFont(cfg.titleFont)
		local text = "Laws - Press F1 to open"
		local tabW = surface.GetTextSize(text) + pad * 2
		local tx, ty = BHUD.Place("topright", tabW, TAB_H)
		BHUD.DrawCard(tx, ty, tabW, TAB_H, text)
		return
	end

	-- Two lists (Dubz Laws): illegal first, then legal. Without that addon, DarkRP's single list.
	local legal, illegal = {}, {}
	local split = DubzLaws and DubzLaws.Legal and DubzLaws.Illegal

	if split then
		legal, illegal = DubzLaws.Legal, DubzLaws.Illegal
	else
		illegal = (DarkRP.getLaws and DarkRP.getLaws()) or {}
	end

	local key = w .. "|" .. table.concat(illegal, "\1") .. "||" .. table.concat(legal, "\1")

	if key ~= cachedKey then
		cachedLines = {}

		local function section(title, color, list)
			if not split and title == "Legal" then return end

			if split then
				cachedLines[#cachedLines + 1] = {text = title, head = true, color = color}
				if #list == 0 then cachedLines[#cachedLines + 1] = {text = "None.", muted = true} end
			end

			for i, law in ipairs(list) do
				for _, line in ipairs(BHUD.Wrap(i .. ". " .. law, cfg.font, w - pad * 2)) do
					cachedLines[#cachedLines + 1] = line
				end
			end

			cachedLines[#cachedLines + 1] = ""
		end

		section("Illegal", Color(235, 100, 90), illegal)
		section("Legal", Color(110, 200, 120), legal)

		if #illegal == 0 and #legal == 0 then cachedLines = {"No laws have been set."} end
		cachedKey = key
	end

	local lineH = BHUD.LineHeight(cfg.font)
	local h = Lerp(anim, TAB_H, BHUD.CardHeight(BHUD.LayoutCursor("topright"), #cachedLines, lineH))
	local x, y = BHUD.Place("topright", w, h)

	local contentY = BHUD.DrawCard(x, y, w, h, "Laws - Press F1 to close")
	BHUD.DrawLines(cachedLines, x + pad, contentY, lineH, y + h - 6, anim)
end

hook.Add("PlayerButtonDown", "BHUD_ToggleLaws", function(ply, button)
	if ply ~= LocalPlayer() or button ~= BHUD.Config.lawsKey or not BHUD.Enabled() then return end
	if IsValid(vgui.GetKeyboardFocus()) then return end
	if CurTime() < lastToggle + BHUD.Config.lawsCooldown then return end

	expanded = not expanded
	lastToggle = CurTime()
end)
