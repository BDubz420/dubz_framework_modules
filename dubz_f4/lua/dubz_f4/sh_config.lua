DubzF4.TabIds = {"home", "jobs", "entities", "weapons", "ammo", "vehicles", "commands", "rules"}

DubzF4.Config = {
    ServerName = "Dubz RP",
    Width = 1180,
    Height = 720,
    SidebarWidth = 230,
    StartTab = "home",
    ToggleDebounce = 0.3,
    ModelChoiceSeconds = 30,

    StoreColumns = 4,
    CommandColumns = 2,
    JobListShare = 0.45,
    ModelFov = 36,
    ModelSpin = 30,
    ShowAnnouncement = true,
    ShowStaff = true,

    Sounds = true,
    OpenSound = "garrysmod/ui_return.wav",

    Tabs = {
        home = true,
        jobs = true,
        entities = true,
        weapons = true,
        ammo = true,
        vehicles = true,
        commands = true,
        rules = true
    },

    Text = {
        Subtitle = "Press F4 again to close",
        TabHome = "Home",
        TabJobs = "Jobs",
        TabEntities = "Entities",
        TabWeapons = "Weapons",
        TabAmmo = "Ammo",
        TabVehicles = "Vehicles",
        TabCommands = "Commands",
        TabRules = "Rules",
        Balance = "Balance",
        Salary = "Salary",
        Job = "Job",
        Online = "Online",
        Slots = "Slots",
        Access = "Access",
        AccessStaff = "Staff",
        AccessVote = "Vote",
        AccessOpen = "Open",
        Announcement = "Announcement",
        StaffOnline = "Staff online",
        NoStaff = "No staff online right now.",
        Community = "Community",
        SearchJobs = "Search jobs...",
        SearchItems = "Search...",
        Loadout = "Loadout",
        NoDescription = "No description available.",
        BecomeJob = "Become {job}",
        CurrentJob = "Current job",
        AdminOnly = "Admin only",
        SuperadminOnly = "Superadmin only",
        RequiresJob = "Requires another job",
        Locked = "Locked",
        JobFull = "Job full",
        OtherCategory = "Other",
        Unknown = "Unknown",
        Buy = "Buy",
        BuyShipment = "Buy shipment",
        Shipment = "Shipment",
        Single = "Single {price}",
        Available = "{count} available",
        Nothing = "Nothing available",
        SingleItem = "Single item",
        InShipment = "x{amount} per shipment",
        Rounds = "{amount} rounds",
        QuickCommands = "Quick commands",
        Run = "Run",
        Rules = "Server rules",
        RulesHint = "Breaking the rules can result in a warn, kick or ban.",
        NoDarkRP = "DarkRP was not detected.",
        TabFailed = "This page failed to load. Check the console."
    }
}

DubzF4.DefaultLinks = {
    {name = "Discord", url = "https://discord.gg/yourinvite"},
    {name = "Website", url = "https://yourwebsite.com"},
    {name = "Workshop", url = "https://steamcommunity.com/sharedfiles/filedetails/?id=0"}
}

DubzF4.DefaultAnnouncement = {
    {text = "Welcome to the server. Read the rules, pick a job and have fun."},
    {text = "Need help? Ask in chat with @ or join the Discord and open a ticket."}
}

DubzF4.DefaultRules = {
    {text = "Respect all players and staff."},
    {text = "No RDM. You need a valid roleplay reason to kill."},
    {text = "No NLR. After you die you forget everything and avoid where you died for 5 minutes."},
    {text = "Stay in character in IC chat. Use // or /ooc for out of character talk."},
    {text = "No FailRP, powergaming or metagaming."},
    {text = "Do not abuse bugs or exploits. Report them to staff."}
}

DubzF4.DefaultStaffGroups = {
    {group = "superadmin", label = "Owner", color = {r = 255, g = 85, b = 95, a = 255}},
    {group = "admin", label = "Admin", color = {r = 255, g = 160, b = 50, a = 255}},
    {group = "moderator", label = "Moderator", color = {r = 80, g = 200, b = 255, a = 255}}
}

DubzF4.DefaultCommands = {
    {name = "Drop money", desc = "Drop cash on the ground.", icon = "economy/attach_money", cmd = "dropmoney", prompt_title = "Drop money", prompt_text = "How much do you want to drop?"},
    {name = "Give money", desc = "Hand cash to the player you look at.", icon = "economy/payments", cmd = "give", prompt_title = "Give money", prompt_text = "How much do you want to give?"},
    {name = "Change RP name", desc = "Change your roleplay name.", icon = "players/id_card", cmd = "rpname", prompt_title = "RP name", prompt_text = "Enter your new roleplay name:"},
    {name = "Drop weapon", desc = "Drop the weapon you are holding.", icon = "darkrp/local_police", cmd = "drop"},
    {name = "Sell all doors", desc = "Sell every door you own.", icon = "misc/door", cmd = "unownalldoors"},
    {name = "Request license", desc = "Ask for a gun license.", icon = "darkrp/badge", cmd = "requestlicense"},
    {name = "Advert", desc = "Broadcast an advert to everyone.", icon = "communication/chat", cmd = "advert", prompt_title = "Advert", prompt_text = "What do you want to advertise?"}
}

function DubzF4.Phrase(key, values)
    local text = DubzF4.Config.Text[key] or key

    for name, value in pairs(values or {}) do
        text = string.Replace(text, "{" .. name .. "}", tostring(value))
    end

    return text
end

function DubzF4.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("f4")
end
