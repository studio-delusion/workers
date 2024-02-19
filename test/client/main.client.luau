local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workers = require(ReplicatedStorage.Packages.workers)
local test_worker = ReplicatedStorage.worker

local worker = workers.worker(test_worker)
print(worker:run("hello from client test worker!"))

local pool = workers.pool(128, test_worker)
print(pool:run("hello from client test worker pool!"))
