local Jobs = DubzF4.Jobs
local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local ROW_HEIGHT = 60
local ICON_SIZE = 44
local HEADER_HEIGHT = 26
local TINT_ALPHA = 28
local LINE_ALPHA = 150

local function findEntry(categories, id)
    for _, entries in pairs(categories) do
        for _, entry in ipairs(entries) do
            if entry.id == id then return entry end
        end
    end
end

local function addHeader(list, category)
    local label = Ui.Label(list, string.upper(category), "tiny")

    label:Dock(TOP)
    label:SetTall(HEADER_HEIGHT)
    label:DockMargin(0, DFW.UI.Space("SM"), 0, 0)
end

local function paintRow(row, entry, selected, w, h)
    local theme = DFW.UI.GetTheme()
    local job = entry.job
    local ok, reason, current = Jobs.State(entry)
    local count, max = team.NumPlayers(entry.id), Jobs.Max(job)

    row.hover = DFW.Anim.Lerp(row, "hover", row:IsHovered() and 1 or 0, 14)
    row.picked = DFW.Anim.Lerp(row, "picked", selected() == entry and 1 or 0, 12)
    draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, DFW.Anim.Color(theme.surface, theme.raised, math.max(row.hover * 0.6, row.picked)))
    local tint = job.color or theme.accent

    if row.picked > 0.02 then
        draw.RoundedBox(DFW.UI.Radius("MD"), 0, 0, w, h, DFW.UI.WithAlpha(tint, TINT_ALPHA * row.picked))
        surface.SetDrawColor(DFW.UI.WithAlpha(tint, LINE_ALPHA * row.picked))
        surface.DrawRect(DFW.UI.Space("MD"), h - 2, w - DFW.UI.Space("MD") * 2, 1)
    end

    local textX = ICON_SIZE + 24

    DFW.Draw.Text(job.name or "?", "BodyBold", textX, h / 2 - 9, ok and theme.text or theme.textMuted)
    DFW.Draw.Text(DubzF4.Phrase("Salary") .. " " .. Adapter.FormatMoney(job.salary or 0), "Small", textX, h / 2 + 10, theme.textDim)

    local right = current and theme.success or ((not ok) and theme.danger or theme.textMuted)

    if current or not ok then DFW.Draw.Text(reason, "Small", w - 14, h / 2 - 9, right, TEXT_ALIGN_RIGHT) end

    DFW.Draw.Text(count .. " / " .. (max > 0 and max or "-"), "Small", w - 14, h / 2 + 10, theme.textMuted, TEXT_ALIGN_RIGHT)
end

local function addRow(list, entry, selected, choose)
    local row = list:Add("DButton")
    local icon = vgui.Create("SpawnIcon", row)

    row:SetText("")
    row:Dock(TOP)
    row:SetTall(ROW_HEIGHT)
    row:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("XS"))
    icon:SetPos(14, (ROW_HEIGHT - ICON_SIZE) / 2)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetModel(Adapter.JobModel(entry.job))
    icon:SetMouseInputEnabled(false)

    row.DoClick = function() choose(entry) end
    row.Paint = function(self, w, h) paintRow(self, entry, selected, w, h) end
end

function Jobs.BuildList(parent, selected, choose)
    local filter = ""
    local list
    local populate

    populate = function()
        list:Clear()

        local categories, order = Jobs.Entries(filter)
        local first

        for _, category in ipairs(order) do
            addHeader(list, category)

            for _, entry in ipairs(categories[category]) do
                first = first or entry
                addRow(list, entry, selected, choose)
            end
        end

        local current = selected()
        local kept = current and findEntry(categories, current.id)
        local pick = kept or findEntry(categories, LocalPlayer():Team()) or first

        if pick then choose(pick) end
    end

    local search = Ui.Search(parent, DubzF4.Phrase("SearchJobs"), function(text)
        filter = text
        populate()
    end)

    search:Dock(TOP)
    search:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    list = Ui.Scroll(parent)
    list:Dock(FILL)
    populate()
end
