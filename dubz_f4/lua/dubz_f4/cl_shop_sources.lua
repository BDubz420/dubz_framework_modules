local Shop = DubzF4.Shop
local Adapter = DubzF4.Adapter

Shop.Sources = Shop.Sources or {}

local function buyButton(price, command, argument)
    return {label = DubzF4.Phrase("Buy"), price = price, fn = function() Adapter.Run(command, argument) end}
end

local function shipmentButtons(shipment)
    local buttons = {}

    if not shipment.noship then
        buttons[#buttons + 1] = {
            label = DubzF4.Phrase(shipment.separate and "Shipment" or "BuyShipment"),
            price = shipment.price,
            fn = function() Adapter.Run("buyshipment", shipment.name) end
        }
    end

    if shipment.separate then
        buttons[#buttons + 1] = {
            label = DubzF4.Phrase("Single", {price = Adapter.FormatMoney(shipment.pricesep or 0)}),
            price = shipment.pricesep,
            fn = function() Adapter.Run("buy", shipment.name) end
        }
    end

    return buttons
end

function Shop.Sources.entities()
    local items = {}

    for _, entity in pairs(Adapter.Entities()) do
        if Adapter.Permitted(entity) then
            items[#items + 1] = {
                name = entity.name, model = entity.model, price = entity.price, sub = entity.category,
                buttons = {buyButton(entity.price, entity.cmd)}
            }
        end
    end

    return items
end

function Shop.Sources.weapons()
    local items = {}

    for _, shipment in pairs(Adapter.Shipments()) do
        local buttons = Adapter.Permitted(shipment) and shipmentButtons(shipment) or {}

        if #buttons > 0 then
            items[#items + 1] = {
                name = shipment.name, model = shipment.model,
                price = shipment.noship and shipment.pricesep or shipment.price,
                sub = shipment.noship and DubzF4.Phrase("SingleItem") or DubzF4.Phrase("InShipment", {amount = shipment.amount or 1}),
                buttons = buttons
            }
        end
    end

    return items
end

function Shop.Sources.ammo()
    local items = {}

    for key, ammo in pairs(Adapter.AmmoTypes()) do
        if not ammo.customCheck or Adapter.Safe(ammo.customCheck, LocalPlayer()) then
            items[#items + 1] = {
                name = ammo.name, model = ammo.model, price = ammo.price,
                sub = ammo.amountGiven and DubzF4.Phrase("Rounds", {amount = ammo.amountGiven}) or nil,
                buttons = {buyButton(ammo.price, "buyammo", ammo.ammoType or key)}
            }
        end
    end

    table.sort(items, function(a, b) return (a.name or "") < (b.name or "") end)

    return items
end

function Shop.Sources.vehicles()
    local items = {}

    for _, vehicle in pairs(Adapter.Vehicles()) do
        if Adapter.Permitted(vehicle) then
            items[#items + 1] = {
                name = vehicle.name, model = vehicle.model, price = vehicle.price,
                buttons = {buyButton(vehicle.price, "buyvehicle", vehicle.name)}
            }
        end
    end

    table.sort(items, function(a, b) return (a.name or "") < (b.name or "") end)

    return items
end
