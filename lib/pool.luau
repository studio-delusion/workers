local Worker = require(script.Parent.worker)
local Util = require(script.Parent.util)

type PoolImpl<T..., R...> = {
	__index: PoolImpl<T..., R...>,
	new: (workers: { Worker.Worker<T..., R...> }?) -> Pool<T..., R...>,
	run: (self: Pool<T..., R...>, T...) -> boolean,
	join: (self: Pool<T..., R...>, attempts: number?) -> boolean,
	join_nth: (self: Pool<T..., R...>, index: number, attempts: number) -> (boolean, R...),
	get_result: (self: Pool<T..., R...>, index: number) -> (boolean, R...),
	is_not_suspended: (self: Pool<T..., R...>) -> boolean,
	size: (self: Pool<T..., R...>) -> number,
	destroy: (self: Pool<T..., R...>) -> boolean,
}

type PoolProps<T..., R...> = {
	workers: { Worker.Worker<T..., R...> },
	results: { any }, -- sadly we can't pack `T...` into a table and type it, therefore we lie about the type when getting the results using a getter
}

export type Pool<T..., R...> = typeof(setmetatable({} :: PoolProps<T..., R...>, {} :: PoolImpl<T..., R...>))

local Pool = {}
Pool.__index = Pool

--[=[
    Constructs a new pool of workers.

    @param workers { Worker<T..., R...> }
    @return Pool<T..., R...>
]=]
function Pool.new<T..., R...>(workers: { Worker.Worker<T..., R...> }): Pool<T..., R...>
	local self = {}
	self.workers = workers
	self.results = {}

	return setmetatable(self, Pool) :: any
end

--[=[
    Runs all workers in the pool with the given arguments.

    @param T... -- Arguments to pass to all workers
    @return boolean -- Did all workers start running?
]=]
function Pool.run<T..., R...>(self: Pool<T..., R...>, ...: T...): boolean
	if self:is_not_suspended() then
		return false
	end

	for _, worker in self.workers do
		worker:run(...)
	end

	return true
end

--[=[
	Attempts to join all workers in the pool back into serial execution.

	Passing any number below 2 into `attempts` will cause the function to not wait for the worker to finish running.\
	Not passing anything into `attempts` will cause the function to infinitely wait for the worker to finish running.
	
	@param attempts number?
	@return boolean -- Was the joining successful?
]=]
function Pool.join<T..., R...>(self: Pool<T..., R...>, attempts: number?): boolean
	for _, worker in self.workers do
		local result = table.pack(worker:join(attempts))
		self.results[worker.id] = result

		if not result[1] then
			return false
		end
	end

	return true
end

--[=[
	Attempts to join the worker in the pool with the given index back into serial execution.

	Passing any number below 2 into `attempts` will cause the function to not wait for the worker to finish running.\
	Not passing anything into `attempts` will cause the function to infinitely wait for the worker to finish running.

	@param index number
	@param attempts number?
	@return boolean, T... -- Did we successfully join the worker, and if so, the result.
]=]
function Pool.join_nth<T..., R...>(self: Pool<T..., R...>, index: number, attempts: number?): (boolean, R...)
	local worker = self.workers[index]
	if not worker then
		return false
	end

	local result = table.pack(worker:join(attempts))
	self.results[worker.id] = result

	if not result[1] then
		return false
	end

	local clone = Util.deep_clone(result)

	return clone :: any
end

--[=[
    Gets the result of the worker with the given index.

    @param index number
    @return boolean, T... -- Did we successfully get the result, and if so, the result.
]=]
function Pool.get_result<T..., R...>(self: Pool<T..., R...>, index: number): (boolean, R...)
	local result = Util.deep_clone(self.results[index])
	if not result[1] then
		return false
	end

	local clone = Util.deep_clone(result)

	return table.unpack(clone) :: any
end

--[=[
    Checks whether any worker in the thread isn't suspended.

    @return boolean
]=]
function Pool.is_not_suspended<T..., R...>(self: Pool<T..., R...>): boolean
	for _, worker in self.workers do
		if worker:status() ~= "suspended" then
			return true
		end
	end
	return false
end

--[=[
    Gets the amount of workers in the pool.

    @return number
]=]
function Pool.size<T..., R...>(self: Pool<T..., R...>): number
	return #self.workers
end

--[=[
	Attempts to destroy all of the pool's workers and clean up their used memory.

	The function will return false if any of the workers aren't in the `suspended` state.

	If necessary, simply use `pool:join()` to wait until all workers finish running and are back to the `suspended` state.

	@return boolean
]=]
function Pool.destroy<T..., R...>(self: Pool<T..., R...>): boolean
	if self:is_not_suspended() then
		return false
	end

	for _, worker in self.workers do
		worker:destroy()
	end

	return true
end

return Pool
