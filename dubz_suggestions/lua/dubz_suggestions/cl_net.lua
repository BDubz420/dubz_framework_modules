DubzSuggestions.State = DubzSuggestions.State or {Topics = {}, Items = {}, Admin = {}, Settings = {}, Loaded = false}
DubzSuggestions.Client = DubzSuggestions.Client or {}

local State = DubzSuggestions.State
local Client = DubzSuggestions.Client
local PING_SOUND = "buttons/button15.wav"

local function send(name, data)
    DFW.Net.Start(name)

    if data then DFW.Net.WriteJSON(data) end

    net.SendToServer()
end

function Client.Find(id)
    for _, item in ipairs(State.Items) do
        if item.id == id then return item end
    end
end

function Client.Request() send("sg_request") end
function Client.Close() send("sg_close") end
function Client.RequestAdmin() send("sg_admin") end
function Client.Submit(data) send("sg_submit", data) end
function Client.Vote(id, value) send("sg_vote", {id = id, value = value}) end
function Client.Moderate(id, action) send("sg_moderate", {id = id, action = action}) end

DFW.Net.Receive("sg_state", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    State.Topics = payload.topics or {}
    State.Items = payload.items or {}
    State.Settings = payload.settings or {}
    State.Loaded = true
    hook.Run("DubzSuggestionsState")
end)

DFW.Net.Receive("sg_item", function()
    local payload = DFW.Net.ReadJSON()

    if not (istable(payload) and isstring(payload.id)) then return end

    local existing = Client.Find(payload.id)

    if existing then
        payload.myVote = existing.myVote
        table.Empty(existing)
        table.Merge(existing, payload)
    else
        payload.myVote = 0
        State.Items[#State.Items + 1] = payload
    end

    hook.Run("DubzSuggestionsState")
end)

DFW.Net.Receive("sg_remove", function()
    local payload = DFW.Net.ReadJSON()

    if not (istable(payload) and isstring(payload.id)) then return end

    for index, item in ipairs(State.Items) do
        if item.id == payload.id then
            table.remove(State.Items, index)
            break
        end
    end

    hook.Run("DubzSuggestionsState")
end)

DFW.Net.Receive("sg_result", function()
    local payload = DFW.Net.ReadJSON()

    if not istable(payload) then return end

    local item = isstring(payload.id) and Client.Find(payload.id)

    if item and isnumber(payload.myVote) then item.myVote = payload.myVote end

    if payload.message then DFW.UI.Notify(payload.message, payload.ok and "success" or "danger") end

    if payload.ok == false and payload.message then Client.Request() end

    hook.Run("DubzSuggestionsResult", payload.ok == true, payload.message, payload)
end)

DFW.Net.Receive("sg_adminlist", function()
    local payload = DFW.Net.ReadJSON()

    State.Admin = istable(payload) and payload.items or {}
    hook.Run("DubzSuggestionsAdmin")
end)

DFW.Net.Receive("sg_ping", function()
    surface.PlaySound(PING_SOUND)
    DFW.UI.Notify(DubzSuggestions.Phrase("Ping"), "info")
end)

DFW.Net.Receive("sg_open", function() DubzSuggestions.Open() end)
DFW.Net.Receive("sg_openadmin", function() DubzSuggestions.OpenAdmin() end)
