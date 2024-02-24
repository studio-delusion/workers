local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Util = require(script.Parent.util)

type WorkerImpl<T..., R...> = {
	__index: WorkerImpl<T..., R...>,
	new: (actor: Actor, worker: ModuleScript, index: number?) -> Worker<T..., R...>,
	run: (self: Worker<T..., R...>, T...) -> boolean,
	join: (self: Worker<T..., R...>, attempts: number?) -> (boolean, R...),
	destroy: (self: Worker<T..., R...>) -> boolean,
	status: (self: Worker<T..., R...>) -> Status,
}

type WorkerProps = {
	actor: Actor,
	index: number?,
	id: number,
}

export type Worker<T..., R...> = typeof(setmetatable({} :: WorkerProps, {} :: WorkerImpl<T..., R...>))

local NextId = 1

local WorkerStatuses = SharedTable.new()
SharedTableRegistry:SetSharedTable("WorkerStatuses", WorkerStatuses)

local WorkerReturns = SharedTable.new()
SharedTableRegistry:SetSharedTable("WorkerReturns", WorkerReturns)

local Worker = {}
Worker.__index = Worker

function Worker.new<T..., R...>(actor: Actor, worker: ModuleScript, index: number?): Worker<T..., R...>
	local self = {} :: WorkerProps
	self.actor = actor
	self.index = index
	self.id = NextId

	NextId += 1
	if NextId >= 0xFFFFFFFF then
		NextId = 1
	end

	WorkerStatuses[self.id] = "new"
	WorkerReturns[self.id] = {}

	task.defer(self.actor.SendMessage, self.actor, "Create", worker, self.id, self.index)

	return setmetatable(self, Worker) :: any
end

--[=[
	Runs the worker with the given arguments.

	This function will return false if the worker is currently running.

	@param T... -- Arguments
	@return boolean
]=]
function Worker.run<T..., R...>(self: Worker<T..., R...>, ...: T...): boolean
	repeat
		task.wait()
	until self:status() ~= "new"

	if self:status() ~= "suspended" then
		return false
	end

	self.actor:SendMessage("Run", ...)

	return true
end

--[=[
	Attempts to join the worker back into serial execution.

	Passing `0` or `1` into `attempts` will cause the function to not wait for the worker to finish running.\
	Not passing anything into `attempts` will cause the function to infinitely wait for the worker to finish running.
	
	@param attempts number?
	@return number, T... -- Did we successfully get the result, and if so, the result.
]=]
function Worker.join<T..., R...>(self: Worker<T..., R...>, attempts: number?): (boolean, R...)
	local attempt = 0
	while self:status() ~= "suspended" do
		attempt += 1

		if attempts and attempts < attempt then
			return false
		end

		task.wait()
	end

	local result = Util.deep_clone(WorkerReturns[self.id])
	return true, table.unpack(result) :: any
end

--[=[
	Attempts to destroy the worker and clean up it's used memory.

	The function will return false if the worker isn't in the `suspended` state.

	@return boolean
]=]
function Worker.destroy<T..., R...>(self: Worker<T..., R...>): boolean
	if self:status() ~= "suspended" then
		return false
	end

	self.actor:Destroy()

	WorkerStatuses[self.id] = nil
	WorkerReturns[self.id] = nil

	return true
end

type Status = "new" | "suspended" | "running"

--[=[
	Gets the worker's status.

	The status can be: `new` | `suspended` | `running`.

	@return Status
]=]
function Worker.status<T..., R...>(self: Worker<T..., R...>): Status
	local status = WorkerStatuses[self.id]
	return status
end

return Worker
