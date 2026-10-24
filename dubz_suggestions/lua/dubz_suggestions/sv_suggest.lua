DubzSuggestions.Suggest = DubzSuggestions.Suggest or {}

local Suggest = DubzSuggestions.Suggest
local Store = DubzSuggestions.Store
local Sync = DubzSuggestions.Sync
local Topics = DubzSuggestions.Topics
local config = DubzSuggestions.Config

local lastSubmitted = {}

local function failure(key, values)
    return false, DubzSuggestions.Phrase(key, values)
end

local function clean(value, limit)
    return string.sub(string.Trim(tostring(value or "")), 1, limit)
end

local function filtered(title, body)
    local text = string.lower(title .. " " .. body)

    for _, word in ipairs(config.WordFilter) do
        if word ~= "" and string.find(text, word, 1, true) then return true end
    end

    return false
end

local function resolveTopic(raw)
    local label = Topics.Label(raw)

    if label then return raw, label end

    if not (config.AllowCustomTopic and Topics.IsCustom(raw)) then return nil end

    local text = clean(Topics.CustomText(raw), config.TopicMax)

    if text == "" then return nil end

    return Topics.CustomId(text), text
end

local function cooldownLeft(ply)
    local ready = (lastSubmitted[ply] or 0) + config.CooldownSeconds

    return math.ceil(math.max(ready - CurTime(), 0))
end

function Suggest.Create(ply, request)
    if not DubzSuggestions.Enabled() then return failure("ErrorDisabled") end

    local title = clean(request.title, config.TitleMax)
    local body = clean(request.body, config.BodyMax)
    local topic, label = resolveTopic(tostring(request.topic or ""))

    if #title < config.TitleMin then return failure("ErrorTitle", {min = config.TitleMin, max = config.TitleMax}) end
    if #body < config.BodyMin then return failure("ErrorBody", {min = config.BodyMin, max = config.BodyMax}) end
    if not topic then return failure("ErrorTopic") end

    local wait = cooldownLeft(ply)

    if wait > 0 then return failure("ErrorCooldown", {seconds = wait}) end
    if Store.CountOpenBy(ply:SteamID64()) >= config.MaxOpenPerPlayer then return failure("ErrorLimit", {max = config.MaxOpenPerPlayer}) end

    local approved = config.AutoApprove and not filtered(title, body)
    local item = Store.Add({
        title = title,
        body = body,
        topic = topic,
        topicLabel = label,
        author = ply:SteamID64(),
        authorName = ply:Nick(),
        anonymous = config.AllowAnonymous and request.anonymous == true,
        createdAt = os.time(),
        status = approved and "new" or "pending",
        votes = {},
        reply = ""
    })

    lastSubmitted[ply] = CurTime()
    Store.SaveNow()
    DubzSuggestions.Staff.Ping()

    if approved then Sync.Item(item) end

    hook.Run("DubzSuggestionsSubmitted", item)

    return true, DubzSuggestions.Phrase(approved and "SubmittedPublic" or "Submitted")
end

hook.Add("PlayerDisconnected", "DubzSuggestions_Cooldown", function(ply)
    lastSubmitted[ply] = nil
end)
