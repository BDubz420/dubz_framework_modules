DubzSuggestions.Moderate = DubzSuggestions.Moderate or {}

local Moderate = DubzSuggestions.Moderate
local Store = DubzSuggestions.Store
local Sync = DubzSuggestions.Sync

local TRANSITIONS = {
    approve = "new",
    reopen = "new",
    reject = "declined",
    hide = "hidden",
    review = "review",
    planned = "planned",
    done = "done"
}

function Moderate.Apply(ply, id, action)
    if not DubzSuggestions.CanModerate(ply) then return false, DubzSuggestions.Phrase("ErrorAccess") end

    local item = Store.Get(id)

    if not item then return false, DubzSuggestions.Phrase("ErrorMissing") end

    if action == "delete" then
        Store.Remove(id)
        Store.Save()
        Sync.Remove(id)
        hook.Run("DubzSuggestionsChanged", id, "delete")

        return true, DubzSuggestions.Phrase("Deleted")
    end

    local status = TRANSITIONS[action]

    if not status then return false, DubzSuggestions.Phrase("ErrorVote") end

    local wasPublic = Sync.PublicStatus[item.status]

    item.status = status
    Store.Save()

    if Sync.PublicStatus[status] then Sync.Item(item) elseif wasPublic then Sync.Remove(id) end

    hook.Run("DubzSuggestionsChanged", id, action)

    return true, DubzSuggestions.Phrase("Moderated")
end
