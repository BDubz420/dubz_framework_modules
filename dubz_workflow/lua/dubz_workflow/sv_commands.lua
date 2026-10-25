local config = DubzWorkflow.Config
local Store = DubzWorkflow.Store
local Staff = DubzWorkflow.Staff
local Sync = DubzWorkflow.Sync

local function commandSet()
    local set = {}

    for _, command in ipairs(DubzWorkflow.List("chat_commands")) do set[string.lower(command)] = true end

    return set
end

local function open(ply)
    if not DubzWorkflow.Enabled() then
        Sync.Result(ply, false, DubzWorkflow.Phrase("ErrorDisabled"))
    elseif not Staff.IsStaff(ply) then
        Sync.Result(ply, false, DubzWorkflow.Phrase("ErrorAccess"))
    else
        Sync.Open(ply)
    end
end

hook.Add("PlayerSay", "DubzWorkflow_Chat", function(ply, text)
    if not commandSet()[string.lower(string.Trim(text))] then return end

    open(ply)

    return ""
end)

concommand.Add(config.ConsoleCommand, function(ply)
    if IsValid(ply) then open(ply) end
end)

concommand.Add("dubz_workflow_status", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local counts = {}

    for _, task in ipairs(Store.All()) do counts[task.status] = (counts[task.status] or 0) + 1 end

    local lines = {"enabled: " .. tostring(DubzWorkflow.Enabled()), "tasks: " .. #Store.All(), "staff online: " .. #Staff.Online()}

    for status, count in SortedPairs(counts) do lines[#lines + 1] = status .. ": " .. count end

    for _, line in ipairs(lines) do
        local text = "[DubzWorkflow] " .. line

        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n") else print(text) end
    end
end)
