if not SERVER then return end

for _, name in ipairs(DubzF4.ServerFiles) do include("dubz_f4/" .. name) end
