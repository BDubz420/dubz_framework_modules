if not SERVER then return end

for _, name in ipairs(DubzSuggestions.ServerFiles) do include("dubz_suggestions/" .. name) end
