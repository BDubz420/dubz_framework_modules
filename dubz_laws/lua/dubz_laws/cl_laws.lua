-- Laws, client side: keeps both lists for the panels that show them (the F1 HUD panel and the F4 laws tab read DubzLaws.Legal / DubzLaws.Illegal)
-- and redraws the laws billboards (/placelaws) as two columns.
net.Receive("DubzLaws_Sync", function()
	local data = util.JSONToTable(net.ReadString()) or {}

	DubzLaws.Legal = data.legal or {}
	DubzLaws.Illegal = data.illegal or {}
	DubzLaws.FixedLegal = data.fixedLegal or 0
	DubzLaws.FixedIllegal = data.fixedIllegal or 0

	hook.Run("DubzLawsChanged")
end)

-- DarkRP's list, for anything that still reads it: illegal laws first, then legal ones, each marked
function DubzLaws.Combined()
	local list = {}

	for _, law in ipairs(DubzLaws.Illegal) do list[#list + 1] = "Illegal: " .. law end
	for _, law in ipairs(DubzLaws.Legal) do list[#list + 1] = "Legal: " .. law end

	return list
end

-- The billboard ------------------------------------------------------------------------------------------------------------------------
-- The board is 558 x 290 of drawing space. LEGAL on the left, ILLEGAL on the right, numbered separately.
local BOARD_W, BOARD_H, COLUMN = 558, 290, 272
local green, red = Color(110, 200, 120), Color(235, 100, 90)

local function wrapped(text, font, width)
	surface.SetFont(font)

	local lines, line = {}, ""

	for word in string.gmatch(text, "%S+") do
		local try = line == "" and word or (line .. " " .. word)

		if line ~= "" and surface.GetTextSize(try) > width then
			lines[#lines + 1] = line
			line = word
		else
			line = try
		end
	end

	if line ~= "" then lines[#lines + 1] = line end
	return lines
end

local function column(list, x, title, color)
	draw.RoundedBox(4, x, 0, COLUMN, 30, Color(20, 20, 20, 255))
	draw.SimpleText(title, "Roboto20", x + COLUMN / 2, 5, color, TEXT_ALIGN_CENTER)

	local y = 36

	if #list == 0 then
		draw.SimpleText("None.", "Roboto20", x + 6, y, Color(150, 150, 150))
		return
	end

	for index, law in ipairs(list) do
		for number, line in ipairs(wrapped(index .. ". " .. law, "Roboto20", COLUMN - 12)) do
			if y > BOARD_H - 22 then return end

			draw.SimpleText(number == 1 and line or ("    " .. line), "Roboto20", x + 6, y, color_white)
			y = y + 21
		end

		y = y + 3
	end
end

local function drawBoard(self)
	self:DrawModel()

	local drawPos = self:LocalToWorld(self.DrawPos or Vector(1, -111, 58))

	local angles = self:GetAngles()
	angles:RotateAroundAxis(self:GetAngles():Forward(), 90)
	angles:RotateAroundAxis(self:GetAngles():Up(), 90)

	cam.Start3D2D(drawPos, angles, 0.4)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, BOARD_W, BOARD_H)

		column(DubzLaws.Legal, 4, "LEGAL", green)
		column(DubzLaws.Illegal, BOARD_W / 2 + 2, "ILLEGAL", red)

		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawRect(BOARD_W / 2 - 1, 8, 2, BOARD_H - 16)
	cam.End3D2D()
end

-- DarkRP's billboard entity loads its own drawing: swap it for ours once everything is up (boards already in the world too)
local function patch()
	local stored = scripted_ents.GetStored("darkrp_laws")
	if stored and stored.t then stored.t.Draw = drawBoard end

	for _, ent in ipairs(ents.FindByClass("darkrp_laws")) do ent.Draw = drawBoard end
end

hook.Add("InitPostEntity", "DubzLaws_Patch", function()
	DarkRP.getLaws = DubzLaws.Combined

	timer.Simple(1, patch)
	timer.Simple(4, patch)
end)

hook.Add("OnEntityCreated", "DubzLaws_PatchNew", function(ent)
	if IsValid(ent) and ent:GetClass() == "darkrp_laws" then timer.Simple(0, function() if IsValid(ent) then ent.Draw = drawBoard end end) end
end)
