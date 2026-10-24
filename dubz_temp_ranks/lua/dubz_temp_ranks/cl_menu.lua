-- The grant window (!tempranks): pick an online player, a group and a time, press Grant. Below it, everyone who
-- currently has a temporary rank with a Remove button. Built from Dubz Framework controls.
local frame
local groups = {}
local activeScroll

local function rebuildActive(list)
	if not IsValid(activeScroll) then return end
	activeScroll:Clear()

	table.sort(list, function(a, b) return a.name < b.name end)

	if #list == 0 then
		local empty = vgui.Create("DFW.Label", activeScroll)
		empty:Dock(TOP)
		empty:SetTall(26)
		empty:SetStyle("small")
		empty:SetText("Nobody has a temporary rank right now.")
	end

	for _, info in ipairs(list) do
		local row = vgui.Create("Panel", activeScroll)
		row:Dock(TOP)
		row:SetTall(36)
		row:DockMargin(0, 0, 6, 3)

		local remove = vgui.Create("DFW.Button", row)
		remove:Dock(RIGHT)
		remove:SetWide(90)
		remove:DockMargin(6, 5, 6, 5)
		remove:SetLabel("Remove")
		remove.DoClick = function()
			net.Start("DubzTempRanks_RemoveRank")
				net.WriteString(info.sid)
			net.SendToServer()
		end

		row.Paint = function(_, w, h)
			local theme = DFW.UI.GetTheme()
			draw.RoundedBox(4, 0, 0, w, h, theme.slot)

			local left = info.expires == 0 and "Permanent" or DubzTempRanks.FormatTime(math.max(0, info.expires - os.time()))
			DFW.Draw.Text(info.name, "Body", 10, h / 2, theme.text)
			DFW.Draw.Text(info.group, "Body", w * 0.5, h / 2, theme.accent)
			DFW.Draw.Text(left, "Small", w - 112, h / 2, theme.textMuted, TEXT_ALIGN_RIGHT)
		end
	end
end

net.Receive("DubzTempRanks_SendData", function()
	rebuildActive(util.JSONToTable(net.ReadString()) or {})
end)

net.Receive("DubzTempRanks_OpenMenu", function()
	groups = util.JSONToTable(net.ReadString()) or {}

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
		chat.AddText(Color(255, 80, 80), "[Temp Ranks] ", color_white, "The Dubz Framework addon isn't installed, so the window can't open.")
		return
	end

	if IsValid(frame) then frame:Remove() end

	frame = DFW.UI.CreateFrame("Temp Ranks", 760, 640, nil, {compact = true, module = "temp_ranks"})
	local content = frame:GetContent()

	local picked, pickedGroup

	-- Top: grant controls
	local top = vgui.Create("Panel", content)
	top:Dock(TOP)
	top:SetTall(250)
	top:DockMargin(4, 4, 4, 8)

	local header = vgui.Create("DFW.SectionHeader", top)
	header:Dock(TOP)
	header:SetText("Grant a rank")

	local controls = vgui.Create("Panel", top)
	controls:Dock(BOTTOM)
	controls:SetTall(40)

	local grant = vgui.Create("DFW.Button", controls)
	grant:Dock(RIGHT)
	grant:SetWide(120)
	grant:DockMargin(8, 4, 0, 4)
	grant:SetVariant("primary")
	grant:SetLabel("Grant")

	local time = vgui.Create("DFW.TextEntry", controls)
	time:Dock(RIGHT)
	time:SetWide(150)
	time:DockMargin(8, 6, 0, 6)
	time:SetPlaceholder("7d, 12h, 30m, perma")
	time:SetText("7d")

	local groupBox = vgui.Create("DFW.Dropdown", controls)
	groupBox:Dock(FILL)
	groupBox:DockMargin(0, 6, 0, 6)
	groupBox:SetPlaceholder("Group...")
	for _, group in ipairs(groups) do groupBox:AddChoice(group, group) end
	groupBox.OnSelect = function(_, _, _, data) pickedGroup = data end

	local players = vgui.Create("DFW.ScrollPanel", top)
	players:Dock(FILL)

	for _, ply in ipairs(player.GetAll()) do
		local button = vgui.Create("DFW.Button", players)
		button:Dock(TOP)
		button:SetTall(28)
		button:DockMargin(0, 0, 6, 2)
		button:SetTextAlign(TEXT_ALIGN_LEFT)
		button:SetLabel(ply:Nick() .. "   (" .. ply:GetUserGroup() .. ")")

		button.DoClick = function(self)
			picked = ply:SteamID64()
			for _, other in ipairs(players:GetCanvas():GetChildren()) do
				if other.SetActive then other:SetActive(other == self) end
			end
		end
	end

	grant.DoClick = function()
		local seconds = DubzTempRanks.ParseTime(time:GetValue())

		if not picked then DFW.UI.Notify("Pick a player first.", "danger", 3) return end
		if not pickedGroup then DFW.UI.Notify("Pick a group.", "danger", 3) return end
		if not seconds then DFW.UI.Notify("Time like 7d, 12h, 30m or perma.", "danger", 3) return end

		net.Start("DubzTempRanks_AddRank")
			net.WriteString(picked)
			net.WriteString(pickedGroup)
			net.WriteUInt(seconds, 32)
		net.SendToServer()
	end

	-- Bottom: who has one now
	local activeHeader = vgui.Create("DFW.SectionHeader", content)
	activeHeader:Dock(TOP)
	activeHeader:SetText("Active temporary ranks")

	activeScroll = vgui.Create("DFW.ScrollPanel", content)
	activeScroll:Dock(FILL)
end)
