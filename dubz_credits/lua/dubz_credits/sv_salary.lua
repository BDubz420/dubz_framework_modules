hook.Add("playerGetSalary", "DubzCredits_SalaryBoost", function(ply, salary)
    if not DubzCredits or not DubzCredits.GetMultiplier then return end

    local mult = tonumber(DubzCredits:GetMultiplier("salary", ply)) or 1
    if mult <= 1 then return end

    local newAmount = math.floor((tonumber(salary) or 0) * mult)

    -- Return values must be:
    -- suppress, message, amount
    return false, nil, newAmount
end)