local Adapter = DubzDarkRP.Adapter
local Fields = DubzDarkRP.Fields

local DEFAULT_CRATE = "models/Items/item_item_crate.mdl"
local SHIPMENT_WEIGHT = 5
local PURCHASE_REACH = 85
local COMMAND_DELAY = 2
local NOTIFY_OK = 0
local NOTIFY_ERROR = 1
local NOTIFY_SECONDS = 4

local function say(ply, kind, key, values)
    if IsValid(ply) then DarkRP.notify(ply, kind, NOTIFY_SECONDS, DubzDarkRP.Phrase(key, values)) end
end

local function blockRemoved(entry)
    if entry and entry.dubzDisabled then return false, false, DubzDarkRP.Phrase("ShopRemoved") end
end

hook.Add("canBuyCustomEntity", "DubzDarkRP_RemovedEntity", function(_, entry) return blockRemoved(entry) end)
hook.Add("canBuyShipment", "DubzDarkRP_RemovedShipment", function(_, entry) return blockRemoved(entry) end)
hook.Add("canBuyPistol", "DubzDarkRP_RemovedPistol", function(_, entry) return blockRemoved(entry) end)
hook.Add("canBuyAmmo", "DubzDarkRP_RemovedAmmo", function(_, entry) return blockRemoved(entry) end)

local function removeShipment(ship)
    Adapter.RemoveFromCategory(ship, "shipments")
    Adapter.RemoveFromCategory(ship, "weapons")
end

local function addShipment(ship)
    if not ship.noship then
        Adapter.EnsureCategory(ship.category, "shipments")
        Adapter.AddToCategory(ship, "shipments")
    end

    if ship.separate then
        Adapter.EnsureCategory(ship.category, "weapons")
        Adapter.AddToCategory(ship, "weapons")
    end
end

local function patchShipmentLookup()
    if DubzDarkRP.ShipmentLookupPatched or not DarkRP.getShipmentByName then return end

    local stock = DarkRP.getShipmentByName

    DubzDarkRP.ShipmentLookupPatched = true

    DarkRP.getShipmentByName = function(name)
        local ship, index = stock(name)

        if ship then return ship, index end

        name = string.lower(tostring(name or ""))

        for key, value in pairs(CustomShipments) do
            if string.lower(value.name or "") == name then return value, key end
        end
    end
end

DubzDarkRP.NewEngine({
    kind = "shipments",
    entries = function() return CustomShipments or {} end,
    idOf = function(ship) return ship.name end,
    nextIndex = function() return #CustomShipments + 1 end,
    create = function(data, index)
        local ship = {}

        patchShipmentLookup()
        Fields.Assign(ship, data, "shipments")
        ship.seperate = ship.separate
        ship.shipModel = DEFAULT_CRATE
        ship.weight = SHIPMENT_WEIGHT
        ship.default = false
        CustomShipments[index] = ship
        addShipment(ship)
        util.PrecacheModel(ship.model)

        return ship
    end,
    update = function(ship, data)
        removeShipment(ship)
        Fields.Assign(ship, data, "shipments")
        ship.seperate = ship.separate
        addShipment(ship)
    end,
    disable = removeShipment
})

local function buyEntity(ply, item)
    if item.dubzDisabled or ply:isArrested() then return end
    if not item.allowPurchaseWhileDead and not ply:Alive() then return say(ply, NOTIFY_ERROR, "ShopDead", {item = item.name}) end
    if istable(item.allowed) and not table.HasValue(item.allowed, ply:Team()) then return say(ply, NOTIFY_ERROR, "ShopWrongJob", {item = item.name}) end
    if item.customCheck and not item.customCheck(ply) then return say(ply, NOTIFY_ERROR, "ShopNotAllowed", {item = item.name}) end
    if ply:customEntityLimitReached(item) then return say(ply, NOTIFY_ERROR, "ShopLimit", {item = item.name}) end

    local canBuy, suppress, message, price = hook.Call("canBuyCustomEntity", nil, ply, item)
    local cost = price or (item.getPrice and item.getPrice(ply, item.price)) or item.price

    if not ply:canAfford(cost) then return say(ply, NOTIFY_ERROR, "ShopCantAfford", {item = item.name}) end

    if canBuy == false then
        if not suppress and message then DarkRP.notify(ply, NOTIFY_ERROR, NOTIFY_SECONDS, message) end

        return
    end

    local start = ply:EyePos()
    local trace = util.TraceLine({start = start, endpos = start + ply:GetAimVector() * PURCHASE_REACH, filter = ply})
    local entity = ents.Create(item.ent)

    if not IsValid(entity) then
        DubzDarkRP.Report("entity class '" .. tostring(item.ent) .. "' for " .. item.name .. " does not exist")
        return say(ply, NOTIFY_ERROR, "ShopFailed", {item = item.name})
    end

    ply:addMoney(-cost)

    if entity.Setowning_ent then entity:Setowning_ent(ply) end

    entity:SetPos(trace.HitPos)
    entity.SID = ply.SID
    entity.allowed = item.allowed
    entity.DarkRPItem = item
    entity:Spawn()
    entity:Activate()
    DarkRP.placeEntity(entity, trace, ply)

    local physics = entity:GetPhysicsObject()

    if IsValid(physics) then physics:Wake() end

    entity.onlyremover = not item.allowTools
    hook.Call("playerBoughtCustomEntity", nil, ply, item, entity, cost)
    say(ply, NOTIFY_OK, "ShopBought", {item = item.name, price = DarkRP.formatMoney(cost)})
    ply:addCustomEntity(item)
end

local function declareBuy(item)
    DarkRP.declareChatCommand{
        command = item.cmd,
        description = DubzDarkRP.Phrase("ShopHelp", {item = item.name}),
        delay = COMMAND_DELAY,
        condition = function() return not item.dubzDisabled end
    }

    if CLIENT then return end

    DarkRP.defineChatCommand(item.cmd, function(ply)
        buyEntity(ply, item)

        return ""
    end)
end

local function addEntityCategory(item)
    Adapter.EnsureCategory(item.category, "entities")
    Adapter.AddToCategory(item, "entities")
end

DubzDarkRP.NewEngine({
    kind = "entities",
    entries = function() return DarkRPEntities or {} end,
    idOf = function(item) return item.cmd end,
    nextIndex = function() return #DarkRPEntities + 1 end,
    create = function(data, index)
        local item = {}

        Fields.Assign(item, data, "entities")
        item.default = false
        DarkRPEntities[index] = item
        addEntityCategory(item)
        declareBuy(item)
        util.PrecacheModel(item.model)

        return item
    end,
    update = function(item, data)
        local before = {cmd = item.cmd, disabled = item.dubzDisabled}

        Adapter.RemoveFromCategory(item, "entities")
        Fields.Assign(item, data, "entities")
        addEntityCategory(item)

        if before.cmd ~= item.cmd or before.disabled then
            pcall(DarkRP.removeChatCommand, before.cmd)
            declareBuy(item)
        end
    end,
    disable = function(item)
        Adapter.RemoveFromCategory(item, "entities")
        pcall(DarkRP.removeChatCommand, item.cmd)
    end
})

local function ammoTable()
    local mode = GAMEMODE or GM

    mode.AmmoTypes = mode.AmmoTypes or {}

    return mode.AmmoTypes
end

local function addAmmoCategory(ammo)
    Adapter.EnsureCategory(ammo.category, "ammo")
    Adapter.AddToCategory(ammo, "ammo")
end

DubzDarkRP.NewEngine({
    kind = "ammo",
    entries = ammoTable,
    idOf = function(ammo) return ammo.ammoType end,
    nextIndex = function(data) return data.ammoType end,
    create = function(data, index)
        local ammo = {}

        Fields.Assign(ammo, data, "ammo")
        ammo.default = false
        ammoTable()[index] = ammo
        addAmmoCategory(ammo)
        util.PrecacheModel(ammo.model)

        return ammo
    end,
    update = function(ammo, data)
        Adapter.RemoveFromCategory(ammo, "ammo")
        Fields.Assign(ammo, data, "ammo")
        addAmmoCategory(ammo)
    end,
    disable = function(ammo) Adapter.RemoveFromCategory(ammo, "ammo") end
})
