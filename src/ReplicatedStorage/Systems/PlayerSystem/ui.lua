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

local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local PlayerUi = {}
local cashText = Elements:FindFirstChild("cash")
local cashSyncStarted = false

local function syncLegacyCashText()
	if not cashText or not cashText.Parent then
		return
	end

	cashText.Text = Util.FormatNumber(ClientData:GetOneData(dataKey.wins) or 0)
end

function PlayerUi.Init()
	syncLegacyCashText()
	if cashSyncStarted then
		return
	end

	cashSyncStarted = true
	task.spawn(function()
		while cashText and cashText.Parent do
			syncLegacyCashText()
			task.wait(0.2)
		end
		cashSyncStarted = false
	end)
end

return PlayerUi
