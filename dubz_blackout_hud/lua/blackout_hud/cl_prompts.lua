-- Votes and questions on the HUD: a vote for mayor, the lottery, a demote, a "do you accept?" ... DarkRP shows each one as a little window with
-- Yes / No buttons; here each is a plain black card, stacked down the left of the screen under the agenda and kept above the chat, with a Yes
-- button that lights green and a No button that lights red when the mouse is over them. Click them: hold the context menu key (C) to get your
-- mouse, like with DarkRP's own windows. (The Yes / No keys, Y and N by default, still answer the oldest card.)
-- DarkRP sends them as the usermessages DoVote / DoQuestion (and KillVoteVGUI / KillQuestionVGUI when one ends early), which are taken over
-- once the game is up, so its own windows never open.
local prompts = {}   -- {kind = "vote" | "question", id, text, born, finish, lines, panel}

local CARD_W, CARD_H = 220, 250   -- a little taller than a square

local function find(kind, id)
	for index, prompt in ipairs(prompts) do
		if prompt.kind == kind and tostring(prompt.id) == tostring(id) then return index, prompt end
	end
end

local function dispose(prompt)
	if IsValid(prompt.panel) then prompt.panel:Remove() end
	prompt.panel = nil
end

local function remove(kind, id)
	local index, prompt = find(kind, id)

	if index then
		dispose(prompt)
		table.remove(prompts, index)
	end
end

-- Answers a card: yes or no
local function answer(prompt, yes)
	if prompt.kind == "vote" then
		RunConsoleCommand("vote", tostring(prompt.id), yes and "yea" or "nay")
	else
		RunConsoleCommand("ans", tostring(prompt.id), yes and "1" or "2")
	end

	remove(prompt.kind, prompt.id)
end

-- The card itself (a real panel, so the buttons can be clicked)
local function makePanel(prompt)
	local cfg = BHUD.Config
	local p = cfg.panel
	local pad = p.pad

	local card = vgui.Create("DPanel")
	card:SetSize(CARD_W, CARD_H)
	card:SetMouseInputEnabled(true)
	card:SetKeyboardInputEnabled(false)
	card:SetPaintBackground(false)
	card:SetAlpha(0)

	local lottery = string.find(string.lower(prompt.text), "lottery", 1, true)
	local name = lottery and "Lottery" or (prompt.kind == "vote" and "Vote" or "Question")

	prompt.lines = BHUD.Wrap(prompt.text, cfg.font, CARD_W - pad * 2)

	card.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, p.bg)

		draw.SimpleText(name, cfg.titleFont, pad, 6, p.title)
		draw.SimpleText(math.max(math.ceil(prompt.finish - CurTime()), 0) .. "s", cfg.titleFont, w - pad, 6, p.muted, TEXT_ALIGN_RIGHT)

		-- The question: as many lines as fit above the buttons
		local lineH = BHUD.LineHeight(cfg.font)
		local room = math.floor((h - 28 - 36 - pad * 2 - lineH) / lineH)

		for index, line in ipairs(prompt.lines) do
			if index > room then break end

			if index == room and #prompt.lines > room then line = string.sub(line, 1, math.max(#line - 3, 1)) .. "..." end
			draw.SimpleText(line, cfg.font, pad, 30 + (index - 1) * lineH, p.text)
		end

		-- How to get the mouse, while it isn't there
		if not vgui.CursorVisible() then
			draw.SimpleText("Hold C to use the mouse", cfg.font, w / 2, h - 36 - pad - lineH - 2, p.muted, TEXT_ALIGN_CENTER)
		end
	end

	local function button(label, hover, yes)
		local b = vgui.Create("DButton", card)
		b:SetText("")
		b:SetSize((CARD_W - pad * 3) / 2, 36)
		b:SetCursor("hand")

		b.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and hover or Color(255, 255, 255, 22))
			draw.SimpleText(label, cfg.titleFont, w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		b.DoClick = function() answer(prompt, yes) end
		return b
	end

	local yes = button("Yes", Color(60, 170, 80, 235), true)
	yes:SetPos(pad, CARD_H - 36 - pad)

	local no = button("No", Color(200, 65, 60, 235), false)
	no:SetPos(pad * 2 + yes:GetWide(), CARD_H - 36 - pad)

	prompt.panel = card
end

local function add(kind, id, text, seconds)
	if not IsValid(LocalPlayer()) then return end

	text = DarkRP.deLocalise and DarkRP.deLocalise(text) or text
	seconds = (seconds and seconds > 0) and seconds or 100

	remove(kind, id)

	local prompt = {kind = kind, id = id, text = text, born = CurTime(), finish = CurTime() + seconds}
	prompts[#prompts + 1] = prompt

	makePanel(prompt)

	LocalPlayer():EmitSound("Town.d1_town_02_elevbell1", 70, 100)
end

local function install()
	usermessage.Hook("DoVote", function(msg)
		local question, id, time = msg:ReadString(), msg:ReadShort(), msg:ReadFloat()
		add("vote", id, question, time)
	end)

	usermessage.Hook("KillVoteVGUI", function(msg) remove("vote", msg:ReadShort()) end)

	usermessage.Hook("DoQuestion", function(msg)
		local question, id, time = msg:ReadString(), msg:ReadString(), msg:ReadFloat()
		add("question", id, question, time)
	end)

	usermessage.Hook("KillQuestionVGUI", function(msg) remove("question", msg:ReadString()) end)

	-- DarkRP's "rp_vote" command (for binds) answers the oldest card too
	concommand.Add("rp_vote", function(_, _, args)
		local prompt = prompts[1]
		if not prompt or not args[1] then return end

		local word = string.lower(args[1])
		answer(prompt, word == "1" or word == "yes" or word == "true")
	end)
end

-- (after DarkRP has registered its own, so these are the ones that stay)
hook.Add("InitPostEntity", "BHUD_InstallPrompts", function() timer.Simple(0, install) end)

-- Typing in chat must not answer anything
local typing = false
hook.Add("StartChat", "BHUD_PromptChatOpen", function() typing = true end)
hook.Add("FinishChat", "BHUD_PromptChatClosed", function() typing = false end)

hook.Add("PlayerButtonDown", "BHUD_AnswerPrompt", function(ply, button)
	if ply ~= LocalPlayer() or #prompts == 0 or not BHUD.Enabled() then return end
	if typing or gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

	local cfg = BHUD.Config

	if button == cfg.promptYesKey then answer(prompts[1], true)
	elseif button == cfg.promptNoKey then answer(prompts[1], false) end
end)

-- Called every frame by the HUD, after the agenda and the laws, so the cards sit under them. Places each card in the left column
-- and stops when the next one would run into the chat (the rest wait their turn: they appear as the ones above are answered).
function BHUD.DrawPrompts()
	local now = CurTime()
	local _, chatY = chat.GetChatBoxPos()
	local limit = (chatY or ScrH()) - 8

	for index = #prompts, 1, -1 do
		if prompts[index].finish <= now then
			dispose(prompts[index])
			table.remove(prompts, index)
		end
	end

	for _, prompt in ipairs(prompts) do
		local panel = prompt.panel
		if not IsValid(panel) then makePanel(prompt) panel = prompt.panel end

		if BHUD.LayoutCursor("topleft") + CARD_H > limit then
			prompt.lastDraw = nil   -- no room left: this one waits
		else
			local x, y = BHUD.Place("topleft", CARD_W, CARD_H)

			panel:SetPos(x, y)
			panel:SetAlpha(255 * math.Clamp((now - prompt.born) / 0.25, 0, 1))
			prompt.lastDraw = RealTime()
		end
	end
end

-- A card only shows while the HUD is drawing it (cinematic mode, a hidden HUD or no room for it hide the panel)
hook.Add("Think", "BHUD_PromptVisibility", function()
	for _, prompt in ipairs(prompts) do
		if IsValid(prompt.panel) then prompt.panel:SetVisible(prompt.lastDraw ~= nil and RealTime() - prompt.lastDraw < 0.25) end
	end
end)
