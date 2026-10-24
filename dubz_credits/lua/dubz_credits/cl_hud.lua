-------------------------------------------------
-- Dubz Credits - Active Boosts HUD
-------------------------------------------------

local boostLocalTimers = boostLocalTimers or {}

-------------------------------------------------
-- Time Formatting
-------------------------------------------------
local function FormatBoostTime(seconds)
    seconds = math.max(tonumber(seconds) or 0, 0)

    -- IMPORTANT: no format string → returns table { h, m, s }
    local t = string.FormattedTime(seconds)

    if t.h and t.h > 0 then
        return string.format("%02i:%02i:%02i", t.h, t.m, t.s)
    end

    return string.format("%02i:%02i", t.m, t.s)
end

local function CleanupLocalBoostTimers(activeBoosts)
    for id in pairs(boostLocalTimers) do
        if not activeBoosts[id] then
            boostLocalTimers[id] = nil
        end
    end
end

-------------------------------------------------
-- Remaining Time (Client Countdown)
-------------------------------------------------
local function GetBoostRemainingSeconds(id, active)
    if not active then return 0 end

    if tonumber(active.remaining) then
        local incoming = tonumber(active.remaining) or 0
        local timerData = boostLocalTimers[id]

        if not timerData
        or not timerData.initial
        or incoming > timerData.initial
        or incoming <= 0 then
            timerData = {
                start = CurTime(),
                initial = incoming
            }
            boostLocalTimers[id] = timerData
        end

        local elapsed = CurTime() - timerData.start
        return math.max(math.floor(timerData.initial - elapsed), 0)
    end

    if tonumber(active.expires) then
        return math.max(tonumber(active.expires) - os.time(), 0)
    end

    return 0
end

-------------------------------------------------
-- HUD Positioning
-------------------------------------------------
local function GetHUDPos(w, h)
    local hudCfg = DubzCredits.Config and DubzCredits.Config.HUD
    if not hudCfg then return 0, 0 end

    local x = hudCfg.XOffset or 20
    local y = hudCfg.YOffset or 120

    if hudCfg.Position == "topright" then
        x = ScrW() - w - x
    elseif hudCfg.Position == "bottomleft" then
        y = ScrH() - h - y
    elseif hudCfg.Position == "bottomright" then
        x = ScrW() - w - x
        y = ScrH() - h - y
    end

    return x, y
end

-------------------------------------------------
-- HUD Paint
-------------------------------------------------
hook.Add("HUDPaint", "DubzCredits_BoostHUD", function()
    if not DubzCredits or not DubzCredits.Enabled()
        or not DubzCredits.ActiveBoosts
        or not DubzCredits.Config
        or not DubzCredits.Config.HUD
        or not DubzCredits.Config.HUD.Enabled
    then
        return
    end

    CleanupLocalBoostTimers(DubzCredits.ActiveBoosts)

    -------------------------------------------------
    -- Build active boost list (GLOBAL + PERSONAL)
    -------------------------------------------------
    local activeList = {}

    -- =========================
    -- GLOBAL BOOSTS
    -- =========================
    for id, data in pairs(DubzCredits.ActiveBoosts or {}) do
        local remaining = GetBoostRemainingSeconds(id, data)

        if remaining > 0 then
            local cfg =
                (DubzCredits.Config.Boosts and DubzCredits.Config.Boosts[id]) or
                (DubzCredits.Config.Events and DubzCredits.Config.Events[id])

            local label = (cfg and cfg.name) or id

            -- Show multiplier for salary
            if cfg and cfg.category == "salary" and tonumber(cfg.multiplier) then
                label = string.format("%s (x%s)", label, tostring(cfg.multiplier))
            end

            activeList[#activeList + 1] = {
                id = id,
                remaining = remaining,
                label = label,
                color = Color(180, 220, 180)
            }
        end
    end

    -- =========================
    -- PERSONAL BOOSTS (STACKED)
    -- =========================
    for id, list in pairs(DubzCredits.PersonalBoosts or {}) do
        local cfg = DubzCredits.Config.PersonalBoosts and DubzCredits.Config.PersonalBoosts[id]

        for _, boost in ipairs(list) do
            local remaining = math.max((boost.expires or 0) - os.time(), 0)

            if remaining > 0 then
                local label = string.format(
                    "%s (+%s)",
                    (cfg and cfg.name) or id,
                    boost.amount or 0
                )

                activeList[#activeList + 1] = {
                    id = id,
                    remaining = remaining,
                    label = label,
                    color = Color(120, 180, 255) -- slightly different color
                }
            end
        end
    end

    if #activeList == 0 then return end

    -------------------------------------------------
    -- Layout
    -------------------------------------------------
    local w = 260
    local rowH = 22
    local headerH = 26
    local h = headerH + (#activeList * (rowH + 4)) + 6

    local x, y = GetHUDPos(w, h)

    -------------------------------------------------
    -- Background
    -------------------------------------------------
    draw.RoundedBox(6, x, y, w, h, Color(0, 0, 0, 180))

    draw.RoundedBoxEx(
        6,
        x,
        y,
        w,
        headerH,
        Color(0, 120, 60, 200),
        true, true, false, false
    )

    draw.SimpleText(
        "Active Boosts",
        "DermaDefaultBold",
        x + 10,
        y + headerH / 2,
        color_white,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    -------------------------------------------------
    -- Rows
    -------------------------------------------------
    local curY = y + headerH + 4

    for _, entry in ipairs(activeList) do
        draw.RoundedBox(4, x + 6, curY, w - 12, rowH, Color(40, 40, 40, 200))

        draw.SimpleText(
            entry.label or entry.id,
            "DermaDefault",
            x + 12,
            curY + rowH / 2,
            color_white,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )

        local formattedTime = FormatBoostTime(entry.remaining)

        draw.SimpleText(
            formattedTime,
            "DermaDefault",
            x + w - 12,
            curY + rowH / 2,
            entry.color or Color(180, 220, 180),
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )

        curY = curY + rowH + 4
    end
end)