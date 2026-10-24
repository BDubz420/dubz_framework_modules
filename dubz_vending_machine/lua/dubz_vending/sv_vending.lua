-- Vending machines, server side: a notification helper, and keeping the machines out of the pocket.
function DubzVending.Say(ply, text, kind)
	if not IsValid(ply) then return end

	if DarkRP and DarkRP.notify then DarkRP.notify(ply, kind or 0, 5, text) else ply:ChatPrint(text) end
end

-- The pocket must not take the machines (best effort: a table edited in the admin menu replaces this)
hook.Add("InitPostEntity", "DubzVending_NoPocket", function()
	timer.Simple(5, function()
		if not (DubzInv and DubzInv.Config and DubzInv.Config.pocketBlacklist) then return end

		DubzInv.Config.pocketBlacklist.sent_soda_machine = true
	end)
end)
