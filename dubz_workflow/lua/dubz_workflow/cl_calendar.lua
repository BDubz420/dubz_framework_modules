DubzWorkflow.Calendar = DubzWorkflow.Calendar or {}

local Calendar = DubzWorkflow.Calendar
local State = DubzWorkflow.State
local Client = DubzWorkflow.Client
local Card = DubzWorkflow.Card
local DAY = 86400
local NOON = 12
local COLUMNS = 7
local MONTH_ROWS = 6
local BAR_HEIGHT = 36
local HINT_HEIGHT = 22
local HEAD_HEIGHT = 24
local CHIP_HEIGHT = 20
local CELL_GAP = 3
local hookCounter = 0

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function stampOf(date)
    local year, month, day = string.match(date, "^(%d+)-(%d+)-(%d+)$")

    return os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = NOON})
end

local function dateOf(time)
    return os.date("%Y-%m-%d", time)
end

local function addDays(time, count)
    return time + count * DAY
end

local function mondayOf(time)
    return addDays(time, -((os.date("*t", time).wday + 5) % 7))
end

local function monthStart(time)
    local parts = os.date("*t", time)

    return os.time({year = parts.year, month = parts.month, day = 1, hour = NOON})
end

local function shiftMonth(time, amount)
    local parts = os.date("*t", time)

    return os.time({year = parts.year, month = parts.month + amount, day = 1, hour = NOON})
end

local function involved(task)
    local me = State.Me.s

    if task.claimedBy and task.claimedBy.s == me then return true end

    for _, entry in ipairs(task.assignees or {}) do
        if entry.s == me then return true end
    end

    return not task.claimedBy and #(task.assignees or {}) == 0
end

local function eligible(task)
    if task.status == "done" or task.status == "pending" then return false end

    return State.Me.manager or involved(task)
end

local function validTime(value)
    local hour, minute = string.match(value, "^(%d%d):(%d%d)$")

    return hour ~= nil and tonumber(hour) < 24 and tonumber(minute) < 60
end

local function indexOf(list, date)
    for index, entry in ipairs(list) do
        if entry.date == date then return index end
    end
end

local function newEntry(view, date)
    local from, to = string.Trim(view.from:GetValue()), string.Trim(view.to:GetValue())

    return {date = date, from = validTime(from) and from or nil, to = validTime(to) and to or nil}
end

local function toggleDate(view, date)
    local task = view.pick and Client.Find(view.pick)

    if not task then return end

    local list = table.Copy(task.schedule or {})

    if input.IsShiftDown() and view.last then
        local first, last = stampOf(view.last), stampOf(date)

        if first > last then first, last = last, first end

        for time = first, last, DAY do
            local day = dateOf(time)

            if not indexOf(list, day) then list[#list + 1] = newEntry(view, day) end
        end
    else
        local index = indexOf(list, date)

        if index then table.remove(list, index) else list[#list + 1] = newEntry(view, date) end
    end

    view.last = date
    Client.Act(task.id, "schedule", {value = list})
end

local function scheduleMap()
    local map = {}

    for _, task in ipairs(State.Tasks) do
        if task.status ~= "done" and task.status ~= "pending" then
            for _, entry in ipairs(task.schedule or {}) do
                map[entry.date] = map[entry.date] or {}
                map[entry.date][#map[entry.date] + 1] = {task = task, entry = entry}
            end
        end
    end

    return map
end

local function chipText(item, week)
    if week and item.entry.from then return item.entry.from .. " " .. item.task.title end

    return item.task.title
end

local function buildChip(cell, view, item, y, width)
    local chip = vgui.Create("Panel", cell)
    local week = view.mode == "week"

    chip:SetPos(4, y)
    chip:SetSize(width, CHIP_HEIGHT - 2)
    chip:SetCursor("hand")
    chip.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()
        local color = Card.TaskColor(theme, item.task)
        local strong = view.pick == item.task.id

        draw.RoundedBox(4, 0, 0, w, h, DFW.UI.WithAlpha(color, strong and 120 or 55))
        DFW.Draw.Text(Card.Fit(chipText(item, week), "Tiny", w - 10), "Tiny", 5, h / 2, theme.text)
    end
    chip.OnMousePressed = function() DubzWorkflow.OpenDetail(item.task.id) end
end

local function paintCell(cell, view, date, w, h)
    local theme = DFW.UI.GetTheme()
    local picked = view.pick and Client.Find(view.pick)
    local scheduled = picked and indexOf(picked.schedule or {}, date)
    local dim = view.mode == "month" and string.sub(date, 1, 7) ~= view.month

    draw.RoundedBox(DFW.UI.Radius("SM"), 0, 0, w, h, theme.surface)

    if scheduled then draw.RoundedBox(DFW.UI.Radius("SM"), 0, 0, w, h, DFW.UI.WithAlpha(theme.accent, 40)) end

    if date == dateOf(os.time()) then
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    DFW.Draw.Text(tostring(tonumber(string.sub(date, 9, 10))), "Small", 8, HEAD_HEIGHT / 2, dim and theme.textDim or theme.text)

    if cell.More and cell.More > 0 then
        DFW.Draw.Text(phrase("CalMore", {count = cell.More}), "Tiny", 8, h - 10, theme.textMuted)
    end
end

local function buildCell(view, grid, date, x, y, width, height, items)
    local cell = vgui.Create("Panel", grid)
    local room = math.max(math.floor((height - HEAD_HEIGHT - 14) / CHIP_HEIGHT), 0)

    cell:SetPos(x, y)
    cell:SetSize(width, height)
    cell.Paint = function(self, w, h) paintCell(self, view, date, w, h) end
    cell.OnMousePressed = function() toggleDate(view, date) end
    cell.More = math.max(#items - room, 0)

    for index = 1, math.min(#items, room) do
        buildChip(cell, view, items[index], HEAD_HEIGHT + (index - 1) * CHIP_HEIGHT, width - 8)
    end
end

local function buildHeader(grid, view, cellWidth)
    for column = 0, COLUMNS - 1 do
        local label = vgui.Create("Panel", grid)

        label:SetPos(column * cellWidth, 0)
        label:SetSize(cellWidth, HEAD_HEIGHT)
        label.Paint = function(_, w, h)
            local sample = addDays(view.start, column)

            DFW.Draw.Text(os.date("%a", sample), "Small", w / 2, h / 2, DFW.UI.GetTheme().textMuted, TEXT_ALIGN_CENTER)
        end
    end
end

local function rebuild(view)
    local grid = view.grid
    local w, h = grid:GetSize()

    grid:Clear()

    if w <= 0 or h <= 0 then return end

    local rows = view.mode == "month" and MONTH_ROWS or 1
    local cellWidth = math.floor(w / COLUMNS)
    local cellHeight = math.floor((h - HEAD_HEIGHT) / rows)
    local map = scheduleMap()

    buildHeader(grid, view, cellWidth)

    for index = 0, COLUMNS * rows - 1 do
        local date = dateOf(addDays(view.start, index))
        local column, row = index % COLUMNS, math.floor(index / COLUMNS)

        buildCell(view, grid, date, column * cellWidth, HEAD_HEIGHT + row * cellHeight, cellWidth - CELL_GAP, cellHeight - CELL_GAP, map[date] or {})
    end
end

local function recompute(view)
    if view.mode == "month" then
        view.anchor = monthStart(view.anchor)
        view.start = mondayOf(view.anchor)
        view.month = string.sub(dateOf(view.anchor), 1, 7)
        view.title:SetText(os.date("%B %Y", view.anchor))
    else
        view.start = mondayOf(view.anchor)
        view.title:SetText(dateOf(view.start) .. "  –  " .. dateOf(addDays(view.start, COLUMNS - 1)))
    end

    view.modeButton:SetLabel(phrase(view.mode == "month" and "CalWeek" or "CalMonth"))
    view.dirty = true
    view.grid:InvalidateLayout()
end

local function step(view, direction)
    if view.mode == "month" then
        view.anchor = shiftMonth(view.anchor, direction)
    else
        view.anchor = addDays(view.anchor, direction * COLUMNS)
    end

    recompute(view)
end

local function navButton(bar, text, width, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(width)
    button:DockMargin(0, 0, 6, 0)
    button:SetLabel(text)
    button:SetVariant("default")
    button.DoClick = onClick

    return button
end

local function timeEntry(bar, placeholder)
    local entry = vgui.Create("DFW.TextEntry", bar)

    entry:Dock(RIGHT)
    entry:SetWide(110)
    entry:DockMargin(6, 0, 0, 0)
    entry:SetPlaceholder(placeholder)

    return entry
end

local function fillPick(view)
    local dropdown = view.pickBox

    dropdown:Clear()
    dropdown:AddChoice(phrase("CalPickNone"), "")

    local found = false

    for _, task in ipairs(State.Tasks) do
        if eligible(task) then
            dropdown:AddChoice(task.title, task.id)
            found = found or task.id == view.pick
        end
    end

    if not found then view.pick = nil end

    dropdown:SelectByData(view.pick or "", true)
end

function Calendar.Build(parent)
    local root = vgui.Create("Panel", parent)
    local view = {mode = "month", anchor = monthStart(os.time())}
    local bar = vgui.Create("Panel", root)

    root:Dock(FILL)
    bar:Dock(TOP)
    bar:SetTall(BAR_HEIGHT)
    bar:DockMargin(0, 0, 0, DFW.UI.Space("SM"))

    view.modeButton = vgui.Create("DFW.Button", bar)
    view.modeButton:Dock(RIGHT)
    view.modeButton:SetWide(90)
    view.modeButton:DockMargin(6, 0, 0, 0)
    view.modeButton:SetVariant("default")
    view.modeButton.DoClick = function()
        view.mode = view.mode == "month" and "week" or "month"
        view.anchor = view.mode == "month" and monthStart(view.anchor) or addDays(view.start, 3)
        recompute(view)
    end
    view.to = timeEntry(bar, phrase("CalTo"))
    view.from = timeEntry(bar, phrase("CalFrom"))
    view.pickBox = vgui.Create("DFW.Dropdown", bar)
    view.pickBox:Dock(RIGHT)
    view.pickBox:SetWide(240)
    view.pickBox:DockMargin(6, 0, 0, 0)
    view.pickBox.OnSelect = function()
        local _, data = view.pickBox:GetSelected()

        view.pick = data ~= "" and data or nil
        view.last = nil
        view.dirty = true
        view.grid:InvalidateLayout()
    end

    navButton(bar, "<", 36, function() step(view, -1) end)
    navButton(bar, ">", 36, function() step(view, 1) end)
    navButton(bar, phrase("CalToday"), 80, function()
        view.anchor = monthStart(os.time())
        view.anchor = view.mode == "week" and os.time({year = os.date("*t").year, month = os.date("*t").month, day = os.date("*t").day, hour = NOON}) or view.anchor
        recompute(view)
    end)

    view.title = vgui.Create("DFW.Label", bar)
    view.title:Dock(FILL)
    view.title:SetStyle("bodybold")

    local hint = vgui.Create("DFW.Label", root)

    hint:Dock(TOP)
    hint:SetTall(HINT_HEIGHT)
    hint:SetStyle("tiny")
    hint:SetText(phrase("CalHint"))

    view.grid = vgui.Create("Panel", root)
    view.grid:Dock(FILL)
    view.grid.PerformLayout = function(_, gridW, gridH)
        if view.dirty or view.laidW ~= gridW or view.laidH ~= gridH then
            view.dirty = false
            view.laidW, view.laidH = gridW, gridH
            rebuild(view)
        end
    end

    hookCounter = hookCounter + 1

    local name = "DubzWorkflow_CalendarView" .. hookCounter

    hook.Add("DubzWorkflowState", name, function()
        if not IsValid(root) then return end

        fillPick(view)
        view.dirty = true
        view.grid:InvalidateLayout()
    end)

    root.OnRemove = function() hook.Remove("DubzWorkflowState", name) end

    fillPick(view)
    recompute(view)

    return root
end
