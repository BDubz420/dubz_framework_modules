DubzDarkRP.Pages = DubzDarkRP.Pages or {}

local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local KINDS = {"jobs", "shipments", "entities", "ammo", "doorgroups"}
local BAR_HEIGHT = 34
local HINT_HEIGHT = 24
local HEADER_HEIGHT = 34
local ROW_HEIGHT = 56
local TOGGLE_WIDTH = 60
local PAD = 14
local hookCounter = 0

local function phrase(key, values)
    return DubzDarkRP.Phrase(key, values)
end

local function send(action, kind, id)
    DFW.Net.Start("drp_edit")
    DFW.Net.WriteJSON({action = action, kind = kind, id = id})
    net.SendToServer()
end

local function header(scroll, kind)
    local label = scroll:Add("DFW.Label")

    label:Dock(TOP)
    label:SetTall(HEADER_HEIGHT)
    label:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
    label:SetStyle("heading")
    label:SetText(phrase("DefaultsGroup", {kind = phrase(Kinds.Meta[kind].label)}))
end

local function buildRow(scroll, kind, row)
    local holder = scroll:Add("Panel")
    local toggle = vgui.Create("DFW.Toggle", holder)
    local data = Fields.Extract(row.entry, kind)
    local engine = Kinds.Engine(kind)

    holder:Dock(TOP)
    holder:SetTall(ROW_HEIGHT)
    holder:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("SM"))
    holder.Paint = function(_, w, h)
        local theme = DFW.UI.GetTheme()
        local enabled = toggle:GetChecked()

        DFW.Draw.Card(0, 0, w, h, {radius = "MD", color = theme.surface})
        DFW.Draw.Text(data.name or row.id, "BodyBold", PAD, 20, enabled and theme.text or theme.textMuted)
        DFW.Draw.Text(row.id, "Small", PAD, 40, theme.textDim)
    end
    holder.PerformLayout = function(_, w, h)
        toggle:SetPos(w - TOGGLE_WIDTH - PAD, (h - 28) / 2)
        toggle:SetSize(TOGGLE_WIDTH, 28)
    end

    toggle.OnChange = function(_, value) send(value and "restore" or "remove", kind, row.id) end
    holder.Sync = function() toggle:SetChecked(engine.Status(row.id) ~= "removed", true) end
    holder:Sync()

    return holder
end

DubzDarkRP.Pages.defaults = {
    Build = function(parent)
        local root = vgui.Create("Panel", parent)
        local bar = vgui.Create("Panel", root)
        local search = vgui.Create("DFW.TextEntry", bar)
        local hint = vgui.Create("DFW.Label", root)
        local scroll = vgui.Create("DFW.ScrollPanel", root)
        local rows = {}
        local filter = ""

        bar:Dock(TOP)
        bar:SetTall(BAR_HEIGHT)
        bar:DockMargin(0, DFW.UI.Space("SM"), 0, DFW.UI.Space("SM"))
        search:Dock(FILL)
        search:SetPlaceholder(phrase("DefaultsSearch"))
        hint:Dock(TOP)
        hint:SetTall(HINT_HEIGHT)
        hint:SetStyle("tiny")
        hint:SetText(phrase("DefaultsHint"))
        scroll:Dock(FILL)

        local function populate()
            local shown = 0

            rows = {}
            scroll:Clear()

            for _, kind in ipairs(KINDS) do
                local engine = Kinds.Engine(kind)
                local matches = {}

                for _, row in ipairs(engine.List()) do
                    local name = string.lower(Fields.Extract(row.entry, kind).name or row.id)

                    if engine.Original(row.id) and (filter == "" or string.find(name .. " " .. row.id, filter, 1, true)) then
                        matches[#matches + 1] = row
                    end
                end

                if #matches > 0 then
                    header(scroll, kind)

                    for _, row in ipairs(matches) do
                        rows[#rows + 1] = buildRow(scroll, kind, row)
                        shown = shown + 1
                    end
                end
            end

            if shown == 0 then
                local empty = scroll:Add("DFW.Label")

                empty:Dock(TOP)
                empty:SetTall(40)
                empty:SetStyle("muted")
                empty:SetAlign(TEXT_ALIGN_CENTER)
                empty:SetText(phrase("DefaultsEmpty"))
            end
        end

        local function syncRows()
            for _, row in ipairs(rows) do row:Sync() end
        end

        search.OnChange = function()
            filter = string.lower(search:GetValue())
            populate()
        end

        hookCounter = hookCounter + 1

        local name = "DubzDarkRP_DefaultsPage" .. hookCounter

        hook.Add("DubzDarkRPChanged", name, function()
            if IsValid(root) then syncRows() end
        end)
        hook.Add("DubzDarkRPResult", name, function()
            if IsValid(root) then syncRows() end
        end)

        root.OnRemove = function()
            hook.Remove("DubzDarkRPChanged", name)
            hook.Remove("DubzDarkRPResult", name)
        end

        populate()

        return root
    end
}
