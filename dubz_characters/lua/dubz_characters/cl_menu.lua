-- The start screen. Full screen over the blurred world with the server name across the top.
--   Your characters: a list on the left (your slots, free ones to create in, premium ones locked), the selected
--   character large in the middle, and their details with a big Play button on the right.
--   New character: three steps on the right (name, look, outfit); the left shows all three steps and what you have
--   picked so far, and the middle is the live preview.
-- Discord and the rules are small links along the bottom. The HUD and chat are hidden until a character is chosen
-- (the server also keeps the player still, unseen and unhurt).
local cfg = DubzChars.Config

local menu
local menu_prevCinematic
local info = {chars = {}, slots = 1, maxSlots = 1, last = 0, starters = {}}
local music

local function scale() return ScrH() / 1080 end
local function px(n) return math.floor(n * scale()) end

local function makeFonts()
	surface.CreateFont("DubzChars.Brand", {font = "Arial", size = px(34), weight = 800, extended = true})
	surface.CreateFont("DubzChars.Heading", {font = "Arial", size = px(40), weight = 700, extended = true})
	surface.CreateFont("DubzChars.Name", {font = "Arial", size = px(26), weight = 700, extended = true})
	surface.CreateFont("DubzChars.Body", {font = "Arial", size = px(20), weight = 500, extended = true})
	surface.CreateFont("DubzChars.Button", {font = "Arial", size = px(22), weight = 700, extended = true})
	surface.CreateFont("DubzChars.Small", {font = "Arial", size = px(15), weight = 500, extended = true})
end

local function theme()
	return (DFW and DFW.UI and DFW.UI.GetTheme and DFW.UI.GetTheme()) or {
		accent = Color(241, 196, 15), text = color_white, textMuted = Color(180, 180, 180), textDim = Color(130, 130, 130),
		slot = Color(0, 0, 0, 160),
	}
end

local blurMat = Material("pp/blurscreen")

local function drawBlur(w, h, amount)
	if amount <= 0 then return end

	surface.SetMaterial(blurMat)
	surface.SetDrawColor(255, 255, 255, 255)

	for i = 1, 3 do
		blurMat:SetFloat("$blur", (i / 3) * amount)
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, w, h)
	end
end

-- Music ------------------------------------------------------------------------------------------------------------

local function startMusic()
	if cfg.musicUrl == "" or IsValid(music) then return end

	sound.PlayURL(cfg.musicUrl, "", function(channel)
		if not IsValid(channel) then return end
		if not IsValid(menu) then channel:Stop() return end

		channel:SetVolume(cfg.musicVolume)
		channel:EnableLooping(true)
		channel:Play()
		music = channel
	end)
end

local function stopMusic()
	if IsValid(music) then music:Stop() end
	music = nil
end

-- Small helpers ----------------------------------------------------------------------------------------------------

local function modelFor(face, clothing)
	return DubzCosmetics.ModelFor(face, clothing) or DubzCosmetics.ModelFor(face, DubzCosmetics.DefaultClothing) or "models/player/group01/male_01.mdl"
end

-- The HUD comes back: used by every way the menu can end (the staff preview used to leave it hidden)
local function restoreHud()
	if BHUD then BHUD.Cinematic = false end
	menu_prevCinematic = nil
end

-- If the server hasn't answered a click after a few seconds, say so (instead of nothing happening)
local function watchdog(what)
	timer.Create("DubzChars_Watchdog", 8, 1, function()
		if DubzChars.MenuOpen and DFW and DFW.UI and DFW.UI.Notify then
			DFW.UI.Notify("The server hasn't answered " .. what .. ". Try again, and if it keeps happening tell staff.", "danger", 10)
		end
	end)
end

local function sendId(name, id)
	-- A staff preview changes nothing (Play and Create just close it), except Delete: that is real, so a character can be removed from here
	if DubzChars.Preview and name ~= "DubzChars_Delete" then
		if IsValid(menu) then menu:Remove() menu = nil end
		DubzChars.MenuOpen = false
		stopMusic()
		restoreHud()
		return
	end

	net.Start(name)
		net.WriteUInt(id or 0, 32)
	net.SendToServer()

	if name == "DubzChars_Select" then watchdog("your Play click") elseif name == "DubzChars_Delete" then watchdog("the delete") end
end

-- A plain dark rounded panel
local function plate(parent, alpha)
	local panel = vgui.Create("Panel", parent)
	panel.Alpha = alpha or 160
	panel.Paint = function(self, w, h)
		draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, self.Alpha))
	end
	return panel
end

-- Plain text that lights up under the mouse (the small links)
local function textButton(parent, text, onClick, danger)
	local button = vgui.Create("DButton", parent)
	button:SetText("")
	button:SetCursor("hand")
	button.Paint = function(self, w, h)
		local base = danger and Color(240, 130, 120, 170) or Color(200, 200, 200, 200)
		local color = self:IsHovered() and (danger and Color(255, 150, 140) or color_white) or base
		draw.SimpleText(text, "DubzChars.Body", w / 2, h / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	button.DoClick = onClick

	surface.SetFont("DubzChars.Body")
	button:SetWide(surface.GetTextSize(text) + px(28))
	return button
end

-- A large button: "primary" is filled with the accent colour, anything else is an outline
local function pill(parent, text, kind, onClick)
	local button = vgui.Create("DButton", parent)
	button:SetText("")
	button:SetCursor("hand")
	button.Paint = function(self, w, h)
		local t = theme()
		local on = self:IsEnabled()
		local hot = on and self:IsHovered()

		if kind == "primary" then
			local color = on and (hot and ColorAlpha(t.accent, 255) or Color(t.accent.r * 0.9, t.accent.g * 0.9, t.accent.b * 0.9)) or Color(70, 70, 70)
			draw.RoundedBox(8, 0, 0, w, h, color)
			draw.SimpleText(text, "DubzChars.Button", w / 2, h / 2, on and Color(20, 20, 20) or Color(130, 130, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.RoundedBox(8, 0, 0, w, h, hot and Color(255, 255, 255, 40) or Color(255, 255, 255, 14))
			draw.SimpleText(text, "DubzChars.Button", w / 2, h / 2, on and color_white or Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	button.DoClick = onClick
	return button
end

-- A model on a stage. zoom = "body" (whole character) or "head". spin = true lets you drag it to turn it around, and
-- shows the accessories the character wears (set with panel:SetLook).
local function portrait(parent, model, zoom, spin)
	local panel = vgui.Create("DModelPanel", parent)
	panel:SetModel(model)
	panel:SetAmbientLight(Color(150, 150, 150))
	panel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	panel:SetDirectionalLight(BOX_FRONT, Color(200, 200, 200))

	if zoom == "head" then
		panel:SetFOV(24)
		panel:SetCamPos(Vector(60, 0, 66))
		panel:SetLookAt(Vector(0, 0, 65))
	else
		panel:SetFOV(30)
		panel:SetCamPos(Vector(120, 0, 36))
		panel:SetLookAt(Vector(0, 0, 36))
	end

	panel.Yaw = 0
	panel.Accessories = {}

	panel.LayoutEntity = function(self, ent)
		if self.Dragging then
			local x = gui.MouseX()
			self.Yaw = self.Yaw + (x - self.LastX) * 0.7
			self.LastX = x
		end

		ent:SetAngles(Angle(0, self.Yaw, 0))

		if not self.SeqSet then
			self.SeqSet = true
			local seq = ent:LookupSequence("idle_all_01")
			ent:SetSequence(seq > 0 and seq or 0)
		end
	end

	if spin then
		panel:SetCursor("sizewe")

		panel.OnMousePressed = function(self, code)
			if code ~= MOUSE_LEFT then return end
			self.Dragging, self.LastX = true, gui.MouseX()
			self:MouseCapture(true)
		end

		panel.OnMouseReleased = function(self)
			self.Dragging = false
			self:MouseCapture(false)
		end
	end

	-- The accessories the character wears, drawn on the model like they are in the game
	local id = tostring(panel)

	local function clearAccessories()
		for _, slot in ipairs(DubzCosmetics.Config.slots) do DubzCosmetics.ClearAttachment("chars_" .. id .. slot.id) end
	end

	panel.PostDrawModel = function(self, ent)
		local modelPath = self:GetModel()

		for _, slot in ipairs(DubzCosmetics.Config.slots) do
			local def = DubzCosmetics.Get(self.Accessories[slot.id])

			if def and not def.virtual then
				local pos, ang, scale = DubzCosmetics.GetPlacement(def, modelPath)
				DubzCosmetics.DrawAttachment(ent, def, pos, ang, scale, "chars_" .. id .. slot.id, LocalPlayer())
			else
				DubzCosmetics.ClearAttachment("chars_" .. id .. slot.id)
			end
		end
	end

	local baseRemove = panel.OnRemove
	panel.OnRemove = function(self)
		clearAccessories()
		if baseRemove then baseRemove(self) end
	end

	panel.SetPortrait = function(self, newModel, accessories)
		self:SetModel(newModel)
		self.SeqSet = false
		self.Accessories = accessories or {}
	end

	return panel
end

-- The model and accessories a character really looks like right now (what Cosmetics has saved for them)
local function lookOf(char)
	local look = char.look or {}
	return modelFor(look.face or char.face, look.clothing or char.clothing), look.accessories or {}
end

local views = {}

-- Where the three-column stage sits inside the stage panel
local function columns(stage, left, middle, right, leftW, rightW)
	stage.PerformLayout = function(self, w, h)
		local W = math.min(px(1560), w * 0.9)
		local H = h
		local x0 = (w - W) / 2
		local gap = px(24)

		left:SetPos(x0, 0)
		left:SetSize(leftW, H)

		right:SetPos(x0 + W - rightW, 0)
		right:SetSize(rightW, H)

		middle:SetPos(x0 + leftW + gap, 0)
		middle:SetSize(W - leftW - rightW - gap * 2, H)
	end
	stage:InvalidateLayout(true)
end

-- Your characters ------------------------------------------------------------------------------------------------------

function views.characters(stage, go)
	local selected
	for index, char in ipairs(info.chars) do
		if char.id == info.last then selected = index end
	end
	selected = selected or 1

	-- Left: one row per slot
	local left = plate(stage, 150)
	local rowH = px(92)

	local title = vgui.Create("DLabel", left)
	title:Dock(TOP)
	title:SetTall(px(56))
	title:DockMargin(px(20), px(10), 0, 0)
	title:SetFont("DubzChars.Name")
	title:SetTextColor(color_white)
	title:SetText("Your characters")

	local list = vgui.Create("DFW.ScrollPanel", left)
	list:Dock(FILL)
	list:DockMargin(px(10), 0, px(6), px(10))

	local middle = vgui.Create("Panel", stage)
	local shown = info.chars[selected]
	local shownModel, shownAccessories = "models/player/group01/male_01.mdl", {}
	if shown then shownModel, shownAccessories = lookOf(shown) end

	local body = portrait(middle, shownModel, "body", true)
	body:SetPortrait(shownModel, shownAccessories)
	body:Dock(FILL)

	local spinHint = vgui.Create("DLabel", middle)
	spinHint:Dock(BOTTOM)
	spinHint:SetTall(px(26))
	spinHint:SetFont("DubzChars.Small")
	spinHint:SetTextColor(theme().textDim)
	spinHint:SetContentAlignment(5)
	spinHint:SetText("Drag to turn")
	spinHint:MoveToBack()   -- docked panels are laid out in order: the bottom strip before the fill

	local right = plate(stage, 175)
	local rightInner = vgui.Create("Panel", right)
	rightInner:Dock(FILL)
	rightInner:DockMargin(px(28), px(24), px(28), px(24))

	local rows = {}
	local showSelected

	local function addRow(content)
		local row = vgui.Create("DButton", list)
		row:Dock(TOP)
		row:SetTall(rowH)
		row:DockMargin(0, 0, px(4), px(6))
		row:SetText("")
		row:SetCursor("hand")
		content(row)
		return row
	end

	for index = 1, info.maxSlots do
		local char = info.chars[index]

		if char then
			local row = addRow(function(r)
				local headModel = lookOf(char)
				local head = portrait(r, headModel, "head")
				head:SetPortrait(headModel, select(2, lookOf(char)))   -- hats and glasses show on the small face too
				head:Dock(LEFT)
				head:SetWide(rowH)
				head:SetMouseInputEnabled(false)
			end)

			row.DoClick = function() selected = index showSelected() end
			row.Paint = function(self, w, h)
				local chosen = selected == index
				draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, chosen and 34 or (self:IsHovered() and 20 or 8)))

				draw.SimpleText(char.first .. " " .. char.last, "DubzChars.Name", rowH + px(10), h / 2 - px(2), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

				local clothing = DubzCosmetics.GetClothing(char.clothing)
				draw.SimpleText(clothing and clothing.name or "", "DubzChars.Small", rowH + px(10), h / 2 + px(2), theme().textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			rows[index] = row
		elseif index <= info.slots then
			local row = addRow(function() end)
			row.DoClick = function() go("create") end
			row.Paint = function(self, w, h)
				draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, self:IsHovered() and 26 or 8))
				draw.SimpleText("+", "DubzChars.Heading", rowH / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("New character", "DubzChars.Body", rowH + px(10), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		else
			-- Slots only premium players get
			local row = addRow(function() end)
			row:SetCursor("arrow")
			row.Paint = function(self, w, h)
				draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, 5))
				draw.SimpleText("Premium slot", "DubzChars.Body", rowH / 2 + px(10), h / 2, Color(255, 255, 255, 80), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end

	-- Right: details of the selected character
	local nameLabel = vgui.Create("DLabel", rightInner)
	nameLabel:Dock(TOP)
	nameLabel:SetTall(px(54))
	nameLabel:SetFont("DubzChars.Heading")
	nameLabel:SetTextColor(color_white)

	local lookLabel = vgui.Create("DLabel", rightInner)
	lookLabel:Dock(TOP)
	lookLabel:SetTall(px(30))
	lookLabel:SetFont("DubzChars.Body")
	lookLabel:SetTextColor(theme().textMuted)

	local playedLabel = vgui.Create("DLabel", rightInner)
	playedLabel:Dock(TOP)
	playedLabel:SetTall(px(30))
	playedLabel:SetFont("DubzChars.Small")
	playedLabel:SetTextColor(theme().textDim)

	local delete = textButton(rightInner, "Delete this character", function()
		local char = info.chars[selected]
		if not char then return end

		DFW.UI.Confirm("Delete character", "Delete " .. char.first .. " " .. char.last .. "? This can't be undone from here.", function()
			sendId("DubzChars_Delete", char.id)
		end)
	end, true)
	delete:Dock(BOTTOM)
	delete:SetTall(px(34))
	delete:DockMargin(0, px(10), 0, 0)

	local playText = "Play"
	if info.switching and info.chars[selected] and info.chars[selected].id == info.current then playText = "Back to the game"
	elseif info.switching then playText = "Switch to this character" end

	local play = pill(rightInner, playText, "primary", function()
		local char = info.chars[selected] or info.chars[1]

		if char then
			if not DubzChars.Preview and DFW and DFW.UI and DFW.UI.Notify then DFW.UI.Notify("Loading " .. char.first .. " " .. char.last .. "...", "info", 3) end
			sendId("DubzChars_Select", char.id)
		end
	end)
	play:Dock(BOTTOM)
	play:SetTall(px(64))

	function showSelected()
		local char = info.chars[selected]
		if not char then return end

		nameLabel:SetText(char.first .. " " .. char.last)

		local face, clothing = DubzCosmetics.GetFace(char.face), DubzCosmetics.GetClothing(char.clothing)
		lookLabel:SetText((face and face.name or "") .. "  -  " .. (clothing and clothing.name or ""))
		playedLabel:SetText((char.last_played or 0) > 0 and ("Last played " .. os.date("%d %b %Y, %H:%M", char.last_played)) or "Never played")

		body:SetPortrait(lookOf(char))
	end

	showSelected()
	columns(stage, left, middle, right, px(400), px(440))
end

-- Creating one: three steps ----------------------------------------------------------------------------------------------

function views.create(stage, go)
	local state = {
		step = 1, reached = 1, face = "male_01", gender = "Male", first = "", last = "",
		clothing = info.starters[1] or DubzCosmetics.DefaultClothing,
	}

	-- Left: the three steps with what you picked
	local left = plate(stage, 150)

	local head = vgui.Create("DLabel", left)
	head:Dock(TOP)
	head:SetTall(px(56))
	head:DockMargin(px(20), px(10), 0, 0)
	head:SetFont("DubzChars.Name")
	head:SetTextColor(color_white)
	head:SetText("New character")

	-- Middle: the preview
	local middle = vgui.Create("Panel", stage)
	local preview = portrait(middle, modelFor(state.face, state.clothing), "body", true)
	preview:Dock(FILL)

	local spinHint = vgui.Create("DLabel", middle)
	spinHint:Dock(BOTTOM)
	spinHint:SetTall(px(26))
	spinHint:SetFont("DubzChars.Small")
	spinHint:SetTextColor(theme().textDim)
	spinHint:SetContentAlignment(5)
	spinHint:SetText("Drag to turn")
	spinHint:MoveToBack()   -- docked panels are laid out in order: the bottom strip before the fill

	-- Right: the step
	local right = plate(stage, 175)
	local inner = vgui.Create("Panel", right)
	inner:Dock(FILL)
	inner:DockMargin(px(28), px(24), px(28), px(24))

	local heading = vgui.Create("DLabel", inner)
	heading:Dock(TOP)
	heading:SetTall(px(52))
	heading:SetFont("DubzChars.Heading")
	heading:SetTextColor(color_white)

	local hint = vgui.Create("DLabel", inner)
	hint:Dock(TOP)
	hint:SetTall(px(30))
	hint:SetFont("DubzChars.Body")
	hint:SetTextColor(theme().textMuted)

	local footer = vgui.Create("Panel", inner)
	footer:Dock(BOTTOM)
	footer:SetTall(px(60))

	local backButton = pill(footer, "Back", "ghost", function() end)
	backButton:Dock(LEFT)
	backButton:SetWide(px(130))

	local nextButton = pill(footer, "Next", "primary", function() end)
	nextButton:Dock(RIGHT)
	nextButton:SetWide(px(200))

	local body = vgui.Create("Panel", inner)
	body:Dock(FILL)
	body:DockMargin(0, px(14), 0, px(12))

	local firstEntry, lastEntry, problem
	local showStep

	local function nameOk()
		return (DubzChars.ValidateName(state.first, state.last))
	end

	-- The order: look (gender, then model) -> outfit -> name. The name comes last so the random name can follow the look's gender.
	local function summary(step)
		if step == 1 then
			local face = DubzCosmetics.GetFace(state.face)
			return face and face.name or ""
		elseif step == 2 then
			local clothing = DubzCosmetics.GetClothing(state.clothing)
			return clothing and clothing.name or ""
		end

		local full = string.Trim(state.first .. " " .. state.last)
		return full ~= "" and full or "Not chosen"
	end

	-- The steps list on the left
	local stepRows = {}
	local titles = {"Look", "Outfit", "Name"}

	for step = 1, 3 do
		local row = vgui.Create("DButton", left)
		row:Dock(TOP)
		row:SetTall(px(84))
		row:DockMargin(px(10), 0, px(10), px(8))
		row:SetText("")
		row:SetCursor("hand")

		row.Paint = function(self, w, h)
			local active = state.step == step
			draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255, active and 34 or (self:IsHovered() and 18 or 8)))

			local done = step < state.reached or (step == 3 and nameOk() and state.reached >= 3)
			draw.RoundedBox(h, px(14), h / 2 - px(18), px(36), px(36), (active or done) and theme().accent or Color(255, 255, 255, 40))
			draw.SimpleText(done and "ok" or tostring(step), "DubzChars.Small", px(32), h / 2, (active or done) and Color(20, 20, 20) or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			draw.SimpleText(titles[step], "DubzChars.Name", px(68), h / 2 - px(2), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(summary(step), "DubzChars.Small", px(68), h / 2 + px(2), theme().textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end

		-- Jump to a step you have already been to
		row.DoClick = function()
			if step <= state.reached then showStep(step) end
		end

		stepRows[step] = row
	end

	local function refreshPreview()
		preview:SetPortrait(modelFor(state.face, state.clothing))
	end

	local function updateNext()
		if state.step == 3 then
			nextButton:SetEnabled(nameOk())
		else
			nextButton:SetEnabled(DubzCosmetics.ModelFor(state.face, state.clothing) ~= nil)
		end
	end

	local steps = {}

	-- 1: gender, then the model
	steps[1] = function()
		heading:SetText("Pick a look")
		hint:SetText("Choose male or female, then who you look like. This is who people will see.")

		local tabs = vgui.Create("DFW.TabBar", body)
		tabs:Dock(TOP)
		tabs:SetTall(px(38))
		tabs:AddTab("Male", "Male")
		tabs:AddTab("Female", "Female")

		local scroll = vgui.Create("DFW.ScrollPanel", body)
		scroll:Dock(FILL)
		scroll:DockMargin(0, px(10), 0, 0)

		local function fill()
			scroll:Clear()

			local layout = vgui.Create("DIconLayout", scroll)
			layout:Dock(TOP)
			layout:SetSpaceX(px(8))
			layout:SetSpaceY(px(8))

			for _, id in ipairs(DubzCosmetics.FaceOrder) do
				local face = DubzCosmetics.Faces[id]

				if face.gender == state.gender and DubzCosmetics.ModelFor(id, state.clothing) then
					local tile = vgui.Create("DFW.ItemSlot", layout)
					tile:SetSize(px(110), px(110))
					tile:SetItem({model = modelFor(id, state.clothing)}, face.name)
					tile:SetHighlight(state.face == id)
					tile.OnClick = function()
						state.face = id
						refreshPreview()
						fill()
					end

					layout:Add(tile)
				end
			end
		end

		tabs.OnTabChanged = function(_, id)
			state.gender = id

			local current = DubzCosmetics.GetFace(state.face)
			if not current or current.gender ~= id then
				for _, faceId in ipairs(DubzCosmetics.FaceOrder) do
					if DubzCosmetics.Faces[faceId].gender == id then state.face = faceId break end
				end
			end

			refreshPreview()
			fill()
		end

		tabs:SetActive(state.gender, true)
		fill()
	end

	-- 2: the starting outfit
	steps[2] = function()
		heading:SetText("What are you wearing?")
		hint:SetText("Where you start. You can change clothes later.")

		local row = vgui.Create("DIconLayout", body)
		row:Dock(TOP)
		row:SetSpaceX(px(14))
		row:SetSpaceY(px(14))

		local tiles = {}

		for _, id in ipairs(info.starters) do
			local clothing = DubzCosmetics.GetClothing(id)

			if clothing and DubzCosmetics.ModelFor(state.face, id) then
				local tile = vgui.Create("DFW.ItemSlot", row)
				tile:SetSize(px(170), px(200))
				tile:SetItem({model = modelFor(state.face, id)}, clothing.name)
				tile:SetHighlight(state.clothing == id)

				tile.PaintOver = function(_, w, h)
					draw.SimpleText(clothing.name, "DubzChars.Small", w / 2, h - px(14), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

				tile.OnClick = function()
					state.clothing = id
					for other, t in pairs(tiles) do t:SetHighlight(other == id) end
					refreshPreview()
				end

				tiles[id] = tile
				row:Add(tile)
			end
		end
	end

	-- 3: the name. Each field has its name above it, left aligned with the box; one Random name button follows the gender picked in step 1.
	steps[3] = function()
		heading:SetText("Who are you?")
		hint:SetText("Choose a first and last name. Letters only.")

		-- (laid out by hand, top to bottom, so nothing can change places)
		local form = vgui.Create("Panel", body)
		form:Dock(FILL)

		local stack = {}

		local function add(panel, height, gap)
			stack[#stack + 1] = {panel = panel, height = height, gap = gap or 0}
			return panel
		end

		form.PerformLayout = function(self, w)
			local y = 0

			for _, item in ipairs(stack) do
				item.panel:SetPos(0, y)
				item.panel:SetSize(w, item.height)
				y = y + item.height + item.gap
			end
		end

		local function caption(text)
			local label = vgui.Create("DLabel", form)
			label:SetFont("DubzChars.Small")
			label:SetTextColor(theme().textMuted)
			label:SetText(text)
			label:SetContentAlignment(4)

			return add(label, px(22), px(4))
		end

		local function entry(saved)
			local e = vgui.Create("DFW.TextEntry", form)
			e:SetText(saved or "")

			return add(e, px(52), px(16))
		end

		caption("First name")
		firstEntry = entry(state.first)

		caption("Last name")
		lastEntry = entry(state.last)

		problem = add(vgui.Create("DLabel", form), px(26), px(8))
		problem:SetFont("DubzChars.Small")
		problem:SetTextColor(Color(240, 130, 120))

		local function changed()
			state.first, state.last = firstEntry:GetValue(), lastEntry:GetValue()

			local ok, reason = DubzChars.ValidateName(state.first, state.last)
			local started = string.Trim(state.first) ~= "" or string.Trim(state.last) ~= ""
			problem:SetText((not ok and started) and reason or "")
			updateNext()
		end

		firstEntry.OnChange = changed
		lastEntry.OnChange = changed

		-- A random name from the list for the gender picked in step 1 (always one that passes the name rules)
		local dice = add(pill(form, "Random name", "ghost", function()
			local firsts = state.gender == "Female" and DubzChars.RandomFirstFemale or DubzChars.RandomFirstMale

			for _ = 1, 30 do
				local first, last = firsts[math.random(#firsts)], DubzChars.RandomLast[math.random(#DubzChars.RandomLast)]

				if DubzChars.ValidateName(first, last) then
					firstEntry:SetText(first)
					lastEntry:SetText(last)
					changed()
					return
				end
			end
		end), px(46), 0)

		form:InvalidateLayout(true)
		changed()
		firstEntry:RequestFocus()
	end

	function showStep(step)
		state.step = step
		state.reached = math.max(state.reached, step)

		body:Clear()
		firstEntry, lastEntry, problem = nil, nil, nil
		steps[step]()

		backButton:SetVisible(step > 1 or info.chars[1] ~= nil)
		nextButton.Label = step == 3 and "Create and play" or "Next"
		updateNext()
	end

	-- The label of a pill is fixed when it is made, so rebuild the paint for the changing Next button
	nextButton.Paint = function(self, w, h)
		local t = theme()
		local on = self:IsEnabled()
		local color = on and (self:IsHovered() and t.accent or Color(t.accent.r * 0.9, t.accent.g * 0.9, t.accent.b * 0.9)) or Color(70, 70, 70)

		draw.RoundedBox(8, 0, 0, w, h, color)
		draw.SimpleText(self.Label or "Next", "DubzChars.Button", w / 2, h / 2, on and Color(20, 20, 20) or Color(130, 130, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	backButton.DoClick = function()
		if state.step == 1 then go("characters") else showStep(state.step - 1) end
	end

	nextButton.DoClick = function()
		if state.step < 3 then showStep(state.step + 1) return end

		if not nameOk() then return end
		if DubzChars.Preview then sendId() return end

		net.Start("DubzChars_Create")
			net.WriteString(state.first or "")
			net.WriteString(state.last or "")
			net.WriteString(state.face)
			net.WriteString(state.clothing)
		net.SendToServer()

		watchdog("the new character")
	end

	columns(stage, left, middle, right, px(400), px(560))
	showStep(1)
end

-- Rules -----------------------------------------------------------------------------------------------------------

function views.rules(stage, go)
	local W, H = math.min(px(860), ScrW() * 0.7), px(680)

	local card = plate(stage, 175)
	card:SetSize(W, H)
	stage.PerformLayout = function(self, w, h) card:SetPos((w - W) / 2, (h - H) / 2) end
	stage:InvalidateLayout(true)

	local title = vgui.Create("DLabel", card)
	title:Dock(TOP)
	title:DockMargin(px(28), px(20), 0, 0)
	title:SetTall(px(52))
	title:SetFont("DubzChars.Heading")
	title:SetTextColor(color_white)
	title:SetText("Server rules")

	local back = pill(card, "Back", "ghost", function() go(info.chars[1] and "characters" or "create") end)
	back:Dock(BOTTOM)
	back:SetTall(px(52))
	back:DockMargin(px(28), px(10), px(28), px(20))

	local scroll = vgui.Create("DFW.ScrollPanel", card)
	scroll:Dock(FILL)
	scroll:DockMargin(px(28), px(8), px(20), 0)

	local rules = (DubzF4 and DubzF4.Rules) or {}

	if #rules == 0 then
		local none = vgui.Create("DLabel", scroll)
		none:Dock(TOP)
		none:SetTall(px(40))
		none:SetFont("DubzChars.Body")
		none:SetTextColor(theme().textMuted)
		none:SetText("The rules are in the F4 menu once you are in.")
	end

	for index, rule in ipairs(rules) do
		local line = vgui.Create("DLabel", scroll)
		line:Dock(TOP)
		line:DockMargin(0, 0, px(12), px(12))
		line:SetFont("DubzChars.Body")
		line:SetTextColor(color_white)
		line:SetWrap(true)
		line:SetAutoStretchVertical(true)
		line:SetText(index .. ".  " .. rule)
	end
end

-- The window -------------------------------------------------------------------------------------------------------

local function close()
	if IsValid(menu) then menu:Remove() end
	menu = nil
	stopMusic()

	restoreHud()

	DubzChars.MenuOpen = false
	hook.Run("DubzCharsMenuClosed")
end

local function setView(name)
	if not IsValid(menu) then return end

	menu.Stage:Clear()
	menu.Stage.PerformLayout = nil
	menu.View = name

	views[name](menu.Stage, setView)
end

local function open()
	if IsValid(menu) then
		-- A fresh list arrived while the menu is up (a deletion, a refused create): stay on the same page
		setView(#info.chars == 0 and "create" or (menu.View == "rules" and "rules" or "characters"))
		return
	end

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end   -- no framework: nothing to show

	makeFonts()

	menu = vgui.Create("EditablePanel")
	menu:SetSize(ScrW(), ScrH())
	menu:SetPos(0, 0)
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(true)
	menu:SetAlpha(0)
	menu:AlphaTo(255, 0.5, 0)

	DubzChars.MenuOpen = true

	-- Hide the HUD and chat behind it (the HUD's cinematic switch)
	if BHUD then menu_prevCinematic = BHUD.Cinematic BHUD.Cinematic = true end

	menu.Paint = function(self, w, h)
		drawBlur(w, h, cfg.blur)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)

		-- The server's logo, top and centre (the written name when there is no picture)
		local logo = cfg.logo ~= "" and Material(cfg.logo, "smooth mips") or nil

		if logo and not logo:IsError() then
			local lh = px(cfg.logoHeight)
			local lw = lh * (logo:Width() / math.max(logo:Height(), 1))

			surface.SetMaterial(logo)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(w / 2 - lw / 2, h * 0.012, lw, lh)
		else
			draw.SimpleText(string.upper(cfg.serverName .. " " .. cfg.serverTag), "DubzChars.Brand", w / 2, h * 0.06, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.upper(cfg.subtitle), "DubzChars.Small", w / 2, h * 0.06 + px(30), Color(255, 255, 255, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		draw.SimpleText(cfg.footer, "DubzChars.Small", w / 2, h - px(14), Color(255, 255, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	-- The stage fills the middle of the screen
	menu.Stage = vgui.Create("Panel", menu)
	menu.Stage:SetPos(0, ScrH() * 0.14)
	menu.Stage:SetSize(ScrW(), ScrH() * 0.7)

	-- Small links along the bottom
	local dock = vgui.Create("Panel", menu)
	dock:SetSize(px(420), px(44))
	dock:SetPos((ScrW() - px(420)) / 2, ScrH() * 0.88)

	local rules = textButton(dock, "Server Rules", function() setView("rules") end)
	rules:Dock(RIGHT)

	local discord = textButton(dock, "Discord", function() if cfg.discordUrl ~= "" then gui.OpenURL(cfg.discordUrl) end end)
	discord:Dock(RIGHT)

	local mine = textButton(dock, "My Characters", function() setView(#info.chars == 0 and "create" or "characters") end)
	mine:Dock(RIGHT)

	if info.switching and not DubzChars.Preview then
		local exit = pill(menu, "Cancel", "ghost", function()
			net.Start("DubzChars_Cancel")
			net.SendToServer()

			menu:Remove()
			menu = nil
			DubzChars.MenuOpen = false
			stopMusic()
			restoreHud()
		end)
		exit:SetSize(px(160), px(46))
		exit:SetPos(ScrW() - px(190), px(20))
	end

	-- Close: always for a preview, and for anyone the server is NOT holding at the screen (opened with !charmenu, not stuck at the gate).
	-- Only a player held at the gate with no character has no way out: they have to pick or make one.
	-- (not when the switch screen is up: it has its own Cancel button, which also tells the server)
	-- (a player who is still loading in has no LocalPlayer yet: that is someone joining, held at the screen, so no Close)
	local lp = LocalPlayer()
	local held = not IsValid(lp) or lp:GetNWBool("dubz_char_pending", false)

	if DubzChars.Preview or (not info.switching and not held) then
		local exit = vgui.Create("DFW.Button", menu)
		exit:SetSize(px(220), px(40))
		exit:SetPos(ScrW() - px(240), px(20))
		exit:SetLabel(DubzChars.Preview and "Close preview" or "Close")
		exit.DoClick = function()
			menu:Remove()
			menu = nil
			DubzChars.MenuOpen = false
			stopMusic()
			restoreHud()
		end
	end

	-- First visit: straight to registering a character
	setView(#info.chars == 0 and "create" or "characters")
	startMusic()
end

-- Networking -------------------------------------------------------------------------------------------------------

local lastRaw

net.Receive("DubzChars_List", function()
	local raw = net.ReadString()
	local data = util.JSONToTable(raw) or {}

	-- (the same list resent while the menu is already up changes nothing; a different one - after a delete or a create - redraws it)
	local resend = DubzChars.MenuOpen and raw == lastRaw
	lastRaw = raw
	if resend then return end
	info = {
		chars = data.chars or {}, slots = data.slots or 1, maxSlots = math.max(data.maxSlots or 1, data.slots or 1),
		last = data.last or 0, starters = data.starters or {}, switching = data.switching == true, current = data.current or 0,
	}
	DubzChars.ListReceived = true
	DubzChars.Preview = data.preview == true

	-- The lobby camera, if the server has one
	DubzChars.Camera = data.camera and {pos = Vector(data.camera.pos[1], data.camera.pos[2], data.camera.pos[3]), ang = Angle(data.camera.ang[1], data.camera.ang[2], data.camera.ang[3])} or nil

	-- Only outfits that exist as clothing sets
	local valid = {}
	for _, id in ipairs(info.starters) do
		if DubzCosmetics.GetClothing(id) then valid[#valid + 1] = id end
	end
	if #valid == 0 then valid[1] = DubzCosmetics.DefaultClothing end
	info.starters = valid

	open()

	net.Start("DubzChars_Opened")
	net.SendToServer()
end)

net.Receive("DubzChars_Result", function()
	local ok, text = net.ReadBool(), net.ReadString()
	timer.Remove("DubzChars_Watchdog")

	if not ok and text ~= "" and DFW and DFW.UI and DFW.UI.Notify then DFW.UI.Notify(text, "danger", 4) end
end)

net.Receive("DubzChars_Done", function()
	timer.Remove("DubzChars_Watchdog")
	-- Coming back to the game, or switching character in game, is not an arrival: no welcome screen then (only from the join gate)
	DubzChars.EnterQuiet = info.switching == true or DubzChars.Preview == true
	hook.Run("DubzCharsEntered")   -- the welcome screen listens for this

	if not IsValid(menu) then close() return end

	menu:AlphaTo(0, 0.4, 0, function() close() end)
end)

-- Ask for the characters once the game has loaded, and again a few times if nothing came back (the server may
-- still have been loading the player)
hook.Add("InitPostEntity", "DubzChars_Ready", function()
	for attempt = 1, 4 do
		timer.Simple(1 + attempt * 3, function()
			if DubzChars.ListReceived or DubzChars.MenuOpen then return end

			net.Start("DubzChars_Ready")
			net.SendToServer()
		end)
	end
end)

-- Keep asking while the server says we are at the character screen and it has not come up (the server may not have been ready the first times)
timer.Create("DubzChars_AskAgain", 3, 0, function()
	local lp = LocalPlayer()
	if not IsValid(lp) or DubzChars.MenuOpen or not lp:GetNWBool("dubz_char_pending", false) then return end

	net.Start("DubzChars_Ready")
	net.SendToServer()
end)

-- Other first-join popups wait for this: DubzChars.IsChoosing() is true while the start screen is up or pending
function DubzChars.IsChoosing()
	return DubzChars.MenuOpen == true or (IsValid(LocalPlayer()) and LocalPlayer():GetNWBool("dubz_char_pending", false))
end

-- While choosing a character (not the staff preview) the world is seen through the lobby camera
hook.Add("CalcView", "DubzChars_LobbyCamera", function(ply, origin, angles, fov)
	if not DubzChars.MenuOpen or DubzChars.Preview or not DubzChars.Camera then return end

	return {origin = DubzChars.Camera.pos, angles = DubzChars.Camera.ang, fov = fov, drawviewer = false}
end)
