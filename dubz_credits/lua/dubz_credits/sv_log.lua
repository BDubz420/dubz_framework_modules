DubzCredits = DubzCredits or {}
DubzCredits.LogLevel = DubzCredits.LogLevel or "info"
-- Levels: info, warn, error, debug

local LEVELS = {
    info  = 1,
    warn  = 2,
    error = 3,
    debug = 0
}

local function ShouldLog(level)
    return LEVELS[level] >= LEVELS[DubzCredits.LogLevel]
end

local function Prefix(level)
    return "[DubzCredits][" .. string.upper(level) .. "] "
end

-------------------------------------------------
-- CORE LOGGER
-------------------------------------------------
function DubzCredits:Log(level, msg)
    level = level or "info"
    msg = tostring(msg or "")

    if not ShouldLog(level) then return end

    -- Console output
    print(Prefix(level) .. msg)

    -- Optional file logging
    if level == "error" or level == "warn" then
        file.CreateDir("dubz_credits")
        file.Append(
            "dubz_credits/log.txt",
            os.date("[%Y-%m-%d %H:%M:%S] ") .. Prefix(level) .. msg .. "\n"
        )
    end
end

-------------------------------------------------
-- SHORTCUTS
-------------------------------------------------
function DubzCredits:LogInfo(msg)
    self:Log("info", msg)
end

function DubzCredits:LogWarn(msg)
    self:Log("warn", msg)
end

function DubzCredits:LogError(msg)
    self:Log("error", msg)
end

function DubzCredits:LogDebug(msg)
    self:Log("debug", msg)
end
