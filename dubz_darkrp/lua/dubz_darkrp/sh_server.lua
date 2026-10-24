if not SERVER then return end

for _, name in ipairs(DubzDarkRP.ServerFiles) do include("dubz_darkrp/" .. name) end
