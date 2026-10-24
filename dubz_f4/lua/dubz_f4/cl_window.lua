local config = DubzF4.Config
local state = DubzF4.State
local Ui = DubzF4.Ui
local WINDOW_ICON = "darkrp/agenda"
local PAGE_FADE = 0.12

local function validTab(tabs, id)
    for _, tab in ipairs(tabs) do
        if tab.ID == id then return id end
    end
end

local function failedPage(page)
    page:Clear()
    Ui.Label(page, DubzF4.Phrase("TabFailed"), "heading", DFW.UI.GetTheme().danger, TEXT_ALIGN_CENTER):Dock(FILL)
end

local function showTab(frame, id, force)
    if frame.ActiveTab == id and not force then return end

    local tab = frame.TabList and DubzF4.Tabs:Get(id)

    if not tab then return end

    frame.ActiveTab = id
    frame.Sidebar.SetActive(id)
    frame.Container:Clear()

    local page = vgui.Create("Panel", frame.Container)

    page:Dock(FILL)
    page:SetAlpha(0)
    page:AlphaTo(255, PAGE_FADE, 0)

    local ok, err = pcall(tab.build, page)

    if not ok then
        DubzF4.Report("page '" .. id .. "' failed to build: " .. tostring(err))
        failedPage(page)
    end
end

local function handleKey(_, key)
    if key == KEY_F4 then
        DubzF4.Close()
    elseif key == KEY_ESCAPE then
        gui.HideGameUI()
        DubzF4.Close()
    end
end

function DubzF4.Open()
    if IsValid(state.Frame) then state.Frame:Remove() end

    local tabs = DubzF4.ActiveTabs()
    local frame = DFW.UI.CreateFrame(config.ServerName, config.Width, config.Height, WINDOW_ICON, {module = "f4"})
    local content = frame:GetContent()

    state.Frame = frame
    frame.TabList = tabs
    frame:SetSubtitle(DubzF4.Phrase("Subtitle"))
    frame.OnKeyCodePressed = handleKey
    frame.OnClose = function() state.LastTab = frame.ActiveTab end

    frame.Sidebar = DubzF4.Sidebar.Build(content, tabs, function(id) showTab(frame, id) end)
    frame.Container = vgui.Create("Panel", content)
    frame.Container:Dock(FILL)
    frame.Container:DockMargin(DFW.UI.Space("MD"), 0, 0, 0)

    if config.Sounds then surface.PlaySound(config.OpenSound) end

    showTab(frame, validTab(tabs, state.LastTab) or validTab(tabs, config.StartTab) or (tabs[1] and tabs[1].ID))

    return frame
end

function DubzF4.Refresh()
    local frame = state.Frame

    if IsValid(frame) and frame.ActiveTab then showTab(frame, frame.ActiveTab, true) end
end
