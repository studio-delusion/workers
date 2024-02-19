local SharedTableRegistry = game:GetService("SharedTableRegistry")

local Actor = script:GetActor()
assert(Actor, "This script isn't owned by an actor, even though it should be")

local Worker: ModuleScript? = nil
local Id: number = 0
local Index: number = 0

local WorkerStatuses = SharedTableRegistry:GetSharedTable("WorkerStatuses")
local WorkerReturns = SharedTableRegistry:GetSharedTable("WorkerReturns")

type Status = "new" | "suspended" | "running"

local function set_status(status: Status)
	WorkerStatuses[Id] = status
end

local function set_return(...)
	WorkerReturns[Id] = table.pack(...)
end

Actor:BindToMessage("Create", function(worker: ModuleScript, id: number, index: number?)
	Worker = worker
	Id = id
	Index = index or 0
	set_status("suspended")
end)

Actor:BindToMessage("Run", function(...)
	assert(Worker, "This script doesn't have a set worker.")
	set_status("running")
	local worker = require(Worker) :: any

	task.desynchronize()

	worker.Index = Index

	local result = worker.run(...)
	set_return(result)

	set_status("suspended")

	task.synchronize()
end)
