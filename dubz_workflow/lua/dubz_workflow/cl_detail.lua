local State = DubzWorkflow.State
local Client = DubzWorkflow.Client
local Card = DubzWorkflow.Card
local Format = DubzWorkflow.Format
local config = DubzWorkflow.Config
local WINDOW_ICON = "actions/check"
local ACTION_HEIGHT = 40
local ROW = 24
local NOTES_HEIGHT = 90
local WORK_STATUSES = {"todo", "progress", "blocked", "review"}
local frame
local shownId
local shownStamp

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function pad()
    return DFW.UI.Space("MD")
end

local function heading(scroll, text)
    local label = scroll:Add("DFW.Label")

    label:Dock(TOP)
    label:SetTall(28)
    label:DockMargin(0, pad(), 0, 0)
    label:SetStyle("heading")
    label:SetText(text)
end

local function line(scroll, text, style)
    local label = scroll:Add("DFW.Label")

    label:Dock(TOP)
    label:SetTall(ROW)
    label:SetStyle(style or "muted")
    label:SetText(text)
end

local function isMine(task)
    for _, entry in ipairs(task.assignees or {}) do
        if entry.s == State.Me.s then return true end
    end

    return task.claimedBy and task.claimedBy.s == State.Me.s
end

local function summary(scroll, task)
    line(scroll, DubzWorkflow.StatusLabel(task.status) .. "  •  " .. task.priority, "bodybold")
    line(scroll, phrase("FieldAssignees") .. ": " .. Card.Names(task))

    if task.claimedBy then line(scroll, phrase("ClaimedBy", {name = task.claimedBy.n})) end

    if task.due and task.due ~= "" then line(scroll, phrase(Card.Overdue(task) and "Overdue" or "Due", {date = task.due})) end

    if task.status == "done" and task.doneBy then
        line(scroll, phrase("DoneBy", {name = task.doneBy.n, date = os.date("%Y-%m-%d", task.doneAt or 0)}))
    end

    if task.summary and task.summary ~= "" then line(scroll, task.summary, "body") end
end

local function instructions(scroll, task)
    if not task.instructions or task.instructions == "" then return end

    heading(scroll, phrase("SectionInstructions"))

    local body = Format.Panel(scroll, task.instructions)

    body:Dock(TOP)
    body:DockMargin(0, 4, 0, 0)
end

local function schedule(scroll, task)
    if #(task.schedule or {}) == 0 then return end

    heading(scroll, phrase("SectionSchedule"))

    for _, entry in ipairs(task.schedule) do
        local times = entry.from and (entry.to and DubzWorkflow.Dates.Range(entry.from, entry.to) or DubzWorkflow.Dates.Clock(entry.from)) or ""

        line(scroll, entry.date .. (times ~= "" and ("  " .. times) or ""), "body")
    end
end

local function links(scroll, task)
    if #(task.links or {}) == 0 then return end

    heading(scroll, phrase("SectionLinks"))

    for _, link in ipairs(task.links) do
        local text, available = DubzWorkflow.Links.Describe(link)
        local button = scroll:Add("DFW.Button")

        button:Dock(TOP)
        button:SetTall(32)
        button:DockMargin(0, 4, 0, 0)
        button:SetVariant("default")
        button:SetEnabled(available)
        button:SetLabel(available and text or phrase("LinkUnavailable", {label = text}))
        button.DoClick = function() DubzWorkflow.Links.Open(link) end
    end
end

local function checklist(scroll, task)
    if #(task.checklist or {}) == 0 then return end

    heading(scroll, phrase("SectionChecklist"))

    for index, entry in ipairs(task.checklist) do
        local box = scroll:Add("DFW.Checkbox")

        box:Dock(TOP)
        box:SetTall(ROW + 4)
        box:SetLabel(entry.t)
        box:SetChecked(entry.d, true)
        box.OnChange = function(_, value) Client.Act(task.id, "check", {index = index, value = value}) end
    end
end

local function notes(scroll, task)
    heading(scroll, phrase("FieldNotes"))

    local entry = scroll:Add("DFW.TextEntry")

    entry:Dock(TOP)
    entry:SetTall(NOTES_HEIGHT)
    entry:SetMultiline(true)
    entry:SetUpdateOnType(true)
    entry:SetPlaceholder(phrase("NotesPlaceholder"))
    entry:SetValue(task.notes or "")

    local save = scroll:Add("DFW.Button")

    save:Dock(TOP)
    save:SetTall(32)
    save:DockMargin(0, 6, 0, 0)
    save:SetLabel(phrase("AddNote"))
    save.DoClick = function() Client.Act(task.id, "notes", {value = entry:GetValue()}) end
end

local function history(scroll, task)
    if #(task.history or {}) == 0 then return end

    heading(scroll, phrase("SectionHistory"))

    for index = #task.history, 1, -1 do
        local entry = task.history[index]

        line(scroll, os.date("%Y-%m-%d %H:%M", entry.at) .. "  " .. entry.by .. " " .. entry.what, "small")
    end
end

local function actionButton(bar, text, variant, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(120)
    button:DockMargin(0, 0, 6, 0)
    button:SetLabel(text)
    button:SetVariant(variant)
    button.DoClick = onClick

    return button
end

local function statusDropdown(bar, task)
    local dropdown = vgui.Create("DFW.Dropdown", bar)

    dropdown:Dock(LEFT)
    dropdown:SetWide(140)
    dropdown:DockMargin(0, 0, 6, 0)

    for _, status in ipairs(WORK_STATUSES) do dropdown:AddChoice(DubzWorkflow.StatusLabel(status), status) end

    dropdown:SelectByData(task.status, true)
    dropdown.OnSelect = function()
        local _, data = dropdown:GetSelected()

        if data and data ~= task.status then Client.Act(task.id, "status", {value = data}) end
    end
end

local function workActions(bar, task)
    if task.claimedBy and task.claimedBy.s == State.Me.s then
        actionButton(bar, phrase("Unclaim"), "default", function() Client.Act(task.id, "unclaim") end)
    elseif not task.claimedBy then
        actionButton(bar, phrase("Claim"), "primary", function() Client.Act(task.id, "claim") end)
    end

    if task.status == "done" then
        actionButton(bar, phrase("Reopen"), "default", function() Client.Act(task.id, "status", {value = "todo"}) end)
    else
        actionButton(bar, phrase("MarkDone"), "primary", function() Client.Act(task.id, "status", {value = "done"}) end)
        statusDropdown(bar, task)
    end
end

local function managerActions(bar, task)
    local manager = State.Me.manager

    if task.status == "pending" and manager then
        actionButton(bar, phrase("Approve"), "primary", function() Client.Act(task.id, "approve") end)
        actionButton(bar, phrase("Reject"), "danger", function() Client.Act(task.id, "reject") end)
    end

    if manager then
        actionButton(bar, phrase("Edit"), "default", function() DubzWorkflow.OpenEditor(task.id) end)
        actionButton(bar, phrase("Delete"), "danger", function()
            DFW.UI.Confirm(phrase("Delete"), task.title, function() Client.Act(task.id, "delete") end, {danger = true, confirmLabel = phrase("Delete")})
        end)
    end
end

local function build(task)
    local content = frame:GetContent()

    content:Clear()
    frame:SetTitle(task.title)
    frame:SetSubtitle(DubzWorkflow.StatusLabel(task.status))

    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(ACTION_HEIGHT)
    bar:DockMargin(0, pad(), 0, 0)

    if task.status ~= "pending" and (isMine(task) or State.Me.manager or (not task.claimedBy and #(task.assignees or {}) == 0)) then
        workActions(bar, task)
    end

    managerActions(bar, task)

    local scroll = vgui.Create("DFW.ScrollPanel", content)

    scroll:Dock(FILL)
    summary(scroll, task)
    instructions(scroll, task)
    schedule(scroll, task)
    links(scroll, task)
    checklist(scroll, task)
    notes(scroll, task)
    history(scroll, task)
end

local function refresh()
    if not (IsValid(frame) and shownId) then return end

    local task = Client.Find(shownId)

    if not task then
        frame:Close()
        return
    end

    if task.updatedAt == shownStamp then return end

    shownStamp = task.updatedAt
    build(task)
end

function DubzWorkflow.OpenDetail(id)
    local task = Client.Find(id)

    if not task then return end

    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame(task.title, config.DetailWidth, config.DetailHeight, WINDOW_ICON, {module = "workflow"})
    shownId = id
    shownStamp = task.updatedAt
    build(task)
end

hook.Add("DubzWorkflowState", "DubzWorkflow_Detail", refresh)
