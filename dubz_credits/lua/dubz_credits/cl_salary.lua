hook.Add("playerGetSalary", "DubzCredits_SalaryBoost_HUD", function(ply, salary)
    if not DubzCredits
        or not DubzCredits.GetMultiplier
    then
        return
    end

    local mult = DubzCredits:GetMultiplier("salary", ply)
    if not mult or mult <= 1 then return end

    return math.floor(salary * mult)
end)

hook.Add("playerGetSalary", "DubzCredits_DebugSalary", function(ply, salary)
    print("[DEBUG] Salary:", salary)
    print("[DEBUG] Mult:", DubzCredits:GetMultiplier("salary", ply))
end)