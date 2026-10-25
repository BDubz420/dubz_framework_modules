DubzWorkflow.Jobs = DubzWorkflow.Jobs or {}

local Jobs = DubzWorkflow.Jobs
local State = DubzWorkflow.State
local config = DubzWorkflow.Config
local WINDOW_ICON = "darkrp/work"
local HEADER_HEIGHT = 34
local COLUMN_GAP = 10
local CARD_HEIGHT = 74
local ICON_SIZE = 52
local FIELD_HEIGHT = 32
local NOTE_HEIGHT = 130
local LABEL_HEIGHT = 20
local BUTTON_HEIGHT = 38
local MODEL_WIDTH = 220
local TINT = 0.16
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

local function fitModel(panel)
    local entity = panel.Entity

    if not IsValid(entity) then return end

    local mins, maxs = entity:GetRenderBounds()
    local center = (mins + maxs) / 2
    local size = (maxs - mins):Length()

    panel:SetLookAt(center)
    panel:SetCamPos(center + Vector(size * 0.95, size * 0.3, size * 0.05))
    panel:SetFOV(40)
end

local function buildModel(parent, job)
    local holder = vgui.Create("Panel", parent)

    holder:Dock(LEFT)
    holder:SetWide(MODEL_WIDTH)
    holder:DockMargin(0, 0, DFW.UI.Space("MD"), 0)
    holder.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()

        draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, DFW.Anim.Color(theme.surface, jobColor(job), TINT))
    end

    if not job.model then return end

    local preview = vgui.Create("DModelPanel", holder)

    preview:Dock(FILL)
    preview:SetModel(job.model)
    preview.LayoutEntity = function(_, entity)
        entity:SetAngles(Angle(0, (RealTime() * 30) % 360, 0))
    end
    fitModel(preview)
end

local function taskChoices(dropdown, selected)
    dropdown:AddChoice(phrase("JobNoTask"), "")

    for _, task in ipairs(State.Tasks) do
        local open = task.status ~= "done" and task.status ~= "pending"

        if open or task.id == selected then dropdown:AddChoice(task.title, task.id) end
    end

    dropdown:SelectByData(selected or "", true)
end

local function field(parent, text)
    local label = vgui.Create("DFW.Label", parent)

    label:Dock(TOP)
    label:SetTall(LABEL_HEIGHT)
    label:SetStyle("small")
    label:SetText(text)
end

local function actionButton(bar, text, variant, width, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(width)
    button:DockMargin(0, 0, 6, 0)
    button:SetLabel(text)
    button:SetVariant(variant)
    button.DoClick = onClick

    return button
end

function Jobs.OpenDialog(id)
    local job = State.Jobs.byId[id]

    if not job then return end

    if IsValid(dialog) then dialog:Remove() end

    dialog = DFW.UI.CreateFrame(phrase("JobDialogTitle"), config.JobDialogWidth, config.JobDialogHeight, WINDOW_ICON, {module = "workflow"})
    dialog:SetSubtitle(job.name)

    local content = dialog:GetContent()
    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("MD"), 0, 0)
    buildModel(content, job)

    local right = vgui.Create("Panel", content)

    right:Dock(FILL)
    field(right, phrase("JobStatus"))

    local status = vgui.Create("DFW.Dropdown", right)

    status:Dock(TOP)
    status:SetTall(FIELD_HEIGHT)
    status:DockMargin(0, 0, 0, DFW.UI.Space("SM"))

    for _, entry in ipairs(State.Jobs.statuses) do status:AddChoice(entry, entry) end

    status:SelectByData(job.status, true)
    field(right, phrase("JobNote"))

    local note = vgui.Create("DFW.TextEntry", right)

    note:Dock(TOP)
    note:SetTall(NOTE_HEIGHT)
    note:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    note:SetMultiline(true)
    note:SetUpdateOnType(true)
    note:SetPlaceholder(phrase("JobNotePlaceholder"))
    note:SetValue(job.note or "")
    field(right, phrase("JobLinkedTask"))

    local tasks = vgui.Create("DFW.Dropdown", right)

    tasks:Dock(TOP)
    tasks:SetTall(FIELD_HEIGHT)
    taskChoices(tasks, job.task)

    local function selectedTask()
        local _, data = tasks:GetSelected()

        return data ~= "" and data or nil
    end

    actionButton(bar, phrase("Save"), "primary", 110, function()
        local _, data = status:GetSelected()

        if data then send("wf_jobset", {id = id, status = data, note = note:GetValue(), task = selectedTask()}) end
    end)

    if State.Me.manager then
        actionButton(bar, phrase("JobCreateTask"), "default", 150, function() send("wf_jobtask", {id = id}) end)
    end

    actionButton(bar, phrase("SuggestOpenTask"), "ghost", 130, function()
        local task = selectedTask()

        if task and DubzWorkflow.Client.Find(task) then DubzWorkflow.OpenDetail(task) end
    end)
end

local function buildCard(scroll, job)
    local card = scroll:Add("DFW.Card")
    local theme = DFW.UI.GetTheme()

    card:Dock(TOP)
    card:DockMargin(0, 0, DFW.UI.Space("SM"), DFW.UI.Space("SM"))
    card:SetTall(CARD_HEIGHT)
    card:SetCursor("hand")
    card:SetAccent(jobColor(job))
    card:SetCardColor(DFW.Anim.Color(theme.surface, jobColor(job), TINT))

    if job.model then
        local icon = vgui.Create("SpawnIcon", card)

        icon:SetPos(14, (CARD_HEIGHT - ICON_SIZE) / 2)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetModel(job.model)
        icon:SetMouseInputEnabled(false)
    end

    card.PaintOver = function(_, w)
        local current = DFW.UI.GetTheme()
        local left = job.model and (ICON_SIZE + 26) or 16
        local limit = w - left - 12
        local linked = job.task and DubzWorkflow.Client.Find(job.task)

        DFW.Draw.Text(DubzWorkflow.Card.Fit(job.name, "BodyBold", limit), "BodyBold", left, 20, current.text)

        if job.note and job.note ~= "" then
            DFW.Draw.Text(DubzWorkflow.Card.Fit(string.gsub(job.note, "%s+", " "), "Tiny", limit), "Tiny", left, 40, current.textMuted)
        end

        if linked then
            DFW.Draw.Text("→ " .. DubzWorkflow.Card.Fit(linked.title, "Tiny", limit - 14), "Tiny", left, 58, current.accent)
        end
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
    root.PerformLayout = function(_, w, h)
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

    hook.Add("DubzWorkflowState", name, function()
        if IsValid(root) and State.Jobs.loaded then refresh() end
    end)

    root.OnRemove = function()
        hook.Remove("DubzWorkflowJobs", name)
        hook.Remove("DubzWorkflowState", name)
    end

    Jobs.Request()

    if State.Jobs.loaded then refresh() end

    return root
end
