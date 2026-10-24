local config = DubzSuggestions.Config
local Sync = DubzSuggestions.Sync
local SMALL_BITS = 8
local JSON_BITS = 8 * 4096
local REQUEST_COOLDOWN = 1
local SUBMIT_COOLDOWN = 1
local MODERATE_COOLDOWN = 0.3

DFW.Net.Receive("sg_request", function(_, ply)
    Sync.Subscribe(ply)
    Sync.State(ply)
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN})

DFW.Net.Receive("sg_close", function(_, ply)
    Sync.Unsubscribe(ply)
end, {maxBits = SMALL_BITS})

DFW.Net.Receive("sg_submit", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not istable(request) then return end

    local ok, message = DubzSuggestions.Suggest.Create(ply, request)

    Sync.Result(ply, ok, message)
end, {maxBits = JSON_BITS, cooldown = SUBMIT_COOLDOWN})

DFW.Net.Receive("sg_vote", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and isnumber(request.value)) then return end

    local ok, message, value = DubzSuggestions.Votes.Cast(ply, request.id, request.value)

    if ok then Sync.Result(ply, true, nil, {id = request.id, myVote = value}) else Sync.Result(ply, false, message) end
end, {maxBits = JSON_BITS, cooldown = config.VoteCooldown})

DFW.Net.Receive("sg_admin", function(_, ply)
    if DubzSuggestions.CanModerate(ply) then Sync.Admin(ply) end
end, {maxBits = SMALL_BITS, cooldown = REQUEST_COOLDOWN})

DFW.Net.Receive("sg_moderate", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.id) and isstring(request.action)) then return end

    local ok, message = DubzSuggestions.Moderate.Apply(ply, request.id, request.action)

    Sync.Result(ply, ok, message)

    if ok then Sync.Admin(ply) end
end, {maxBits = JSON_BITS, cooldown = MODERATE_COOLDOWN})
