if DubzCredits.Config.StorageType ~= "mysql" then return end
require("mysqloo")

local cfg = DubzCredits.Config.MySQL
local db

hook.Add("Initialize", "DubzCredits_MySQL", function()
    db = mysqloo.connect(cfg.Host, cfg.Username, cfg.Password, cfg.Database, cfg.Port)

    function db:onConnected()
        local q = db:query([[
            CREATE TABLE IF NOT EXISTS dubz_credits (
                steamid64 VARCHAR(32) PRIMARY KEY,
                balance INT NOT NULL
            )
        ]])
        q:start()
    end

    db:connect()
end)

function DubzCredits.Storage:Load(id)
    local q = db:query("SELECT balance FROM dubz_credits WHERE steamid64='" .. id .. "'")
    q.onSuccess = function(_, data)
        DubzCredits.Data[id] = data[1] and tonumber(data[1].balance) or 0
    end
    q:start()
    return 0
end

function DubzCredits.Storage:Save(id, amount)
    db:query("REPLACE INTO dubz_credits VALUES ('" .. id .. "', " .. amount .. ")"):start()
end
