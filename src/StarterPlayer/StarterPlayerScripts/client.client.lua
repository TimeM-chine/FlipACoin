local Replicated = game:GetService("ReplicatedStorage")
local SystemMgr = require(Replicated.Systems.SystemMgr)
local FirstPersonCamera = require(script.Parent:WaitForChild("Modules"):WaitForChild("FirstPersonCamera"))

FirstPersonCamera.Start()
SystemMgr.Start()
