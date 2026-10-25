DubzWorkflow.Board = DubzWorkflow.Board or {}

local Board = DubzWorkflow.Board
local State = DubzWorkflow.State
local Card = DubzWorkflow.Card
local config = DubzWorkflow.Config
local HEADER_HEIGHT = 34
local COLUMN_GAP = 10
local COLUMNS = {"todo", "progress", "blocked", "review"}
local hookCounter = 0
local BAR_HEIGHT = 32
local SORTS = {
    {id = "priority", key = "SortPriority"},
    {id = "newest", key = "SortNewest"},
    {id = "due", key = "SortDue"}
}
local view = {sort = "priority", priority = ""}

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function involved(task)
    local me = State.Me.s

    if task.claimedBy and task.claimedBy.s == me then return true end

    for _, entry in ipairs(task.assignees or {}) do
        if entry.s == me then return true end
    end

    return false
end

local FILTERS = {
    mine = function(task) return involved(task) and task.status ~= "done" and task.status ~= "pending" end,
    done = function(task) return task.status == "done" end,
    review = function(task) return task.status == "pending" end
}

local function ordered(list, mode)
    table.sort(list, function(a, b)
        if mode == "done" then return (a.doneAt or 0) > (b.doneAt or 0) end

        if view.sort == "newest" then return (a.createdAt or 0) > (b.createdAt or 0) end

        if view.sort == "due" then
            local first = a.due and a.due ~= "" and a.due or "9999-99-99"
            local second = b.due and b.due ~= "" and b.due or "9999-99-99"

            if first ~= second then return first < second end
        end

        local left, right = Card.PriorityRank(a.priority), Card.PriorityRank(b.priority)

        if left ~= right then return left > right end

        return (a.updatedAt or 0) > (b.updatedAt or 0)
    end)

    return list
end

local function collect(predicate, mode)
    local list = {}

    for _, task in ipairs(State.Tasks) do
        if predicate(task) and (view.priority == "" or task.priority == view.priority) then list[#list + 1] = task end
    end

    return ordered(list, mode)
end

local function fill(scroll, tasks)
    scroll:Clear()

    if #tasks == 0 then
        local empty = scroll:Add("DFW.Label")

        empty:Dock(TOP)
        empty:SetTall(40)
        empty:SetStyle("muted")
        empty:SetAlign(TEXT_ALIGN_CENTER)
        empty:SetText(phrase("NoTasks"))

        return
    end

    for _, task in ipairs(tasks) do Card.Build(scroll, task, DubzWorkflow.OpenDetail) end
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
        local tasks = collect(function(task) return task.status == status end, "board")

        header:SetText(DubzWorkflow.StatusLabel(status) .. "  " .. #tasks)
        fill(scroll, tasks)
    end

    return column
end

local function buildColumns(root)
    local columns = {}

    for _, status in ipairs(COLUMNS) do columns[#columns + 1] = buildColumn(root, status) end

    root.PerformLayout = function(self, w, h)
        local each = math.floor((w - COLUMN_GAP * (#columns - 1)) / #columns)

        for index, column in ipairs(columns) do
            column:SetPos((index - 1) * (each + COLUMN_GAP), 0)
            column:SetSize(each, h)
        end
    end

    return function()
        for _, column in ipairs(columns) do column.Refresh() end
    end
end

local function buildToolbar(root, onChange)
    local bar = vgui.Create("Panel", root)
    local sort = vgui.Create("DFW.Dropdown", bar)
    local filter = vgui.Create("DFW.Dropdown", bar)

    bar:Dock(TOP)
    bar:SetTall(BAR_HEIGHT)
    bar:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    filter:Dock(RIGHT)
    filter:SetWide(190)
    sort:Dock(RIGHT)
    sort:SetWide(210)
    sort:DockMargin(0, 0, 8, 0)

    for _, entry in ipairs(SORTS) do sort:AddChoice(phrase(entry.key), entry.id) end

    sort:SelectByData(view.sort, true)
    sort.OnSelect = function()
        local _, data = sort:GetSelected()

        view.sort = data or "priority"
        onChange()
    end

    filter:AddChoice(phrase("FilterAll"), "")

    for _, entry in ipairs(DubzWorkflow.List("priorities")) do filter:AddChoice(entry, entry) end

    filter:SelectByData(view.priority, true)
    filter.OnSelect = function()
        local _, data = filter:GetSelected()

        view.priority = data or ""
        onChange()
    end
end

function Board.Build(parent, mode)
    local root = vgui.Create("Panel", parent)
    local refresh
    local area

    root:Dock(FILL)
    buildToolbar(root, function() refresh() end)
    area = vgui.Create("Panel", root)
    area:Dock(FILL)

    if mode == "board" then
        refresh = buildColumns(area)
    else
        local scroll = vgui.Create("DFW.ScrollPanel", area)

        scroll:Dock(FILL)
        refresh = function() fill(scroll, collect(FILTERS[mode] or FILTERS.mine, mode)) end
    end

    hookCounter = hookCounter + 1

    local name = "DubzWorkflow_Board" .. hookCounter

    hook.Add("DubzWorkflowState", name, function()
        if IsValid(root) then refresh() end
    end)

    root.OnRemove = function() hook.Remove("DubzWorkflowState", name) end
    refresh()

    return root
end
