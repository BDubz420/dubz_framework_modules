DubzWorkflow.Notify = DubzWorkflow.Notify or {}

local Notify = DubzWorkflow.Notify
local Store = DubzWorkflow.Store
local Staff = DubzWorkflow.Staff
local Sync = DubzWorkflow.Sync
local config = DubzWorkflow.Config
local REMINDER_TIMER = "DubzWorkflow_Reminders"

local function assignedTo(task, sid)
    for _, entry in ipairs(task.assignees or {}) do
        if entry.s == sid then return true end
    end

    return false
end

local function unseenFor(ply)
    local sid = ply:SteamID64()
    local told = Store.Person(ply).told
    local list = {}

    for _, task in ipairs(Store.All()) do
        if task.status ~= "done" and task.status ~= "pending" and assignedTo(task, sid) and told[task.id] ~= task.updatedAt then
            list[#list + 1] = task
        end
    end

    return list
end

local function markSeen(ply, list)
    local told = Store.Person(ply).told

    for _, task in ipairs(list) do told[task.id] = task.updatedAt end

    Store.Save()
end

function Notify.Unseen(ply, text)
    if not (IsValid(ply) and Staff.IsStaff(ply) and Staff.Working(ply)) then return end

    local list = unseenFor(ply)

    if #list == 0 then return end

    markSeen(ply, list)
    Sync.Notice(ply, "popup", DubzWorkflow.Phrase(text, {count = #list}), #list)
end

function Notify.Assigned(task, sids)
    for _, sid in ipairs(sids) do
        local ply = Staff.Find(sid)

        if ply and Staff.IsStaff(ply) and Staff.Working(ply) then
            markSeen(ply, {task})
            Sync.Notice(ply, "popup", DubzWorkflow.Phrase("NoticeLive", {title = task.title}), 1)
        end
    end
end

local function dueBy(task, today)
    return task.due and task.due ~= "" and task.due <= today
end

local function scheduledOn(task, today)
    for _, entry in ipairs(task.schedule or {}) do
        if entry.date == today then return true end
    end

    return false
end

local function dueCount(ply)
    local today = os.date("%Y-%m-%d")
    local sid = ply:SteamID64()
    local count = 0

    for _, task in ipairs(Store.All()) do
        local open = task.status ~= "done" and task.status ~= "pending"

        if open and assignedTo(task, sid) and (dueBy(task, today) or scheduledOn(task, today)) then count = count + 1 end
    end

    return count
end

local function remind()
    for _, ply in ipairs(player.GetAll()) do
        if Staff.IsStaff(ply) and Staff.Working(ply) then
            local count = dueCount(ply)

            if count > 0 then Sync.Notice(ply, "reminder", DubzWorkflow.Phrase("NoticeReminder", {count = count}), count) end
        end
    end
end

hook.Add("PlayerInitialSpawn", "DubzWorkflow_JoinPopup", function(ply)
    timer.Simple(config.JoinPopupDelay, function()
        if DubzWorkflow.Enabled() then Notify.Unseen(ply, "NoticeJoin") end
    end)
end)

timer.Create(REMINDER_TIMER, math.max(config.ReminderMinutes, 1) * 60, 0, function()
    if DubzWorkflow.Enabled() then remind() end
end)
