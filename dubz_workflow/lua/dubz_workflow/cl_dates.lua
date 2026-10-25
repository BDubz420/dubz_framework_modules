DubzWorkflow.Dates = DubzWorkflow.Dates or {}

local Dates = DubzWorkflow.Dates
local DAY = 86400
local NOON = 12

Dates.DAY = DAY

function Dates.Stamp(date)
    local year, month, day = string.match(date, "^(%d+)-(%d+)-(%d+)$")

    return os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = NOON})
end

function Dates.Date(time)
    return os.date("%Y-%m-%d", time)
end

function Dates.AddDays(time, count)
    return time + count * DAY
end

function Dates.Monday(time)
    return Dates.AddDays(time, -((os.date("*t", time).wday + 5) % 7))
end

function Dates.MonthStart(time)
    local parts = os.date("*t", time)

    return os.time({year = parts.year, month = parts.month, day = 1, hour = NOON})
end

function Dates.ShiftMonth(time, amount)
    local parts = os.date("*t", time)

    return os.time({year = parts.year, month = parts.month + amount, day = 1, hour = NOON})
end

function Dates.Today()
    return Dates.Date(os.time())
end

function Dates.TwelveHour(time, seconds)
    local hour = tonumber(os.date("%I", time))

    return hour .. os.date(seconds and ":%M:%S %p" or ":%M %p", time)
end

function Dates.Clock(value)
    local hour, minute = string.match(tostring(value or ""), "^(%d%d):(%d%d)$")

    if not hour then return "" end

    local number = tonumber(hour)

    return (number % 12 == 0 and 12 or number % 12) .. ":" .. minute .. (number >= 12 and " PM" or " AM")
end

function Dates.Range(from, to)
    if not (from and to) then return "" end

    return Dates.Clock(from) .. " – " .. Dates.Clock(to)
end
