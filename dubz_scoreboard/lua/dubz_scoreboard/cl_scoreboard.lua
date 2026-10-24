-- The TAB scoreboard, built from Dubz Framework controls and the framework theme (DFW.UI / DFW.Draw / DFW.Button /
-- DFW.ScrollPanel). Click a player to open a drawer under their row: Profile, staff commands and commend icons.
-- Without the framework installed it does nothing, so the default scoreboard shows instead.
local cfg = DubzScoreboard.Config

local ROW_H = 25
local DRAWER_H = 44

local board
local iconCache = {}

local function frameworkReady()
	return DFW ~= nil and DFW.UI ~= nil and DFW.Draw ~= nil
end

local function Icon(path)
	iconCache[path] = iconCache[path] or Material(path)
	return iconCache[path]
end

local function CanSee()
	local group = string.lower(LocalPlayer():GetUserGroup() or "")
	return cfg.staffGroups[group] == true
end

-- True only when the dubz_karma addon fully loaded on this client (it may be missing or half uploaded).
local function HasCommends()
	return DubzKarma ~= nil and istable(DubzKarma.Commends) and isfunction(DubzKarma.TopCommend) and DubzKarma.Enabled()
end

local function rank(ply)
	local group = DubzScoreboard.Groups[string.lower(ply:GetUserGroup() or "")]
	if not group then return nil end
	return group.name, DFW.Collections.ToColor(group.color)
end

-- Drawer shown under a player row: a Profile button, staff commands (toggling where it makes sense), and the
-- commend icons. Commend icons need the dubz_karma addon; without it rows don't expand.
local function BuildDrawer(entry, targ)
	local drawer = vgui.Create("Panel", entry)
	drawer:Dock(TOP)
	drawer:SetTall(DRAWER_H)
	drawer:SetVisible(false)
	drawer.Buttons = {}  -- text buttons, laid out from the left
	drawer.Icons = {}    -- commend icons, laid out from the right

	drawer.Paint = function(me, w, h)
		draw.RoundedBox(0, 0, 0, w, h, DFW.UI.GetTheme().surface)
		if not IsValid(targ) then return end

		local karma = DubzKarma.Get(targ)
		if karma then
			local x = w - 10 - #me.Icons * 36 - 10
			DFW.Draw.Text("Karma: " .. karma, "Small", x, h / 2 - 7, DFW.UI.GetTheme().text, TEXT_ALIGN_RIGHT)
		end
	end

	-- label can be a string or a function returning one (for toggle buttons); alt is the other state's text so
	-- the button is wide enough for both
	local function AddButton(label, onClick, alt)
		local btn = vgui.Create("DFW.Button", drawer)
		btn.LabelFunc = isfunction(label) and label or nil
		btn:SetLabel(isfunction(label) and label() or label)

		local widest = DFW.UI.TextSize(btn:GetLabel(), "Button")
		if alt then widest = math.max(widest, (DFW.UI.TextSize(alt, "Button"))) end
		btn.Wide = widest + 28

		btn.Think = function(me)
			if me.LabelFunc then me:SetLabel(me.LabelFunc()) end
		end

		btn.DoClick = function()
			if IsValid(targ) then onClick() end
		end

		table.insert(drawer.Buttons, btn)
	end

	local function Run(cmd)
		LocalPlayer():ConCommand(cmd .. ' "' .. targ:Nick() .. '"')
	end

	AddButton("Profile", function() targ:ShowProfile() end)

	if CanSee() then
		AddButton("Go-To", function() Run("ulx goto") end)
		AddButton("Bring", function() Run("ulx bring") end)

		AddButton(function() return targ.Is_Frozen and "Unfreeze" or "Freeze" end, function()
			Run(targ.Is_Frozen and "ulx unfreeze" or "ulx freeze")
			targ.Is_Frozen = not targ.Is_Frozen
		end, "Unfreeze")

		AddButton(function() return targ.Is_Jailed and "Unjail" or "Jail" end, function()
			Run(targ.Is_Jailed and "ulx unjail" or "ulx jail")
			targ.Is_Jailed = not targ.Is_Jailed
		end, "Unjail")

		AddButton("Spectate", function() LocalPlayer():ConCommand("fspectate " .. targ:Nick()) end)
	end

	-- Commend icons: no background, just the icon and its count sitting on the drawer
	for _, kind in ipairs(DubzKarma.Commends) do
		local btn = vgui.Create("DButton", drawer)
		btn:SetText("")
		btn:SetTooltip(string.format("%s - %s (%+d karma)", kind.name, kind.desc, kind.karma))

		btn.Paint = function(me, w, h)
			local alpha = 200
			if targ == LocalPlayer() then alpha = 110 elseif me:IsHovered() then alpha = 255 end

			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(Icon(kind.icon))
			surface.DrawTexturedRect(w / 2 - 8, 5, 16, 16)

			if IsValid(targ) then
				local text = DFW.UI.GetTheme().text
				DFW.Draw.Text(DubzKarma.GetCommend(targ, kind.id), "Small", w / 2, h - 11, Color(text.r, text.g, text.b, alpha), TEXT_ALIGN_CENTER)
			end
		end

		btn.DoClick = function()
			if not IsValid(targ) or targ == LocalPlayer() then return end

			net.Start("DubzKarma_Commend")
				net.WriteEntity(targ)
				net.WriteString(kind.id)
			net.SendToServer()
		end

		table.insert(drawer.Icons, btn)
	end

	drawer.PerformLayout = function(me, w, h)
		local x = 10
		for _, btn in ipairs(me.Buttons) do
			btn:SetSize(btn.Wide, 24)
			btn:SetPos(x, (h - 24) / 2)
			x = x + btn.Wide + 4
		end

		local iconW = 36
		local right = w - 10 - #me.Icons * iconW
		for i, btn in ipairs(me.Icons) do
			btn:SetSize(iconW, 34)
			btn:SetPos(right + (i - 1) * iconW, (h - 34) / 2)
		end
	end

	return drawer
end

local sorters = {
	money = function(a, b) return (a:getDarkRPVar("money") or 0) > (b:getDarkRPVar("money") or 0) end,
	name = function(a, b) return string.lower(a:Nick()) < string.lower(b:Nick()) end,
	job = function(a, b) return team.GetName(a:Team()) < team.GetName(b:Team()) end,
	ping = function(a, b) return a:Ping() < b:Ping() end,
}

local function BuildRow(list, targ, index)
	local theme = DFW.UI.GetTheme()
	local clr = team.GetColor(targ:Team())
	local teamColor = Color(clr.r, clr.g, clr.b, 255)

	local entry = vgui.Create("Panel", list)
	entry:Dock(TOP)
	entry:SetTall(ROW_H)
	entry:DockMargin(0, 0, 6, 0)

	local item = vgui.Create("Panel", entry)
	item:Dock(TOP)
	item:SetTall(ROW_H)

	item.Paint = function(me, w, h)
		surface.SetDrawColor(teamColor)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 30)
		surface.DrawRect(0, 0, w, 2)

		local stripe = index % 2 == 0 and DFW.UI.GetTheme().track or DFW.UI.GetTheme().outline
		surface.SetDrawColor(stripe.r, stripe.g, stripe.b, 200)
		surface.DrawRect(0, h - 2, w, 2)

		if not IsValid(targ) then return end

		local text = DFW.UI.GetTheme().text
		local y = h / 2 - 1

		local nick = targ:Nick() .. (targ:isWanted() and "   Wanted!" or "")
		DFW.Draw.Text(nick, "Small", w * 0.04, y, text)

		if cfg.showRanks then
			local name, color = rank(targ)
			if name then
				local nickW = DFW.UI.TextSize(nick, "Small")
				DFW.Draw.Text("[" .. name .. "]", "Small", w * 0.04 + nickW + 8, y, color)
			end
		end

		if cfg.showGang then DFW.Draw.Text(targ:getGang(), "Small", w * 0.25, y, text, TEXT_ALIGN_CENTER) end
		if cfg.showJob then DFW.Draw.Text(team.GetName(targ:Team()), "Small", w * 0.5, y, text, TEXT_ALIGN_CENTER) end
		if cfg.showMoney then DFW.Draw.Text(DarkRP.formatMoney(targ:getDarkRPVar("money") or 0), "Small", w * 0.70, y, text, TEXT_ALIGN_CENTER) end

		if cfg.showKD then
			DFW.Draw.Text(string.format("%i:%i", math.max(targ:Frags(), 0), math.max(targ:Deaths(), 0)), "Small", w * 0.80, y, text, TEXT_ALIGN_CENTER)
		end

		if cfg.showPing then DFW.Draw.Text(targ:Ping() .. "ms", "Small", w * 0.90, y, text, TEXT_ALIGN_RIGHT) end

		-- Status icon: the commend this player has received most, with its count
		if HasCommends() then
			local top, count = DubzKarma.TopCommend(targ)
			if top then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(Icon(top.icon))
				surface.DrawTexturedRect(w * 0.915, 4, 16, 16)
				DFW.Draw.Text(count, "Small", w * 0.915 + 19, y, text, TEXT_ALIGN_LEFT)
			end
		end
	end

	-- Click a row to open / close its drawer (one open at a time)
	local bounds = vgui.Create("DLabel", item)
	bounds:SetPos(0, 0)
	bounds:SetText("")
	bounds:SetMouseInputEnabled(true)

	if HasCommends() then
		local drawer = BuildDrawer(entry, targ)

		bounds.DoClick = function()
			local opening = not drawer:IsVisible()

			if IsValid(board.OpenDrawer) and board.OpenDrawer ~= drawer then
				board.OpenDrawer:SetVisible(false)
				board.OpenDrawer:GetParent():SetTall(ROW_H)
			end

			drawer:SetVisible(opening)
			entry:SetTall(ROW_H + (opening and DRAWER_H or 0))
			board.OpenDrawer = opening and drawer or nil
			list:InvalidateLayout(true)
		end
	end

	local avatar = vgui.Create("AvatarImage", item)
	avatar:SetSize(25, 25)
	avatar:SetPos(0, 0)
	avatar:SetPlayer(targ, 25)

	local mute = vgui.Create("DFW.Button", item)
	mute:SetSize(22, 22)
	mute:SetVariant("ghost")
	-- The button keeps its 22 pixel hitbox; the icon is drawn nearly as big as the button
	mute.Paint = function(self, w, h)
		local t = DFW.UI.GetTheme()
		if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(t.text, 30)) end

		local size = 20
		DFW.Icons.Draw(targ:IsMuted() and "actions/muted" or "actions/unmuted", (w - size) / 2, (h - size) / 2, size, size, targ:IsMuted() and t.danger or t.text)
	end
	mute.DoClick = function()
		targ:SetMuted(not targ:IsMuted())
	end

	-- Keep the row-width dependent children in place however wide the list stretches the row
	item.PerformLayout = function(me, w, h)
		bounds:SetSize(w - 25, h)
		mute:SetPos(w - 26, 1)
	end
end

local function CreateBoard()
	if IsValid(board) then board:Remove() end

	local scale = cfg.scale or 0.85
	local theme = DFW.UI.GetTheme()

	board = vgui.Create("Panel")
	board.DFWModule = "scoreboard"   -- ties its buttons to the scoreboard's Hover Sounds switch
	board:SetSize(ScrW() * 0.5 * scale, ScrH() * 0.92 * scale)
	board:Center()
	board:SetMouseInputEnabled(true)
	board:SetKeyboardInputEnabled(false)
	gui.EnableScreenClicker(true)

	local titleFont = DFW.UI.CreateFont("scoreboard_title", 38, 700)

	board.Paint = function(me, w, h)
		local t = DFW.UI.GetTheme()
		draw.RoundedBox(8, 0, 0, w, h, t.background)

		DFW.Draw.Text(cfg.serverName, titleFont, w / 2, 30, t.text, TEXT_ALIGN_CENTER)

		local count = #player.GetAll()
		local text = count == 1 and "There is currently 1 person online." or ("There are currently " .. count .. "/" .. game.MaxPlayers() .. " players online.")
		DFW.Draw.Text(text, "Small", w / 2, h - 14, t.textMuted, TEXT_ALIGN_CENTER)
	end

	local list = vgui.Create("DFW.ScrollPanel", board)
	list:Dock(FILL)
	list:DockMargin(10, 56, 6, 28)

	local players = player.GetAll()
	table.sort(players, sorters[cfg.sortBy] or sorters.money)

	for index, targ in ipairs(players) do BuildRow(list, targ, index) end
end

local function RemoveBoard()
	if IsValid(board) then board:Remove() end
	board = nil
	gui.EnableScreenClicker(false)
end

-- The old Elegant scoreboard (if its files are still on the server) hooks the same events and would win; remove it
local function removeOldScoreboard()
	for _, name in ipairs({"ELEGANT_CREATE_BOARD", "ShowCustomScoreboard"}) do hook.Remove("ScoreboardShow", name) end
	for _, name in ipairs({"ELEGANT_REMOVE_BOARD", "HideCustomScoreboard"}) do hook.Remove("ScoreboardHide", name) end
end

removeOldScoreboard()
hook.Add("InitPostEntity", "DubzScoreboard_RemoveOld", removeOldScoreboard)

hook.Add("ScoreboardShow", "DubzScoreboard_Show", function()
	-- Master switch off (or no framework): fall back to the default scoreboard
	if not frameworkReady() or not DFW.Bind.Enabled("scoreboard") then return end

	CreateBoard()
	return true
end)

hook.Add("ScoreboardHide", "DubzScoreboard_Hide", function()
	if not frameworkReady() then return end
	if not DFW.Bind.Enabled("scoreboard") and not IsValid(board) then return end

	RemoveBoard()
	return true
end)
