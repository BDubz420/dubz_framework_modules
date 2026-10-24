DubzWorkflow.Store = DubzWorkflow.Store or {}

local Store = DubzWorkflow.Store
local TASK_FILE = "dubz_workflow/tasks"
local PEOPLE_FILE = "dubz_workflow/people"
local VERSION = 1
local SAVE_DELAY = 2
local SAVE_TIMER = "DubzWorkflow_Save"

local tasks = {}
local order = {}
local people = {}
local nextId = 1

function Store.Load()
    local saved = DFW.Data.ReadJSON(TASK_FILE, {})
    local highest = 0

    tasks, order = {}, {}

    for _, row in ipairs(istable(saved.tasks) and saved.tasks or {}) do
        if isstring(row.id) and isstring(row.title) then
            tasks[row.id] = row
            order[#order + 1] = row.id
            highest = math.max(highest, tonumber(string.sub(row.id, 2)) or 0)
        end
    end

    nextId = math.max(tonumber(saved.nextId) or 1, highest + 1)

    local saw = DFW.Data.ReadJSON(PEOPLE_FILE, {})

    people = {}

    for _, row in ipairs(istable(saw.people) and saw.people or {}) do
        if isstring(row.s) then
            local told = {}

            for _, entry in ipairs(istable(row.told) and row.told or {}) do
                if isstring(entry.id) then told[entry.id] = entry.u end
            end

            people[row.s] = {s = row.s, n = row.n or "", working = row.working ~= false, told = told}
        end
    end
end

function Store.SaveNow()
    local rows, folk = {}, {}

    for _, id in ipairs(order) do rows[#rows + 1] = tasks[id] end

    for _, person in pairs(people) do
        local told = {}

        for id, stamp in pairs(person.told) do told[#told + 1] = {id = id, u = stamp} end

        folk[#folk + 1] = {s = person.s, n = person.n, working = person.working, told = told}
    end

    local ok, reason = DFW.Data.WriteJSON(TASK_FILE, {version = VERSION, nextId = nextId, tasks = rows})
    local okPeople = DFW.Data.WriteJSON(PEOPLE_FILE, {version = VERSION, people = folk})

    if not ok then DubzWorkflow.Report("could not save tasks: " .. tostring(reason)) end

    return ok and okPeople
end

function Store.Save()
    timer.Create(SAVE_TIMER, SAVE_DELAY, 1, Store.SaveNow)
end

function Store.Get(id)
    return tasks[id]
end

function Store.All()
    local list = {}

    for _, id in ipairs(order) do list[#list + 1] = tasks[id] end

    return list
end

function Store.Add(task)
    task.id = "t" .. nextId
    nextId = nextId + 1
    tasks[task.id] = task
    order[#order + 1] = task.id

    return task
end

function Store.Remove(id)
    tasks[id] = nil

    for index, value in ipairs(order) do
        if value == id then
            table.remove(order, index)
            break
        end
    end
end

function Store.Person(ply)
    local sid = ply:SteamID64()
    local person = people[sid]

    if not person then
        person = {s = sid, n = ply:Nick(), working = DubzWorkflow.Config.DefaultWorking, told = {}}
        people[sid] = person
    end

    person.n = ply:Nick()

    return person
end

Store.Load()

hook.Add("ShutDown", "DubzWorkflow_Save", Store.SaveNow)
