DubzDarkRP.Form = DubzDarkRP.Form or {}

local Form = DubzDarkRP.Form
local Fields = DubzDarkRP.Fields
local Pickers = DubzDarkRP.Pickers
local ROW_HEIGHT = 58
local TOGGLE_HEIGHT = 34
local BUTTON_HEIGHT = 38
local LABEL_HEIGHT = 18
local SLIDER_LIMIT = 500
local HEADER_HEIGHT = 40
local PICKER_WIDTH = 150
local PICKER_HEIGHT = 24
local PICKER_ROW = 28
local BUTTON_GAP = 4
local MESSAGE_HEIGHT = 22

local function row(parent, height)
    local holder = parent:Add("Panel")

    holder:Dock(TOP)
    holder:SetTall(height)
    holder:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))

    return holder
end

local function caption(holder, text, height)
    local label = vgui.Create("DFW.Label", holder)

    label:SetText(text)
    label:SetStyle("small")
    label:Dock(TOP)
    label:SetTall(height or LABEL_HEIGHT)
end

local function textControl(holder, changed)
    local entry = vgui.Create("DFW.TextEntry", holder)

    entry:Dock(TOP)
    entry:SetTall(32)
    entry.OnChange = function() changed() end

    return {
        Read = function() return entry:GetValue() end,
        Write = function(value) entry:SetValue(tostring(value)) end,
        Lock = function(locked) entry:SetEnabled(not locked) end
    }
end

local function choiceControl(holder, spec, changed)
    local dropdown = vgui.Create("DFW.Dropdown", holder)

    dropdown:Dock(TOP)
    dropdown:SetTall(32)
    dropdown.OnSelect = function() changed() end

    for _, choice in ipairs(spec.choices) do dropdown:AddChoice(choice, choice) end

    return {
        Read = function()
            local _, data = dropdown:GetSelected()

            return data
        end,
        Write = function(value) dropdown:SelectByData(value, true) end,
        Lock = function(locked) dropdown:SetEnabled(not locked) end
    }
end

local function numberControl(holder, spec, changed)
    if spec.max > SLIDER_LIMIT then return textControl(holder, changed) end

    local slider = vgui.Create("DFW.Slider", holder)

    slider:Dock(TOP)
    slider:SetTall(32)
    slider:SetRange(spec.min, spec.max)
    slider:SetDecimals(spec.decimals)
    slider.OnValueChanged = function() changed() end

    return {Read = function() return slider:GetValue() end, Write = function(value) slider:SetValue(value, true) end}
end

local function colorControl(holder, changed)
    local button = vgui.Create("DFW.ColorButton", holder)

    button:Dock(TOP)
    button:SetTall(32)
    button.OnValueChanged = function() changed() end

    return {
        Read = function()
            local color = button:GetColor()

            return {r = color.r, g = color.g, b = color.b, a = color.a}
        end,
        Write = function(value) button:SetColor(Color(value.r, value.g, value.b, value.a)) end
    }
end

local LIST_PICKERS = {
    jobs = {label = "PickerJobs", icon = "darkrp/work", open = function(items, apply) Pickers.Jobs(items, apply) end},
    playermodels = {label = "PickerModels", icon = "players/person", open = function(items, apply) Pickers.Models(items, apply) end},
    weapons = {label = "PickerWeapons", icon = "darkrp/local_police", open = function(items, apply) Pickers.Weapons(items, apply) end}
}

local TEXT_PICKERS = {
    weapon = {label = "PickerWeapons", icon = "darkrp/local_police", open = function(value, apply) Pickers.Weapon(value, apply) end},
    props = {label = "PickerProps", icon = "economy/inventory_2", open = function(value, apply) Pickers.Props(value, apply) end},
    ammomodels = {label = "PickerAmmoModels", icon = "economy/inventory_2", open = function(value, apply) Pickers.AmmoModels(value, apply) end}
}

local function pickerTextControl(holder, definition, changed)
    local bar = vgui.Create("Panel", holder)
    local button = vgui.Create("DFW.Button", bar)
    local entry = vgui.Create("DFW.TextEntry", bar)

    bar:Dock(TOP)
    bar:SetTall(32)
    button:Dock(RIGHT)
    button:SetWide(PICKER_WIDTH)
    button:DockMargin(DFW.UI.Space("SM"), 0, 0, 0)
    button:SetLabel(DubzDarkRP.Phrase(definition.label))
    button:SetIcon(definition.icon)
    entry:Dock(FILL)
    entry.OnChange = function() changed() end
    button.DoClick = function()
        definition.open(entry:GetValue(), function(value)
            entry:SetValue(value)
            changed()
        end)
    end

    return {
        Read = function() return entry:GetValue() end,
        Write = function(value) entry:SetValue(tostring(value)) end,
        Lock = function(locked)
            entry:SetEnabled(not locked)
            button:SetEnabled(not locked)
        end
    }
end

local function addPicker(holder, tags, spec, changed)
    local button = vgui.Create("DFW.Button", holder)
    local definition = LIST_PICKERS[spec.picker]

    button:SetSize(PICKER_WIDTH, PICKER_HEIGHT)
    button:SetLabel(DubzDarkRP.Phrase(definition.label))
    button:SetIcon(definition.icon)
    button.DoClick = function()
        definition.open(tags:GetItems(), function(items)
            tags:SetItems(items)
            changed()
        end)
    end

    holder.PerformLayout = function(_, w) button:SetPos(w - PICKER_WIDTH, (PICKER_ROW - PICKER_HEIGHT) / 2) end
end

local function listControl(holder, spec, changed)
    local tags = vgui.Create("DubzDarkRP.Tags", holder)

    tags:Dock(TOP)
    tags:SetPlaceholder(DubzDarkRP.Phrase("TagPlaceholder"))
    local head = spec.picker and PICKER_ROW or LABEL_HEIGHT

    tags.OnHeightChanged = function(height) holder:SetTall(head + height + DFW.UI.Space("SM")) end
    tags.OnItemsChanged = function() changed() end

    if spec.picker then addPicker(holder, tags, spec, changed) end

    return {Read = function() return tags:GetItems() end, Write = function(value) tags:SetItems(value) end}
end

local function boolControl(parent, kind, spec, changed)
    local holder = row(parent, TOGGLE_HEIGHT)
    local toggle = vgui.Create("DFW.Toggle", holder)

    toggle:Dock(FILL)
    toggle:SetLabel(DubzDarkRP.Phrase(Fields.LabelKey(kind, spec.key)))
    toggle.OnChange = function() changed() end

    return {Read = function() return toggle:GetChecked() end, Write = function(value) toggle:SetChecked(value == true, true) end}
end

local function fieldControl(parent, kind, spec, changed)
    if spec.type == "bool" then return boolControl(parent, kind, spec, changed) end

    local holder = row(parent, ROW_HEIGHT)

    local listLike = spec.type == "list" or spec.type == "jobs"

    caption(holder, DubzDarkRP.Phrase(Fields.LabelKey(kind, spec.key)), (listLike and spec.picker) and PICKER_ROW or nil)

    if spec.type == "choice" then return choiceControl(holder, spec, changed) end
    if spec.type == "number" then return numberControl(holder, spec, changed) end
    if spec.type == "color" then return colorControl(holder, changed) end
    if spec.type == "list" or spec.type == "jobs" then return listControl(holder, spec, changed) end

    if spec.type == "string" and TEXT_PICKERS[spec.picker] then return pickerTextControl(holder, TEXT_PICKERS[spec.picker], changed) end

    return textControl(holder, changed)
end

local function actionButton(bar, text, variant, onClick)
    local button = vgui.Create("DFW.Button", bar)

    button:SetLabel(text)
    button:SetVariant(variant)
    button.DoClick = onClick

    return button
end

local function spreadButtons(bar)
    bar.PerformLayout = function(self, w, h)
        local children = self:GetChildren()
        local count = #children

        if count == 0 then return end

        local each = math.floor((w - BUTTON_GAP * (count - 1)) / count)

        for index, child in ipairs(children) do
            child:SetPos((index - 1) * (each + BUTTON_GAP), 0)
            child:SetSize(each, h)
        end
    end
end

local function buildHeader(card, actions)
    local header = vgui.Create("Panel", card)
    local close = vgui.Create("DFW.Button", header)
    local title = vgui.Create("DFW.Label", header)

    header:Dock(TOP)
    header:SetTall(HEADER_HEIGHT)
    close:Dock(RIGHT)
    close:SetWide(70)
    close:SetLabel(DubzDarkRP.Phrase("Close"))
    close:SetVariant("ghost")
    close.DoClick = actions.Close
    title:Dock(FILL)
    title:SetStyle("heading")

    return title
end

function Form.Build(parent, kind, actions)
    local card = vgui.Create("DFW.Card", parent)
    local pad = DFW.UI.Space("LG")
    local title = buildHeader(card, actions)
    local bar = vgui.Create("Panel", card)
    local message = vgui.Create("DFW.Label", card)
    local scroll = vgui.Create("DFW.ScrollPanel", card)
    local controls = {}
    local state = {id = nil, loading = false}

    local function changed()
        if not state.loading then actions.Dirty() end
    end

    card:DockPadding(pad, pad, pad, pad)
    bar:Dock(BOTTOM)
    bar:SetTall(BUTTON_HEIGHT)
    bar:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
    spreadButtons(bar)
    message:Dock(BOTTOM)
    message:SetTall(MESSAGE_HEIGHT)
    message:SetStyle("small")
    scroll:Dock(FILL)

    for _, spec in ipairs(Fields.Specs(kind)) do controls[spec.key] = fieldControl(scroll, kind, spec, changed) end

    local function readRaw()
        local raw = {}

        for key, control in pairs(controls) do raw[key] = control.Read() end

        return raw
    end

    local function save() actions.Save(state.id, readRaw()) end

    actionButton(bar, DubzDarkRP.Phrase("Save"), "primary", save)
    actionButton(bar, DubzDarkRP.Phrase("Duplicate"), "default", function() actions.Duplicate(readRaw()) end)
    actionButton(bar, DubzDarkRP.Phrase("Restore"), "default", function() if state.id then actions.Restore(state.id) end end)
    actionButton(bar, DubzDarkRP.Phrase("Remove"), "danger", function() if state.id then actions.Remove(state.id) end end)

    return {
        Panel = card,
        Save = save,
        Id = function() return state.id end,
        SetMessage = function(text, ok)
            message:SetText(text or "")
            message:SetColor(ok and DFW.UI.GetTheme().success or DFW.UI.GetTheme().danger)
        end,
        Load = function(id, data)
            data = data or Fields.DefaultsOf(kind)
            state.loading = true
            state.id = id
            title:SetText(id and tostring(data.name) or DubzDarkRP.Phrase("DrawerNew"))

            for key, control in pairs(controls) do control.Write(data[key]) end

            for _, spec in ipairs(Fields.Specs(kind)) do
                local control = controls[spec.key]

                if spec.immutable and control.Lock then control.Lock(id ~= nil) end
            end

            state.loading = false
        end
    }
end
