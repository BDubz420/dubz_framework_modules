DubzF4.Home = DubzF4.Home or {}

local Home = DubzF4.Home
local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local ROW_HEIGHT = 78
local INSET = 14
local TITLE_TOP = 12
local VALUE_TOP = 36

local function definitions()
    local ply = LocalPlayer()

    return {
        {"Balance", function(theme) return Adapter.FormatMoney(Adapter.Money(ply)), theme.success end},
        {"Salary", function(theme) return Adapter.FormatMoney(Adapter.Salary(ply)), theme.gold end},
        {"Job", function() return Adapter.JobName(ply) or DubzF4.Phrase("Unknown"), team.GetColor(ply:Team()) end},
        {"Online", function(theme) return #player.GetAll() .. " / " .. game.MaxPlayers(), theme.text end}
    }
end

local function addStat(row, definition)
    local card = Ui.Card(row)
    local title = Ui.Label(card, string.upper(DubzF4.Phrase(definition[1])), "tiny")
    local value = Ui.Label(card, "", "heading")

    value.Think = function(self)
        local text, color = definition[2](DFW.UI.GetTheme())

        self:SetText(text)
        self:SetColor(color)
    end

    card.PerformLayout = function(_, w)
        title:SetPos(INSET, TITLE_TOP)
        title:SetSize(w - INSET * 2, 16)
        value:SetPos(INSET, VALUE_TOP)
        value:SetSize(w - INSET * 2, 28)
    end
end

function Home.Stats(parent)
    local row = vgui.Create("Panel", parent)

    row:Dock(TOP)
    row:SetTall(ROW_HEIGHT)
    row:DockMargin(0, 0, 0, Ui.Gap())
    Ui.Distribute(row, Ui.Gap())

    for _, definition in ipairs(definitions()) do addStat(row, definition) end

    return row
end
