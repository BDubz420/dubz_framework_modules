-------------------------------------------------
-- Admin credit commands (SteamID + SteamID64 safe)
-------------------------------------------------

local function IsAdmin(ply)
    return not IsValid(ply) or ply:IsSuperAdmin()
end

local function ToSteamID64(id)
    if not id or id == "" then return nil end

    -- Already SteamID64
    if string.match(id, "^%d+$") then
        return id
    end

    -- Convert STEAM_X:Y:Z → SteamID64
    if string.StartWith(id, "STEAM_") then
        local sid64 = util.SteamIDTo64(id)
        if sid64 ~= "0" then
            return sid64
        end
    end

    return nil
end

local function FindOnlineBySteamID64(steamid64)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid64 then
            return ply
        end
    end
end

-------------------------------------------------
-- ADD CREDITS
-------------------------------------------------
concommand.Add("dubzcredits_add", function(ply, _, args, argStr)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        DubzCredits:Notify(ply, "You do not have permission.", 1)
        return
    end

    -- Parse from raw string (more reliable than args[])
    local parts = string.Explode(" ", string.Trim(argStr or ""))

    local rawId = parts[1]
    local amount = tonumber(parts[2])

    if not rawId or rawId == "" or not amount or amount <= 0 then
        if IsValid(ply) then
            DubzCredits:Notify(
                ply,
                "Usage: dubzcredits_add <steamid / steamid64> <amount>",
                1
            )
        else
            print("[DubzCredits] Usage: dubzcredits_add <steamid / steamid64> <amount>")
        end
        return
    end

    -- Convert to SteamID64 (supports STEAM_ and numeric)
    local steamid64 = ToSteamID64(rawId)
    if not steamid64 then
        if IsValid(ply) then
            DubzCredits:Notify(ply, "Invalid SteamID or SteamID64.", 1)
        end
        return
    end

    -- Online?
    local target = FindOnlineBySteamID64(steamid64)
    if target then
        DubzCredits:Add(target, amount)
        DubzCredits:Notify(target, "+" .. amount .. " credits added.")
        if IsValid(ply) then
            DubzCredits:Notify(ply, "Added credits to " .. target:Nick())
        end
        return
    end

    -- Offline grant
    local current = tonumber(DubzCredits.Storage:Load(steamid64)) or 0
    DubzCredits.Storage:Save(steamid64, current + amount)

    if IsValid(ply) then
        DubzCredits:Notify(ply, "Added credits to offline player.")
    end

    DubzCredits:LogInfo(
        "ADMIN ADD: " .. steamid64 .. " +" .. amount ..
        " by " .. (IsValid(ply) and ply:SteamID64() or "CONSOLE")
    )
end)

-------------------------------------------------
-- CLEAR PERSONAL BOOSTS
-------------------------------------------------
concommand.Add("dubz_pboosts_clear", function(ply, _, args)
    local isConsole = not IsValid(ply)

    if not isConsole and not ply:IsAdmin() then
        DubzCredits:Notify(ply, "You do not have permission.", 1)
        return
    end

    -- Usage: dubz_pboosts_clear [steamid64]
    local targetID = args[1]

    -- =========================
    -- CLEAR ALL
    -- =========================
    if not targetID then
        DubzCredits.PersonalBoosts = {}
        DubzCredits:SavePersonalBoosts()

        for _, p in ipairs(player.GetAll()) do
            DubzCredits:SyncPersonalBoosts(p)
        end

        local msg = "All personal boosts have been cleared."

        if isConsole then
            print("[DubzCredits] " .. msg)
        else
            DubzCredits:Notify(ply, msg, 0)
        end

        return
    end

    -- =========================
    -- CLEAR SPECIFIC PLAYER
    -- =========================
    local target = nil

    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == targetID then
            target = p
            break
        end
    end

    DubzCredits.PersonalBoosts[targetID] = nil
    DubzCredits:SavePersonalBoosts()

    if IsValid(target) then
        DubzCredits:SyncPersonalBoosts(target)
    end

    local msg = "Cleared personal boosts for " .. targetID

    if isConsole then
        print("[DubzCredits] " .. msg)
    else
        DubzCredits:Notify(ply, msg, 0)
    end
end)

concommand.Add("dubz_shop_refresh", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    PickWeeklyItems()

    for _, p in ipairs(player.GetAll()) do
        DubzCredits:SyncShop(p)
    end

    print("[DubzCredits] Shop force refreshed.")
end)

-------------------------------------------------
-- SET CREDITS
-------------------------------------------------
concommand.Add("dubzcredits_set", function(ply, _, args, argStr)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        DubzCredits:Notify(ply, "You do not have permission.", 1)
        return
    end

    -- Parse raw input (more reliable)
    local parts = string.Explode(" ", string.Trim(argStr or ""))

    local rawId = parts[1]
    local amount = tonumber(parts[2])

    if not rawId or rawId == "" or amount == nil then
        if IsValid(ply) then
            DubzCredits:Notify(
                ply,
                "Usage: dubzcredits_set <steamid / steamid64> <amount>",
                1
            )
        else
            print("[DubzCredits] Usage: dubzcredits_set <steamid / steamid64> <amount>")
        end
        return
    end

    amount = math.max(0, math.floor(amount))

    local steamid64 = ToSteamID64(rawId)
    if not steamid64 then
        if IsValid(ply) then
            DubzCredits:Notify(ply, "Invalid SteamID or SteamID64.", 1)
        end
        return
    end

    -- Online?
    local target = FindOnlineBySteamID64(steamid64)
    if target then
        DubzCredits:SetBalance(target, amount)
        DubzCredits:SyncToClient(target)

        DubzCredits:Notify(target, "Your credits were set to " .. amount)

        if IsValid(ply) then
            DubzCredits:Notify(ply, "Set credits for " .. target:Nick())
        end
    else
        -- Offline
        DubzCredits.Storage:Save(steamid64, amount)

        if IsValid(ply) then
            DubzCredits:Notify(ply, "Set credits for offline player.")
        else
            print("[DubzCredits] Set credits for offline player:", steamid64, amount)
        end
    end

    if DubzCredits.Log then
        DubzCredits:LogInfo(
            "ADMIN SET: " .. steamid64 .. " = " .. amount ..
            " by " .. (IsValid(ply) and ply:SteamID64() or "CONSOLE")
        )
    end
end)

concommand.Add("dubz_boosts_help", function(ply)
    local isConsole = not IsValid(ply)

    local lines = {
        "=== Dubz Credits Commands ===",
        "dubz_boosts_clear                - Clear ALL global boosts",
        "dubz_boost_remove <id>           - Remove specific global boost",
        "dubz_pboosts_clear               - Clear ALL personal boosts",
        "dubz_pboosts_clear <steamid64>   - Clear personal boosts for player",
    }

    for _, line in ipairs(lines) do
        if isConsole then
            print(line)
        else
            DubzCredits:Notify(ply, line, 0)
        end
    end
end)

-------------------------------------------------
-- FORCE-START A BOOST
-------------------------------------------------

concommand.Add("dubzcredits_forceboost", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local id = args[1]
    if not DubzCredits.Config.Boosts[id] then
        if IsValid(ply) then
            DubzCredits:Notify(ply, "Invalid boost ID.", 1)
        end
        return
    end

    local ok, err = DubzCredits:ActivateBoost(id, ply)
    if not ok then
        if IsValid(ply) then
            DubzCredits:Notify(ply, err or "Could not activate boost.", 1)
        end
        return
    end

    for _, p in ipairs(player.GetAll()) do
        DubzCredits:SyncBoosts(p)
    end

    if DarkRP and DarkRP.notifyAll then
        DarkRP.notifyAll(0, 6, "Admin activated boost: " .. DubzCredits.Config.Boosts[id].name)
    end
end)

-------------------------------------------------
-- CLEAN ALL ACTIVE BOOSTS
-------------------------------------------------

concommand.Add("dubz_boosts_clear", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        DubzCredits:Notify(ply, "You do not have permission.", 1)
        return
    end

    DubzCredits.Boosts.active = {}
    DubzCredits:SaveBoosts()

    for _, p in ipairs(player.GetAll()) do
        DubzCredits:SyncBoosts(p)
    end

    if IsValid(ply) then
        DubzCredits:Notify(ply, "All active boosts have been cleared.")
    else
        print("[DubzCredits] All active boosts cleared.")
    end
end)

-------------------------------------------------
-- REMOVE A SPECIFIC BOOST
-------------------------------------------------

concommand.Add("dubz_boost_remove", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then
        DubzCredits:Notify(ply, "You do not have permission.", 1)
        return
    end

    local id = args[1]
    if not id or id == "" then
        local msg = "Usage: dubz_boost_remove <boost_id>"

        if IsValid(ply) then
            DubzCredits:Notify(ply, msg, 1)
        else
            print("[DubzCredits] " .. msg)
        end
        return
    end

    if not DubzCredits.Boosts.active[id] then
        if IsValid(ply) then
            DubzCredits:Notify(ply, "That boost is not active.", 1)
        else
            print("[DubzCredits] Boost not active:", id)
        end
        return
    end

    DubzCredits.Boosts.active[id] = nil
    DubzCredits:SaveBoosts()

    for _, p in ipairs(player.GetAll()) do
        DubzCredits:SyncBoosts(p)
    end

    if IsValid(ply) then
        DubzCredits:Notify(ply, "Removed boost: " .. id)
    else
        print("[DubzCredits] Removed boost:", id)
    end
end)

