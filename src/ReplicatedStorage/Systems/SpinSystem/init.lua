--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local SpinPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local TableModule = require(Replicated.modules.TableModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData, SpinUi

local SpinSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
SpinSystem.__index = SpinSystem

if IsServer then
	SpinSystem.Client = setmetatable({}, SpinSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	SpinSystem.Server = setmetatable({}, SpinSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function SpinSystem:Init()
	GetSystemMgr()
end

function SpinSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local waitingSpinTime = playerIns:GetOneData(dataKey.waitingSpinTime)
		if waitingSpinTime ~= -1 and os.time() - waitingSpinTime >= SpinPresets.FreeSpinInterval then
			playerIns:AddOneData(dataKey.spin, 1)
			if playerIns:GetOneData(dataKey.spin) < 3 then
				playerIns:SetOneData(dataKey.waitingSpinTime, os.time())
			else
				playerIns:SetOneData(dataKey.waitingSpinTime, -1)
			end
		else
			if waitingSpinTime == -1 and playerIns:GetOneData(dataKey.spin) < 3 then
				playerIns:SetOneData(dataKey.waitingSpinTime, os.time())
			end
		end

		args = {
			spin = playerIns:GetOneData(dataKey.spin),
			waitingSpinTime = playerIns:GetOneData(dataKey.waitingSpinTime),
		}

		self.Client:PlayerAdded(player, args)
	else
		ClientData:SetDataTable(args)
		SpinUi = require(script.ui)
		SpinUi.Init()
	end
end

function SpinSystem:AddSpin(sender, player, args: { count: number })
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local count = args.count or 1
		local reason = args.reason or "waiting"
		local playerIns = PlayerServerClass.GetIns(player)
		playerIns:AddOneData(dataKey.spin, count)

		if playerIns:GetOneData(dataKey.spin) >= 3 then
			if reason == "waiting" then
				playerIns:SetOneData(dataKey.waitingSpinTime, -1)
			end
		else
			local waitingSpinTime = playerIns:GetOneData(dataKey.waitingSpinTime)
			if waitingSpinTime == -1 then
				playerIns:SetOneData(dataKey.waitingSpinTime, os.time())
			end

			if reason == "waiting" then
				playerIns:SetOneData(dataKey.waitingSpinTime, os.time())
			else
				-- nothing
			end
		end

		args = {
			spin = playerIns:GetOneData(dataKey.spin),
			waitingSpinTime = playerIns:GetOneData(dataKey.waitingSpinTime),
		}
		self.Client:AddSpin(player, args)
	else
		ClientData:SetDataTable(args)
		SpinUi.AddSpin()
	end
end

function SpinSystem:TrySpin(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local spin = playerIns:GetOneData(dataKey.spin)
		if spin > 0 then
			self:AddSpin(SENDER, player, { count = -1, reason = "spin" })
			self:Spin(SENDER, player)
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You don't have enough spins",
			})
		end
	end
end

function SpinSystem:TryAddFreeSpin(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local waitingSpinTime = playerIns:GetOneData(dataKey.waitingSpinTime)
		if os.time() - waitingSpinTime >= SpinPresets.FreeSpinInterval then
			self:AddSpin(SENDER, player, { count = 1 })
		end
	end
end

function SpinSystem:Spin(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local pool = {}

		for i, reward in ipairs(SpinPresets.Rewards) do
			pool[i] = reward.weight
		end

		local rewardIndex = TableModule.Choices(pool, 1, true)[1]
		local reward = SpinPresets.Rewards[rewardIndex]

		local playerIns = PlayerServerClass.GetIns(player)
		local rebirth = playerIns:GetOneData(dataKey.rebirth)
		rebirth = rebirth == 0 and 1 or rebirth
		task.delay(5, function()
			for _, item in ipairs(reward.items) do
				item.reason = "Spin"
				local count = item.count
				if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, item.itemType) then
					count = count * rebirth * rebirth
				end
				SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, {
					itemType = item.itemType,
					count = count,
					name = item.name,
					reason = "Spin",
				})
			end
		end)

		args = {
			rewardIndex = rewardIndex,
			spin = playerIns:GetOneData(dataKey.spin),
		}
		AnalyticsService:LogCustomEvent(player, "spin")
		self.Client:Spin(player, args)
	else
		ClientData:SetOneData(dataKey.spin, args.spin)
		SpinUi.Spin(args)
	end
end

return SpinSystem
