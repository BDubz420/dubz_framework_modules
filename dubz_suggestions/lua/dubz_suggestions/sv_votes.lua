DubzSuggestions.Votes = DubzSuggestions.Votes or {}

local Votes = DubzSuggestions.Votes
local Store = DubzSuggestions.Store
local Sync = DubzSuggestions.Sync
local config = DubzSuggestions.Config

local VALID = {[-1] = true, [0] = true, [1] = true}

function Votes.Cast(ply, id, value)
    local item = Store.Get(id)

    if not (item and Sync.PublicStatus[item.status] and VALID[value]) then return false, DubzSuggestions.Phrase("ErrorVote") end

    local sid = ply:SteamID64()

    if item.author == sid and not config.AllowOwnVote then return false, DubzSuggestions.Phrase("ErrorOwnVote") end

    item.votes[sid] = value ~= 0 and value or nil
    Store.Save()
    Sync.Item(item)

    return true, nil, value
end
