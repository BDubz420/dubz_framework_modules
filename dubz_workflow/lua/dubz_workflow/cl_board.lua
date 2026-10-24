DubzWorkflow.Board = DubzWorkflow.Board or {}

local Board = DubzWorkflow.Board
local State = DubzWorkflow.State
local Card = DubzWorkflow.Card
local config = DubzWorkflow.Config
local HEADER_HEIGHT = 34
local COLUMN_GAP = 10
local COLUMNS = {"todo", "progress", "blocked", "review"}
local hookCounter = 0

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

        local left, right = Card.PriorityRank(a.priority), Card.PriorityRank(b.priority)

        if left ~= right then return left > right end

        return (a.updatedAt or 0) > (b.updatedAt or 0)
    end)

    return list
end

local function collect(predicate, mode)
    local list = {}

    for _, task in ipairs(State.Tasks) do
        if predicate(task) then list[#list + 1] = task end
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

function Board.Build(parent, mode)
    local root = vgui.Create("Panel", parent)
    local refresh

    root:Dock(FILL)

    if mode == "board" then
        refresh = buildColumns(root)
    else
        local scroll = vgui.Create("DFW.ScrollPanel", root)

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
