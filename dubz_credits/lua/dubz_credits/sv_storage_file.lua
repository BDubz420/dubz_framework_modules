DubzCredits.Storage = DubzCredits.Storage or {}

local dir = "dubz_credits"
file.CreateDir(dir)

function DubzCredits.Storage:Load(id)
    local path = dir .. "/" .. id .. ".txt"
    if not file.Exists(path, "DATA") then return 0 end
    return tonumber(file.Read(path, "DATA")) or 0
end

function DubzCredits.Storage:Save(id, amount)
    file.Write(dir .. "/" .. id .. ".txt", tostring(amount))
end
