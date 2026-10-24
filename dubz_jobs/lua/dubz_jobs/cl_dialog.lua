-- The conversation box: the NPC's name and what they say along the bottom of the screen, with the things you can answer
-- as buttons. Close it with the X, Escape, or by walking away. Built from Dubz Framework controls.
local box

local function close()
	if IsValid(box) then box:Remove() end
	box = nil
end

local function show(npc, data)
	close()
	if not (DFW and DFW.UI) then return end

	local w, h = math.min(ScrW() * 0.5, 980), 70 + 74 + #data.options * 46
	box = vgui.Create("EditablePanel")
	box:SetSize(w, h)
	box:SetPos((ScrW() - w) / 2, ScrH() - h - 70)
	box:MakePopup()
	box:SetKeyboardInputEnabled(false)
	box.Npc = npc
	box.Born = CurTime()

	-- The text appears a few letters at a time, like someone talking
	local shown = 0
	local total = #data.text

	box.Paint = function(self, pw, ph)
		draw.RoundedBox(10, 0, 0, pw, ph, Color(0, 0, 0, 175))

		local theme = DFW.UI.GetTheme()
		DFW.Draw.Text(data.name, "Heading", 24, 28, theme.accent)

		shown = math.min(total, math.floor((CurTime() - self.Born) * 70))
		local text = string.sub(data.text, 1, shown)

		-- Wrap by hand to the box width
		surface.SetFont(DFW.UI.Font("Body"))
		local y, line = 62, ""

		for word in string.gmatch(text, "%S+") do
			local try = line == "" and word or (line .. " " .. word)

			if surface.GetTextSize(try) > pw - 48 then
				DFW.Draw.Text(line, "Body", 24, y, theme.text)
				y, line = y + 24, word
			else
				line = try
			end
		end

		if line ~= "" then DFW.Draw.Text(line, "Body", 24, y, theme.text) end
	end

	-- Walking away (or Escape) ends it
	box.Think = function(self)
		if not IsValid(self.Npc) or LocalPlayer():GetPos():Distance(self.Npc:GetPos()) > DubzJobs.Config.talkDistance * 1.4 then close() return end
		if input.IsKeyDown(KEY_ESCAPE) or gui.IsGameUIVisible() then close() end
	end

	local y = h - #data.options * 46 - 10

	for _, option in ipairs(data.options) do
		local button = vgui.Create("DFW.Button", box)
		button:SetPos(24, y)
		button:SetSize(w - 48, 40)
		button:SetLabel(option.label)
		button.DoClick = function()
			net.Start("DubzJobs_Choose")
				net.WriteEntity(npc)
				net.WriteUInt(option.id, 8)
			net.SendToServer()

			if option.close then close() end
		end

		y = y + 46
	end
end

net.Receive("DubzJobs_Talk", function()
	local npc = net.ReadEntity()
	local data = util.JSONToTable(net.ReadString())

	if data and data.close then close() return end
	if IsValid(npc) and data then show(npc, data) end
end)
