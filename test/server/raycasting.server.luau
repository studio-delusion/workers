local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Workers = require(ReplicatedStorage.Packages.workers)
local RaycastWorker = ReplicatedStorage.raycast

local Pool: { Workers.Worker<(Vector3, Vector3, RaycastParams?), (RaycastResult?)> } = table.create(Players.MaxPlayers)
