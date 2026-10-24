DubzCredits = DubzCredits or {}
DubzCredits.Version = "1.0.0"

local function Line(char, len)
    return string.rep(char, len or 50)
end

hook.Add("Initialize", "DubzCredits_Boot", function()
    print("")
    print(Line("="))
    print(" Dubz Credits System")
    print(" Version: " .. (DubzCredits.Version or "unknown"))
    print(" Storage: " .. (DubzCredits.Config and DubzCredits.Config.StorageType or "unknown"))
    print(" Status: Loaded successfully")
    print(Line("="))
    print("")
end)
