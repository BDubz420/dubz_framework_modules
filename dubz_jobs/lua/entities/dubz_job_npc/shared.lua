-- A job NPC: talk to it (E) to be hired for a job, buy the tool again, or quit. The base for every job site; the spawnable
-- ones (Dubz Jobs category) inherit it and say which site they are. Which job, the NPC's name and the tool are in the
-- admin menu's Job Sites table.
ENT.Type = "ai"
ENT.Base = "base_ai"

ENT.PrintName = "Job NPC"
ENT.Author = "BDubz420"
ENT.Category = "Dubz Jobs"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Site")
end
