DubzTitles = DubzTitles or {}

DubzTitles.SystemName = "Dubz Titles System"

-- Settings. These are the defaults; the Dubz Framework admin menu (!dubzconfig) edits them live, along with the
-- Titles and Colors tables below.
DubzTitles.Config = {
    DataFolder = "dubz_titles_system",
    CustomColorPrice = 25,

    UseMoneyTracker = true, -- Uses custom darkrp money tracker addon

    AdminGroups = {
        ["superadmin"] = true,
        ["admin"] = true
    },

    VIPGroups = {
        ["vip"] = true,
        ["vip+"] = true,
        ["premium"] = true,
        ["superadmin"] = true,
        ["admin"] = true
    }
}

-- The default titles. `required` is the money you must have EARNED before you can buy it (0 = none); `vip` titles
-- are for VIP groups only. The admin menu's Titles table starts from these and replaces them when edited.
DubzTitles.DefaultTitles = {
    -- Early flex (1k-5k)
    { id = "homeless", name = "Homeless", price = 1000 },
    { id = "certified_noob", name = "Certified Noob", price = 1500 },
    { id = "chill_guy", name = "Chill Guy", price = 2000 },
    { id = "professional_afk", name = "Professional AFK", price = 2500 },
    { id = "npc_energy", name = "NPC Energy", price = 3000 },
    { id = "just_vibing", name = "Just Vibing", price = 3500 },
    { id = "unemployed_legend", name = "Unemployed Legend", price = 4000 },

    -- Mid tier (5k-12k)
    { id = "contractor", name = "Contractor", price = 5000 },
    { id = "businessman", name = "Businessman", price = 6500 },
    { id = "tax_evader", name = "Tax Evader", price = 7000 },
    { id = "underground_dealer", name = "Underground Dealer", price = 8500 },
    { id = "city_official", name = "City Official", price = 10000 },
    { id = "veteran", name = "Veteran", price = 11000 },

    -- High tier (12k-25k)
    { id = "mercenary", name = "Mercenary", price = 13000 },
    { id = "main_character", name = "Main Character", price = 15000 },
    { id = "plot_armor", name = "Plot Armor", price = 16000 },
    { id = "og_player", name = "OG Player", price = 18000 },
    { id = "glitch_system", name = "Glitch in the System", price = 20000 },
    { id = "investor", name = "Investor", price = 22000 },

    -- Endgame flex (25k+)
    { id = "elite_member", name = "Elite Member", price = 26000 },
    { id = "high_roller", name = "High Roller", price = 35000 },

    -- VIP titles
    { id = "vip_lounge", name = "VIP Lounge", price = 20000, vip = true },
    { id = "money_moves", name = "Money Moves", price = 30000, vip = true },
    { id = "upper_class", name = "Upper Class", price = 35000, vip = true },
    { id = "server_royalty", name = "Server Royalty", price = 50000, vip = true },
    { id = "gold_status", name = "Gold Status", price = 75000, vip = true }
}

DubzTitles.DefaultColors = {
    { id = "white", name = "White", color = Color(255,255,255), price = 0 },

    -- cheap colors (starter)
    { id = "gray", name = "Gray", color = Color(180,180,180), price = 500 },
    { id = "black", name = "Black", color = Color(25,25,25), price = 750 },

    -- mid colors
    { id = "red", name = "Red", color = Color(220,60,60), price = 1000 },
    { id = "green", name = "Green", color = Color(60,220,60), price = 1000 },
    { id = "blue", name = "Blue", color = Color(70,130,255), price = 1000 },

    { id = "orange", name = "Orange", color = Color(255,140,40), price = 1200 },
    { id = "cyan", name = "Cyan", color = Color(60,220,220), price = 1200 },
    { id = "lime", name = "Lime", color = Color(160,255,60), price = 1200 },

    -- premium colors
    { id = "purple", name = "Purple", color = Color(180,80,255), price = 2000 },
    { id = "pink", name = "Pink", color = Color(255,105,180), price = 2000 },
    { id = "gold", name = "Gold", color = Color(255,200,0), price = 3000 }
}

-- What the rest of the addon reads: the normal and the VIP titles, and the colour list. They start as the defaults
-- and are replaced whenever the tables are edited in the admin menu.
DubzTitles.Titles = {}
DubzTitles.VIPTitles = {}
DubzTitles.Colors = {}

for _, title in ipairs(DubzTitles.DefaultTitles) do
    table.insert(title.vip and DubzTitles.VIPTitles or DubzTitles.Titles, title)
end

for _, colorInfo in ipairs(DubzTitles.DefaultColors) do
    DubzTitles.Colors[#DubzTitles.Colors + 1] = colorInfo
end

function DubzTitles.GetAllTitles()
    local titles = {}

    for _, title in ipairs(DubzTitles.Titles or {}) do
        titles[#titles + 1] = title
    end

    for _, title in ipairs(DubzTitles.VIPTitles or {}) do
        titles[#titles + 1] = title
    end

    return titles
end

function DubzTitles.FindTitle(id)
    for _, title in ipairs(DubzTitles.GetAllTitles()) do
        if title.id == id then
            return title
        end
    end
end

function DubzTitles.FindColor(id)
    for _, colorInfo in ipairs(DubzTitles.Colors or {}) do
        if colorInfo.id == id then
            return colorInfo
        end
    end
end

function DubzTitles.IsAdmin(ply)
    if not IsValid(ply) then return false end

    local group = string.lower(ply:GetUserGroup() or "")
    return DubzTitles.Config.AdminGroups[group] == true
end

function DubzTitles.IsVIP(ply)
    if not IsValid(ply) then return false end

    local group = string.lower(ply:GetUserGroup() or "")
    return DubzTitles.Config.VIPGroups[group] == true
end

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzTitles.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("titles")
end
