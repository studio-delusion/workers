local Worker = require(script.Parent.worker)
local Util = require(script.Parent.util)

type PoolImpl<T...> = {
	__index: PoolImpl<T...>,
	new: (workers: { Worker.Worker<T...> }?) -> Pool<T...>,
	run: (self: Pool<T...>, T...) -> boolean,
	join: (self: Pool<T...>, attempts: number?) -> boolean,
	join_nth: (self: Pool<T...>, index: number, attempts: number) -> (boolean, T...),
	get_result: (self: Pool<T...>, index: number) -> (boolean, T...),
	is_not_suspended: (self: Pool<T...>) -> boolean,
	size: (self: Pool<T...>) -> number,
	destroy: (self: Pool<T...>) -> boolean,
}

type PoolProps<T...> = {
	workers: { Worker.Worker<T...> },
	results: { any }, -- sadly we can't pack `T...` into a table and type it, therefore we lie about the type when getting the results using a getter
}

export type Pool<T...> = typeof(setmetatable({} :: PoolProps<T...>, {} :: PoolImpl<T...>))

local Pool = {}
Pool.__index = Pool

--[=[
    Constructs a new pool of workers.

    @param workers { Worker<T...> }
    @return Pool<T...>
]=]
function Pool.new<T...>(workers: { Worker.Worker<T...> }): Pool<T...>
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
function Pool.run<T...>(self: Pool<T...>, ...: T...): boolean
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
function Pool.join<T...>(self: Pool<T...>, attempts: number?): boolean
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
function Pool.join_nth<T...>(self: Pool<T...>, index: number, attempts: number?): (boolean, T...)
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
function Pool.get_result<T...>(self: Pool<T...>, index: number): (boolean, T...)
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
function Pool.is_not_suspended<T...>(self: Pool<T...>): boolean
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
function Pool.size<T...>(self: Pool<T...>): number
	return #self.workers
end

--[=[
	Attempts to destroy all of the pool's workers and clean up their used memory.

	The function will return false if any of the workers aren't in the `suspended` state.

	If necessary, simply use `pool:join()` to wait until all workers finish running and are back to the `suspended` state.

	@return boolean
]=]
function Pool.destroy<T...>(self: Pool<T...>): boolean
	if self:is_not_suspended() then
		return false
	end

	for _, worker in self.workers do
		worker:destroy()
	end

	return true
end

return Pool
