-- The City Worker, client side: a small card with the job and the step to do, a marker to the job, a glow on the spot or part to use next, and the bar
-- that fills while a tool is held. Plain black cards built from the framework's fonts, like the rest.
local cfg = DubzCW.Config

local state          -- the job now: {target, name, summary, step, steps, text, hint, zones, introUntil}
local glow = Material("sprites/light_glow02_add")

net.Receive("DubzCW_State", function()
	if not net.ReadBool() then state = nil return end

	local job = {
		targetPos = net.ReadVector(), name = net.ReadString(), summary = net.ReadString(),
		step = net.ReadUInt(6), steps = net.ReadUInt(6), text = net.ReadString(), hint = net.ReadString(), prompt = net.ReadString(),
	}

	local intro = net.ReadBool()
	job.zones = {}

	for index = 1, net.ReadUInt(3) do
		job.zones[index] = {pos = net.ReadVector(), ent = net.ReadEntity(), radius = net.ReadFloat()}
	end

	-- The summary shows in full for a while when the job starts; later steps keep that timer
	job.introUntil = intro and (CurTime() + 16) or (state and state.introUntil) or 0
	state = job
end)

local function font(name)
	return DFW.UI.Font and DFW.UI.Font(name) or "DermaDefault"
end

-- Text cut into lines no wider than `width`
local function wrap(text, fontName, width)
	surface.SetFont(fontName)

	local lines, line = {}, ""

	for word in string.gmatch(text, "%S+") do
		local test = line == "" and word or (line .. " " .. word)

		if surface.GetTextSize(test) > width and line ~= "" then
			lines[#lines + 1] = line
			line = word
		else
			line = test
		end
	end

	if line ~= "" then lines[#lines + 1] = line end

	return lines
end

local WHITE, DIM = Color(255, 255, 255), Color(190, 190, 190)

-- A ring from the top, clockwise, filled to `fraction` (0 to 1): small quads along the arc so it is smooth
local function drawRing(cx, cy, inner, outer, fraction, color)
	if fraction <= 0 then return end

	local steps = math.max(math.ceil(96 * fraction), 1)
	local sweep = math.pi * 2 * fraction

	draw.NoTexture()
	surface.SetDrawColor(color)

	for step = 0, steps - 1 do
		local a1 = -math.pi / 2 + sweep * step / steps
		local a2 = -math.pi / 2 + sweep * (step + 1) / steps

		surface.DrawPoly({
			{x = cx + math.cos(a1) * inner, y = cy + math.sin(a1) * inner},
			{x = cx + math.cos(a1) * outer, y = cy + math.sin(a1) * outer},
			{x = cx + math.cos(a2) * outer, y = cy + math.sin(a2) * outer},
			{x = cx + math.cos(a2) * inner, y = cy + math.sin(a2) * inner},
		})
	end
end

hook.Add("HUDPaint", "DubzCW_HUD", function()
	local lp = LocalPlayer()
	if not (IsValid(lp) and DFW and DFW.Draw) then return end

	local w, h = ScrW(), ScrH()

	-- The bar while a tool is held
	local hold = lp:GetNWFloat("dcw_hold", 0)
	local mode = lp:GetNWInt("dcw_mode", 0)

	-- (turning the wrench: a ring of dots round the crosshair that fills as it goes round)
	if mode == 2 and hold > 0.01 then
		-- A smooth ring: a dark track, and a white arc from the top, clockwise
		drawRing(w / 2, h / 2, 40, 50, 1, Color(0, 0, 0, 160))
		drawRing(w / 2, h / 2, 42, 48, math.Clamp(hold, 0, 1), Color(235, 235, 235, 240))
		draw.SimpleTextOutlined(math.floor(hold * 100) .. "%", "DermaDefaultBold", w / 2, h / 2 + 64, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
	elseif mode == 1 and hold > 0.01 then
		local bw, bh = 240, 18
		local x, y = w / 2 - bw / 2, h * 0.62

		draw.RoundedBox(6, x - 6, y - 6, bw + 12, bh + 12, Color(0, 0, 0, 160))
		draw.RoundedBox(3, x, y, bw * math.Clamp(hold, 0, 1), bh, Color(235, 235, 235, 230))
	end

	if not state then return end

	-- The card
	local width, pad = 330, 12
	local body, small = font("Body"), font("Small")
	local lines = {}
	local intro = CurTime() < state.introUntil

	lines[#lines + 1] = {state.name, "BodyBold", WHITE}

	if intro then
		for _, text in ipairs(wrap(state.summary, body, width - pad * 2)) do lines[#lines + 1] = {text, "Body", DIM} end

		lines[#lines + 1] = {"", "Body", DIM}
	end

	local stepText = state.step <= state.steps and ("Step " .. state.step .. " of " .. state.steps) or "Finishing up"
	lines[#lines + 1] = {stepText, "Small", DIM}

	for _, text in ipairs(wrap(state.text, body, width - pad * 2)) do lines[#lines + 1] = {text, "Body", WHITE} end
	for _, text in ipairs(wrap(state.hint, small, width - pad * 2)) do lines[#lines + 1] = {text, "Small", DIM} end

	local height = pad * 2 + #lines * 20
	local x, y = 20, h * 0.36

	draw.RoundedBox(6, x, y, width, height, Color(0, 0, 0, 160))

	for index, line in ipairs(lines) do
		DFW.Draw.Text(line[1], line[2], x + pad, y + pad + (index - 1) * 20 + 10, line[3])
	end

	-- The marker to the job, until the worker is close (a name and the distance, no box: the same as the dealer's)
	if state.targetPos and state.targetPos ~= vector_origin then
		local distance = lp:GetPos():Distance(state.targetPos)

		if distance > cfg.MarkerDistance then
			local screen = (state.targetPos + Vector(0, 0, 70)):ToScreen()
			local margin = 60
			local mx, my = math.Clamp(screen.x, margin, w - margin), math.Clamp(screen.y, margin, h - margin)

			if not screen.visible then my = h - margin end

			draw.SimpleTextOutlined(state.name, "DermaDefaultBold", mx, my - 9, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
			draw.SimpleTextOutlined(math.floor(distance * 0.0254) .. " m", "DermaDefault", mx, my + 9, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
		end
	end

	-- What to do, written next to the spot (on the screen, so a wall or the machine never hides it): the step, and the key or tool for it
	local best, bestScore

	for _, zone in ipairs(state.zones) do
		local pos = IsValid(zone.ent) and zone.ent:WorldSpaceCenter() or zone.pos

		if pos and pos ~= vector_origin and EyePos():DistToSqr(pos) < 400 * 400 then
			local screen = pos:ToScreen()

			if screen.visible then
				local score = math.abs(screen.x - w / 2) + math.abs(screen.y - h / 2)

				if not bestScore or score < bestScore then best, bestScore = screen, score end
			end
		end
	end

	if best then
		draw.SimpleTextOutlined(state.text, "DermaDefaultBold", best.x, best.y - 26, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))

		if state.prompt ~= "" then
			draw.SimpleTextOutlined(state.prompt, "DermaDefault", best.x, best.y - 11, Color(255, 215, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
		end
	end
end)

-- While the wrench is turned the view is held still: the mouse is for the turning (the server reads its moves from the command, not from the view)
local lockAngle

hook.Add("CreateMove", "DubzCW_Lock", function(cmd)
	local lp = LocalPlayer()

	if IsValid(lp) and lp:GetNWBool("dcw_turning") then
		lockAngle = lockAngle or cmd:GetViewAngles()
		cmd:SetViewAngles(lockAngle)
	else
		lockAngle = nil
	end
end)

-- The glow on the parts of the step
hook.Add("PreDrawHalos", "DubzCW_Halos", function()
	if not state then return end

	local list = {}

	for _, zone in ipairs(state.zones) do
		if IsValid(zone.ent) then list[#list + 1] = zone.ent end
	end

	if #list > 0 then halo.Add(list, cfg.HighlightColor, 3, 3, 2, true, true) end
end)

-- The glow on the spots (the edge to pull, where a part goes), with what to do next to it
hook.Add("PostDrawTranslucentRenderables", "DubzCW_Spots", function()
	if not state then return end

	local pulse = 0.65 + 0.35 * math.sin(CurTime() * 4)
	local color = cfg.HighlightColor
	local eye = EyePos()

	-- (small dots: the size is in the settings)
	local size = cfg.SpotSize

	for _, zone in ipairs(state.zones) do
		if not IsValid(zone.ent) then
			render.SetMaterial(glow)
			render.DrawSprite(zone.pos, size, size, Color(color.r, color.g, color.b, 255 * pulse))
		end
	end
end)
