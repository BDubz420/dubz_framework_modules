local config = DubzF4.Config
local MAX_BITS = 8 * 400
local COOLDOWN = 0.5

local choices = {}

local function jobByCommand(command)
    for _, job in pairs(RPExtraTeams or {}) do
        if job.command == command then return job end
    end
end

local function modelsOf(job)
    return istable(job.model) and job.model or {job.model}
end

DFW.Net.Receive("f4_model", function(_, ply)
    local command = net.ReadString()
    local model = net.ReadString()
    local job = jobByCommand(command)

    if not (job and table.HasValue(modelsOf(job), model)) then return end

    choices[ply] = {command = command, model = model, expires = CurTime() + config.ModelChoiceSeconds}
end, {maxBits = MAX_BITS, cooldown = COOLDOWN})

hook.Add("PlayerSetModel", "DubzF4_ChosenModel", function(ply)
    local choice = choices[ply]

    if not choice or CurTime() > choice.expires then return end

    local job = RPExtraTeams and RPExtraTeams[ply:Team()]

    if job and job.command == choice.command then return choice.model end
end)

hook.Add("PlayerDisconnected", "DubzF4_ChosenModel", function(ply)
    choices[ply] = nil
end)
