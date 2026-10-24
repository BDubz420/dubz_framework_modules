if not SERVER then return end

for _, name in ipairs(DubzWorkflow.ServerFiles) do include("dubz_workflow/" .. name) end
