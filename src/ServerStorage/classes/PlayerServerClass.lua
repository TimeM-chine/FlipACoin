--[[
--Author: TimeM_chine
--Created Date: Tue Jan 16 2024
--Description: player cls --> server side, universal player cls
--Version: 1.3.0 -- fix GetIns safety, remove self-managed PlayerRemoving
--Last Modified: 2026-03-23
--]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Replicated = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

---- requires  ----
local DataMgr = require(ServerStorage.modules.DataManager)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey

---- configs ----
local GameConfig = require(Replicated.configs.GameConfig)

---- variables ----
local playerInsList = {}

---- main ----
local PlayerServerClass = {}
PlayerServerClass.__index = PlayerServerClass
PlayerServerClass.player = nil

local function CreatePlayerIns(player: Player)
	-- Safety: never create an instance for a player who already left
	if not player:IsDescendantOf(Players) then
		return
	end

	local playerIns = setmetatable({}, PlayerServerClass)
	playerIns.player = player
	if not playerIns:WaitForDataLoaded() then
		return
	end
	if not playerInsList[player.UserId] then
		print(`  --> Created {player.name} ins`)
		player.CharacterAdded:Connect(function(character)
			playerIns:InitCharacter(character)
		end)
		player.Chatted:Connect(function(message, recipient)
			playerIns:OnChatted(message, recipient)
		end)
		playerInsList[player.UserId] = playerIns
	end
	return playerIns
end

-- default: create instance if player is still in the game
function PlayerServerClass.GetIns(player, createIfNil)
	if not playerInsList[player.UserId] then
		-- createIfNil = createIfNil == nil and true or false
		if createIfNil then
			return CreatePlayerIns(player)
		end
	else
		return playerInsList[player.UserId]
	end
end

-- NOTE: PlayerRemoving is NOT handled here.
-- SystemMgr calls RemoveIns() at the correct time (after all systems finish cleanup).

-- Called by SystemMgr after DataManager:ReleaseProfile
function PlayerServerClass.RemoveIns(player)
	playerInsList[player.UserId] = nil
end

function PlayerServerClass:WaitForDataLoaded()
	local profileLoaded = self.player:WaitForChild("profileLoaded", 15)
	if not profileLoaded then
		self.player:Kick("There seems to be some problem with your network, please try again later.")
	else
		return true
	end
end

function PlayerServerClass:GetOneData(key)
	return DataMgr:GetPlayerOneData(self.player, key)
end

function PlayerServerClass:GetAllData()
	return DataMgr:GetPlayerAllData(self.player)
end

function PlayerServerClass:SetOneData(key, value)
	return DataMgr:SetPlayerOneData(self.player, key, value)
end

function PlayerServerClass:ResetPlayerData()
	return DataMgr:ResetPlayerData(self.player)
end

function PlayerServerClass:ResetPlayerOneData(key)
	return DataMgr:ResetPlayerOneData(self.player, key)
end

function PlayerServerClass:AddOneData(key, num)
	local oldValue = self:GetOneData(key)
	if not oldValue then
		print("Value not found", self.player.Name, key)
		return
	end
	self:SetOneData(key, oldValue + num)
end

function PlayerServerClass:InitCharacter(character) end

function PlayerServerClass:OnChatted(message, recipient)
	if (not table.find(GameConfig.DevIds, self.player.UserId)) and (not RunService:IsStudio()) then
		return
	end
	local SystemMgr = require(Replicated.Systems.SystemMgr)
	local SENDER = SystemMgr.SENDER
	if message == "/reset data" then
		self:ResetPlayerData()
	elseif string.match(message, "/wins (%d+)") then
		SystemMgr.systems.EcoSystem:AddResource(SENDER, self.player, {
			resourceType = "wins",
			count = tonumber(string.match(message, "/wins (%d+)")),
		})
	elseif string.match(message, "/candy (%d+)") then
		SystemMgr.systems.EventSystem:AddWins(SENDER, self.player, {
			count = tonumber(string.match(message, "/candy (%d+)")),
		})
	elseif string.match(message, "/exp (%d+)") then
		SystemMgr.systems.GrassSystem:AddExp(SENDER, self.player, {
			exp = tonumber(string.match(message, "/exp (%d+)")),
		})
	end
end

function PlayerServerClass:LogOnboarding(step, stepName)
	local onboardingFunnelStep = self:GetOneData(dataKey.onboardingFunnelStep)
	if onboardingFunnelStep >= step then
		return
	end
	AnalyticsService:LogOnboardingFunnelStepEvent(self.player, step, stepName)
	self:SetOneData(dataKey.onboardingFunnelStep, step)
	self.player:SetAttribute("onboardingFunnelStep", step)
end

----[[ not that universal functions ]] ----
function PlayerServerClass:IsVip()
	local gamePasses = self:GetOneData(dataKey.gamePasses)
	return gamePasses.vip
end

return PlayerServerClass
