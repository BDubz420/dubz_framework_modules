local mats = {}

-- Material() every frame is wasteful; cache by path.
function BHUD.GetMat(path)
	local mat = mats[path]
	if not mat then
		mat = Material(path)
		mats[path] = mat
	end
	return mat
end

function BHUD.LineHeight(font)
	surface.SetFont(font)
	local _, h = surface.GetTextSize("A")
	return h
end

local function withAlpha(col, alpha)
	return Color(col.r, col.g, col.b, col.a * alpha)
end

-- Splits text into lines that fit maxW, honouring explicit newlines.
function BHUD.Wrap(text, font, maxW)
	surface.SetFont(font)
	local lines = {}

	for _, para in ipairs(string.Explode("\n", text)) do
		local line = ""
		for word in string.gmatch(para, "%S+") do
			local test = (line == "") and word or (line .. " " .. word)
			if line ~= "" and surface.GetTextSize(test) > maxW then
				lines[#lines + 1] = line
				line = word
			else
				line = test
			end
		end
		lines[#lines + 1] = line
	end

	return lines
end

function BHUD.FormatTime(sec)
	sec = math.floor(sec)
	return string.format("%d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
end

-- Y of the first free row beside the top bar (below it, or above it when flipped).
function BHUD.PanelTop()
	local cfg = BHUD.Config
	if cfg.flip then return 10 end
	return cfg.barHeight + 6
end

-- Draws the card background and title (titleColor optional). Returns the y where content starts.
function BHUD.DrawCard(x, y, w, h, title, alpha, titleColor, center)
	local p = BHUD.Config.panel
	alpha = alpha or 1

	draw.RoundedBox(8, x, y, w, h, withAlpha(p.bg, alpha))

	if center then
		draw.SimpleText(title, BHUD.Config.titleFont, x + w / 2, y + 6, withAlpha(titleColor or p.title, alpha), TEXT_ALIGN_CENTER)
	else
		draw.SimpleText(title, BHUD.Config.titleFont, x + p.pad, y + 6, withAlpha(titleColor or p.title, alpha))
	end

	return y + 28
end

-- Draws lines inside a card, stopping at limitY (default: bottom of the screen). With center, x is the centre.
-- A line is a string, or {text = "", head = true} / {text = "", muted = true}.
function BHUD.DrawLines(lines, x, y, lineH, limitY, alpha, center)
	local cfg = BHUD.Config
	local p = cfg.panel
	limitY = limitY or (ScrH() - 12)
	alpha = alpha or 1

	for _, line in ipairs(lines) do
		if y + lineH > limitY then break end

		local text, font, col = line, cfg.font, p.text
		if istable(line) then
			text = line.text
			if line.head then font, col = cfg.titleFont, p.title
			elseif line.muted then col = p.muted end
			if line.color then col = line.color end
		end

		if text ~= "" then draw.SimpleText(text, font, x, y, withAlpha(col, alpha), center and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT) end
		y = y + lineH
	end
end

-- Height a card needs for n lines, clamped so it never leaves the screen.
function BHUD.CardHeight(y, n, lineH)
	local h = 28 + n * lineH + 10
	return math.min(h, ScrH() - 12 - y)
end
