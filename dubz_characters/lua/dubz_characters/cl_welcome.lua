-- The welcome screen: shown each time a character is picked (or once per character if Welcome Every Time is off), and any time with the chat command. Pages:
-- the ones written in the admin menu's "Welcome Text" table (the server's welcome and how we play), then Controls
-- (live from the F4 How To Play table) and Rules (live from the F4 Rules table). Built from Dubz Framework controls.
local cfg = DubzChars.Config

local frame

local function paragraph(parent, text, muted)
	local label = vgui.Create("DLabel", parent)
	label:Dock(TOP)
	label:DockMargin(8, 0, 14, 12)
	label:SetFont(DFW.UI.Font and DFW.UI.Font("Body") or "DermaDefault")
	label:SetTextColor(muted and DFW.UI.GetTheme().textMuted or DFW.UI.GetTheme().text)
	label:SetWrap(true)
	label:SetAutoStretchVertical(true)
	label:SetText(text)
	return label
end

local function heading(parent, text)
	local header = vgui.Create("DFW.SectionHeader", parent)
	header:Dock(TOP)
	header:DockMargin(0, 6, 0, 6)
	header:SetText(text)
	return header
end

-- The pages, in order: written ones, then Controls, then Rules
local function buildPages()
	local pages, byName = {}, {}

	for _, row in ipairs(DubzChars.Welcome or {}) do
		local page = byName[row.page]

		if not page then
			page = {name = row.page, paragraphs = {}}
			byName[row.page] = page
			pages[#pages + 1] = page
		end

		page.paragraphs[#page.paragraphs + 1] = row.text
	end

	if cfg.welcomeShowControls and DubzF4 and DubzF4.HelpGroups then
		pages[#pages + 1] = {name = "Controls", controls = true}
	end

	if cfg.welcomeShowRules and DubzF4 and DubzF4.Rules and #DubzF4.Rules > 0 then
		pages[#pages + 1] = {name = "Rules", rules = true}
	end

	return pages
end

local function fill(scroll, page)
	scroll:Clear()

	for _, text in ipairs(page.paragraphs or {}) do paragraph(scroll, text) end

	if page.controls then
		for _, group in ipairs(DubzF4.HelpGroups()) do
			heading(scroll, group[1])

			for _, row in ipairs(group[2]) do
				paragraph(scroll, "[" .. row[1] .. "]   " .. row[2], false):DockMargin(8, 0, 14, 6)
			end
		end
	end

	if page.rules then
		for index, rule in ipairs(DubzF4.Rules) do paragraph(scroll, index .. ".  " .. rule) end
	end
end

function DubzChars.OpenWelcome()
	if not (DFW and DFW.UI and DFW.UI.CreateFrame) then return end
	if IsValid(frame) then frame:Remove() end

	local pages = buildPages()
	if #pages == 0 then return end

	frame = DFW.UI.CreateFrame(cfg.welcomeTitle, 860, 620, nil, {compact = true, module = "characters"})
	frame:Center()
	local content = frame:GetContent()

	local tabs = vgui.Create("DFW.TabBar", content)
	tabs:Dock(TOP)
	tabs:SetTall(36)
	tabs:DockMargin(4, 4, 4, 8)

	local bottom = vgui.Create("Panel", content)
	bottom:Dock(BOTTOM)
	bottom:SetTall(48)

	local go = vgui.Create("DFW.Button", bottom)
	go:Dock(RIGHT)
	go:SetWide(220)
	go:DockMargin(8, 6, 4, 6)
	go:SetVariant("primary")
	go:SetLabel("Let's go")
	go.DoClick = function() frame:Close() end

	local hint = vgui.Create("DLabel", bottom)
	hint:Dock(FILL)
	hint:DockMargin(8, 0, 0, 0)
	hint:SetFont("DermaDefault")
	hint:SetTextColor(DFW.UI.GetTheme().textMuted)
	hint:SetText("Open this again any time with " .. cfg.welcomeCommand .. ". The F4 menu has the full list.")

	local scroll = vgui.Create("DFW.ScrollPanel", content)
	scroll:Dock(FILL)

	for index, page in ipairs(pages) do tabs:AddTab(tostring(index), page.name) end

	tabs.OnTabChanged = function(_, id) fill(scroll, pages[tonumber(id)]) end
	tabs:SetActive("1", true)
	fill(scroll, pages[1])
end

-- First spawn of a character: show it once (remembered per character on this computer)
hook.Add("DubzCharsEntered", "DubzChars_Welcome", function()
	if not cfg.welcomeEnabled or DubzChars.EnterQuiet then return end

	timer.Simple(2, function()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		-- Every time a character is picked, unless it is set to once per character
		local key = "dubz_welcome_" .. lp:GetNWInt("dubz_char_id", 0)
		if not cfg.welcomeEveryTime and cookie.GetNumber(key, 0) == 1 then return end

		cookie.Set(key, "1")
		DubzChars.OpenWelcome()
	end)
end)

hook.Add("OnPlayerChat", "DubzChars_WelcomeCommand", function(ply, text)
	if ply ~= LocalPlayer() or string.lower(string.Trim(text)) ~= string.lower(cfg.welcomeCommand) then return end

	DubzChars.OpenWelcome()
	return true
end)

concommand.Add("dubz_welcome", function() DubzChars.OpenWelcome() end)
