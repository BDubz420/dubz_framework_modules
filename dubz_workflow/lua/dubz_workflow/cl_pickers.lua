DubzWorkflow.Pickers = DubzWorkflow.Pickers or {}

local Pickers = DubzWorkflow.Pickers
local Dates = DubzWorkflow.Dates
local config = DubzWorkflow.Config
local WINDOW_ICON = "actions/check"
local ARROW_WIDTH = 38
local ARROW_HEIGHT = 26
local DIAL_HEIGHT = 120
local ROW_LABEL = 22
local BUTTON_HEIGHT = 38
local MONTH_ROWS = 6
local COLUMNS = 7
local HEAD_HEIGHT = 24
local CELL_GAP = 3

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local DIAL = {}

function DIAL:Init()
    self.Hour, self.Minute, self.PM, self.Active = 9, 0, false, false

    local function arrow(icon, field, direction)
        local button = vgui.Create("DFW.Button", self)

        button:SetVariant("ghost")
        button:SetIcon(icon)
        button.DoClick = function() self:Step(field, direction) end

        return button
    end

    self.Arrows = {
        hour = {arrow("actions/arrow_drop_up", "hour", 1), arrow("actions/arrow_drop_down", "hour", -1)},
        minute = {arrow("actions/arrow_drop_up", "minute", 1), arrow("actions/arrow_drop_down", "minute", -1)},
        ampm = {arrow("actions/arrow_drop_up", "ampm", 1), arrow("actions/arrow_drop_down", "ampm", -1)}
    }
end

function DIAL:Step(field, direction)
    if field == "hour" then
        self.Hour = (self.Hour - 1 + direction) % 12 + 1
    elseif field == "minute" then
        self.Minute = (self.Minute + direction * math.max(config.TimeMinuteStep, 1)) % 60
    else
        self.PM = not self.PM
    end

    self.Active = true
    self:OnChange(self:GetValue())
end

function DIAL:GetValue()
    if not self.Active then return "" end

    return string.format("%02d:%02d", self.Hour % 12 + (self.PM and 12 or 0), self.Minute)
end

function DIAL:SetValue(value)
    local hour, minute = string.match(tostring(value or ""), "^(%d%d):(%d%d)$")

    if not hour then
        self.Active = false
        return
    end

    hour = tonumber(hour)
    self.Active = true
    self.PM = hour >= 12
    self.Hour = hour % 12 == 0 and 12 or hour % 12
    self.Minute = tonumber(minute)
end

function DIAL:Clear()
    self.Active = false
    self:OnChange("")
end

function DIAL:OnChange() end

function DIAL:Columns()
    local w = self:GetWide()

    return {hour = w * 0.2, minute = w * 0.5, ampm = w * 0.8}
end

function DIAL:PerformLayout(w, h)
    for field, center in pairs(self:Columns()) do
        local pair = self.Arrows[field]

        pair[1]:SetPos(center - ARROW_WIDTH / 2, 0)
        pair[1]:SetSize(ARROW_WIDTH, ARROW_HEIGHT)
        pair[2]:SetPos(center - ARROW_WIDTH / 2, h - ARROW_HEIGHT)
        pair[2]:SetSize(ARROW_WIDTH, ARROW_HEIGHT)
    end
end

function DIAL:OnMouseWheeled(delta)
    local x = self:CursorPos()
    local columns = self:Columns()
    local field = x < (columns.hour + columns.minute) / 2 and "hour" or (x < (columns.minute + columns.ampm) / 2 and "minute" or "ampm")

    self:Step(field, delta > 0 and 1 or -1)

    return true
end

function DIAL:Paint(w, h)
    local theme = DFW.UI.GetTheme()
    local columns = self:Columns()
    local color = self.Active and theme.text or theme.textDim

    draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, theme.surfaceAlt)
    DFW.Draw.Text(self.Active and tostring(self.Hour) or "--", "Title", columns.hour, h / 2, color, TEXT_ALIGN_CENTER)
    DFW.Draw.Text(":", "Title", (columns.hour + columns.minute) / 2, h / 2 - 2, theme.textMuted, TEXT_ALIGN_CENTER)
    DFW.Draw.Text(self.Active and string.format("%02d", self.Minute) or "--", "Title", columns.minute, h / 2, color, TEXT_ALIGN_CENTER)
    DFW.Draw.Text(self.Active and (self.PM and "PM" or "AM") or "--", "Heading", columns.ampm, h / 2, color, TEXT_ALIGN_CENTER)
end

vgui.Register("DubzWorkflow.TimeDial", DIAL, "Panel")

local function dialRow(parent, label, value)
    local caption = vgui.Create("Panel", parent)
    local text = vgui.Create("DFW.Label", caption)
    local clear = vgui.Create("DFW.Button", caption)
    local dial = vgui.Create("DubzWorkflow.TimeDial", parent)

    caption:Dock(TOP)
    caption:SetTall(ROW_LABEL + 6)
    clear:Dock(RIGHT)
    clear:SetWide(90)
    clear:SetLabel(phrase("TimeNotSet"))
    clear:SetVariant("ghost")
    text:Dock(FILL)
    text:SetStyle("small")
    text:SetText(label)
    dial:Dock(TOP)
    dial:SetTall(DIAL_HEIGHT)
    dial:DockMargin(0, 0, 0, DFW.UI.Space("MD"))
    dial:SetValue(value)
    clear.DoClick = function() dial:Clear() end

    return dial
end

function Pickers.Times(from, to, onDone)
    local frame = DFW.UI.CreateFrame(phrase("PickerTimes"), 440, 440, WINDOW_ICON, {module = "workflow"})
    local content = frame:GetContent()
    local bar = vgui.Create("Panel", content)

    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)

    local fromDial = dialRow(content, phrase("TimeFrom"), from)
    local toDial = dialRow(content, phrase("TimeTo"), to)
    local done = vgui.Create("DFW.Button", bar)

    done:Dock(RIGHT)
    done:SetWide(120)
    done:SetLabel(phrase("Done"))
    done:SetVariant("primary")
    done.DoClick = function()
        onDone(fromDial:GetValue(), toDial:GetValue())
        frame:Close()
    end

    local cancel = vgui.Create("DFW.Button", bar)

    cancel:Dock(RIGHT)
    cancel:SetWide(110)
    cancel:DockMargin(0, 0, 6, 0)
    cancel:SetLabel(phrase("Cancel"))
    cancel:SetVariant("ghost")
    cancel.DoClick = function() frame:Close() end
end

local function entryFor(state, date)
    local from, to = state.from ~= "" and state.from or nil, state.to ~= "" and state.to or nil

    return {date = date, from = from, to = to}
end

local function toggle(state, date)
    if not state.multi then
        state.selected = {[date] = {date = date}}
        state.last = date
        return
    end

    if input.IsShiftDown() and state.last then
        local first, last = Dates.Stamp(state.last), Dates.Stamp(date)

        if first > last then first, last = last, first end

        for time = first, last, Dates.DAY do
            local day = Dates.Date(time)

            state.selected[day] = state.selected[day] or entryFor(state, day)
        end
    else
        state.selected[date] = not state.selected[date] and entryFor(state, date) or nil
    end

    state.last = date
end

local function paintCell(state, date, w, h)
    local theme = DFW.UI.GetTheme()
    local chosen = state.selected[date]
    local dim = string.sub(date, 1, 7) ~= state.month

    draw.RoundedBox(DFW.UI.Radius("SM"), 0, 0, w, h, chosen and theme.accent or theme.surfaceAlt)

    if date == Dates.Today() then
        surface.SetDrawColor(theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    DFW.Draw.Text(tostring(tonumber(string.sub(date, 9, 10))), "Body", w / 2, h / 2, chosen and theme.onAccent or (dim and theme.textDim or theme.text), TEXT_ALIGN_CENTER)
end

local function rebuildGrid(state)
    local grid = state.grid
    local w, h = grid:GetSize()

    grid:Clear()

    if w <= 0 or h <= 0 then return end

    local cellWidth = math.floor(w / COLUMNS)
    local cellHeight = math.floor((h - HEAD_HEIGHT) / MONTH_ROWS)

    for column = 0, COLUMNS - 1 do
        local label = vgui.Create("Panel", grid)

        label:SetPos(column * cellWidth, 0)
        label:SetSize(cellWidth, HEAD_HEIGHT)
        label.Paint = function(_, labelW, labelH)
            DFW.Draw.Text(os.date("%a", Dates.AddDays(state.start, column)), "Small", labelW / 2, labelH / 2, DFW.UI.GetTheme().textMuted, TEXT_ALIGN_CENTER)
        end
    end

    for index = 0, COLUMNS * MONTH_ROWS - 1 do
        local date = Dates.Date(Dates.AddDays(state.start, index))
        local cell = vgui.Create("Panel", grid)

        cell:SetPos((index % COLUMNS) * cellWidth, HEAD_HEIGHT + math.floor(index / COLUMNS) * cellHeight)
        cell:SetSize(cellWidth - CELL_GAP, cellHeight - CELL_GAP)
        cell:SetCursor("hand")
        cell.Paint = function(_, cellW, cellH) paintCell(state, date, cellW, cellH) end
        cell.OnMousePressed = function()
            toggle(state, date)
            state.dirty = true
            grid:InvalidateLayout()
        end
    end
end

local function recompute(state)
    state.anchor = Dates.MonthStart(state.anchor)
    state.start = Dates.Monday(state.anchor)
    state.month = string.sub(Dates.Date(state.anchor), 1, 7)
    state.title:SetText(os.date("%B %Y", state.anchor))
    state.dirty = true
    state.grid:InvalidateLayout()
end

local function selectedList(state)
    local list = {}

    for _, entry in pairs(state.selected) do list[#list + 1] = entry end

    table.sort(list, function(a, b) return a.date < b.date end)

    return list
end

local function timesLabel(state)
    local range = Dates.Range(state.from ~= "" and state.from or nil, state.to ~= "" and state.to or nil)

    return phrase("TimesButton") .. ": " .. (range ~= "" and range or phrase("TimesNone"))
end

local function navButton(bar, text, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:Dock(LEFT)
    button:SetWide(36)
    button:DockMargin(0, 0, 6, 0)
    button:SetLabel(text)
    button.DoClick = onClick

    return button
end

function Pickers.Dates(options)
    local state = {multi = options.multi == true, selected = {}, from = options.from or "", to = options.to or ""}
    local first = options.selected

    if state.multi then
        for _, entry in ipairs(first or {}) do state.selected[entry.date] = table.Copy(entry) end
    elseif isstring(first) and string.match(first, "^%d%d%d%d%-%d%d%-%d%d$") then
        state.selected[first] = {date = first}
    end

    local anchorDate = (state.multi and first and first[1] and first[1].date) or (isstring(first) and first ~= "" and first) or Dates.Today()

    state.anchor = Dates.Stamp(string.match(anchorDate, "^%d%d%d%d%-%d%d%-%d%d$") and anchorDate or Dates.Today())

    local frame = DFW.UI.CreateFrame(options.title or phrase("PickerDays"), 560, 620, WINDOW_ICON, {module = "workflow"})
    local content = frame:GetContent()
    local bottom = vgui.Create("Panel", content)
    local top = vgui.Create("Panel", content)

    bottom:Dock(BOTTOM)
    bottom:SetTall(BUTTON_HEIGHT)
    bottom:DockMargin(0, DFW.UI.Space("MD"), 0, 0)
    top:Dock(TOP)
    top:SetTall(34)
    top:DockMargin(0, 0, 0, DFW.UI.Space("SM"))

    local done = vgui.Create("DFW.Button", bottom)

    done:Dock(RIGHT)
    done:SetWide(110)
    done:SetLabel(phrase("Done"))
    done:SetVariant("primary")

    local clear = vgui.Create("DFW.Button", bottom)

    clear:Dock(RIGHT)
    clear:SetWide(100)
    clear:DockMargin(0, 0, 6, 0)
    clear:SetLabel(phrase("ClearAll"))
    clear:SetVariant("ghost")

    state.timesButton = vgui.Create("DFW.Button", bottom)

    if state.multi then
        state.timesButton:Dock(FILL)
        state.timesButton:DockMargin(0, 0, 6, 0)
        state.timesButton:SetLabel(timesLabel(state))
        state.timesButton.DoClick = function()
            Pickers.Times(state.from, state.to, function(from, to)
                state.from, state.to = from, to
                state.timesButton:SetLabel(timesLabel(state))
            end)
        end
    else
        state.timesButton:Remove()
    end

    navButton(top, "<", function()
        state.anchor = Dates.ShiftMonth(state.anchor, -1)
        recompute(state)
    end)
    navButton(top, ">", function()
        state.anchor = Dates.ShiftMonth(state.anchor, 1)
        recompute(state)
    end)

    state.title = vgui.Create("DFW.Label", top)
    state.title:Dock(FILL)
    state.title:SetStyle("bodybold")
    state.grid = vgui.Create("Panel", content)
    state.grid:Dock(FILL)
    state.grid.PerformLayout = function(_, gridW, gridH)
        if state.dirty or state.laidW ~= gridW or state.laidH ~= gridH then
            state.dirty = false
            state.laidW, state.laidH = gridW, gridH
            rebuildGrid(state)
        end
    end

    clear.DoClick = function()
        state.selected = {}
        state.dirty = true
        state.grid:InvalidateLayout()
    end

    done.DoClick = function()
        local list = selectedList(state)

        if state.multi then options.onDone(list) else options.onDone(list[1] and list[1].date or "") end

        frame:Close()
    end

    recompute(state)
end
