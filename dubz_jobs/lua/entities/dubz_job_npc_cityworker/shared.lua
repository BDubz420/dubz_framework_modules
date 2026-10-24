-- The city foreman: spawn from the entities tab (Dubz Jobs). Everything is inherited from dubz_job_npc. He hires players as City Workers (the repair jobs of
-- the City Worker addon) and hands over the wrench.
ENT.Type = "ai"
ENT.Base = "dubz_job_npc"

ENT.PrintName = "City Foreman"
ENT.Category = "Dubz Jobs"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PresetSite = "cityworker"
