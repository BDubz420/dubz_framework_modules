DubzF4.Sidebar = DubzF4.Sidebar or {}

local Sidebar = DubzF4.Sidebar
local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local config = DubzF4.Config
local CARD_HEIGHT = 76
local AVATAR_SIZE = 52
local NAV_HEIGHT = 40

local function liveLabel(parent, style, source)
    local label = Ui.Label(parent, "", style)

    label.Think = function(self)
        local text, color = source()

        self:SetText(text)

        if color then self:SetColor(color) end
    end

    return label
end

local function buildPlayerCard(parent)
    local ply = LocalPlayer()
    local card = vgui.Create("Panel", parent)
    local avatar = vgui.Create("AvatarImage", card)
    local name = Ui.Label(card, ply:Nick(), "bodybold")
    local job = liveLabel(card, "small", function()
        return Adapter.JobName(ply) or "", team.GetColor(ply:Team())
    end)
    local wallet = liveLabel(card, "small", function()
        return Adapter.FormatMoney(Adapter.Money(ply)), DFW.UI.GetTheme().success
    end)

    card:Dock(TOP)
    card:SetTall(CARD_HEIGHT)
    avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
    avatar:SetPlayer(ply, 64)

    card.PerformLayout = function(_, w)
        local x = AVATAR_SIZE + DFW.UI.Space("MD")
        local width = w - x

        avatar:SetPos(0, 8)
        name:SetPos(x, 8)
        name:SetSize(width, 18)
        job:SetPos(x, 28)
        job:SetSize(width, 16)
        wallet:SetPos(x, 46)
        wallet:SetSize(width, 16)
    end

    return card
end

function Sidebar.Build(parent, tabs, onSelect)
    local side = Ui.Card(parent)
    local buttons = {}
    local pad = DFW.UI.Space("MD")

    side:Dock(LEFT)
    side:SetWide(config.SidebarWidth)
    side:DockPadding(pad, pad, pad, pad)
    buildPlayerCard(side)

    for _, tab in ipairs(tabs) do
        local button = vgui.Create("DFW.NavButton", side)

        button:Dock(TOP)
        button:SetTall(NAV_HEIGHT)
        button:DockMargin(0, DFW.UI.Space("XS"), 0, 0)
        button:SetLabel(DubzF4.Phrase(tab.name))
        button:SetIcon(tab.icon)
        button.DoClick = function() onSelect(tab.ID) end
        buttons[tab.ID] = button
    end

    return {
        Panel = side,
        SetActive = function(id)
            for tabId, button in pairs(buttons) do button:SetActive(tabId == id) end
        end
    }
end
