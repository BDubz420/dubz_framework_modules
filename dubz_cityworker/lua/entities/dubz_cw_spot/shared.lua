-- A spot for a street job: a leak, a fire hydrant, a pile of rubble, an electrical fault or a bench, put down with the City Worker Placer tool and saved for the
-- map. It sits quiet until a worker is given the job; then it is "active" (leaking, spraying, a pile of rubble, sparking). Made by sv_spots.lua, not spawnable.
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "City Worker Spot"
ENT.Author = "BDubz420"
ENT.Category = "Dubz City Worker"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Kind")      -- leak, hydrant, rubble, electric or bench
	self:NetworkVar("Bool", 0, "Active")      -- a worker has the job: it is broken
	self:NetworkVar("Int", 0, "SpotId")       -- its number in the map's list (the placer shows it)
end
