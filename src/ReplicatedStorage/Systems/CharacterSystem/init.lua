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
local HEAD_POSE_MIN_INTERVAL = 1 / 14
local HEAD_POSE_TIMEOUT = 0.6
local HEAD_POSE_PITCH_LIMIT = math.rad(35)
local HEAD_POSE_YAW_LIMIT = math.rad(90)
local HEAD_POSE_SMOOTH_ALPHA = 0.22
local NECK_PITCH_WEIGHT = 0.7
local NECK_YAW_WEIGHT = 0.72
local WAIST_YAW_WEIGHT = 0.22

---- server variables ----
local PlayerServerClass, AnalyticsService
local headPoseLastSentAt = {}
local headPoseTargets = {}
local headPoseStates = {}
local headPoseRenderConnection

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
	if IsServer then
		startHeadPoseRenderer()
	end
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

function CharacterSystem:PlayerRemoving(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		headPoseLastSentAt[player.UserId] = nil
		headPoseTargets[player.UserId] = nil
		headPoseStates[player.UserId] = nil
	else
	end
end

---- common ----

function CharacterSystem:HeadPoseChanged(sender, player, args)
	if IsServer then
		local sourcePlayer = sender == SENDER and player or sender
		local poseArgs = args or (sender ~= SENDER and player)
		if not sourcePlayer or not sourcePlayer:IsDescendantOf(Players) then
			return
		end
		if typeof(poseArgs) ~= "table" then
			return
		end

		local now = os.clock()
		local lastSentAt = headPoseLastSentAt[sourcePlayer.UserId]
		if typeof(lastSentAt) == "number" and now - lastSentAt < HEAD_POSE_MIN_INTERVAL then
			return
		end

		local pitch = tonumber(poseArgs.pitch)
		local yaw = tonumber(poseArgs.yaw)
		if not pitch or not yaw then
			return
		end

		local userId = sourcePlayer.UserId
		headPoseLastSentAt[userId] = now
		headPoseTargets[userId] = {
			pitch = math.clamp(pitch, -HEAD_POSE_PITCH_LIMIT, HEAD_POSE_PITCH_LIMIT),
			yaw = math.clamp(yaw, -HEAD_POSE_YAW_LIMIT, HEAD_POSE_YAW_LIMIT),
			updatedAt = now,
		}
	else
	end
end

---- server ----

function getHeadPoseMotor(character, motorName)
	local motor = character:FindFirstChild(motorName, true)
	if motor and motor:IsA("Motor6D") then
		return motor
	end

	return nil
end

function getHeadPoseRig(player)
	local character = player.Character
	if not character then
		return nil
	end

	local neck = getHeadPoseMotor(character, "Neck")
	if not neck then
		return nil
	end

	return {
		neck = neck,
		waist = getHeadPoseMotor(character, "Waist"),
	}
end

function getHeadPoseState(player)
	local rig = getHeadPoseRig(player)
	if not rig then
		return nil
	end

	local userId = player.UserId
	local state = headPoseStates[userId]
	if state and state.neck == rig.neck and state.waist == rig.waist then
		return state
	end

	state = {
		neck = rig.neck,
		waist = rig.waist,
		neckC0 = rig.neck.C0,
		waistC0 = rig.waist and rig.waist.C0 or nil,
		pitch = 0,
		yaw = 0,
	}
	headPoseStates[userId] = state
	return state
end

function applyHeadPose(player, target)
	local state = getHeadPoseState(player)
	if not state then
		return
	end

	state.pitch += (target.pitch - state.pitch) * HEAD_POSE_SMOOTH_ALPHA
	state.yaw += (target.yaw - state.yaw) * HEAD_POSE_SMOOTH_ALPHA

	state.neck.C0 = state.neckC0 * CFrame.Angles(state.pitch * NECK_PITCH_WEIGHT, state.yaw * NECK_YAW_WEIGHT, 0)
	if state.waist and state.waistC0 then
		state.waist.C0 = state.waistC0 * CFrame.Angles(0, state.yaw * WAIST_YAW_WEIGHT, 0)
	end
end

function startHeadPoseRenderer()
	if headPoseRenderConnection then
		return
	end

	headPoseRenderConnection = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local target = headPoseTargets[player.UserId]
			if not target or now - target.updatedAt > HEAD_POSE_TIMEOUT then
				target = {
					pitch = 0,
					yaw = 0,
					updatedAt = now,
				}
			end
			applyHeadPose(player, target)
		end
	end)
end

---- client ----

return CharacterSystem
