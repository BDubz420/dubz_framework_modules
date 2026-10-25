DubzDarkRP.Pickers = DubzDarkRP.Pickers or {}

local Pickers = DubzDarkRP.Pickers
local WINDOW_ICON = "darkrp/local_police"
local ROW_HEIGHT = 34
local HEADER_HEIGHT = 38
local SEARCH_HEIGHT = 32
local SEARCH_LIMIT = 150
local ROW_GAP = 2

local function phrase(key, values)
    return DubzDarkRP.Phrase(key, values)
end

local function catalogue()
    local entries, seen = {}, {}

    local function add(class, name, category)
        if not isstring(class) or class == "" or seen[class] then return end

        seen[class] = true
        entries[#entries + 1] = {
            class = class,
            name = (isstring(name) and name ~= "") and name or class,
            category = (isstring(category) and category ~= "") and category or phrase("WeaponsOther")
        }
    end

    for _, swep in ipairs(weapons.GetList()) do add(swep.ClassName, swep.PrintName, swep.Category) end

    for class, data in pairs(list.Get("Weapon")) do add(data.ClassName or class, data.PrintName, data.Category) end

    table.sort(entries, function(a, b) return string.lower(a.name) < string.lower(b.name) end)

    return entries
end

local function grouped(entries)
    local groups, order = {}, {}

    for _, entry in ipairs(entries) do
        if not groups[entry.category] then
            groups[entry.category] = {}
            order[#order + 1] = entry.category
        end

        table.insert(groups[entry.category], entry)
    end

    table.sort(order, function(a, b) return string.lower(a) < string.lower(b) end)

    return groups, order
end

local function paintRow(row, selected, w, h)
    local theme = DFW.UI.GetTheme()
    local picked = selected[row.Entry.class]

    draw.RoundedBox(DFW.UI.Radius("SM"), 0, 0, w, h, picked and theme.accent or (row:IsHovered() and theme.raised or theme.surface))
    DFW.Draw.Text(row.Entry.name, "Body", 12, h / 2, picked and theme.onAccent or theme.text)
    DFW.Draw.Text(row.Entry.class, "Tiny", w - 12, h / 2, picked and theme.onAccent or theme.textDim, TEXT_ALIGN_RIGHT)
end

local function addRow(parent, entry, selected, toggle)
    local row = parent:Add("DButton")

    row:SetText("")
    row:Dock(TOP)
    row:SetTall(ROW_HEIGHT)
    row:DockMargin(0, 0, 0, ROW_GAP)
    row.Entry = entry
    row.Paint = function(self, w, h) paintRow(self, selected, w, h) end
    row.DoClick = function() toggle(entry.class) end

    return row
end

local function selectedIn(entries, selected)
    local count = 0

    for _, entry in ipairs(entries) do
        if selected[entry.class] then count = count + 1 end
    end

    return count
end

local function buildCategory(scroll, name, entries, selected, toggle, expanded)
    local block = scroll:Add("Panel")
    local header = vgui.Create("DButton", block)
    local body = vgui.Create("Panel", block)
    local built = false

    block:Dock(TOP)
    block:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))
    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)
    header:SetText("")
    body:Dock(TOP)
    body:SetTall(0)

    local function open(state)
        expanded[name] = state

        if state and not built then
            built = true

            for _, entry in ipairs(entries) do addRow(body, entry, selected, toggle) end
        end

        body:SetTall(state and #entries * (ROW_HEIGHT + ROW_GAP) or 0)
        block:SetTall(HEADER_HEIGHT + body:GetTall())
        scroll:InvalidateLayout()
    end

    header.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()
        local count = selectedIn(entries, selected)
        local label = name .. "  ·  " .. phrase("WeaponsCount", {count = #entries}) .. (count > 0 and ("  ·  " .. count .. " ✓") or "")

        draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, theme.raised)
        DFW.Draw.Text((expanded[name] and "▾ " or "▸ ") .. label, "BodyBold", 12, h / 2, theme.text)
    end
    header.DoClick = function() open(not expanded[name]) end

    block:SetTall(HEADER_HEIGHT)

    if expanded[name] then open(true) end
end

function Pickers.Weapons(current, onDone, single)
    local frame = Pickers.OpenModal(phrase("WeaponsTitle"), 760, 660, WINDOW_ICON)
    local content = frame:GetContent()
    local bar = Pickers.BottomBar(frame)
    local counter = vgui.Create("DFW.Label", bar)
    local search = vgui.Create("DFW.TextEntry", content)
    local scroll = vgui.Create("DFW.ScrollPanel", content)
    local entries = catalogue()
    local groups, order = grouped(entries)
    local selected, chosen, expanded = {}, {}, {}
    local filter = ""

    search:Dock(TOP)
    search:SetTall(SEARCH_HEIGHT)
    search:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    search:SetPlaceholder(phrase("WeaponsSearch"))
    scroll:Dock(FILL)

    local function updateCounter()
        counter:SetText(phrase("SelectedCount", {count = #chosen}))
    end

    local function toggle(class)
        if single then
            table.Empty(selected)
            table.Empty(chosen)
            selected[class] = true
            chosen[1] = class
        elseif selected[class] then
            selected[class] = nil

            for index, value in ipairs(chosen) do
                if value == class then
                    table.remove(chosen, index)
                    break
                end
            end
        else
            selected[class] = true
            chosen[#chosen + 1] = class
        end

        updateCounter()
    end

    for _, class in ipairs(current or {}) do
        if not selected[class] then
            selected[class] = true
            chosen[#chosen + 1] = class
        end
    end

    local function render()
        scroll:Clear()

        if filter ~= "" then
            local shown = 0

            for _, entry in ipairs(entries) do
                if shown < SEARCH_LIMIT and string.find(string.lower(entry.name .. " " .. entry.class .. " " .. entry.category), filter, 1, true) then
                    addRow(scroll, entry, selected, toggle)
                    shown = shown + 1
                end
            end

            return
        end

        for _, name in ipairs(order) do
            if selectedIn(groups[name], selected) > 0 then expanded[name] = true end
        end

        for _, name in ipairs(order) do buildCategory(scroll, name, groups[name], selected, toggle, expanded) end
    end

    counter:Dock(LEFT)
    counter:SetWide(200)
    counter:SetStyle("small")
    Pickers.BarButton(bar, phrase("AddSelected"), "primary", function()
        onDone(single and (chosen[#chosen] or "") or table.Copy(chosen))
        frame:Close()
    end)
    Pickers.BarButton(bar, phrase("ClearSelection"), "default", function()
        table.Empty(selected)
        table.Empty(chosen)
        updateCounter()
    end)

    search.OnChange = function()
        filter = string.lower(search:GetValue())
        render()
    end

    updateCounter()
    render()
end

function Pickers.Weapon(value, onDone)
    Pickers.Weapons(value ~= "" and {value} or {}, onDone, true)
end
