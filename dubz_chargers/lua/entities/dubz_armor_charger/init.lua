AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- All behaviour is shared with the other charger: see lua/dubz_chargers/sv_chargers.lua (settings in the admin menu).
if not (DubzChargers and DubzChargers.Setup) then
    ErrorNoHalt("[DubzChargers] lua/autorun/dubz_chargers.lua didn't load, so the armor charger can't work.\n")
    return
end

DubzChargers.Setup(ENT, "armor")
