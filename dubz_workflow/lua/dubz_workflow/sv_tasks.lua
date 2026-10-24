DubzWorkflow.Tasks = DubzWorkflow.Tasks or {}

local Tasks = DubzWorkflow.Tasks
local Store = DubzWorkflow.Store
local Staff = DubzWorkflow.Staff
local config = DubzWorkflow.Config

local WORK_STATUS = {todo = true, progress = true, blocked = true, review = true}
local MANAGER_ACTIONS = {approve = true, reject = true, delete = true}

local function phrase(key, values)
    return DubzWorkflow.Phrase(key, values)
end

local function failure(key)
    return false, phrase(key)
end

local function person(ply)
    return {s = ply:SteamID64(), n = ply:Nick()}
end

local function addHistory(task, ply, key, values)
    task.history = task.history or {}
    task.history[#task.history + 1] = {at = os.time(), by = ply:Nick(), what = phrase(key, values)}

    while #task.history > config.HistoryMax do table.remove(task.history, 1) end

    task.updatedAt = os.time()
end

local function clean(value, limit)
    return string.sub(string.Trim(tostring(value or "")), 1, limit)
end

local function validDate(value)
    return value == "" or string.match(value, "^%d%d%d%d%-%d%d%-%d%d$") ~= nil
end

local function cleanTags(list)
    local tags = {}

    for _, tag in ipairs(istable(list) and list or {}) do
        local text = clean(tag, 24)

        if text ~= "" and #tags < config.TagMax then tags[#tags + 1] = text end
    end

    return tags
end

local function cleanAssignees(list)
    local result, seen = {}, {}

    for _, entry in ipairs(istable(list) and list or {}) do
        if istable(entry) and isstring(entry.s) and string.match(entry.s, "^%d+$") and #entry.s < 24 and not seen[entry.s] then
            seen[entry.s] = true
            result[#result + 1] = {s = entry.s, n = clean(entry.n, 40)}
        end
    end

    return result
end

local function cleanChecklist(list, previous)
    local done = {}

    for _, entry in ipairs(previous or {}) do done[entry.t] = entry.d end

    local result = {}

    for _, text in ipairs(istable(list) and list or {}) do
        local value = clean(text, 120)

        if value ~= "" and #result < config.ChecklistMax then result[#result + 1] = {t = value, d = done[value] == true} end
    end

    return result
end

local function cleanLinks(list)
    local result = {}

    for _, entry in ipairs(istable(list) and list or {}) do
        local kind, ref = clean(istable(entry) and entry.type, 40), clean(istable(entry) and entry.ref, 80)

        if string.match(kind, "^[%w%._%-]+$") and ref ~= "" and #result < config.LinkMax then
            result[#result + 1] = {type = kind, ref = ref}
        end
    end

    return result
end

local function validTime(value)
    local hour, minute = string.match(value, "^(%d%d):(%d%d)$")

    return hour ~= nil and tonumber(hour) < 24 and tonumber(minute) < 60
end

local function cleanSchedule(list)
    local result, seen = {}, {}

    for _, entry in ipairs(istable(list) and list or {}) do
        local date = clean(istable(entry) and entry.date, 10)
        local year, month, day = string.match(date, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

        if year and tonumber(month) >= 1 and tonumber(month) <= 12 and tonumber(day) >= 1 and tonumber(day) <= 31
            and not seen[date] and #result < config.ScheduleMax then
            local from, to = clean(entry.from, 5), clean(entry.to, 5)

            seen[date] = true
            result[#result + 1] = {
                date = date,
                from = validTime(from) and from or nil,
                to = validTime(to) and to or nil
            }
        end
    end

    table.sort(result, function(a, b) return a.date < b.date end)

    return result
end

local function priorityOf(value)
    for _, entry in ipairs(config.Priorities) do
        if entry == value then return value end
    end

    return config.DefaultPriority
end

local function apply(task, data)
    task.title = clean(data.title, config.TitleMax)
    task.summary = clean(data.summary, config.SummaryMax)
    task.priority = priorityOf(data.priority)
    task.tags = cleanTags(data.tags)
    task.assignees = cleanAssignees(data.assignees)
    task.due = clean(data.due, 10)
    task.instructions = clean(data.instructions, config.InstructionsMax)
    task.checklist = cleanChecklist(data.checklist, task.checklist)
    task.links = cleanLinks(data.links)

    local hex = string.lower(clean(data.color, 7))

    task.color = DubzWorkflow.PaletteColor(hex) and hex or nil
end

local function validate(data)
    if #clean(data.title, config.TitleMax) == 0 then return failure("ErrorTitle") end

    if not validDate(clean(data.due, 10)) then return failure("ErrorDate") end

    return true
end

local function addedAssignees(before, after)
    local had, added = {}, {}

    for _, entry in ipairs(before) do had[entry.s] = true end

    for _, entry in ipairs(after) do
        if not had[entry.s] then added[#added + 1] = entry.s end
    end

    return added
end

function Tasks.Save(ply, data)
    if not Staff.IsStaff(ply) then return failure("ErrorAccess") end

    local ok, message = validate(data)

    if not ok then return false, message end

    local manager = Staff.IsManager(ply)
    local existing = isstring(data.id) and Store.Get(data.id)

    if existing then
        if not manager then return failure("ErrorManager") end

        local before = existing.assignees or {}

        apply(existing, data)

        if WORK_STATUS[data.status] and existing.status ~= "pending" then existing.status = data.status end

        addHistory(existing, ply, "HistoryEdited")
        Store.Save()
        hook.Run("DubzWorkflowTaskChanged", existing, "edit")

        return true, phrase("Saved"), existing, addedAssignees(before, existing.assignees)
    end

    local task = {createdBy = person(ply), createdAt = os.time(), history = {}, notes = ""}

    apply(task, data)
    task.status = manager and (WORK_STATUS[data.status] and data.status or "todo") or "pending"
    Store.Add(task)
    addHistory(task, ply, manager and "HistoryCreated" or "HistorySubmitted")
    Store.Save()
    hook.Run("DubzWorkflowTaskChanged", task, "create")

    return true, phrase(manager and "Saved" or "Submitted"), task, manager and addedAssignees({}, task.assignees) or {}
end

local function canWork(ply, task)
    if Staff.IsManager(ply) then return true end

    local sid = ply:SteamID64()

    if task.claimedBy and task.claimedBy.s == sid then return true end

    for _, entry in ipairs(task.assignees or {}) do
        if entry.s == sid then return true end
    end

    return not task.claimedBy and #(task.assignees or {}) == 0
end

local function setStatus(ply, task, status)
    task.status = status
    task.doneBy, task.doneAt = nil, nil

    if status == "done" then
        task.doneBy = person(ply)
        task.doneAt = os.time()
    end

    addHistory(task, ply, "HistoryStatus", {status = DubzWorkflow.StatusLabel(status)})
end

local HANDLERS = {}

function HANDLERS.claim(ply, task)
    task.claimedBy = person(ply)
    task.claimedAt = os.time()

    if task.status == "todo" then task.status = "progress" end

    addHistory(task, ply, "HistoryClaimed")
end

function HANDLERS.unclaim(ply, task)
    task.claimedBy, task.claimedAt = nil, nil

    if task.status == "progress" then task.status = "todo" end

    addHistory(task, ply, "HistoryReleased")
end

function HANDLERS.status(ply, task, request)
    if not (WORK_STATUS[request.value] or request.value == "done") then return failure("ErrorStatus") end

    setStatus(ply, task, request.value)
end

function HANDLERS.notes(ply, task, request)
    task.notes = clean(request.value, config.NoteMax)
    addHistory(task, ply, "HistoryNotes")
end

function HANDLERS.check(ply, task, request)
    local entry = task.checklist and task.checklist[tonumber(request.index) or 0]

    if not entry then return failure("ErrorMissing") end

    entry.d = request.value == true
    addHistory(task, ply, "HistoryChecklist")
end

function HANDLERS.schedule(ply, task, request)
    if task.status == "done" then return failure("ErrorStatus") end

    task.schedule = cleanSchedule(request.value)
    addHistory(task, ply, "HistoryScheduled")
end

function HANDLERS.approve(ply, task)
    task.status = "todo"
    addHistory(task, ply, "HistoryApproved")
end

function Tasks.Act(ply, request)
    if not Staff.IsStaff(ply) then return failure("ErrorAccess") end

    local task = Store.Get(request.id)

    if not task then return failure("ErrorMissing") end

    local action = request.action

    if MANAGER_ACTIONS[action] and not Staff.IsManager(ply) then return failure("ErrorManager") end

    if action == "delete" or action == "reject" then
        Store.Remove(task.id)
        Store.Save()
        hook.Run("DubzWorkflowTaskChanged", task, "delete")

        return true, phrase("Deleted"), task, {}, true
    end

    local handler = HANDLERS[action]

    if not handler then return failure("ErrorStatus") end

    if not canWork(ply, task) then return failure("ErrorAccess") end

    if task.status == "pending" and action ~= "approve" then return failure("ErrorStatus") end

    local ok, message = handler(ply, task, request)

    if ok == false then return false, message end

    Store.Save()
    hook.Run("DubzWorkflowTaskChanged", task, action)

    return true, phrase("Updated"), task, {}
end
