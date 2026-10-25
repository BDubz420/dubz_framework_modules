DubzDarkRP.Pickers = DubzDarkRP.Pickers or {}

local Pickers = DubzDarkRP.Pickers
local WINDOW_ICON = "economy/inventory_2"
local ICON_SIZE = 80
local ICON_GAP = 6
local COLUMNS = 9
local BATCH = 18
local HEADER_HEIGHT = 38
local SEARCH_HEIGHT = 32
local SEARCH_LIMIT = 108
local PRESET_HEIGHT = 60
local PRESET_ICON = 48
local PATH_HEIGHT = 32
local fillCounter = 0

local function phrase(key, values)
    return DubzDarkRP.Phrase(key, values)
end

local function categories()
    local tree = spawnmenu and spawnmenu.GetPropTable and spawnmenu.GetPropTable() or {}
    local list = {}

    for _, node in pairs(tree) do
        if istable(node) and istable(node.contents) then
            local models = {}

            for _, item in ipairs(node.contents) do
                if istable(item) and item.type == "model" and isstring(item.model) then models[#models + 1] = string.lower(item.model) end
            end

            if #models > 0 then list[#list + 1] = {name = tostring(node.name or "Props"), models = models} end
        end
    end

    table.sort(list, function(a, b) return string.lower(a.name) < string.lower(b.name) end)

    return list
end

local function rowsFor(count)
    return math.ceil(count / COLUMNS) * (ICON_SIZE + ICON_GAP)
end

local function fillIcons(layout, models, selection, pick)
    local index = 1

    fillCounter = fillCounter + 1

    local name = "DubzDarkRP_PropFill" .. fillCounter

    timer.Create(name, 0, 0, function()
        if not IsValid(layout) then
            timer.Remove(name)
            return
        end

        for _ = 1, BATCH do
            local path = models[index]

            if not path then
                timer.Remove(name)
                return
            end

            index = index + 1

            local icon = layout:Add("SpawnIcon")

            icon:SetModel(path)
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon.ModelPath = path
            icon.DoClick = function() pick(path) end
            icon.PaintOver = function(self, w, h)
                if selection.path ~= self.ModelPath then return end

                local theme = DFW.UI.GetTheme()

                surface.SetDrawColor(theme.accent)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end
    end)
end

local function iconLayout(parent, count)
    local layout = parent:Add("DIconLayout")

    layout:Dock(TOP)
    layout:SetSpaceX(ICON_GAP)
    layout:SetSpaceY(ICON_GAP)
    layout:SetTall(rowsFor(count))

    return layout
end

local function buildCategory(scroll, entry, selection, pick, expanded)
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
        expanded[entry.name] = state

        if state and not built then
            built = true
            fillIcons(iconLayout(body, #entry.models), entry.models, selection, pick)
        end

        body:SetTall(state and rowsFor(#entry.models) or 0)
        block:SetTall(HEADER_HEIGHT + body:GetTall())
        scroll:InvalidateLayout()
    end

    header.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()
        local label = entry.name .. "  ·  " .. phrase("ModelCount", {count = #entry.models})

        draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, theme.raised)
        DFW.Draw.Text((expanded[entry.name] and "▾ " or "▸ ") .. label, "BodyBold", 12, h / 2, theme.text)
    end
    header.DoClick = function() open(not expanded[entry.name]) end

    block:SetTall(HEADER_HEIGHT)
end

local function pathBar(frame, selection, onDone)
    local bar = Pickers.BottomBar(frame)
    local entry

    Pickers.BarButton(bar, phrase("UseModel"), "primary", function()
        onDone(string.Trim(entry:GetValue()))
        frame:Close()
    end)

    entry = vgui.Create("DFW.TextEntry", bar)
    entry:Dock(FILL)
    entry:SetTall(PATH_HEIGHT)
    entry:SetPlaceholder(phrase("AmmoModelCustom"))
    entry:SetUpdateOnType(true)
    entry:SetValue(selection.path or "")
    entry.OnChange = function() selection.path = string.Trim(entry:GetValue()) end

    return function(path)
        selection.path = path
        entry:SetValue(path)
    end
end

function Pickers.Props(current, onDone)
    local frame = Pickers.OpenModal(phrase("PropsTitle"), 860, 700, WINDOW_ICON)
    local selection = {path = current ~= "" and string.lower(current) or nil}
    local setPath = pathBar(frame, selection, onDone)
    local content = frame:GetContent()
    local search = vgui.Create("DFW.TextEntry", content)
    local scroll = vgui.Create("DFW.ScrollPanel", content)
    local all = categories()
    local expanded = {}
    local filter = ""

    search:Dock(TOP)
    search:SetTall(SEARCH_HEIGHT)
    search:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    search:SetPlaceholder(phrase("PropsSearch"))
    scroll:Dock(FILL)

    local function render()
        scroll:Clear()

        if filter ~= "" then
            local matches = {}

            for _, entry in ipairs(all) do
                for _, path in ipairs(entry.models) do
                    if #matches < SEARCH_LIMIT and string.find(path, filter, 1, true) then matches[#matches + 1] = path end
                end
            end

            if #matches == 0 then
                local empty = scroll:Add("DFW.Label")

                empty:Dock(TOP)
                empty:SetTall(40)
                empty:SetStyle("muted")
                empty:SetAlign(TEXT_ALIGN_CENTER)
                empty:SetText(phrase("PropsEmpty"))

                return
            end

            fillIcons(iconLayout(scroll, #matches), matches, selection, setPath)

            return
        end

        for _, entry in ipairs(all) do buildCategory(scroll, entry, selection, setPath, expanded) end
    end

    search.OnChange = function()
        filter = string.lower(search:GetValue())
        render()
    end

    render()
end

function Pickers.AmmoModels(current, onDone)
    local frame = Pickers.OpenModal(phrase("AmmoModelsTitle"), 560, 560, WINDOW_ICON)
    local selection = {path = current ~= "" and current or nil}
    local setPath = pathBar(frame, selection, onDone)
    local scroll = vgui.Create("DFW.ScrollPanel", frame:GetContent())

    scroll:Dock(FILL)

    for _, preset in ipairs(DubzDarkRP.AmmoModels()) do
        local row = scroll:Add("DButton")
        local icon = vgui.Create("SpawnIcon", row)

        row:SetText("")
        row:Dock(TOP)
        row:SetTall(PRESET_HEIGHT)
        row:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))
        icon:SetPos(8, (PRESET_HEIGHT - PRESET_ICON) / 2)
        icon:SetSize(PRESET_ICON, PRESET_ICON)
        icon:SetModel(preset.model)
        icon:SetMouseInputEnabled(false)
        row.Paint = function(self, w, h)
            local theme = DFW.UI.GetTheme()
            local picked = selection.path == preset.model

            draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, picked and theme.accent or (self:IsHovered() and theme.raised or theme.surface))
            DFW.Draw.Text(preset.name, "BodyBold", PRESET_ICON + 24, h / 2 - 9, picked and theme.onAccent or theme.text)
            DFW.Draw.Text(preset.model, "Tiny", PRESET_ICON + 24, h / 2 + 11, picked and theme.onAccent or theme.textDim)
        end
        row.DoClick = function() setPath(preset.model) end
    end
end
