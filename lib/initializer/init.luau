local RunService = game:GetService("RunService")

local initializer = {}

function initializer.get(): BaseScript
	return if RunService:IsServer() then script.server:Clone() else script.client:Clone()
end

return initializer
