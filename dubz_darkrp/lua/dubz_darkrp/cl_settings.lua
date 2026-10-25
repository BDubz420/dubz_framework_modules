DubzDarkRP.SettingsState = DubzDarkRP.SettingsState or {list = {}, loaded = false}
DubzDarkRP.Pages = DubzDarkRP.Pages or {}

local State = DubzDarkRP.SettingsState
local Info = DubzDarkRP.SettingInfo
local ROW_HEIGHT = 62
local CONTROL_WIDTH = 240
local RESET_WIDTH = 80
local BAR_HEIGHT = 34
local HINT_HEIGHT = 24
local PAD = 14
local hookCounter = 0

local function phrase(key, values)
    return DubzDarkRP.Phrase(key, values)
end

local function send(name, data)
    DFW.Net.Start(name)

    if data then DFW.Net.WriteJSON(data) end

    net.SendToServer()
end

local function fit(text, font, limit)
    if DFW.UI.TextSize(text, font) <= limit then return text end

    while #text > 1 and DFW.UI.TextSize(text .. "…", font) > limit do text = string.sub(text, 1, #text - 1) end

    return text .. "…"
end

local function commit(key, value)
    send("drp_setting", {key = key, value = value})
end

DFW.Net.Receive("drp_settings", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.list = payload.settings or {}
    State.loaded = true
    hook.Run("DubzDarkRPSettings")
end)

DFW.Net.Receive("drp_settingsync", function()
    local payload = DFW.Net.ReadJSON()
    local current = GAMEMODE and GAMEMODE.Config

    if not (istable(payload) and current) then return end

    for _, row in ipairs(payload.values or {}) do
        if current[row.k] ~= nil and type(current[row.k]) == type(row.v) then current[row.k] = row.v end
    end
end)

local function numberControl(holder, entry, range)
    if range then
        local dropdown = vgui.Create("DFW.Dropdown", holder)

        for value = range.min, range.max do dropdown:AddChoice(tostring(value), value) end

        dropdown.OnSelect = function()
            local _, data = dropdown:GetSelected()

            if data ~= nil then commit(entry.k, data) end
        end

        return dropdown, function(row) dropdown:SelectByData(tonumber(row.v), true) end
    end

    return nil
end

local function textControl(holder, entry)
    local box = vgui.Create("DFW.TextEntry", holder)
    local numeric = entry.t == "number"
    local last = tostring(entry.v)

    local function submit()
        local text = string.Trim(box:GetValue())

        if text == last then return end

        if numeric then
            local number = tonumber(text)

            if number then commit(entry.k, number) end
        else
            commit(entry.k, text)
        end
    end

    box.OnEnter = submit
    box.OnFocusChanged = function(_, gained) if not gained then submit() end end

    return box, function(row)
        last = tostring(row.v)

        if not box:HasFocus() then box:SetValue(last) end
    end
end

local function boolControl(holder, entry)
    local toggle = vgui.Create("DFW.Toggle", holder)

    toggle.OnChange = function(_, value) commit(entry.k, value) end

    return toggle, function(row) toggle:SetChecked(row.v == true, true) end
end

local function buildRow(scroll, entry)
    local holder = scroll:Add("Panel")
    local range = entry.t == "number" and Info.ranges[entry.k] or nil
    local control, update

    holder:Dock(TOP)
    holder:SetTall(ROW_HEIGHT)
    holder:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))

    if entry.t == "boolean" then
        control, update = boolControl(holder, entry)
    elseif range then
        control, update = numberControl(holder, entry, range)
    else
        control, update = textControl(holder, entry)
    end

    local reset = vgui.Create("DFW.Button", holder)

    reset:SetLabel(phrase("SettingsReset"))
    reset:SetVariant("ghost")
    reset.DoClick = function() send("drp_setting", {key = entry.k, reset = true}) end

    holder.Paint = function(self, w, h)
        local theme = DFW.UI.GetTheme()
        local limit = w - CONTROL_WIDTH - RESET_WIDTH - PAD * 3

        DFW.Draw.Card(0, 0, w, h, {radius = "MD", color = theme.surface})
        DFW.Draw.Text(entry.k, "BodyBold", PAD, 20, self.Changed and theme.accent or theme.text)
        DFW.Draw.Text(fit(DubzDarkRP.SettingDescription(entry.k), "Small", limit), "Small", PAD, 42, theme.textMuted)
    end

    holder.PerformLayout = function(_, w, h)
        control:SetPos(w - CONTROL_WIDTH - PAD, (h - 32) / 2)
        control:SetSize(CONTROL_WIDTH, 32)
        reset:SetPos(w - CONTROL_WIDTH - RESET_WIDTH - PAD * 2, (h - 30) / 2)
        reset:SetSize(RESET_WIDTH, 30)
    end

    holder.Refresh = function(self, row)
        self.Changed = row.c
        reset:SetVisible(row.c == true)
        update(row)
        reset:SetTooltip(phrase("SettingsDefault", {value = tostring(row.d)}))
    end

    holder:Refresh(entry)

    return holder
end

DubzDarkRP.Pages.settings = {
    Build = function(parent)
        local root = vgui.Create("Panel", parent)
        local bar = vgui.Create("Panel", root)
        local search = vgui.Create("DFW.TextEntry", bar)
        local hint = vgui.Create("DFW.Label", root)
        local scroll = vgui.Create("DFW.ScrollPanel", root)
        local rows = {}
        local filter = ""
        local built = ""

        bar:Dock(TOP)
        bar:SetTall(BAR_HEIGHT)
        bar:DockMargin(0, DFW.UI.Space("SM"), 0, DFW.UI.Space("SM"))
        search:Dock(FILL)
        search:SetPlaceholder(phrase("SettingsSearch"))
        hint:Dock(TOP)
        hint:SetTall(HINT_HEIGHT)
        hint:SetStyle("tiny")
        hint:SetText(phrase("SettingsHint"))
        scroll:Dock(FILL)

        local function populate()
            local keys = {}

            for _, entry in ipairs(State.list) do keys[#keys + 1] = entry.k end

            local signature = #keys .. "|" .. filter

            if signature ~= built then
                built = signature
                rows = {}
                scroll:Clear()

                for _, entry in ipairs(State.list) do
                    if filter == "" or string.find(string.lower(entry.k .. " " .. DubzDarkRP.SettingDescription(entry.k)), filter, 1, true) then
                        rows[entry.k] = buildRow(scroll, entry)
                    end
                end

                if next(rows) == nil then
                    local empty = scroll:Add("DFW.Label")

                    empty:Dock(TOP)
                    empty:SetTall(40)
                    empty:SetStyle("muted")
                    empty:SetAlign(TEXT_ALIGN_CENTER)
                    empty:SetText(phrase("SettingsEmpty"))
                end

                return
            end

            for _, entry in ipairs(State.list) do
                if rows[entry.k] then rows[entry.k]:Refresh(entry) end
            end
        end

        search.OnChange = function()
            filter = string.lower(search:GetValue())
            populate()
        end

        hookCounter = hookCounter + 1

        local name = "DubzDarkRP_SettingsPage" .. hookCounter

        hook.Add("DubzDarkRPSettings", name, function()
            if IsValid(root) then populate() end
        end)

        root.OnRemove = function() hook.Remove("DubzDarkRPSettings", name) end

        send("drp_settings")

        if State.loaded then populate() end

        return root
    end
}
