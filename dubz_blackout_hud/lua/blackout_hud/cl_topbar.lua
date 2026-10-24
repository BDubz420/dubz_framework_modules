local GAP = 4

local leftItems, rightItems = {}, {}

local function boxWidth(item)
	surface.SetFont(BHUD.Config.font)
	local w = surface.GetTextSize(item.text) + 3
	if item.mat then w = w + 20 end
	return w + 11
end

local function drawBox(x, y, item, w)
	local col = item.color or color_black
	local inner = w - 11
	local textOffset = 0

	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawOutlinedRect(x, y + 2, w, 26)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(x + 1, y + 3, w - 2, 24)

	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(x + 2, y + 4, w - 4, 22)

	surface.SetDrawColor(col.r, col.g, col.b, 20)
	surface.DrawRect(x + 2, y + 4, w - 4, 22)

	if item.mat then
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(BHUD.GetMat(item.mat))
		surface.DrawTexturedRect(x + 5, y + 7, 16, 16)
		textOffset = 20
	end

	draw.SimpleText(item.text, BHUD.Config.font, x + 7 + textOffset, y + 7, item.textColor or Color(225, 225, 225))
end

-- The entries in the order and on the side the "Top Bar" table says. Entries the table doesn't mention (new ones)
-- keep their own side and go last; entries switched off are skipped.
local function orderedBars()
	local byName = {}
	for _, bar in ipairs(BHUD.Bars) do byName[bar.name] = bar end

	local list, used = {}, {}

	for _, row in ipairs(BHUD.BarRows or {}) do
		local bar = byName[row.name]

		if bar and not used[row.name] then
			used[row.name] = true
			if row.enabled then list[#list + 1] = {bar = bar, side = row.side} end
		end
	end

	for _, bar in ipairs(BHUD.Bars) do
		if not used[bar.name] then list[#list + 1] = {bar = bar, side = bar.side or "left"} end
	end

	return list
end

-- Collects the visible entries for each side. An entry hides itself by returning nil/false/""/0.
local function collect(lp)
	table.Empty(leftItems)
	table.Empty(rightItems)

	for _, entry in ipairs(orderedBars()) do
		local bar = entry.bar
		local text = bar.func(lp)
		if text and text ~= "" and text ~= 0 then
			local col = bar.color
			if isfunction(col) then col = col(lp) end
			local textCol = bar.textColor
			if isfunction(textCol) then textCol = textCol(lp) end
			local item = {text = text, mat = bar.mat, color = col, textColor = textCol}
			item.w = boxWidth(item)
			table.insert(entry.side == "right" and rightItems or leftItems, item)
		end
	end
end

function BHUD.DrawTopBar(lp)
	local cfg = BHUD.Config
	local sw, sh = ScrW(), ScrH()
	local y = cfg.flip and (sh - cfg.barHeight) or 0

	local bg = cfg.panel.bg
	surface.SetDrawColor(bg.r, bg.g, bg.b, 200)
	surface.DrawRect(0, y, sw, cfg.barHeight)

	collect(lp)

	local x = 3
	for _, item in ipairs(leftItems) do
		drawBox(x, y, item, item.w)
		x = x + item.w + GAP
	end

	-- Right side: lay out from the right edge so the last entry hugs the screen edge.
	x = sw - 3
	for i = #rightItems, 1, -1 do
		local item = rightItems[i]
		x = x - item.w
		drawBox(x, y, item, item.w)
		x = x - GAP
	end
end
