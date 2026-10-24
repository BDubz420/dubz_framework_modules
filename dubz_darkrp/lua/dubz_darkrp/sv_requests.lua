local config = DubzDarkRP.Config
local Edit = DubzDarkRP.Edit
local Sync = DubzDarkRP.Sync
local EDIT_BITS = 8 * 8192
local SYNC_BITS = 8

local ACTIONS = {
    save = function(ply, request) return Edit.Save(ply, request.kind, request.id, istable(request.data) and request.data or {}) end,
    remove = function(ply, request) return Edit.Remove(ply, request.kind, request.id) end,
    restore = function(ply, request) return Edit.Restore(ply, request.kind, request.id) end
}

DFW.Net.Receive("drp_sync", function(_, ply)
    Sync.Snapshot(ply)
end, {maxBits = SYNC_BITS, cooldown = config.SyncCooldown})

DFW.Net.Receive("drp_edit", function(_, ply)
    local request = DFW.Net.ReadJSON()

    if not (istable(request) and isstring(request.action) and isstring(request.kind)) then return end
    if request.id ~= nil and not isstring(request.id) then return end

    local run = ACTIONS[request.action]

    if not run then return end

    local ok, message = run(ply, request)

    Sync.Result(ply, ok, message)
end, {maxBits = EDIT_BITS, cooldown = config.EditCooldown, access = DubzDarkRP.CanManage})
