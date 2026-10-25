DubzWorkflow.Staff = DubzWorkflow.Staff or {}

local Staff = DubzWorkflow.Staff
local Store = DubzWorkflow.Store
local config = DubzWorkflow.Config

local function listed(list, value)
    value = string.lower(value)

    for _, entry in ipairs(list) do
        if string.lower(entry) == value then return true end
    end

    return false
end

function Staff.IsStaff(ply)
    if not IsValid(ply) then return false end

    local custom = hook.Run("DubzWorkflowIsStaff", ply)

    if custom ~= nil then return custom == true end

    if listed(DubzWorkflow.List("staff_steamids"), ply:SteamID64()) then return true end

    if config.StaffMode == "ranks" then return listed(DubzWorkflow.List("staff_ranks"), ply:GetUserGroup()) end

    return ply:IsAdmin()
end

function Staff.IsManager(ply)
    if not Staff.IsStaff(ply) then return false end

    return ply:IsSuperAdmin() or listed(DubzWorkflow.List("manager_ranks"), ply:GetUserGroup())
end

function Staff.Working(ply)
    return Store.Person(ply).working == true
end

function Staff.SetWorking(ply, working)
    Store.Person(ply).working = working == true
    Store.Save()
end

function Staff.Online()
    local list = {}

    for _, ply in ipairs(player.GetAll()) do
        if Staff.IsStaff(ply) then
            list[#list + 1] = {s = ply:SteamID64(), n = ply:Nick(), working = Staff.Working(ply)}
        end
    end

    return list
end

function Staff.Find(sid)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == sid then return ply end
    end
end

hook.Add("DubzWorkflowIsWorking", "DubzWorkflow_Presence", function(ply)
    if Staff.IsStaff(ply) then return Staff.Working(ply) end
end)
