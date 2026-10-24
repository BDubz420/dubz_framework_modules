DubzF4.Jobs = DubzF4.Jobs or {}

local Jobs = DubzF4.Jobs
local Adapter = DubzF4.Adapter
local CHECK_INTERVAL = 0.4
local ADMIN_LEVEL = 1
local SUPERADMIN_LEVEL = 2

function Jobs.Max(job)
    local max = job.max or 0

    if max > 0 and max < 1 then max = math.ceil(max * #player.GetAll()) end

    return max
end

local function staffLock(job, ply)
    if job.admin == ADMIN_LEVEL and not ply:IsAdmin() then return DubzF4.Phrase("AdminOnly") end
    if job.admin == SUPERADMIN_LEVEL and not ply:IsSuperAdmin() then return DubzF4.Phrase("SuperadminOnly") end
end

local function customFailure(job, ply)
    local message = job.CustomCheckFailMsg

    if isfunction(message) then message = Adapter.Safe(message, ply, job) end

    return isstring(message) and message or DubzF4.Phrase("Locked")
end

function Jobs.Evaluate(job, id)
    local ply = LocalPlayer()

    if ply:Team() == id then return false, DubzF4.Phrase("CurrentJob"), true end

    local locked = staffLock(job, ply)

    if locked then return false, locked end

    if job.NeedToChangeFrom and not Adapter.TeamMatch(job.NeedToChangeFrom, ply:Team()) then
        return false, DubzF4.Phrase("RequiresJob")
    end

    if job.customCheck and not Adapter.Safe(job.customCheck, ply) then return false, customFailure(job, ply) end

    local max = Jobs.Max(job)

    if max > 0 and team.NumPlayers(id) >= max then return false, DubzF4.Phrase("JobFull") end

    local allowed, reason = hook.Run("DubzF4CanUseJob", ply, job, id)

    if allowed == false then return false, reason or DubzF4.Phrase("Locked") end

    return true
end

function Jobs.State(entry)
    if (entry.nextCheck or 0) < CurTime() then
        entry.ok, entry.reason, entry.current = Jobs.Evaluate(entry.job, entry.id)
        entry.nextCheck = CurTime() + CHECK_INTERVAL
    end

    return entry.ok, entry.reason, entry.current
end

Jobs.Chosen = Jobs.Chosen or {}

local function announceModel(id, job)
    local models = Adapter.JobModels(job)
    local choice = Jobs.Chosen[id]

    if #models < 2 or not (choice and table.HasValue(models, choice)) then return end

    DFW.Net.Start("f4_model")
    net.WriteString(job.command)
    net.WriteString(choice)
    net.SendToServer()
end

function Jobs.Become(id, job)
    announceModel(id, job)

    local needsVote = job.vote or (job.RequiresVote and Adapter.Safe(job.RequiresVote, LocalPlayer(), id))

    Adapter.Run(needsVote and ("vote" .. job.command) or job.command)
    DubzF4.Close()
end

function Jobs.Entries(filter)
    local categories, order = {}, {}

    for id, job in SortedPairs(Adapter.Jobs()) do
        local category = job.category or DubzF4.Phrase("OtherCategory")
        local name = string.lower(job.name or "")

        local visible = filter == "" or string.find(name, filter, 1, true) or string.find(string.lower(category), filter, 1, true)

        if visible and not job.dubzDisabled then
            if not categories[category] then
                categories[category] = {}
                order[#order + 1] = category
            end

            table.insert(categories[category], {id = id, job = job})
        end
    end

    return categories, order
end

concommand.Add("dubz_f4_jobs", function()
    for index, job in ipairs(Adapter.Jobs()) do
        print(string.format("%3d  %-18s removed=%s  %s", index, tostring(job.dubzId), tostring(job.dubzDisabled == true), tostring(job.name)))
    end
end)
