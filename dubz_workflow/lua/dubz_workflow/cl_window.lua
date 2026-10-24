local State = DubzWorkflow.State
local Client = DubzWorkflow.Client
local Board = DubzWorkflow.Board
local config = DubzWorkflow.Config
local WINDOW_ICON = "actions/check"
local BAR_HEIGHT = 44
local CLOCK_WIDTH = 150
local PRESENCE_WIDTH = 110
local NEW_WIDTH = 120
local TEAM_WIDTH = 110
local GAP = 8
local frame
local pendingOpen = false
local pendingTab

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function serverTime()
    local base = State.Settings.serverTime

    if not base then return nil end

    return os.date("%H:%M", base + math.floor(CurTime() - (State.Settings.receivedAt or CurTime())))
end

local function buildClock(bar)
    local clock = vgui.Create("Panel", bar)

    clock:Dock(RIGHT)
    clock:SetWide(CLOCK_WIDTH)
    clock.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()
        local server = serverTime()

        DFW.Draw.Text(os.date("%H:%M:%S"), "BodyBold", w, server and h * 0.3 or h * 0.38, theme.text, TEXT_ALIGN_RIGHT)
        DFW.Draw.Text(os.date("%a %d %b %Y"), "Tiny", w, server and h * 0.58 or h * 0.72, theme.textMuted, TEXT_ALIGN_RIGHT)

        if server then DFW.Draw.Text(phrase("ServerTime", {time = server}), "Tiny", w, h * 0.86, theme.textDim, TEXT_ALIGN_RIGHT) end
    end
end

local function buildPresence(bar)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(RIGHT)
    button:SetWide(PRESENCE_WIDTH)
    button:DockMargin(0, 0, GAP, 0)

    local function paint()
        local working = State.Me.working == true

        button:SetLabel(phrase(working and "Working" or "Playing"))
        button:SetVariant(working and "primary" or "default")
        button:SetIcon(working and "actions/check" or "players/person")
    end

    button.DoClick = function()
        State.Me.working = not (State.Me.working == true)
        paint()
        Client.Presence(State.Me.working)
    end

    hook.Add("DubzWorkflowTeam", "DubzWorkflow_WindowPresence", function()
        if IsValid(button) then paint() end
    end)

    paint()
end

local function buildTeam(bar)
    local label = vgui.Create("DFW.Label", bar)

    label:Dock(RIGHT)
    label:SetWide(TEAM_WIDTH)
    label:SetStyle("small")
    label:SetAlign(TEXT_ALIGN_RIGHT)

    local function update()
        local count = 0

        for _, member in ipairs(State.Team) do
            if member.working then count = count + 1 end
        end

        label:SetText(phrase("TeamWorking", {count = count}))
    end

    hook.Add("DubzWorkflowTeam", "DubzWorkflow_WindowTeam", function()
        if IsValid(label) then update() end
    end)

    update()
end

local function buildNew(bar)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(RIGHT)
    button:SetWide(NEW_WIDTH)
    button:DockMargin(GAP, 0, GAP, 0)
    button:SetLabel(phrase("NewTask"))
    button:SetIcon("actions/add")
    button:SetVariant("primary")
    button.DoClick = function() DubzWorkflow.OpenEditor() end
end

local function buildTabs(bar, body, startTab)
    local tabs = vgui.Create("DFW.TabBar", bar)
    local active

    tabs:Dock(FILL)
    tabs.OnTabChanged = function(_, id)
        if active == id then return end

        active = id
        body:Clear()

        if id == "jobs" then
            DubzWorkflow.Jobs.Build(body)
        elseif id == "calendar" then
            DubzWorkflow.Calendar.Build(body)
        elseif id == "suggestions" then
            DubzWorkflow.Suggestions.Build(body)
        else
            Board.Build(body, id)
        end
    end

    tabs:AddTab("board", phrase("TabBoard"))
    tabs:AddTab("mine", phrase("TabMine"))
    tabs:AddTab("calendar", phrase("TabCalendar"))
    tabs:AddTab("done", phrase("TabDone"))
    tabs:AddTab("jobs", phrase("TabJobs"))

    if DubzSuggestions then tabs:AddTab("suggestions", phrase("TabSuggestions")) end

    if State.Me.manager then tabs:AddTab("review", phrase("TabReview")) end

    tabs:SetActive(startTab or "board")

    return tabs
end

local function build(startTab)
    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame(phrase("WindowTitle"), config.WindowWidth, config.WindowHeight, WINDOW_ICON, {module = "workflow"})
    frame:SetSubtitle(phrase("WindowSubtitle"))

    local content = frame:GetContent()
    local bar = vgui.Create("Panel", content)
    local body = vgui.Create("Panel", content)

    bar:Dock(TOP)
    bar:SetTall(BAR_HEIGHT)
    bar:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    body:Dock(FILL)
    buildClock(bar)
    buildPresence(bar)
    buildTeam(bar)

    buildNew(bar)
    buildTabs(bar, body, startTab)

    local closed = frame.OnClose

    frame.OnClose = function(...)
        Client.Close()

        if closed then return closed(...) end
    end
end

function DubzWorkflow.Open(tab)
    if not DubzWorkflow.Enabled() then
        DFW.UI.Notify(phrase("ErrorDisabled"), "danger")
        return
    end

    pendingOpen = true
    pendingTab = isstring(tab) and tab or nil
    Client.Request()
end

hook.Add("DubzWorkflowState", "DubzWorkflow_WindowOpen", function()
    if not pendingOpen then return end

    pendingOpen = false
    build(pendingTab)
end)
