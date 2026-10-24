DubzCredits = DubzCredits or {}
DubzCredits.Config = DubzCredits.Config or {}

-- ===============================
-- STORAGE SETTINGS
-- ===============================

-- "file" or "mysql"
DubzCredits.Config.StorageType = "file"

-- ===============================
-- MYSQL SETTINGS (Recommended)
-- ===============================
DubzCredits.Config.MySQL = {
    Host = "127.0.0.1",
    Username = "root",
    Password = "",
    Database = "gmod",
    Port = 3306,
}

-------------------------------------------------
-- STORE / CREDIT PURCHASE
-------------------------------------------------
DubzCredits.Config.Store = {
    Enabled = true,
    URL = "https://shop.lowkeynetworks.com",
    --URL = "https://shop.lowkeynetworks.com",
    ButtonText = "Buy Credits"
}

-------------------------------------------------
-- BOOST CATEGORIES (STACKING RULES)
-------------------------------------------------
DubzCredits.Config.BoostCategories = {
    printer = {
        maxActive = 1,
        description = "Affects all money printers"
    },
    salary = {
        maxActive = 1,
        description = "Affects DarkRP salary"
    },
    xp = {
        maxActive = 2,
        description = "Affects XP systems"
    },
    bitcoin = {
        maxActive = 1,
        description = "Affects all bitcoin miners"
    },
    props = {
        maxActive = 1,
        description = "Increases prop limit"
    },
}

-- ===============================
-- HUD SETTINGS
-- ===============================
DubzCredits.Config.HUD = {
    Enabled = true,
    Position = "topright", -- topleft, topright, bottomleft, bottomright
    XOffset = 20,
    YOffset = 120
}

-- ===============================
-- UI FLAGS
-- ===============================
DubzCredits.Config.UI = {
    ConversionsEnabled = true,       -- the Conversions section (credits -> cash)
    BoostsEnabled = true,            -- global boosts (everyone benefits)
    PersonalBoostsEnabled = true,    -- personal boosts (only the buyer benefits)
    WeeklyShopEnabled = true,        -- the rotating weekly item shop
    EventsEnabled = true
}

-- ===============================
-- CONVERSIONS
-- ===============================
DubzCredits.Config.Conversions = {
    cash_50k = {
        name = "10 Credits → $10,000",
        cost = 10,
        reward = function(ply)
            ply:addMoney(10000)
            return true
        end
    }
}

-- ===============================
-- GLOBAL BOOSTS
-- ===============================
DubzCredits.Config.Boosts = {
    printer_2x_2h = {
        name = "2x Printer Output (2 Hours)",
        cost = 50,
        duration = 7200,
        category = "printer",
        multiplier = 2,
        maxActive = 1,
        scope = "global"
    },

    salary_2x_2h = {
        name = "2x Salary For Everyone (2 Hours)",
        cost = 40,
        duration = 7200,
        category = "salary",
        multiplier = 2,
        maxActive = 1,
        scope = "global"
    },

    salary_1_5x_1h = {
        name = "1.5x Salary (1 Hour)",
        cost = 25,
        duration = 3600,
        category = "salary",
        multiplier = 1.5,
        maxActive = 1,
        scope = "global"
    },

    bitcoin_2x_2h = {
        name = "2x Bitcoin Output (2 Hours)",
        cost = 60,
        duration = 7200,
        category = "bitcoin",
        multiplier = 2,
        maxActive = 1,
        scope = "global"
    },
}

DubzCredits.Config.PersonalBoosts = {

    prop_20 = {
        name = "+20 Props (1 Day)",
        cost = 5,
        duration = 24 * 60 * 60,
        amount = 20
    },

    prop_50 = {
        name = "+50 Props (1 Day)",
        cost = 10,
        duration = 24 * 60 * 60,
        amount = 50
    },

    prop_120 = {
        name = "+120 Props (1 Day)",
        cost = 20,
        duration = 24 * 60 * 60,
        amount = 120
    }
}

-- ===============================
-- DAILY CREDITS
-- ===============================
DubzCredits.Config.Daily = {
    daily_credits = {
        mincredits = 1,
        maxcredits = 5,
        vip_ranks = {
            "vip", 
            "superadmin", 
            "adminvip", 
            "trialmoderatorvip", 
            "moderatorvip", 
            "helpervip", 
            "headadminvip"
        },
        vipmultiplier = 2
    }
}

-- ===============================
-- ITEM SHOP
-- ===============================
DubzCredits.Config.Items = {

    vip = {
        name = "VIP (7 Days)",
        cost = 100,
        model = "models/props_c17/BriefCase001a.mdl",
        cam_pos = Vector(50, 50, 50),
        cam_ang = Angle(25, 45, 0),
        fov = 45,
        rarity = "epic",
        desc = "Grants VIP perks for 7 days.",
        -- Needs the Dubz Temp Ranks addon; buying again adds 7 more days. Returning false refunds the credits.
        reward = function(ply)
            if not (DubzTempRanks and DubzTempRanks.AddTempRank) then return false end

            local ok = DubzTempRanks:AddTempRank(ply, "vip", 7 * 24 * 60 * 60)
            return ok == true
        end
    },

    crate = {
        name = "Reward Crate",
        cost = 25,
        model = "models/Items/item_item_crate.mdl",
        cam_pos = Vector(30, 30, 30),
        cam_ang = Angle(25, 45, 0),
        fov = 60,
        rarity = "rare",
        desc = "Contains random rewards.",
        reward = function(ply)
            return DubzRewards:SpawnRewardBox(ply, "dubz_reward_daily")
        end
    },

    cash_bundle = {
        name = "$25,000 Cash",
        cost = 15,
        model = "models/props/cs_assault/money.mdl",
        rarity = "common",
        desc = "Instant cash reward.",
        reward = function(ply) ply:addMoney(25000) end
    },

    armor = {
        name = "Armor Kit",
        cost = 10,
        model = "models/items/battery.mdl",
        rarity = "common",
        desc = "Gives armor.",
        reward = function(ply) ply:SetArmor(100) end
    },

    medkit = {
        name = "Health Kit",
        cost = 8,
        model = "models/items/healthkit.mdl",
        rarity = "common",
        desc = "Restore health.",
        reward = function(ply) ply:SetHealth(100) end
    },

    ammo_pack = {
        name = "Ammo Pack",
        cost = 12,
        model = "models/items/boxmrounds.mdl",
        rarity = "uncommon",
        desc = "Gives ammo.",
        reward = function(ply) end
    },

    radio = {
        name = "Radio Device",
        cost = 20,
        model = "models/props_lab/citizenradio.mdl",
        rarity = "rare",
        desc = "Roleplay item.",
        reward = function(ply) end
    },

    laptop = {
        name = "Laptop",
        cost = 30,
        model = "models/props_lab/laptop.mdl",
        rarity = "rare",
        desc = "Utility device.",
        reward = function(ply) end
    },

    gold_bar = {
        name = "Gold Bar",
        cost = 40,
        model = "models/props/de_inferno/gold_bar.mdl",
        rarity = "epic",
        desc = "High value item.",
        reward = function(ply) end
    },

    soda = {
        name = "Soda Can",
        cost = 2,
        model = "models/props_junk/PopCan01a.mdl",
        rarity = "common",
        desc = "Just a drink.",
        reward = function(ply) end
    }
}

-- Master kill switch (admin menu > Modules > Credits). Off = no purchases, no daily credits, no boost multipliers and
-- no boosts HUD (balances are kept). True when the framework isn't installed, so credits still work.
function DubzCredits.Enabled()
    return not (DFW and DFW.Bind) or DFW.Bind.Enabled("credits")
end
