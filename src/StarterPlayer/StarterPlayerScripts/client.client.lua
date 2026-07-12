local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SystemMgr = require(Replicated.Systems.SystemMgr)
local FirstPersonCamera = require(script.Parent:WaitForChild("Modules"):WaitForChild("FirstPersonCamera"))

FirstPersonCamera.Start()
SystemMgr.Start()
if RunService:IsStudio() then
	require(Replicated.Systems.TestSystem.ui).Init()
end
