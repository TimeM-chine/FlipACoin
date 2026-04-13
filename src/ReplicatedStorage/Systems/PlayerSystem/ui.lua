---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local Util = require(Replicated.modules.Util)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ClientData = require(Replicated.Systems.ClientData)
local PlayerPresets = require(script.Parent.Presets)
local DoorPresets = require(Replicated.Systems.DoorSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local ExpBar = Elements:WaitForChild("ExpBar")
local bar = ExpBar:WaitForChild("Bar")
local levelFrame = ExpBar:WaitForChild("Level")
local levelText = levelFrame:WaitForChild("level")
local expText = levelFrame:WaitForChild("exp")

local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local PlayerUi = {}

function PlayerUi.Init() end

return PlayerUi
