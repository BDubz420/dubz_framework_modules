-- The skills menu, built entirely from Dubz Framework controls (DFW.Frame, DFW.XPBar, DFW.SkillBox ...), so restyling
-- those controls or the theme restyles this menu too.
-- Toggle with the open key (F6 by default, changeable in the admin config), /skills, or the dubz_skills console command.
local cfg = DubzSkills.Config

local frame

local function tooltipText(def)
	local lp = LocalPlayer()
	local level = DubzSkills.GetLevel(lp, def.id)
	local xp = DubzSkills.GetXP(lp, def.id)

	local lines = {def.name, "Level " .. level .. " / " .. def.maxLevel}

	if level < def.maxLevel then
		lines[#lines + 1] = "XP: " .. xp .. " / " .. DubzSkills.XPForLevel(def, level + 1)
	else
		lines[#lines + 1] = "Maxed out"
	end

	if def.effect then
		local text = def.effect(level)
		if level < def.maxLevel then text = text .. "  (next level: " .. def.effect(level + 1) .. ")" end
		lines[#lines + 1] = text
	end

	if def.desc then lines[#lines + 1] = def.desc end

	return table.concat(lines, "\n")
end

local function overallTooltip()
	local lp = LocalPlayer()
	local level = DubzSkills.GetOverallLevel(lp)
	local total = DubzSkills.GetTotalXP(lp)

	if level >= cfg.maxOverallLevel then
		return "Level " .. level .. " (maximum)\nTotal XP: " .. string.Comma(total)
	end

	local from = DubzSkills.XPForOverall(level)
	local to = DubzSkills.XPForOverall(level + 1)

	return "Level " .. level .. "\nXP: " .. string.Comma(total - from) .. " / " .. string.Comma(to - from)
		.. "  (" .. math.floor(DubzSkills.OverallProgress(lp) * 100) .. "%)\n"
		.. string.Comma(to - total) .. " XP to level " .. (level + 1)
end

local function addCategory(scroll, category)
	local header = vgui.Create("DFW.SectionHeader")
	header:Dock(TOP)
	header:DockMargin(0, 8, 0, 2)
	header:SetText(category.name)
	scroll:AddItem(header)

	for _, def in ipairs(category.skills) do
		local row = vgui.Create("DFW.SkillBox")
		row:Dock(TOP)
		row:SetSkill(
			def.name,
			def.maxLevel,
			function() return DubzSkills.GetLevel(LocalPlayer(), def.id) end,
			function() return DubzSkills.Progress(LocalPlayer(), def.id) end,
			function() return tooltipText(def) end
		)
		scroll:AddItem(row)
	end
end

local function closeMenu()
	if IsValid(frame) then frame:Remove() end
	frame = nil
end

-- Clean toggle: one action per key press (holding the key does nothing more), and one second between
-- toggles. To close it with the key you must let go and press again.
local nextToggle = 0
local waitRelease = false

local function openMenu()
	closeMenu()

	-- If the key is still held when the window appears, ignore it until it is released
	waitRelease = input.IsKeyDown(cfg.openKey)

	frame = DFW.UI.CreateFrame("Skills", 360, math.min(ScrH() * 0.75, 640), nil, {compact = true, module = "skills"})

	local baseThink = frame.Think
	frame.Think = function(self)
		baseThink(self)
		if waitRelease and not input.IsKeyDown(cfg.openKey) then waitRelease = false end
	end

	local baseKey = frame.OnKeyCodePressed
	frame.OnKeyCodePressed = function(self, key)
		if key == cfg.openKey and not waitRelease then DubzSkills.ToggleMenu() return end
		baseKey(self, key)
	end

	local content = frame:GetContent()

	-- Overall level: "Level N" over a bar that fills as ALL your skill XP adds up; hover for the numbers
	local overall = vgui.Create("DFW.XPBar", content)
	overall:Dock(TOP)
	overall:SetLevel(DubzSkills.GetOverallLevel(LocalPlayer())) -- also sizes the control (caption + bar)
	overall:DockMargin(9, 2, 9, 8)
	overall:SetTooltipFunc(overallTooltip)
	overall.Think = function(self)
		local lp = LocalPlayer()
		self:SetLevel(DubzSkills.GetOverallLevel(lp))
		self:SetFraction(DubzSkills.OverallProgress(lp))
	end

	local scroll = vgui.Create("DFW.ScrollPanel", content)
	scroll:Dock(FILL)
	scroll:DockMargin(5, 0, 5, 5)

	for _, category in ipairs(DubzSkills.Categories) do
		if #category.skills > 0 then
			local ok, err = pcall(addCategory, scroll, category)
			if not ok then
				ErrorNoHalt("[DubzSkills] couldn't build category " .. tostring(category.id) .. ": " .. tostring(err) .. "\n")
				chat.AddText(Color(255, 80, 80), "[Skills] ", color_white, "Menu error: " .. tostring(err))
			end
		end
	end

	frame:InvalidateLayout(true)
	content:InvalidateLayout(true)
	scroll:InvalidateLayout(true)
end

function DubzSkills.ToggleMenu()
	if CurTime() < nextToggle then return end
	if not DubzSkills.Enabled() then return end

	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then
		nextToggle = CurTime() + 1
		chat.AddText(Color(255, 80, 80), "[Skills] ", color_white, "The Dubz Framework addon isn't installed, so the skills menu can't open.")
		return
	end

	nextToggle = CurTime() + 1

	if IsValid(frame) then closeMenu() else openMenu() end
end

concommand.Add("dubz_skills", DubzSkills.ToggleMenu)

net.Receive("DubzSkills_Open", function()
	if not IsValid(frame) then DubzSkills.ToggleMenu() end
end)

local keyHeld = false

hook.Add("PlayerButtonUp", "DubzSkills_OpenKeyUp", function(ply, button)
	if ply == LocalPlayer() and button == cfg.openKey then keyHeld = false end
end)

hook.Add("PlayerButtonDown", "DubzSkills_OpenKey", function(ply, button)
	if ply ~= LocalPlayer() or button ~= cfg.openKey then return end

	-- Only the first frame of a press counts
	if keyHeld then return end
	keyHeld = true

	-- Don't steal the key while typing in a text box
	local focus = vgui.GetKeyboardFocus()
	if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end

	DubzSkills.ToggleMenu()
end)
