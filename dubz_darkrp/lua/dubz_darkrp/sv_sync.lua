DubzDarkRP.Sync = DubzDarkRP.Sync or {}

local Sync = DubzDarkRP.Sync
local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds
local Store = DubzDarkRP.Store

function Sync.Payload(kind, id)
    local engine = Kinds.Engine(kind)
    local entry = engine.Get(id)

    if not entry then return nil end

    return {kind = kind, id = id, index = engine.Index(id), data = Fields.Extract(entry, kind), disabled = entry.dubzDisabled == true}
end

local function send(name, data)
    DFW.Net.Start(name)

    local ok, reason = DFW.Net.WriteJSON(data)

    if not ok then
        DubzDarkRP.Report("could not send " .. name .. ": " .. tostring(reason))
        return false
    end

    return true
end

function Sync.Delta(kind, id)
    local payload = Sync.Payload(kind, id)

    if payload and send("drp_job", payload) then net.Broadcast() end
end

function Sync.Snapshot(ply)
    local items = {}

    for _, kind in ipairs(Kinds.ReplayOrder) do
        for _, id in ipairs(Store.Ids(kind)) do
            local payload = Sync.Payload(kind, id)

            if payload then items[#items + 1] = payload end
        end
    end

    if send("drp_sync", {items = items}) then net.Send(ply) end
end

function Sync.Result(ply, ok, message)
    if send("drp_result", {ok = ok, message = message}) then net.Send(ply) end
end

function Sync.Open(ply, kind)
    if send("drp_open", {kind = kind}) then net.Send(ply) end
end
