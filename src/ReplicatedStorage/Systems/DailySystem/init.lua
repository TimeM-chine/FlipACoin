--[[
--Author: TimeM_chine
--Created Date: Fri May 17 2024
--Description: init.lua
--Version: 1.0
--Last Modified: 2024-05-17 6:26:35
--]]

---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Types = require(Replicated.configs.Types)
local DailyPresets = require(script.Presets)
local Textures = require(Replicated.configs.Textures)
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ItemType = Keys.ItemType

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local DAILY_STATE = {
	claimed = 2,
	active = 1,
	notReady = 0,
}

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local DailyUi = { pendingCalls = {} }
setmetatable(DailyUi, Types.mt)

local DailySystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
DailySystem.__index = DailySystem

if IsServer then
	DailySystem.Client = setmetatable({}, DailySystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	DailySystem.Server = setmetatable({}, DailySystem)
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function DailySystem:Init()
	if IsServer then
		local ConfigService = game:GetService("ConfigService")
		local config = ConfigService:GetConfigAsync()
		local DAY_2_REWARD = "Day2Reward"
		local Day2Reward = config:GetValue(DAY_2_REWARD)
		local stringValue = Instance.new("StringValue")
		stringValue.Name = "Day2Reward"
		stringValue.Value = Day2Reward
		stringValue.Parent = script.Presets
		DailyPresets.GiftList[2].name = Day2Reward
	end

	GetSystemMgr()
end

function DailySystem:PlayerAdded(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end
		local dailyClaim = playerIns:GetOneData(dataKey.dailyClaim)
		local loginTime = playerIns:GetOneData(dataKey.loginTime)
		local now = os.time()
		local lastDay = math.floor(loginTime / GameConfig.OneDay)
		local today = math.floor(now / GameConfig.OneDay)
		if lastDay ~= today then
			for i = 1, #DailyPresets.GiftList do
				if not dailyClaim[i] then
					dailyClaim[i] = DAILY_STATE.active
					break
				end

				if i == #DailyPresets.GiftList then
					playerIns:SetOneData(dataKey.dailyClaim, { DAILY_STATE.active })
				end
			end
			playerIns:SetOneData(dataKey.loginTime, now)
		end
		args = {
			dailyClaim = playerIns:GetOneData(dataKey.dailyClaim),
		}
		self.Client:PlayerAdded(player, args)
	else
		ClientData:SetOneData(dataKey.dailyClaim, args.dailyClaim)
		local pendingCalls = DailyUi.pendingCalls

		DailyUi = require(script.ui)
		DailyUi.Init(args)

		for _, call in ipairs(pendingCalls) do
			DailyUi[call.functionName](table.unpack(call.args))
		end
	end
end

function DailySystem:TryClaimGift(sender, player, args)
	if IsServer then
		player = player or sender
		local dayIndex = args.dayIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local dailyClaim = playerIns:GetOneData(dataKey.dailyClaim)
		if dailyClaim[dayIndex] == DAILY_STATE.active then
			self:GiveGift(SENDER, player, {
				dayIndex = dayIndex,
			})
			dailyClaim[dayIndex] = DAILY_STATE.claimed
		elseif dailyClaim[dayIndex] == DAILY_STATE.claimed then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You have claimed this gift.",
				textColor = Color3.fromRGB(255, 0, 0),
			})
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Claim it another day.",
			})
		end
	end
end

function DailySystem:GiveGift(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		AnalyticsService:LogCustomEvent(player, "ClaimDaily", args.dayIndex)
		local gift = DailyPresets.GiftList[args.dayIndex]
		gift.reason = "daily"
		local playerIns = PlayerServerClass.GetIns(player)
		local rebirth = playerIns:GetOneData(dataKey.rebirth)
		rebirth = rebirth == 0 and 1 or rebirth
		local count = gift.count
		if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, gift.itemType) then
			count = count * rebirth * rebirth
		end
		SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, {
			itemType = gift.itemType,
			count = count,
			name = gift.name,
			reason = "daily",
		})
		self.Client:GiveGift(player, args)
	else
		DailyUi.ReceivedGift(args)
	end
end

return DailySystem
