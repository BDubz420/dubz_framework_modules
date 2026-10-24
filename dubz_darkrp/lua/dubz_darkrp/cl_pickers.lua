DubzDarkRP.Pickers = DubzDarkRP.Pickers or {}

local Pickers = DubzDarkRP.Pickers
local Kinds = DubzDarkRP.Kinds
local MODEL_ICON = 92
local MODEL_BATCH = 16
local MODEL_GAP = 6
local MODEL_COLUMNS = 9
local WINDOW_ICON = "players/person"
local BAR_HEIGHT = 38

local modelFrame, jobFrame
local DIM_ALPHA = 190

local function openModal(title, width, height, icon)
    local dim = vgui.Create("DPanel")

    dim:SetSize(ScrW(), ScrH())
    dim:MakePopup()
    dim.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, DIM_ALPHA)
        surface.DrawRect(0, 0, w, h)
    end

    local frame = DFW.UI.CreateFrame(title, width, height, icon, {module = "drp_core"})

    frame.OnRemove = function()
        if IsValid(dim) then dim:Remove() end
    end

    return frame
end

local function bottomBar(frame)
    local bar = vgui.Create("Panel", frame:GetContent())

    bar:Dock(BOTTOM)
    bar:SetTall(BAR_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("SM"), 0, 0)

    return bar
end

local function barButton(bar, text, variant, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:SetLabel(text)
    button:SetVariant(variant)
    button:Dock(RIGHT)
    button:SetWide(150)
    button:DockMargin(DFW.UI.Space("SM"), 0, 0, 0)
    button.DoClick = onClick

    return button
end

local function allModels()
    local list = {}

    for _, path in pairs(player_manager.AllValidModels()) do list[#list + 1] = path end

    table.sort(list)

    return list
end

local function paintSelection(icon, selected)
    if not selected[icon.ModelPath] then return end

    local theme = DFW.UI.GetTheme()
    local w, h = icon:GetSize()

    surface.SetDrawColor(theme.accent)
    surface.DrawOutlinedRect(0, 0, w, h, 3)
    draw.RoundedBox(8, w - 24, 4, 20, 20, theme.accent)
    DFW.Draw.Text("+", "BodyBold", w - 14, 14, theme.onAccent, TEXT_ALIGN_CENTER)
end

local function fillModels(layout, queue, selected, onToggle)
    local index = 0

    layout.Think = function(self)
        for _ = 1, MODEL_BATCH do
            index = index + 1

            local path = queue[index]

            if not path then
                self.Think = nil
                return
            end

            local icon = self:Add("SpawnIcon")

            icon:SetSize(MODEL_ICON, MODEL_ICON)
            icon:SetModel(path)
            icon:SetTooltip(path)
            icon.ModelPath = path
            icon.DoClick = function() onToggle(path) end
            icon.PaintOver = function(panel) paintSelection(panel, selected) end
        end
    end
end

function Pickers.Models(current, onPick)
    if IsValid(modelFrame) then modelFrame:Remove() end

    local models = allModels()
    local selected, count = {}, 0
    local frame = openModal(DubzDarkRP.Phrase("ModelsTitle"), 980, 700, WINDOW_ICON)
    local content = frame:GetContent()
    local bar = bottomBar(frame)
    local counter

    modelFrame = frame

    for _, path in ipairs(current) do
        if not selected[path] then
            selected[path] = true
            count = count + 1
        end
    end

    local function toggle(path)
        selected[path] = not selected[path] or nil
        count = count + (selected[path] and 1 or -1)
        counter:SetText(DubzDarkRP.Phrase("SelectedCount", {count = count}))
    end

    local function chosen()
        local list, seen = {}, {}

        for _, path in ipairs(current) do
            if selected[path] and not seen[path] then
                list[#list + 1] = path
                seen[path] = true
            end
        end

        for _, path in ipairs(models) do
            if selected[path] and not seen[path] then list[#list + 1] = path end
        end

        return list
    end

    barButton(bar, DubzDarkRP.Phrase("AddSelected"), "primary", function()
        onPick(chosen())
        frame:Close()
    end)
    barButton(bar, DubzDarkRP.Phrase("ClearSelection"), "default", function()
        selected, count = {}, 0
        counter:SetText(DubzDarkRP.Phrase("SelectedCount", {count = 0}))
    end)

    counter = vgui.Create("DFW.Label", bar)
    counter:Dock(FILL)
    counter:SetText(DubzDarkRP.Phrase("SelectedCount", {count = count}))
    counter:SetStyle("small")

    local search = vgui.Create("DFW.TextEntry", content)
    local scroll = vgui.Create("DFW.ScrollPanel", content)

    search:Dock(TOP)
    search:SetTall(32)
    search:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    search:SetPlaceholder(DubzDarkRP.Phrase("ModelsSearch"))
    scroll:Dock(FILL)

    local function populate(filter)
        scroll:Clear()

        local layout = scroll:Add("DIconLayout")
        local queue = {}

        layout:Dock(TOP)
        layout:SetSpaceX(MODEL_GAP)
        layout:SetSpaceY(MODEL_GAP)

        for _, path in ipairs(models) do
            if filter == "" or string.find(string.lower(path), filter, 1, true) then queue[#queue + 1] = path end
        end

        table.sort(queue, function(a, b)
            if (selected[a] == true) ~= (selected[b] == true) then return selected[a] == true end

            return a < b
        end)

        layout:SetTall(math.ceil(#queue / MODEL_COLUMNS) * (MODEL_ICON + MODEL_GAP))
        fillModels(layout, queue, selected, toggle)
    end

    search.OnChange = function(entry) populate(string.lower(entry:GetValue())) end
    populate("")
end

local function jobRows()
    local rows = {}

    for _, row in ipairs(Kinds.Engine("jobs").List()) do
        if not row.entry.dubzDisabled then rows[#rows + 1] = row end
    end

    table.sort(rows, function(a, b) return string.lower(a.entry.name or "") < string.lower(b.entry.name or "") end)

    return rows
end

local function paintJobRow(row, selected, w, h)
    local theme = DFW.UI.GetTheme()
    local picked = selected[row.id]

    draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, picked and theme.raised or theme.surface)
    surface.SetDrawColor(row.entry.color or theme.accent)
    surface.DrawRect(0, 6, 4, h - 12)
    DFW.Draw.Text(row.entry.name or row.id, "BodyBold", 16, h / 2 - 8, theme.text)
    DFW.Draw.Text(row.id, "Small", 16, h / 2 + 10, theme.textMuted)

    if picked then
        draw.RoundedBox(8, w - 32, h / 2 - 10, 20, 20, theme.accent)
        DFW.Draw.Text("+", "BodyBold", w - 22, h / 2, theme.onAccent, TEXT_ALIGN_CENTER)
    end
end

function Pickers.Jobs(current, onApply)
    if IsValid(jobFrame) then jobFrame:Remove() end

    local frame = openModal(DubzDarkRP.Phrase("JobsTitle"), 520, 600, "darkrp/work")
    local bar = bottomBar(frame)
    local selected = {}
    local rows = jobRows()

    jobFrame = frame

    for _, id in ipairs(current) do selected[id] = true end

    barButton(bar, DubzDarkRP.Phrase("Apply"), "primary", function()
        local ids = {}

        for _, row in ipairs(rows) do
            if selected[row.id] then ids[#ids + 1] = row.id end
        end

        onApply(ids)
        frame:Close()
    end)
    barButton(bar, DubzDarkRP.Phrase("ClearSelection"), "default", function()
        for id in pairs(selected) do selected[id] = nil end
    end)

    local scroll = vgui.Create("DFW.ScrollPanel", frame:GetContent())

    scroll:Dock(FILL)

    for _, row in ipairs(rows) do
        local button = scroll:Add("DButton")

        button:SetText("")
        button:Dock(TOP)
        button:SetTall(52)
        button:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("XS"))
        button.DoClick = function() selected[row.id] = not selected[row.id] or nil end
        button.Paint = function(_, w, h) paintJobRow(row, selected, w, h) end
    end
end
