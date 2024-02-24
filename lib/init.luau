local Worker = require(script.worker)
local Pool = require(script.pool)
local Initializer = require(script.initializer)

export type Worker<T..., R...> = Worker.Worker<T..., R...>
export type Pool<T..., R...> = Pool.Pool<T..., R...>

local function make_actor(parent: Instance): Actor
	local actor = Instance.new("Actor")
	actor.Parent = parent

	local initializer = Initializer.get()
	initializer.Parent = actor
	initializer.Enabled = true

	return actor
end

local Workers = {}

function Workers.worker<T...>(worker: ModuleScript): Worker<T...>
	local calling_script = getfenv(2).script
	local actor = make_actor(calling_script)
	return Worker.new(actor, worker) :: any
end

function Workers.pool<T...>(size: number, worker: ModuleScript): Pool<T...>
	local workers = table.create(size)
	local calling_script = getfenv(2).script

	for i = 1, size do
		local actor = make_actor(calling_script)
		workers[i] = Worker.new(actor, worker, i)
	end

	return Pool.new(workers) :: any
end

return Workers
