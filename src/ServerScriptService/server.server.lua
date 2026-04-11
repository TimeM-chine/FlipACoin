local ServerStorage = game:GetService("ServerStorage")
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local dataKey = Keys.DataKey

local DataMgr = require(ServerStorage.modules.DataManager)
local GlobalDataModule = require(ServerStorage.modules.GlobalDataModule)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

SystemMgr.Start()
GlobalDataModule.Init()

local BillboardManager = require(ServerStorage.modules.BillboardManager)
BillboardManager.initBillboard()

ScheduleModule.AddSchedule(60, function()
	BillboardManager.initBillboard()

	for _, player in pairs(Players:GetPlayers()) do
		local playerIns = PlayerServerClass.GetIns(player)

		local wins = playerIns:GetOneData(dataKey.wins)
		if wins then
			BillboardManager.savePlayerRankData(player.UserId, wins, "wins")
		end
	end
end)
