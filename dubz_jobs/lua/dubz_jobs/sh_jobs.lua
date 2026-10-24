-- Shared job helpers. While a player holds a job that has accessories (Job Accessories table), those accessories are drawn
-- on top of what they really wear in that slot. This uses the same "virtual worn" hook as the backpack: nothing in the
-- player's saved accessories is touched, so leaving the job puts everything back exactly as it was.
function DubzJobs.JobName(ply)
	return string.lower(team.GetName(ply:Team()) or "")
end

hook.Add("DubzCosVirtualWorn", "DubzJobs_Accessories", function(ply, slotId)
	if not DubzJobs.Enabled() then return end

	local set = DubzJobs.Accessories[DubzJobs.JobName(ply)]
	return set and set[slotId]
end)

-- The DarkRP team index for a job command (nil if there is no such job)
function DubzJobs.TeamOf(command)
	if not DarkRP or not DarkRP.getJobByCommand then return nil end

	local _, index = DarkRP.getJobByCommand(command)
	return index
end
