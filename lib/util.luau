local function deep_clone<T>(object: T): T
	local self = table.clone(object :: any)

	for key, value in next, self do
		if typeof(value) ~= "table" then
			continue
		end
		self[key] = deep_clone(value)
	end

	return self :: any
end

return {
	deep_clone = deep_clone,
}
