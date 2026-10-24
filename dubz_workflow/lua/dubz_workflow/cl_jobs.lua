DubzWorkflow.Jobs = DubzWorkflow.Jobs or {}

local Jobs = DubzWorkflow.Jobs
local State = DubzWorkflow.State
local config = DubzWorkflow.Config
local WINDOW_ICON = "darkrp/work"
local HEADER_HEIGHT = 34
local COLUMN_GAP = 10
local CARD_HEIGHT = 56
local FIELD_HEIGHT = 32
local BUTTON_HEIGHT = 38
local hookCounter = 0
local dialog

State.Jobs = State.Jobs or {statuses = {}, jobs = {}, byId = {}, loaded = false}

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function send(name, data)
    DFW.Net.Start(name)

    if data then DFW.Net.WriteJSON(data) end

    net.SendToServer()
end

function Jobs.Request()
    send("wf_jobreq")
end

local function statusColor(status)
    local theme = DFW.UI.GetTheme()
    local list = State.Jobs.statuses
    local rank
    local top = #list

    for index, entry in ipairs(list) do
        if entry == status then rank = index end
    end

    if not rank or rank == 1 then return theme.textMuted end

    if rank == top then return theme.success or theme.accent end

    if rank == 2 then return theme.warning or theme.accent end

    return theme.accent
end

function DubzWorkflow.JobBadge(id)
    local job = State.Jobs.byId[id]

    if not job then return nil end

    return {text = job.status, color = statusColor(job.status)}
end

DFW.Net.Receive("wf_jobs", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.Jobs.statuses = payload.statuses or {}
    State.Jobs.jobs = payload.jobs or {}
    State.Jobs.byId = {}
    State.Jobs.loaded = true

    for _, job in ipairs(State.Jobs.jobs) do State.Jobs.byId[job.id] = job end

    hook.Run("DubzWorkflowJobs")
end)

hook.Add("DubzDarkRPBoardOpened", "DubzWorkflow_JobBadges", function(kind)
    if kind == "jobs" then Jobs.Request() end
end)

local function jobColor(job)
    local color = job.color

    return color and Color(color.r, color.g, color.b) or DFW.UI.GetTheme().accent
end

function Jobs.OpenDialog(id)
    local job = State.Jobs.byId[id]

    if not job then return end

    if IsValid(dialog) then dialog:Remove() end

    dialog = DFW.UI.CreateFrame(phrase("JobDialogTitle"), config.JobDialogWidth, config.JobDialogHeight, WINDOW_ICON, {module = "workflow"})
    dialog:SetSubtitle(job.name)

    local content = dialog:GetContent()
    local label = vgui.Create("DFW.Label", content)

    label:Dock(TOP)
    label:SetTall(20)
    label:SetStyle("small")
    label:SetText(phrase("JobStatus"))

    local dropdown = vgui.Create("DFW.Dropdown", content)

    dropdown:Dock(TOP)
    dropdown:SetTall(FIELD_HEIGHT)

    for _, status in ipairs(State.Jobs.statuses) do dropdown:AddChoice(status, status) end

    dropdown:SelectByData(job.status, true)

    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)

    local save = vgui.Create("DFW.Button", bar)

    save:Dock(LEFT)
    save:SetWide(120)
    save:DockMargin(0, 0, 6, 0)
    save:SetLabel(phrase("Save"))
    save:SetVariant("primary")
    save.DoClick = function()
        local _, data = dropdown:GetSelected()

        if data then send("wf_jobset", {id = id, status = data}) end
    end

    if State.Me.manager then
        local create = vgui.Create("DFW.Button", bar)

        create:Dock(LEFT)
        create:SetWide(150)
        create:SetLabel(phrase("JobCreateTask"))
        create:SetIcon("actions/add")
        create.DoClick = function() send("wf_jobtask", {id = id}) end
    end
end

local function buildCard(scroll, job)
    local card = scroll:Add("DFW.Card")

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(CARD_HEIGHT)
    card:SetCursor("hand")
    card:SetAccent(jobColor(job))
    card.PaintOver = function(_, w, h)
        local theme = DFW.UI.GetTheme()

        DFW.Draw.Text(job.name, "BodyBold", 20, h / 2, theme.text)
    end
    card.OnMousePressed = function() Jobs.OpenDialog(job.id) end
end

local function buildColumn(parent, status)
    local column = vgui.Create("DFW.Card", parent)
    local header = vgui.Create("DFW.Label", column)
    local scroll = vgui.Create("DFW.ScrollPanel", column)
    local pad = DFW.UI.Space("SM")

    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)
    header:DockMargin(pad + 4, 0, pad, 0)
    header:SetStyle("bodybold")
    scroll:Dock(FILL)
    scroll:DockMargin(pad, 0, 0, pad)

    column.Refresh = function()
        local count = 0

        scroll:Clear()

        for _, job in ipairs(State.Jobs.jobs) do
            if job.status == status then
                count = count + 1
                buildCard(scroll, job)
            end
        end

        header:SetText(status .. "  " .. count)
    end

    return column
end

local function layoutColumns(root, columns)
    root.PerformLayout = function(self, w, h)
        local count = math.max(#columns, 1)
        local each = math.floor((w - COLUMN_GAP * (count - 1)) / count)

        for index, column in ipairs(columns) do
            column:SetPos((index - 1) * (each + COLUMN_GAP), 0)
            column:SetSize(each, h)
        end
    end
end

function Jobs.Build(parent)
    local root = vgui.Create("Panel", parent)
    local columns = {}
    local signature = ""

    root:Dock(FILL)

    local function refresh()
        local key = table.concat(State.Jobs.statuses, "|")

        if key ~= signature then
            signature = key
            root:Clear()
            columns = {}

            for _, status in ipairs(State.Jobs.statuses) do columns[#columns + 1] = buildColumn(root, status) end

            layoutColumns(root, columns)
            root:InvalidateLayout(true)
        end

        for _, column in ipairs(columns) do column.Refresh() end
    end

    if not DubzDarkRP then
        local note = vgui.Create("DFW.Label", root)

        note:Dock(TOP)
        note:SetTall(40)
        note:SetStyle("muted")
        note:SetAlign(TEXT_ALIGN_CENTER)
        note:SetText(phrase("JobsNoDarkRP"))

        return root
    end

    hookCounter = hookCounter + 1

    local name = "DubzWorkflow_JobsView" .. hookCounter

    hook.Add("DubzWorkflowJobs", name, function()
        if IsValid(root) then refresh() end
    end)

    root.OnRemove = function() hook.Remove("DubzWorkflowJobs", name) end

    Jobs.Request()

    if State.Jobs.loaded then refresh() end

    return root
end
