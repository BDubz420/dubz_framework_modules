DubzF4.Shop = DubzF4.Shop or {}

local Shop = DubzF4.Shop
local Ui = DubzF4.Ui
local Adapter = DubzF4.Adapter
local ICON_HEIGHT = 104
local ICON_SIZE = 96
local BUTTON_HEIGHT = 34

local function addIcon(card, item)
    local holder = vgui.Create("Panel", card)
    local icon = vgui.Create("SpawnIcon", holder)

    holder:Dock(TOP)
    holder:SetTall(ICON_HEIGHT)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetModel(item.model or "models/error.mdl")
    icon:SetMouseInputEnabled(false)
    holder.PerformLayout = function(_, w, h) icon:SetPos((w - ICON_SIZE) / 2, (h - ICON_SIZE) / 2) end
end

local function addTexts(card, item)
    local name = Ui.Label(card, item.name or "?", "bodybold", nil, TEXT_ALIGN_CENTER)
    local price = Ui.Label(card, "", "heading", nil, TEXT_ALIGN_CENTER)

    name:Dock(TOP)
    name:SetTall(22)

    if item.sub then
        local sub = Ui.Label(card, item.sub, "small", nil, TEXT_ALIGN_CENTER)

        sub:Dock(TOP)
        sub:SetTall(18)
    end

    price:Dock(TOP)
    price:SetTall(30)
    price.Think = function(self)
        local theme = DFW.UI.GetTheme()

        self:SetText(Adapter.FormatMoney(item.price or 0))
        self:SetColor(Adapter.CanAfford(item.price) and theme.success or theme.danger)
    end
end

local function addButtons(card, item)
    local row = vgui.Create("Panel", card)

    row:Dock(BOTTOM)
    row:SetTall(BUTTON_HEIGHT)
    Ui.Distribute(row, DFW.UI.Space("SM"))

    for _, definition in ipairs(item.buttons) do
        local button = vgui.Create("DFW.Button", row)

        button:SetLabel(definition.label)
        button:SetVariant("primary")
        button.DoClick = definition.fn
        button.Think = function(self) self:SetEnabled(not definition.price or Adapter.CanAfford(definition.price)) end
    end
end

function Shop.Card(parent, width, height, item)
    local card = parent:Add("DFW.Card")
    local pad = DFW.UI.Space("MD")

    card:SetSize(width, height)
    card:DockPadding(pad, pad, pad, pad)
    addIcon(card, item)
    addTexts(card, item)
    addButtons(card, item)

    return card
end
