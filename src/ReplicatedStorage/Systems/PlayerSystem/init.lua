--[[
--Author: TimeM_chine
--Created Date: Mon Oct 16 2023
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-05-25 5:35:19
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

---- requires ----
local PlayerPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey
local playerState = Keys.PlayerState

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData

---- [[ UI ]] ----
local PlayerUi = { pendingCalls = {} }
setmetatable(PlayerUi, Types.mt)

local PlayerSystem: Types.System = {
	whiteList = {
		"GetPlayerData",
		"UpdateLeaderStats",
		"UpdatePlayerHeadGui",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
PlayerSystem.__index = PlayerSystem

if IsServer then
	PlayerSystem.Client = setmetatable({}, PlayerSystem)
	PlayerSystem.AllClients = setmetatable({}, PlayerSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	PlayerSystem.Server = setmetatable({}, PlayerSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function PlayerSystem:Init()
	GetSystemMgr()
end

function PlayerSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		if playerIns:GetOneData(dataKey.createTime) == 0 then
			local badges = playerIns:GetOneData(dataKey.badges) or {}
			if not badges["Welcome"] then
				Util.awardBadge(player, GameConfig.Badges.Welcome)
				badges["Welcome"] = true
			end
			playerIns:SetOneData(dataKey.createTime, os.time())
			self:InitData(player)
		end
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "login")

		-- CreateTimer(player)
		CreateLeaderStats(player)
		args = {
			data = playerIns:GetAllData(),
		}

		self.Client:PlayerAdded(player, args)
	else
		ClientData = require(Replicated.Systems.ClientData)
		ClientData.InitData(args.data)

		local pendingCalls = PlayerUi.pendingCalls

		PlayerUi = require(script.ui)
		PlayerUi.Init()

		for _, call in ipairs(pendingCalls) do
			PlayerUi[call.functionName](table.unpack(call.args))
		end
		-- local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		-- local animator: Animator = Character:WaitForChild("Humanoid"):WaitForChild("Animator")
		-- ScheduleModule.AddSchedule(5, function()
		-- 	warn("-------------------")
		-- 	local tracks = animator:GetPlayingAnimationTracks()
		-- 	for _, track in tracks do
		-- 		print(track, track.Animation.AnimationId, track.Priority)
		-- 	end
		-- end)
	end
end

function PlayerSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.players[player.UserId] = nil
	end
end

function PlayerSystem:AddExp(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		if args.exp then
			playerIns:AddOneData(dataKey.exp, args.exp)
		end

		local exp = playerIns:GetOneData(dataKey.exp)
		local level = playerIns:GetOneData(dataKey.level)

		while exp >= PlayerPresets.Levels[level].levelUpExp do
			exp = exp - PlayerPresets.Levels[level].levelUpExp
			level = level + 1
			if not PlayerPresets.Levels[level] then
				break
			end
		end

		playerIns:SetOneData(dataKey.level, level)
		playerIns:SetOneData(dataKey.exp, exp)
		self.Client:AddExp(player, {
			exp = exp,
			level = level,
		})
	else
		ClientData:SetOneData(dataKey.exp, args.exp)
		ClientData:SetOneData(dataKey.level, args.level)
		PlayerUi.AddExp()
	end
end

-----------[[ change attributes ]]-----------

function PlayerSystem:Rebirth(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		playerIns:SetOneData(dataKey.power, 1)
		args = {
			reason = "rebirth",
			power = 1,
		}

		local leaderStats = player:FindFirstChild("leaderstats")
		if leaderStats then
			leaderStats:FindFirstChild("Rebirth").Value = playerIns:GetOneData(dataKey.rebirth)
		end

		if
			player.Character
			and player.Character:FindFirstChild("Head")
			and player.Character:FindFirstChild("Head"):FindFirstChild("OnPlayerHead")
		then
			local headGui = player.Character:FindFirstChild("Head"):FindFirstChild("OnPlayerHead")
			headGui.name.Text = `{player.DisplayName} Lv.{playerIns:GetOneData(dataKey.rebirth)}`
			headGui.power.Text = "Power: 1"
		end

		self.Client:Rebirth(player, args)
	else
		ClientData:SetOneData(dataKey.power, args.power)
		PlayerUi.AddPower(args)
	end
end

---- [[ common ]] ----

---- [[ server ]] ----
-- function CreateTimer(player)
-- 	local timer = Instance.new("NumberValue")
-- 	timer.Name = "timer"
-- 	timer.Parent = player
-- 	task.spawn(function()
-- 		while task.wait(1) do
-- 			if not player:IsDescendantOf(Players) then
-- 				break
-- 			end
-- 			timer.Value += 1
-- 		end
-- 	end)
-- end

function CreateLeaderStats(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "leaderstats"
	leaderStats.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Cash"
	wins.Value = playerIns:GetOneData(dataKey.wins)
	wins.Parent = leaderStats
end

function PlayerSystem:UpdateLeaderStats(player)
	local leaderStats = player:FindFirstChild("leaderstats")
	if not leaderStats then
		return
	end

	local playerIns = PlayerServerClass.GetIns(player)
	leaderStats:FindFirstChild("Cash").Value = playerIns:GetOneData(dataKey.wins)
end

function PlayerSystem:UpdatePlayerHeadGui(player: Player)
	GetSystemMgr()
	local playerIns = PlayerServerClass.GetIns(player, false)
	if not playerIns then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local onPlayerHead = head:FindFirstChild("onPlayerHead") or head:FindFirstChild("OnPlayerHead")
	if not onPlayerHead then
		return
	end
	onPlayerHead.name.Text = player.DisplayName

	local runData = playerIns:GetOneData(dataKey.runData) or {}
	local seatId = SystemMgr.systems.TableSeatSystem:GetPlayerSeatId(player)
	local streak = runData.currentStreak or 0
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin) or "Rusty Penny"

	onPlayerHead.vip.Visible = true
	onPlayerHead.vip.Text = seatId or "Spectating"
	onPlayerHead.cardPackOpened.Visible = true
	onPlayerHead.cardPackOpened.Text = `Streak {streak} | {equippedCoin}`
	onPlayerHead.cash.Text = `$ {Util.FormatNumber(playerIns:GetOneData(dataKey.wins), true)}`
end

table.insert(PlayerSystem.whiteList, "InitData")
function PlayerSystem:InitData(player)
	local playerIns = PlayerServerClass.GetIns(player)
end

---- [[ client ]] ----

return PlayerSystem
