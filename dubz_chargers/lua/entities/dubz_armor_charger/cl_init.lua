include("shared.lua")

ENT.DisplayTime = 0

net.Receive("Dubz_ArmorCharger_Timer", function()
    local ent = net.ReadEntity()
    local timeLeft = net.ReadFloat()

    if IsValid(ent) then
        ent.DisplayTime = timeLeft
        ent.DisplayStart = CurTime()
    end
end)

function ENT:Draw()
    self:DrawModel()

    local ang = self:GetAngles()
    local pos = self:GetPos()

    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), -90)

    cam.Start3D2D(pos + ang:Up() * 8, ang, 0.1)
        draw.RoundedBox(8, -100, -200, 200, 100, Color(0, 0, 0, 180))
        draw.SimpleText("Armor Charger", "DermaLarge", 0, -200, Color(0, 0, 255), TEXT_ALIGN_CENTER)

        local owner = self:Getowning_ent()
        local ownerName = IsValid(owner) and owner:Nick() or "Unowned"
        draw.SimpleText("Owner: " .. ownerName, "DermaDefaultBold", 0, -170, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        draw.SimpleText("Price: $" .. self:GetNWInt("Price", 100), "DermaDefaultBold", 0, -150, Color(255, 255, 255), TEXT_ALIGN_CENTER)

        if self.DisplayTime and self.DisplayTime > 0 then
            local elapsed = CurTime() - (self.DisplayStart or 0)
            local timeLeft = math.max(0, self.DisplayTime - elapsed)

            if timeLeft > 0 then
                draw.SimpleText("Time Left: " .. math.ceil(timeLeft) .. "s", "DermaDefaultBold", 0, -130, Color(200, 200, 255), TEXT_ALIGN_CENTER)
            else
                self.DisplayTime = 0
                draw.SimpleText("Ready to use!", "DermaDefaultBold", 0, -130, Color(200, 200, 255), TEXT_ALIGN_CENTER)
            end
        else
            draw.SimpleText("Ready to use!", "DermaDefaultBold", 0, -130, Color(200, 200, 255), TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end