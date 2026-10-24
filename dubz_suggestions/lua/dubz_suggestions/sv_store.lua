DubzSuggestions.Store = DubzSuggestions.Store or {}

local Store = DubzSuggestions.Store
local DATA_FILE = "dubz_suggestions/list"
local VERSION = 1
local SAVE_DELAY = 2
local SAVE_TIMER = "DubzSuggestions_Save"

local items = {}
local order = {}
local nextId = 1

Store.OpenStatuses = {pending = true, new = true, review = true, planned = true}

local function toRow(item)
    local votes = {}

    for sid, value in pairs(item.votes) do votes[#votes + 1] = {s = sid, v = value} end

    return {
        id = item.id, title = item.title, body = item.body, topic = item.topic, topicLabel = item.topicLabel,
        author = item.author, authorName = item.authorName, anonymous = item.anonymous, createdAt = item.createdAt,
        status = item.status, reply = item.reply, votes = votes
    }
end

local function fromRow(row)
    local votes = {}

    for _, vote in ipairs(istable(row.votes) and row.votes or {}) do
        if isstring(vote.s) and (vote.v == 1 or vote.v == -1) then votes[vote.s] = vote.v end
    end

    row.votes = votes
    row.reply = row.reply or ""

    return row
end

function Store.Load()
    local saved = DFW.Data.ReadJSON(DATA_FILE, {})
    local highest = 0

    items, order = {}, {}

    for _, row in ipairs(istable(saved.items) and saved.items or {}) do
        if isstring(row.id) and isstring(row.title) and isstring(row.body) then
            items[row.id] = fromRow(row)
            order[#order + 1] = row.id
            highest = math.max(highest, tonumber(string.sub(row.id, 2)) or 0)
        end
    end

    nextId = math.max(tonumber(saved.nextId) or 1, highest + 1)
end

function Store.SaveNow()
    local rows = {}

    for _, id in ipairs(order) do rows[#rows + 1] = toRow(items[id]) end

    local ok, reason = DFW.Data.WriteJSON(DATA_FILE, {version = VERSION, nextId = nextId, items = rows})

    if not ok then DubzSuggestions.Report("could not save suggestions: " .. tostring(reason)) end

    return ok
end

function Store.Save()
    timer.Create(SAVE_TIMER, SAVE_DELAY, 1, Store.SaveNow)
end

function Store.Get(id)
    return items[id]
end

function Store.All()
    local list = {}

    for _, id in ipairs(order) do list[#list + 1] = items[id] end

    return list
end

function Store.Add(item)
    item.id = "s" .. nextId
    nextId = nextId + 1
    items[item.id] = item
    order[#order + 1] = item.id

    return item
end

function Store.Remove(id)
    items[id] = nil

    for index, value in ipairs(order) do
        if value == id then
            table.remove(order, index)
            break
        end
    end
end

function Store.CountOpenBy(sid)
    local count = 0

    for _, item in pairs(items) do
        if item.author == sid and Store.OpenStatuses[item.status] then count = count + 1 end
    end

    return count
end

Store.Load()

hook.Add("ShutDown", "DubzSuggestions_Save", Store.SaveNow)
