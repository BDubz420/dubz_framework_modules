local Shop = DubzF4.Shop
local Ui = DubzF4.Ui
local config = DubzF4.Config
local CARD_HEIGHT = 250
local SEARCH_WIDTH = 280
local SCROLLBAR_ALLOWANCE = 18

local function matching(items, filter)
    local shown = {}

    for _, item in ipairs(items) do
        if filter == "" or string.find(string.lower(item.name or ""), filter, 1, true) then shown[#shown + 1] = item end
    end

    return shown
end

local function fillGrid(scroll, shown, width)
    local gap = DFW.UI.Space("MD")
    local columns = config.StoreColumns
    local cardWidth = math.floor((width - SCROLLBAR_ALLOWANCE - gap * (columns - 1)) / columns)
    local layout = scroll:Add("DIconLayout")

    layout:Dock(TOP)
    layout:SetSpaceX(gap)
    layout:SetSpaceY(gap)
    layout:SetTall(math.ceil(#shown / columns) * (CARD_HEIGHT + gap))

    for _, item in ipairs(shown) do Shop.Card(layout, cardWidth, CARD_HEIGHT, item) end
end

local function buildHead(page, titleKey, count, onSearch)
    local row = vgui.Create("Panel", page)
    local search = Ui.Search(row, DubzF4.Phrase("SearchItems"), onSearch)
    local header = Ui.Header(row, DubzF4.Phrase(titleKey), DubzF4.Phrase("Available", {count = count}))

    row:Dock(TOP)
    row:SetTall(40)
    row:DockMargin(0, 0, 0, DFW.UI.Space("SM"))
    search:Dock(RIGHT)
    search:SetWide(SEARCH_WIDTH)
    header:Dock(FILL)
end

local function buildShop(page, titleKey, source)
    local items = Shop.Sources[source]()
    local filter = ""
    local scroll
    local width = 0

    local function populate()
        scroll:Clear()

        local shown = matching(items, filter)

        if #shown == 0 then
            Ui.Label(scroll, DubzF4.Phrase("Nothing"), "heading", nil, TEXT_ALIGN_CENTER):Dock(TOP)
            return
        end

        fillGrid(scroll, shown, width)
    end

    buildHead(page, titleKey, #items, function(text)
        filter = text
        populate()
    end)

    scroll = Ui.Scroll(page)
    scroll:Dock(FILL)
    Ui.OnSized(scroll, function(w)
        width = w
        populate()
    end)
end

local function register(id, titleKey, order, icon)
    DubzF4.Tabs:Register(id, {
        name = titleKey,
        icon = icon,
        order = order,
        build = function(page) buildShop(page, titleKey, id) end
    })
end

register("entities", "TabEntities", 30, "economy/inventory_2")
register("weapons", "TabWeapons", 40, "darkrp/local_police")
register("ammo", "TabAmmo", 50, "misc/bolt")
register("vehicles", "TabVehicles", 60, "economy/shopping_cart_checkout")
