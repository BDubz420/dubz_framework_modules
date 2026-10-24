DubzSuggestions.Sync = DubzSuggestions.Sync or {}

local Sync = DubzSuggestions.Sync
local Store = DubzSuggestions.Store
local Topics = DubzSuggestions.Topics
local config = DubzSuggestions.Config

local subscribers = {}

Sync.PublicStatus = {new = true, review = true, planned = true, done = true}

local function send(name, data, target)
    DFW.Net.Start(name)

    local ok, reason = DFW.Net.WriteJSON(data)

    if not ok then
        DubzSuggestions.Report("could not send " .. name .. ": " .. tostring(reason))
        return false
    end

    net.Send(target)

    return true
end

local function liveSubscribers()
    local list = {}

    for ply in pairs(subscribers) do
        if IsValid(ply) then list[#list + 1] = ply else subscribers[ply] = nil end
    end

    return list
end

function Sync.Score(item)
    local total = 0

    for _, value in pairs(item.votes) do total = total + value end

    return total
end

function Sync.TopicLabel(item)
    return Topics.Label(item.topic) or item.topicLabel or item.topic
end

function Sync.Public(item, viewer)
    return {
        id = item.id,
        title = item.title,
        body = item.body,
        topic = Sync.TopicLabel(item),
        author = item.anonymous and DubzSuggestions.Phrase("AnonymousName") or item.authorName,
        status = item.status,
        score = Sync.Score(item),
        myVote = viewer and item.votes[viewer:SteamID64()] or 0,
        reply = item.reply,
        createdAt = item.createdAt
    }
end

function Sync.State(ply)
    local list = {}

    for _, item in ipairs(Store.All()) do
        if Sync.PublicStatus[item.status] then list[#list + 1] = Sync.Public(item, ply) end
    end

    send("sg_state", {
        topics = Topics.List(),
        items = list,
        settings = {anonymous = config.AllowAnonymous, custom = config.AllowCustomTopic}
    }, ply)
end

function Sync.Subscribe(ply)
    subscribers[ply] = true
end

function Sync.Unsubscribe(ply)
    subscribers[ply] = nil
end

function Sync.Item(item)
    local targets = liveSubscribers()

    if #targets == 0 then return end

    local payload = Sync.Public(item)

    payload.myVote = nil

    send("sg_item", payload, targets)
end

function Sync.Remove(id)
    local targets = liveSubscribers()

    if #targets > 0 then send("sg_remove", {id = id}, targets) end
end

function Sync.Result(ply, ok, message, extra)
    local payload = extra or {}

    payload.ok = ok
    payload.message = message

    send("sg_result", payload, ply)
end

local function adminAuthor(item)
    if item.anonymous and config.HideAuthorFromStaff then return DubzSuggestions.Phrase("AnonymousName"), "" end

    return item.authorName, item.author
end

function Sync.StaffView(item)
    local author, steam = adminAuthor(item)

    return {
        id = item.id, title = item.title, body = item.body, topic = Sync.TopicLabel(item), author = author,
        steam = steam, anonymous = item.anonymous, status = item.status, score = Sync.Score(item),
        createdAt = item.createdAt
    }
end

function Sync.Admin(ply)
    local list = {}

    for _, item in ipairs(Store.All()) do list[#list + 1] = Sync.StaffView(item) end

    send("sg_adminlist", {items = list}, ply)
end

function Sync.Open(ply, adminWindow)
    send(adminWindow and "sg_openadmin" or "sg_open", {}, ply)
end

hook.Add("PlayerDisconnected", "DubzSuggestions_Subscribers", function(ply)
    subscribers[ply] = nil
end)
