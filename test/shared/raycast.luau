local Raycast = {}

function Raycast.run(origin: Vector3, direction: Vector3, parameters: RaycastParams?): RaycastResult?
	local result = workspace:Raycast(origin, direction, parameters)
	return result
end

return Raycast
