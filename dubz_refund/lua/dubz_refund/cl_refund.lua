-- The refund menu: what a restart cost you. Each item says what you can do with it (respawn it, or take cash), with
-- buttons for everything at once. Open it again with the chat command (!refund). Built from Dubz Framework controls.
local frame
local scroll
local data = {items = {}}

local function money(amount)
	return (DarkRP and DarkRP.formatMoney) and DarkRP.formatMoney(amount) or ("$" .. amount)
end

local function claim(action, index)
	net.Start("DubzRefund_Claim")
		net.WriteString(action)
		net.WriteUInt(index or 0, 16)
	net.SendToServer()
end

local function rebuild()
	if not IsValid(scroll) then return end
	scroll:Clear()

	for _, item in ipairs(data.items) do
		local row = vgui.Create("Panel", scroll)
		row:Dock(TOP)
		row:SetTall(64)
		row:DockMargin(0, 0, 6, 4)

		local icon = vgui.Create("SpawnIcon", row)
		icon:Dock(LEFT)
		icon:SetWide(60)
		icon:DockMargin(2, 2, 6, 2)
		icon:SetModel((item.model and item.model ~= "") and item.model or "models/props_junk/PopCan01a.mdl")
		icon:SetMouseInputEnabled(false)

		local cash = vgui.Create("DFW.Button", row)
		cash:Dock(RIGHT)
		cash:SetWide(150)
		cash:DockMargin(6, 14, 6, 14)
		cash:SetLabel("Take " .. money(item.cash))
		cash.DoClick = function() claim("cash", item.index) end

		if item.mode == "respawn" then
			local respawn = vgui.Create("DFW.Button", row)
			respawn:Dock(RIGHT)
			respawn:SetWide(120)
			respawn:DockMargin(6, 14, 0, 14)
			respawn:SetVariant("primary")
			respawn:SetLabel("Respawn")
			respawn.DoClick = function() claim("respawn", item.index) end
		end

		row.Paint = function(_, w, h)
			local theme = DFW.UI.GetTheme()
			draw.RoundedBox(6, 0, 0, w, h, theme.slot)

			DFW.Draw.Text(item.name, "Body", 76, h / 2 - 9, theme.text)
			DFW.Draw.Text(item.mode == "respawn" and ("Cost " .. money(item.price)) or ("Cost " .. money(item.price) .. "   -   too big to respawn, cash only"), "Tiny", 76, h / 2 + 11, theme.textMuted)
		end
	end
end

net.Receive("DubzRefund_Menu", function()
	data = util.JSONToTable(net.ReadString()) or {items = {}}

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end

	if not IsValid(frame) then
		frame = DFW.UI.CreateFrame("Lost items", 700, 620, nil, {compact = true, module = "refund"})
		frame:SetSubtitle("The server restarted and these were lost. Take them back or take the cash.")
		frame:Center()

		local content = frame:GetContent()

		local bottom = vgui.Create("Panel", content)
		bottom:Dock(BOTTOM)
		bottom:SetTall(50)

		local respawnAll = vgui.Create("DFW.Button", bottom)
		respawnAll:Dock(LEFT)
		respawnAll:SetWide(330)
		respawnAll:DockMargin(0, 6, 8, 6)
		respawnAll:SetVariant("primary")
		respawnAll:SetLabel("Respawn what I can, cash the rest")
		respawnAll.DoClick = function() claim("respawnall") end

		local cashAll = vgui.Create("DFW.Button", bottom)
		cashAll:Dock(FILL)
		cashAll:DockMargin(0, 6, 0, 6)
		cashAll:SetLabel("Take cash for everything")
		cashAll.DoClick = function() claim("cashall") end

		scroll = vgui.Create("DFW.ScrollPanel", content)
		scroll:Dock(FILL)
	end

	rebuild()
end)

net.Receive("DubzRefund_Close", function()
	if IsValid(frame) then frame:Remove() end
	frame = nil
end)
