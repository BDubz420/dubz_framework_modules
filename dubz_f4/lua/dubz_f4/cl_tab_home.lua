local Home = DubzF4.Home
local Ui = DubzF4.Ui
local config = DubzF4.Config
local SIDE_SHARE = 0.38

local function buildSide(body)
    local side = vgui.Create("Panel", body)
    local links = Home.Links(side)

    side:Dock(RIGHT)
    side:DockMargin(Ui.Gap(), 0, 0, 0)

    if links then
        links:Dock(BOTTOM)
        links:DockMargin(0, Ui.Gap(), 0, 0)
    end

    if config.ShowStaff then Home.Staff(side):Dock(FILL) end

    body.PerformLayout = function(_, w)
        side:SetWide(config.ShowAnnouncement and math.floor(w * SIDE_SHARE) or w)
    end

    return side
end

local function build(page)
    Home.Stats(page)

    local body = vgui.Create("Panel", page)

    body:Dock(FILL)
    buildSide(body)

    if config.ShowAnnouncement then Home.Announcement(body):Dock(FILL) end
end

DubzF4.Tabs:Register("home", {name = "TabHome", icon = "economy/house", order = 10, build = build})
