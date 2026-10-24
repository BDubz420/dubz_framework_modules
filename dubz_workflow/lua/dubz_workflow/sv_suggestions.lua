local Store = DubzWorkflow.Store
local Sync = DubzWorkflow.Sync
local Staff = DubzWorkflow.Staff
local config = DubzWorkflow.Config
local SMALL_BITS = 8
local JSON_BITS = 8 * 1024
local REQUEST_COOLDOWN = 1
local ACTION_COOLDOWN = 0.3
local LINK_TYPE = "suggestion"
local LISTED = {pending = true, new = true, review = true, planned = true, done = true}
local ACTIONS = {approve = true, reject = true, hide = true, review = true, planned = true, done = true, reopen = true}

local watchers = {}

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function installed()
    return DubzSuggestions and DubzSuggestions.Store and DubzSuggestions.Sync and DubzSuggestions.Sync.StaffView
        and DubzSuggestions.Moderate and true or false
end

local function taskFor(id)
    for _, task in ipairs(Store.All()) do
        for _, link in ipairs(task.links or {}) do
            if link.type == LINK_TYPE and link.ref == id then return task.id end
        end
    end
end

local function payload()
    local list = {}

    for _, item in ipairs(DubzSuggestions.Store.All()) do
        if LISTED[item.status] then
            local row = DubzSuggestions.Sync.StaffView(item)

            row.task = taskFor(item.id)
            list[#list + 1] = row
        end
    end

    return {items = list}
end

local function broadcast()
    if not installed() then return end

    local targets = {}

    for ply in pairs(watchers) do
        if IsValid(ply) and Staff.IsStaff(ply) then targets[#targets + 1] = ply else watchers[ply] = nil end
    end

    if #targets > 0 then Sync.Send("wf_sugs", payload(), targets) end
end

local function allowed(ply)
    if not (DubzWorkflow.Enabled() and Staff.IsStaff(ply)) then
        Sync.Result(ply, false, phrase(DubzWorkflow.Enabled() and "ErrorAccess" or "ErrorDisabled"))
        return false
    end

    if not installed() then
        Sync.Result(ply, false, phrase("ErrorSuggestionsOff"))
        return false
    end

    return true
end

local function starterInstructions(row)
    return table.concat({
        "# Suggestion",
        row.body,
        "# From",
        row.author .. " (" .. row.topic .. ")"
    }, "\n")
end

local function convert(ply, id)
    local item = DubzSuggestions.Store.Get(id)

    if not item then return false, phrase("ErrorSuggestion") end

    if taskFor(id) then return false, phrase("ErrorSuggestionTask") end

    local row = DubzSuggestions.Sync.StaffView(item)
    local ok, message, task = DubzWorkflow.Tasks.Save(ply, {
        title = row.title,
        summary = phrase("SuggestFrom", {author = row.author, topic = row.topic, score = row.score}),
        priority = config.DefaultPriority,
        instructions = starterInstructions(row),
        links = {{type = LINK_TYPE, ref = id}},
        tags = {"suggestion", row.topic}
    })

    if not ok then return false, message end

    Sync.Task(task)

    if config.ConvertSetsPlanned and item.status ~= "pending" then DubzSuggestions.Moderate.Apply(ply, id, "planned") end

    broadcast()

    return true, phrase("SuggestTaskCreated")
end

DFW.Net.Receive("wf_sugreq", function(_, ply)
    if not (DubzWorkflow.Enabled() and Staff.IsStaff(ply) and installed()) then return end

    watchers[ply] = true
    Sync.Send("wf_sugs", payload(), ply)
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN})

DFW.Net.Receive("wf_sugact", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and ACTIONS[request.action] and allowed(ply)) then return end

    local ok, message = DubzSuggestions.Moderate.Apply(ply, request.id, request.action)

    Sync.Result(ply, ok, message)
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})

DFW.Net.Receive("wf_sugtask", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and allowed(ply)) then return end

    if not Staff.IsManager(ply) then
        Sync.Result(ply, false, phrase("ErrorManager"))
        return
    end

    Sync.Result(ply, convert(ply, request.id))
end, {maxBits = JSON_BITS, cooldown = ACTION_COOLDOWN})

hook.Add("DubzSuggestionsSubmitted", "DubzWorkflow_SuggestionsBridge", broadcast)
hook.Add("DubzSuggestionsChanged", "DubzWorkflow_SuggestionsBridge", broadcast)
hook.Add("DubzWorkflowTaskChanged", "DubzWorkflow_SuggestionsBridge", broadcast)

hook.Add("PlayerDisconnected", "DubzWorkflow_SuggestionWatchers", function(ply)
    watchers[ply] = nil
end)
