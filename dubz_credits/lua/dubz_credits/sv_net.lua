-------------------------------------------------
-- Network strings
-------------------------------------------------
util.AddNetworkString("DubzCredits_Notify")
util.AddNetworkString("DubzCredits_Action")
util.AddNetworkString("DubzCredits_BoostSync") -- 🔥 REQUIRED

-------------------------------------------------
-- Notify helper
-------------------------------------------------
function DubzCredits:Notify(ply, msg, notifyType)
    if not IsValid(ply) then return end

    net.Start("DubzCredits_Notify")
        net.WriteString(msg or "")
        net.WriteUInt(notifyType or 0, 4)
    net.Send(ply)
end

-------------------------------------------------
-- Cost helper (sale-aware)
-------------------------------------------------
local function GetCost(cfg)
    local cost = tonumber(cfg.cost) or 0

    if cfg.sale and tonumber(cfg.sale) then
        cost = math.floor(cost * (1 - tonumber(cfg.sale)))
    end

    return math.max(0, cost)
end

-------------------------------------------------
-- Action handler
-------------------------------------------------
net.Receive("DubzCredits_Action", function(_, ply)
    if not IsValid(ply) then return end

    if not DubzCredits.Enabled() then
        DubzCredits:Notify(ply, "Credits are switched off right now.", 1)
        return
    end

    local actionType = net.ReadString()
    local id = net.ReadString()

    local cfg
    if actionType == "convert" then
        cfg = DubzCredits.Config.Conversions and DubzCredits.Config.Conversions[id]
    elseif actionType == "boost" then
        cfg = DubzCredits.Config.Boosts and DubzCredits.Config.Boosts[id]
    elseif actionType == "event" then
        cfg = DubzCredits.Config.Events and DubzCredits.Config.Events[id]
    elseif actionType == "pboost" then
        cfg = DubzCredits.Config.PersonalBoosts and DubzCredits.Config.PersonalBoosts[id]
    elseif actionType == "item" then
        cfg = DubzCredits.Config.Items and DubzCredits.Config.Items[id]
    end

    if not cfg or cfg.enabled == false then
        DubzCredits:Notify(ply, "Invalid or disabled purchase.", 1)
        return
    end

    -- Whole categories can be switched off in the admin menu
    local ui = DubzCredits.Config.UI or {}
    local switches = {convert = "ConversionsEnabled", boost = "BoostsEnabled", pboost = "PersonalBoostsEnabled", item = "WeeklyShopEnabled", event = "EventsEnabled"}

    if ui[switches[actionType]] == false then
        DubzCredits:Notify(ply, "That isn't available right now.", 1)
        return
    end

    local cost = GetCost(cfg)
    if cost <= 0 then
        DubzCredits:Notify(ply, "Invalid cost configuration.", 1)
        return
    end

    -------------------------------------------------
    -- Take credits first
    -------------------------------------------------
    if not DubzCredits:Take(ply, cost) then
        DubzCredits:Notify(ply, "You do not have enough credits.", 1)
        return
    end

    -------------------------------------------------
    -- CONVERSIONS
    -------------------------------------------------
    if actionType == "convert" then
        if not isfunction(cfg.reward) then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, "Conversion misconfigured. Refunded.", 1)
            return
        end

        local ok = cfg.reward(ply)
        if ok == false then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, "Conversion failed. Refunded.", 1)
            return
        end

        DubzCredits:Notify(ply, "Conversion successful!", 0)
        return
    end

    -------------------------------------------------
    -- BOOSTS
    -------------------------------------------------
    if actionType == "boost" then
        if DubzCredits:IsBoostActive(id) then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, "That boost is already active. Refunded.", 1)
            return
        end

        local ok, err = DubzCredits:ActivateBoost(id, ply)
        if not ok then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, err or "Could not activate boost. Refunded.", 1)
            return
        end

        DubzCredits:Notify(ply, (cfg.name or id) .. " activated!", 0)

        -- 🔥 Sync ALL clients (HUD depends on this)
        for _, p in ipairs(player.GetAll()) do
            DubzCredits:SyncBoosts(p)
        end

        return
    end

    -------------------------------------------------
    -- PERSONAL BOOSTS
    -------------------------------------------------
    if actionType == "pboost" then
        if not cfg then
            DubzCredits:Notify(ply, "Invalid boost.", 1)
            return
        end

        -- DO NOT TAKE CREDITS AGAIN (already taken above)

        DubzCredits:ApplyPersonalBoost(ply, id, cfg)

        DubzCredits:Notify(ply, cfg.name .. " activated!", 0)
        return
    end

    -------------------------------------------------
    -- EVENTS (treated as boosts)
    -------------------------------------------------
    if actionType == "event" then
        local ok, err = DubzCredits:ActivateBoost(id, ply)
        if not ok then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, err or "Could not start event. Refunded.", 1)
            return
        end

        if DarkRP and DarkRP.notifyAll then
            DarkRP.notifyAll(0, 6, ply:Nick() .. " started event: " .. (cfg.name or id))
        end

        for _, p in ipairs(player.GetAll()) do
            DubzCredits:SyncBoosts(p)
        end

        return
    end

    -------------------------------------------------
    -- ITEMS
    -------------------------------------------------
    if actionType == "item" then
        if not isfunction(cfg.reward) then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, "Item misconfigured. Refunded.", 1)
            return
        end

        local ok = cfg.reward(ply)

        if ok == false then
            DubzCredits:Add(ply, cost)
            DubzCredits:Notify(ply, "Purchase failed. Refunded.", 1)
            return
        end

        DubzCredits:Notify(ply, "Purchased " .. (cfg.name or id) .. "!", 0)
        return
    end
end)

hook.Add("PlayerSpawnProp", "DubzCredits_PropLimit", function(ply)
    local base = GetConVar("sbox_maxprops"):GetInt()

    local totalBonus = 0

    totalBonus = totalBonus + DubzCredits:GetPersonalPropBonus(ply)

    if ply:GetCount("props") >= (base + totalBonus) then
        DarkRP.notify(ply, 1, 4, "You've hit the prop limit!")
        ply:EmitSound("buttons/button10.wav", 75, 100, 1)
        return false
    end
end)