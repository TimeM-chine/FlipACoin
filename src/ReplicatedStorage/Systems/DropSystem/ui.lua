---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----

local DropUi = {}

function DropUi.Init(pendingCalls)
	for _, call in ipairs(pendingCalls) do
		DropUi[call.functionName](table.unpack(call.args))
	end
end

return DropUi
