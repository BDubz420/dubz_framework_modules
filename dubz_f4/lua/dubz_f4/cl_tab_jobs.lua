local Jobs = DubzF4.Jobs
local Ui = DubzF4.Ui
local config = DubzF4.Config

local function build(page)
    if not DubzF4.Adapter.IsAvailable() then
        Ui.Label(page, DubzF4.Phrase("NoDarkRP"), "heading", nil, TEXT_ALIGN_CENTER):Dock(FILL)
        return
    end

    local listColumn = vgui.Create("Panel", page)
    local detail = Jobs.BuildDetail(page)
    local selected

    listColumn:Dock(LEFT)
    listColumn:DockMargin(0, 0, Ui.Gap(), 0)
    page.PerformLayout = function(_, w) listColumn:SetWide(math.floor(w * config.JobListShare)) end
    detail.Panel:Dock(FILL)

    Jobs.BuildList(listColumn, function() return selected end, function(entry)
        local unchanged = selected and selected.id == entry.id

        selected = entry

        if not unchanged then detail.Show(entry) end
    end)
end

DubzF4.Tabs:Register("jobs", {name = "TabJobs", icon = "darkrp/work", order = 20, build = build})
