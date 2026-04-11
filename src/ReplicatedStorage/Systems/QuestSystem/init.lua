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
local QuestPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local QuestUi = { pendingCalls = {} }
setmetatable(QuestUi, Types.mt)

local QuestSystem: Types.System = {
	whiteList = {
		"DoQuest",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
QuestSystem.__index = QuestSystem

if IsServer then
	QuestSystem.Client = setmetatable({}, QuestSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	QuestSystem.Server = setmetatable({}, QuestSystem)
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

function QuestSystem:Init()
	GetSystemMgr()
end

function QuestSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		self.Client:PlayerAdded(player, args)

		local quests = playerIns:GetOneData(dataKey.quests)
		if not quests.index then
			self:SetQuest(SENDER, player, {
				index = 1,
			})
		else
			local questConfig = QuestPresets.Quests[quests.index]
			for i, quest in quests.quests do
				if quest.questType ~= questConfig.quests[i].questType then
					self:SetQuest(SENDER, player, {
						index = quests.index,
					})
					break
				end
			end

			if #quests.quests ~= #questConfig.quests then
				self:SetQuest(SENDER, player, {
					index = quests.index,
				})
			end
		end
	else
		local pendingCalls = QuestUi.pendingCalls

		QuestUi = require(script.ui)
		QuestUi.Init()

		for _, call in ipairs(pendingCalls) do
			QuestUi[call.functionName](table.unpack(call.args))
		end
	end
end

function QuestSystem:AddProgress(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local questType = args.questType
		local value = args.value
		local name = args.name

		local playerIns = PlayerServerClass.GetIns(player)
		local quests = playerIns:GetOneData(dataKey.quests)
		if not quests or not quests.index or not quests.quests then
			self:SetQuest(SENDER, player, {
				index = 1,
			})
			quests = playerIns:GetOneData(dataKey.quests)
			if not quests or not quests.quests then
				return
			end
		end
		local questsUpdated = {}

		for i, quest in quests.quests do
			-- Check if the quest matches the questType
			if quest.questType == questType then
				if quest.isCompleted then
					continue
				end

				if string.find(questType, "Named") and quest.name ~= name then
					continue
				end

				quest.current = math.min(quest.current + value, quest.target)
				if quest.current == quest.target then
					local questIndex = quests.index
					if questIndex + 1 <= 40 then
						AnalyticsService:LogOnboardingFunnelStepEvent(
							player,
							questIndex * 2,
							`CompletedQuest_{questIndex}`
						)
					end
					AnalyticsService:LogCustomEvent(player, "CompleteQuest", 1, {
						[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = questIndex,
					})
					quest.isCompleted = true
				end

				table.insert(questsUpdated, { index = i, quest = quest })
			end
		end

		if #questsUpdated > 0 then
			args = {
				quests = quests,
				questsUpdated = questsUpdated,
			}
			self.Client:AddProgress(player, args)

			local questIndex = quests.index
			if questIndex and questIndex <= 3 and not quests.completed then
				local allCompleted = true
				for _, quest in quests.quests do
					if not quest.isCompleted then
						allCompleted = false
						break
					end
				end
				if allCompleted then
					task.delay(0.2, function()
						self:ClaimRewards(SENDER, player)
					end)
				end
			end
		end
	else
		ClientData:SetOneData(dataKey.quests, args.quests)
		QuestUi.AddProgress(args)
	end
end

function QuestSystem:ClaimRewards(sender, player, args)
	if IsServer then
		player = player or sender

		local playerIns = PlayerServerClass.GetIns(player)
		local quests = playerIns:GetOneData(dataKey.quests)
		for _, quest in quests.quests do
			if not quest.isCompleted then
				SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
					text = "You have uncompleted quests!",
					textColor = Color3.fromRGB(255, 0, 0),
				})
				return
			end
		end

		local questIndex = quests.index
		local questConfig = QuestPresets.Quests[questIndex]
		for _, reward in questConfig.rewards do
			reward.reason = "Quest"
			SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, reward)
		end

		if questIndex + 1 <= 40 then
			AnalyticsService:LogOnboardingFunnelStepEvent(player, questIndex * 2 + 1, `ClaimReward_{questIndex}`)
		end
		AnalyticsService:LogCustomEvent(player, "ClaimQuest", 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = questIndex,
		})

		local hasNext = QuestPresets.Quests[questIndex + 1] ~= nil
		if hasNext then
			self:SetQuest(SENDER, player, {
				index = questIndex + 1,
			})
		else
			quests.completed = true
			self.Client:SetQuest(player, {
				quests = quests,
			})
		end
	end
end

function QuestSystem:SetQuest(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local index = args.index
		local playerIns = PlayerServerClass.GetIns(player)
		local quests = playerIns:GetOneData(dataKey.quests)
		quests.index = index
		quests.completed = false
		quests.quests = {}

		for i, v in ipairs(QuestPresets.Quests[index].quests) do
			quests.quests[i] = {
				target = v.target,
				questType = v.questType,
				name = v.name,
				current = 0,
				isCompleted = false,
			}
		end

		self.Client:SetQuest(player, {
			quests = quests,
		})
	else
		ClientData:SetOneData(dataKey.quests, args.quests)
		QuestUi.SetQuest()
	end
end

---- [[ Server ]] ----
function QuestSystem:DoQuest(player, args: { questType: string, value: number, name: string })
	local questType = args.questType
	local value = args.value
	local name = args.name

	self:AddProgress(SENDER, player, {
		questType = questType,
		value = value,
		name = name,
	})

	-- SystemMgr.systems.SeasonSystem:AddQuestProgress(SENDER, player, args)
end

return QuestSystem
