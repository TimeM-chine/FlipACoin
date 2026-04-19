--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Last Modified: 2024-03-14 7:06:07
--]]

---- types ----
type System = {
	Remotes: { RemoteEvent },
	whiteList: table,
	IsLoaded: boolean,
}

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local PhysicsService

---- requires ----
local CharacterPresets = require(script.Presets)
local Keys = require(Replicated.configs.Keys)
local Types = require(Replicated.configs.Types)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local ModelModule = require(Replicated.modules.ModelModule)
local dataKey = Keys.DataKey

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local playerHeadReady = {}
local PlayersCollisionGroup = Keys.CollisionGroup.Player

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local CharacterUi = { pendingCalls = {} }
setmetatable(CharacterUi, Types.mt)

local DASH_VELOCITY = Vector3.new(0, 0, -100)

local CharacterSystem: System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
CharacterSystem.__index = CharacterSystem

if IsServer then
	CharacterSystem.Client = setmetatable({}, CharacterSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)

	PhysicsService = game:GetService("PhysicsService")
	if not PhysicsService:IsCollisionGroupRegistered(PlayersCollisionGroup) then
		PhysicsService:RegisterCollisionGroup(PlayersCollisionGroup)
	end
	PhysicsService:CollisionGroupSetCollidable(PlayersCollisionGroup, PlayersCollisionGroup, false)
else
	CharacterSystem.Server = setmetatable({}, CharacterSystem)
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

function CharacterSystem:Init()
	GetSystemMgr()
end

function CharacterSystem:PlayerAdded(sender, player: Player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local character = player.Character

		local function BuildCharacter(model)
			if not player:HasAppearanceLoaded() then
				player.CharacterAppearanceLoaded:Wait()
			end
			local head = model:WaitForChild("Head")
			local onPlayerHead = StarterGui:WaitForChild("Templates"):WaitForChild("onPlayerHead"):Clone()
			onPlayerHead.Enabled = true
			onPlayerHead.Parent = head

			local Humanoid = model:WaitForChild("Humanoid")
			Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			Humanoid.AutoJumpEnabled = false
			Humanoid.UseJumpPower = false
			Humanoid.JumpHeight = 0
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
			SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
			ModelModule.SetModelCollisionGroup(model, Keys.CollisionGroup.Player)
		end

		if character then
			BuildCharacter(character)
		end

		player.CharacterAdded:Connect(function(model)
			BuildCharacter(model)
		end)

		self.Client:PlayerAdded(player)
	else
		local pendingCalls = CharacterUi.pendingCalls

		CharacterUi = require(script.ui)
		CharacterUi.Init()

		for _, call in ipairs(pendingCalls) do
			CharacterUi[call.functionName](table.unpack(call.args))
		end
	end
end

---- common ----

---- server ----

---- client ----

return CharacterSystem
