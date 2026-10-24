local Home = DubzF4.Home
local Ui = DubzF4.Ui
local STAFF_ROW = 44
local AVATAR_SIZE = 32
local LINK_HEIGHT = 34
local LINK_TITLE = 40

local function padded(card)
    local pad = DFW.UI.Space("LG")

    card:DockPadding(pad, pad, pad, pad)
end

function Home.Announcement(parent)
    local card = Ui.Card(parent)

    padded(card)
    Ui.Header(card, DubzF4.Phrase("Announcement"))

    local scroll = Ui.Scroll(card)

    scroll:Dock(FILL)

    for _, row in ipairs(DubzF4.Rows("announcement")) do
        local paragraph = Ui.Paragraph(scroll, row.text, "body")

        paragraph:Dock(TOP)
        paragraph:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("MD"))
    end

    return card
end

local function onlineStaff()
    local groups, staff = {}, {}

    for _, row in ipairs(DubzF4.Rows("staff_groups")) do
        groups[row.group] = {label = row.label, color = DFW.Collections.ToColor(row.color)}
    end

    for _, ply in ipairs(player.GetAll()) do
        local group = groups[ply:GetUserGroup()]

        if group then staff[#staff + 1] = {ply = ply, label = group.label, color = group.color} end
    end

    return staff
end

local function addStaffRow(scroll, member)
    local row = scroll:Add("Panel")
    local avatar = vgui.Create("AvatarImage", row)
    local name = Ui.Label(row, member.ply:Nick(), "body")
    local tag = Ui.Label(row, member.label, "bodybold", member.color, TEXT_ALIGN_RIGHT)

    row:Dock(TOP)
    row:SetTall(DFW.UI.Scale(STAFF_ROW))
    row:DockMargin(0, 0, DFW.UI.Space("MD"), DFW.UI.Space("XS"))
    avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
    avatar:SetPlayer(member.ply, 64)

    row.PerformLayout = function(_, w, h)
        avatar:SetPos(0, (h - AVATAR_SIZE) / 2)
        name:SetPos(AVATAR_SIZE + DFW.UI.Space("MD"), 0)
        name:SetSize(w * 0.55, h)
        tag:SetPos(w * 0.55, 0)
        tag:SetSize(w * 0.45, h)
    end
end

function Home.Staff(parent)
    local card = Ui.Card(parent)
    local staff = onlineStaff()

    padded(card)
    Ui.Header(card, DubzF4.Phrase("StaffOnline"), tostring(#staff))

    if #staff == 0 then
        Ui.Label(card, DubzF4.Phrase("NoStaff"), "muted", nil, TEXT_ALIGN_CENTER):Dock(FILL)
        return card
    end

    local scroll = Ui.Scroll(card)

    scroll:Dock(FILL)

    for _, member in ipairs(staff) do addStaffRow(scroll, member) end

    return card
end

function Home.Links(parent)
    local links = {}

    for _, row in ipairs(DubzF4.Rows("links")) do
        if row.url and row.url ~= "" then links[#links + 1] = row end
    end

    if #links == 0 then return nil end

    local card = Ui.Card(parent)
    local gap = DFW.UI.Space("SM")
    local pad = DFW.UI.Space("LG")

    padded(card)
    card:SetTall(pad * 2 + LINK_TITLE + #links * (LINK_HEIGHT + gap))
    Ui.Header(card, DubzF4.Phrase("Community"))

    for _, link in ipairs(links) do
        local button = vgui.Create("DFW.Button", card)

        button:Dock(TOP)
        button:SetTall(LINK_HEIGHT)
        button:DockMargin(0, 0, 0, gap)
        button:SetLabel(link.name)
        button:SetIcon("communication/link")
        button.DoClick = function() gui.OpenURL(link.url) end
    end

    return card
end
