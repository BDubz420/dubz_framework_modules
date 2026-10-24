local config = DubzDarkRP.Config
local Edit = DubzDarkRP.Edit
local Fields = DubzDarkRP.Fields
local Kinds = DubzDarkRP.Kinds

local TRUE_WORDS = {["1"] = true, ["true"] = true, ["yes"] = true, ["on"] = true}
local FIRST_VALUE = 4

local function reply(ply, text)
    local line = "[DubzDarkRP] " .. text

    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line .. "\n") else print(line) end
end

local function guarded(name, run)
    concommand.Add(name, function(ply, _, args)
        if not DubzDarkRP.CanManage(ply) then return end

        run(ply, args)
    end)
end

local function spec(kind, key)
    for _, field in ipairs(Fields.Specs(kind)) do
        if field.key == key then return field end
    end
end

local function coerce(field, text)
    if field.type == "bool" then return TRUE_WORDS[string.lower(text)] == true end
    if field.type == "number" then return tonumber(text) end

    if field.type == "color" then
        local r, g, b = string.match(text, "^(%d+),(%d+),(%d+)$")

        return r and {r = tonumber(r), g = tonumber(g), b = tonumber(b), a = 255}
    end

    return text
end

local function report(ply, ok, message)
    reply(ply, (ok and "ok: " or "failed: ") .. tostring(message))
end

local function validKind(ply, kind)
    if Kinds.Meta[kind or ""] then return true end

    reply(ply, "kind must be one of: " .. table.concat(Kinds.Order, ", "))

    return false
end

guarded("dubz_drp_list", function(ply, args)
    local kind = args[1] or "jobs"

    if not validKind(ply, kind) then return end

    for _, row in ipairs(Kinds.Engine(kind).List()) do
        reply(ply, string.format("%-8s %-22s %-10s %s", tostring(row.index), row.id, row.status, row.entry.name or "?"))
    end
end)

guarded("dubz_drp_set", function(ply, args)
    local kind, id, key = args[1], args[2], args[3]

    if not validKind(ply, kind) then return end

    local field = key and spec(kind, key)

    if not (id and field and args[FIRST_VALUE]) then
        reply(ply, "usage: dubz_drp_set <kind> <id> <field> <value>")
        return
    end

    local value = coerce(field, table.concat(args, " ", FIRST_VALUE))

    if value == nil then
        reply(ply, "could not read that value for " .. key)
        return
    end

    report(ply, Edit.Save(ply, kind, id, {[key] = value}))
end)

guarded("dubz_drp_remove", function(ply, args)
    if validKind(ply, args[1]) then report(ply, Edit.Remove(ply, args[1], args[2] or "")) end
end)

guarded("dubz_drp_restore", function(ply, args)
    if validKind(ply, args[1]) then report(ply, Edit.Restore(ply, args[1], args[2] or "")) end
end)

guarded("dubz_drp_status", function(ply)
    reply(ply, "enabled: " .. tostring(DubzDarkRP.Enabled()))
    reply(ply, "darkrp ready: " .. tostring(DubzDarkRP.Adapter.Ready()))

    for _, kind in ipairs(Kinds.Order) do reply(ply, kind .. ": " .. Kinds.Engine(kind).Count()) end
end)

concommand.Add(config.EditorCommand, function(ply, _, args)
    if not (IsValid(ply) and DubzDarkRP.CanManage(ply)) then return end

    DubzDarkRP.Sync.Open(ply, Kinds.Meta[args[1] or ""] and args[1] or "jobs")
end)

hook.Add("PlayerSay", "DubzDarkRP_Chat", function(ply, text)
    local typed = string.lower(string.Trim(text))

    for _, command in ipairs(config.ChatCommands) do
        if typed == string.lower(command) then
            if DubzDarkRP.CanManage(ply) then
                DubzDarkRP.Sync.Open(ply, "jobs")
            else
                DubzDarkRP.Adapter.Notify(ply, DubzDarkRP.Phrase("NoAccess"))
            end

            return ""
        end
    end
end)
