DubzDarkRP.Audit = DubzDarkRP.Audit or {}

local config = DubzDarkRP.Config

function DubzDarkRP.Audit.Log(actor, action, id, before, after)
    local record = {
        time = os.time(),
        actor = IsValid(actor) and actor:Nick() or DubzDarkRP.Phrase("Console"),
        steam = IsValid(actor) and actor:SteamID64() or "-",
        action = action,
        id = id,
        before = before,
        after = after
    }

    print("[DubzDarkRP] " .. record.actor .. " " .. action .. " " .. id)

    if config.AuditLog then file.Append(config.AuditFile, util.TableToJSON(record) .. "\n") end
end
