local State = DubzWorkflow.State
local Client = DubzWorkflow.Client
local config = DubzWorkflow.Config
local WINDOW_ICON = "actions/add"
local FIELD_HEIGHT = 32
local LABEL_HEIGHT = 20
local BODY_HEIGHT = 150
local LIST_HEIGHT = 90
local BUTTON_HEIGHT = 38
local WORK_STATUSES = {"todo", "progress", "blocked", "review"}
local frame
local resultHook = "DubzWorkflow_EditorResult"

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function row(scroll, height)
    local holder = scroll:Add("Panel")

    holder:Dock(TOP)
    holder:SetTall(height)
    holder:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))

    return holder
end

local function caption(holder, text)
    local label = vgui.Create("DFW.Label", holder)

    label:Dock(TOP)
    label:SetTall(LABEL_HEIGHT)
    label:SetStyle("small")
    label:SetText(text)
end

local function textField(scroll, label, value, height, multiline)
    local holder = row(scroll, LABEL_HEIGHT + (height or FIELD_HEIGHT))

    caption(holder, label)

    local entry = vgui.Create("DFW.TextEntry", holder)

    entry:Dock(TOP)
    entry:SetTall(height or FIELD_HEIGHT)
    entry:SetUpdateOnType(true)

    if multiline then entry:SetMultiline(true) end

    entry:SetValue(value or "")

    return entry
end

local function choiceField(scroll, label, choices, selected)
    local holder = row(scroll, LABEL_HEIGHT + FIELD_HEIGHT)

    caption(holder, label)

    local dropdown = vgui.Create("DFW.Dropdown", holder)

    dropdown:Dock(TOP)
    dropdown:SetTall(FIELD_HEIGHT)

    for _, choice in ipairs(choices) do dropdown:AddChoice(choice.label, choice.data) end

    dropdown:SelectByData(selected, true)

    return dropdown
end

local function selected(dropdown)
    local _, data = dropdown:GetSelected()

    return data
end

local function assigneeNames(list)
    if #list == 0 then return phrase("NoAssignees") end

    local names = {}

    for _, entry in ipairs(list) do names[#names + 1] = entry.n ~= "" and entry.n or entry.s end

    return table.concat(names, ", ")
end

local function toggleAssignee(list, entry)
    for index, existing in ipairs(list) do
        if existing.s == entry.s then
            table.remove(list, index)
            return
        end
    end

    list[#list + 1] = {s = entry.s, n = entry.n}
end

local function assigneeField(scroll, list)
    local holder = row(scroll, LABEL_HEIGHT * 2 + FIELD_HEIGHT * 2 + 8)
    local summary

    caption(holder, phrase("FieldAssignees"))
    summary = vgui.Create("DFW.Label", holder)
    summary:Dock(TOP)
    summary:SetTall(LABEL_HEIGHT)
    summary:SetStyle("body")

    local function refresh() summary:SetText(assigneeNames(list)) end

    local bar = vgui.Create("Panel", holder)

    bar:Dock(TOP)
    bar:SetTall(FIELD_HEIGHT)

    local clear = vgui.Create("DFW.Button", bar)

    clear:Dock(RIGHT)
    clear:SetWide(80)
    clear:SetLabel(phrase("ClearAssignees"))
    clear:SetVariant("ghost")
    clear.DoClick = function()
        table.Empty(list)
        refresh()
    end

    local team = vgui.Create("DFW.Dropdown", bar)

    team:Dock(FILL)
    team:DockMargin(0, 0, 6, 0)
    team:AddChoice(phrase("AddAssignee"), "")

    for _, member in ipairs(State.Team) do team:AddChoice(member.n, member.s) end

    team:SelectByData("", true)
    team.OnSelect = function()
        local sid = selected(team)

        if not sid or sid == "" then return end

        for _, member in ipairs(State.Team) do
            if member.s == sid then toggleAssignee(list, member) end
        end

        team:SelectByData("", true)
        refresh()
    end

    local idBar = vgui.Create("Panel", holder)

    idBar:Dock(TOP)
    idBar:SetTall(FIELD_HEIGHT)
    idBar:DockMargin(0, 8, 0, 0)

    local idEntry = vgui.Create("DFW.TextEntry", idBar)

    idEntry:Dock(FILL)
    idEntry:SetPlaceholder("SteamID64")
    idEntry.OnEnter = function()
        local sid = string.Trim(idEntry:GetValue())

        if string.match(sid, "^%d+$") then toggleAssignee(list, {s = sid, n = ""}) end

        idEntry:SetValue("")
        refresh()
    end

    refresh()
end

local function linkSummary(list)
    if #list == 0 then return phrase("NoLinks") end

    local parts = {}

    for _, link in ipairs(list) do parts[#parts + 1] = (DubzWorkflow.Links.Describe(link)) end

    return table.concat(parts, ", ")
end

local function fillTargets(dropdown, definition)
    dropdown:Clear()
    dropdown:AddChoice(phrase("LinkTarget"), "")

    for _, choice in ipairs(definition and definition.choices and definition.choices() or {}) do
        dropdown:AddChoice(choice.label, choice.ref)
    end

    dropdown:SelectByData("", true)
end

local function linkField(scroll, list)
    local holder = row(scroll, LABEL_HEIGHT * 2 + FIELD_HEIGHT * 2 + 8)
    local summary

    caption(holder, phrase("SectionLinks"))
    summary = vgui.Create("DFW.Label", holder)
    summary:Dock(TOP)
    summary:SetTall(LABEL_HEIGHT)
    summary:SetStyle("body")

    local function refresh() summary:SetText(linkSummary(list)) end

    local bar = vgui.Create("Panel", holder)

    bar:Dock(TOP)
    bar:SetTall(FIELD_HEIGHT)

    local clear = vgui.Create("DFW.Button", bar)

    clear:Dock(RIGHT)
    clear:SetWide(110)
    clear:SetLabel(phrase("LinkClear"))
    clear:SetVariant("ghost")
    clear.DoClick = function()
        table.Empty(list)
        refresh()
    end

    local add = vgui.Create("DFW.Button", bar)

    add:Dock(RIGHT)
    add:SetWide(100)
    add:DockMargin(0, 0, 6, 0)
    add:SetLabel(phrase("LinkAdd"))
    add:SetVariant("primary")

    local kinds = vgui.Create("DFW.Dropdown", bar)

    kinds:Dock(FILL)
    kinds:DockMargin(0, 0, 6, 0)
    kinds:AddChoice(phrase("LinkType"), "")

    for _, definition in ipairs(DubzWorkflow.Links.All()) do kinds:AddChoice(definition.label, definition.id) end

    kinds:SelectByData("", true)

    local targets = vgui.Create("DFW.Dropdown", holder)

    targets:Dock(TOP)
    targets:SetTall(FIELD_HEIGHT)
    targets:DockMargin(0, 8, 0, 0)
    fillTargets(targets, nil)
    kinds.OnSelect = function() fillTargets(targets, DubzWorkflow.Links.Get(selected(kinds))) end

    add.DoClick = function()
        local kind, ref = selected(kinds), selected(targets)

        if not kind or kind == "" or not ref or ref == "" then
            DFW.UI.Notify(phrase("LinkNeedsTarget"), "danger")
            return
        end

        if #list < config.LinkMax then list[#list + 1] = {type = kind, ref = ref} end

        refresh()
    end

    refresh()
end

local function dateField(scroll, label, value)
    local holder = row(scroll, LABEL_HEIGHT + FIELD_HEIGHT)

    caption(holder, label)

    local bar = vgui.Create("Panel", holder)
    local pick = vgui.Create("DFW.Button", bar)
    local entry = vgui.Create("DFW.TextEntry", bar)

    bar:Dock(TOP)
    bar:SetTall(FIELD_HEIGHT)
    pick:Dock(RIGHT)
    pick:SetWide(130)
    pick:DockMargin(6, 0, 0, 0)
    pick:SetLabel(phrase("PickDate"))
    pick:SetIcon("actions/add")
    entry:Dock(FILL)
    entry:SetPlaceholder(phrase("NoDate"))
    entry:SetUpdateOnType(true)
    entry:SetValue(value or "")
    pick.DoClick = function()
        DubzWorkflow.Pickers.Dates({
            title = phrase("PickerDate"),
            selected = entry:GetValue(),
            onDone = function(date) entry:SetValue(date) end
        })
    end

    return entry
end

local function scheduleSummary(list)
    if #list == 0 then return phrase("NoDays") end

    local parts = {}

    for index = 1, math.min(#list, 4) do
        local range = DubzWorkflow.Dates.Range(list[index].from, list[index].to)

        parts[#parts + 1] = list[index].date .. (range ~= "" and (" " .. range) or "")
    end

    return table.concat(parts, ", ") .. (#list > 4 and (" +" .. (#list - 4)) or "")
end

local function scheduleField(scroll, list)
    local holder = row(scroll, LABEL_HEIGHT * 2 + FIELD_HEIGHT)
    local summary

    caption(holder, phrase("FieldSchedule"))
    summary = vgui.Create("DFW.Label", holder)
    summary:Dock(TOP)
    summary:SetTall(LABEL_HEIGHT)
    summary:SetStyle("body")

    local function refresh() summary:SetText(scheduleSummary(list)) end

    local bar = vgui.Create("Panel", holder)

    bar:Dock(TOP)
    bar:SetTall(FIELD_HEIGHT)

    local pick = vgui.Create("DFW.Button", bar)

    pick:Dock(LEFT)
    pick:SetWide(150)
    pick:DockMargin(0, 0, 6, 0)
    pick:SetLabel(phrase("PickDays"))
    pick:SetIcon("actions/add")
    pick:SetVariant("primary")
    pick.DoClick = function()
        DubzWorkflow.Pickers.Dates({
            multi = true,
            title = phrase("PickerDays"),
            selected = list,
            onDone = function(chosen)
                table.Empty(list)

                for _, entry in ipairs(chosen) do list[#list + 1] = entry end

                refresh()
            end
        })
    end

    local clear = vgui.Create("DFW.Button", bar)

    clear:Dock(LEFT)
    clear:SetWide(100)
    clear:SetLabel(phrase("ClearAll"))
    clear:SetVariant("ghost")
    clear.DoClick = function()
        table.Empty(list)
        refresh()
    end

    refresh()
end

local function collectTags(text)
    local tags = {}

    for tag in string.gmatch(text, "[^,]+") do
        tag = string.Trim(tag)

        if tag ~= "" then tags[#tags + 1] = tag end
    end

    return tags
end

local function collectLines(text)
    local lines = {}

    for _, entry in ipairs(string.Explode("\n", text)) do
        entry = string.Trim(entry)

        if entry ~= "" then lines[#lines + 1] = entry end
    end

    return lines
end

local function checklistText(task)
    local lines = {}

    for _, entry in ipairs(task and task.checklist or {}) do lines[#lines + 1] = entry.t end

    return table.concat(lines, "\n")
end

local function priorityChoices()
    local list = {}

    for _, entry in ipairs(DubzWorkflow.List("priorities")) do list[#list + 1] = {label = entry, data = entry} end

    return list
end

local function colorChoices()
    local list = {{label = phrase("ColorNone"), data = ""}}

    for _, entry in ipairs(DubzWorkflow.PaletteList()) do list[#list + 1] = {label = entry.name, data = entry.hex} end

    return list
end

local function statusChoices()
    local list = {}

    for _, status in ipairs(WORK_STATUSES) do list[#list + 1] = {label = DubzWorkflow.StatusLabel(status), data = status} end

    return list
end

function DubzWorkflow.OpenEditor(id)
    local task = id and Client.Find(id) or nil

    if IsValid(frame) then frame:Remove() end

    frame = DFW.UI.CreateFrame(phrase(task and "EditorEdit" or "EditorNew"), config.EditorWidth, config.EditorHeight, WINDOW_ICON, {module = "workflow"})

    local content = frame:GetContent()
    local manager = State.Me.manager
    local assignees = table.Copy(task and task.assignees or {})
    local links = table.Copy(task and task.links or {})
    local schedule = table.Copy(task and task.schedule or {})
    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("MD"), 0, 0)

    local scroll = vgui.Create("DFW.ScrollPanel", content)

    scroll:Dock(FILL)

    local title = textField(scroll, phrase("FieldTitle"), task and task.title)
    local summary = textField(scroll, phrase("FieldSummary"), task and task.summary)
    local priority = choiceField(scroll, phrase("FieldPriority"), priorityChoices(), task and task.priority or config.DefaultPriority)
    local status

    if manager then
        status = choiceField(scroll, phrase("FieldStatus"), statusChoices(), task and task.status or "todo")
    end

    local color = choiceField(scroll, phrase("FieldColor"), colorChoices(), task and task.color or "")
    local due = dateField(scroll, phrase("FieldDue"), task and task.due)
    local tags = textField(scroll, phrase("FieldTags"), task and table.concat(task.tags or {}, ", "))

    assigneeField(scroll, assignees)
    scheduleField(scroll, schedule)
    linkField(scroll, links)

    local instructions = textField(scroll, phrase("FieldInstructions") .. "  (" .. phrase("InstructionsHint") .. ")", task and task.instructions, BODY_HEIGHT, true)
    local checklist = textField(scroll, phrase("FieldChecklist"), checklistText(task), LIST_HEIGHT, true)

    local cancel = vgui.Create("DFW.Button", bar)

    cancel:Dock(RIGHT)
    cancel:SetWide(110)
    cancel:SetLabel(phrase("Cancel"))
    cancel:SetVariant("ghost")
    cancel.DoClick = function() frame:Close() end

    local save = vgui.Create("DFW.Button", bar)

    save:Dock(RIGHT)
    save:SetWide(manager and 110 or 180)
    save:DockMargin(0, 0, 6, 0)
    save:SetLabel(manager and phrase("Save") or phrase("SubmitForReview"))
    save:SetVariant("primary")
    save.DoClick = function()
        save:SetEnabled(false)
        Client.Save({
            id = task and task.id,
            title = title:GetValue(),
            summary = summary:GetValue(),
            priority = selected(priority),
            color = selected(color),
            status = status and selected(status),
            due = due:GetValue(),
            tags = collectTags(tags:GetValue()),
            assignees = assignees,
            links = links,
            schedule = schedule,
            instructions = instructions:GetValue(),
            checklist = collectLines(checklist:GetValue())
        })
    end

    hook.Add("DubzWorkflowResult", resultHook, function(ok)
        if not IsValid(frame) then
            hook.Remove("DubzWorkflowResult", resultHook)
            return
        end

        if IsValid(save) then save:SetEnabled(true) end

        if ok then frame:Close() end
    end)
end
