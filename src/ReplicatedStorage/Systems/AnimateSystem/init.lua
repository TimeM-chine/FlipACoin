--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.3
--Last Modified: 2024-05-24 8:50:00
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
while not AnimationClipProvider do
	task.wait(1)
	AnimationClipProvider = game:GetService("AnimationClipProvider")
end

---- requires ----
local AnimatePresets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local animateId = 0
local animTracks = {}

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer

local AnimateSystem: Types.System = {
	whiteList = {
		"GetAnimationTrack",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
AnimateSystem.__index = AnimateSystem

if IsServer then
	AnimateSystem.Client = setmetatable({}, AnimateSystem)
	AnimateSystem.AllClients = setmetatable({}, AnimateSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	AnimateSystem.Server = setmetatable({}, AnimateSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function AnimateSystem:Init()
	GetSystemMgr()
end

function AnimateSystem:PlayerAdded(sender, player)
	if IsServer then
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end
		local Character = player.Character or player.CharacterAdded:Wait()
	end
end

function AnimateSystem:PlayerRemoving(sender, player)
	if IsServer then
		animTracks[player.UserId] = nil
	end
end

type PlayAnimationArgs = {
	actor: Model,
	animName: string,
	animKey: string,
	secondKey: string, -- if didn't find anim in animKey, will try to find in secondKey
	priority: Enum.AnimationPriority,
	speed: number,
	looped: boolean,
	shouldPlay: boolean,
	onServer: boolean,
}
local function PlayAnimation(args)
	local actor = args.actor
	local animKey = args.animKey
	local secondKey = args.secondKey
	local animName = args.animName
	local shouldPlay = args.shouldPlay == nil and true or args.shouldPlay

	local identifier
	if actor:IsDescendantOf(Players) then
		animKey = "player"
		identifier = actor.UserId
		actor = actor.Character or actor.CharacterAdded:Wait()
	else
		identifier = actor:GetAttribute("AnimateIdentifier")
		if not identifier then
			animateId += 1
			actor:SetAttribute("AnimateIdentifier", "animate" .. animateId)
			identifier = "animate" .. animateId
		end
	end

	if (not AnimatePresets.Animations[animKey]) or not AnimatePresets.Animations[animKey][animName] then
		if not AnimatePresets.Animations[secondKey][animName] then
			warn(`No animation {animName} in {animKey} or {secondKey}`)
			return
		end
		animKey = secondKey
	end

	if not animTracks[identifier] then
		animTracks[identifier] = {}
		actor.Destroying:Connect(function(child, parent)
			print("Destroying animTracks", actor)
			for _, track in pairs(animTracks[identifier]) do
				track:Stop()
				track:Destroy()
			end
			animTracks[identifier] = nil
		end)
	end

	if animTracks[identifier][animName] then
		if shouldPlay then
			animTracks[identifier][animName]:Play()
			animTracks[identifier][animName]:AdjustSpeed(args.speed)
		end
		return animTracks[identifier][animName]
	end

	local priority = args.priority or AnimatePresets.Animations[animKey][animName].priority
	local speed = args.speed or AnimatePresets.Animations[animKey][animName].speed
	local looped = args.looped or AnimatePresets.Animations[animKey][animName].looped

	local humanoid = actor:FindFirstChild("Humanoid")
	local animator
	if humanoid then
		animator = humanoid:FindFirstChild("Animator")
	else
		animator = actor:FindFirstChild("Animator", true)
	end

	local loopTime = 1
	while not animator:IsDescendantOf(workspace) do
		loopTime += 1
		task.wait(1)
		if loopTime > 5 then
			warn("PlayAnimation: No animator found", animator, animator.Parent, animator.Parent.Parent, actor)
			return
		end
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = AnimatePresets.Animations[animKey][animName].id
	-- print(animator, animator.Parent, args)
	animTracks[identifier][animName] = animator:LoadAnimation(animation)
	-- animTracks[identifier][animName] = {
	--     Play = function()
	--     end,
	--     Stop = function()
	--     end,
	--     AdjustSpeed = function()
	--     end,
	--     Priority = priority,
	--     Looped = looped,
	-- }
	animTracks[identifier][animName].Priority = priority
	animTracks[identifier][animName].Looped = looped
	if shouldPlay then
		animTracks[identifier][animName]:Play()
		animTracks[identifier][animName]:AdjustSpeed(speed)
	end
	return animTracks[identifier][animName] :: AnimationTrack
end

function AnimateSystem:PlayAnimation(sender, player, args: PlayAnimationArgs)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local onServer = args.onServer or true

		if not onServer then
			self.AllClients:PlayAnimation(args)
			return
		end

		return PlayAnimation(args)
	else
		return PlayAnimation(args)
	end
end

function AnimateSystem:GetAnimationTrack(sender, player, args)
	args.shouldPlay = false
	return self:PlayAnimation(sender, player, args)
end

function AnimateSystem:StopAnimation(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local actor = args.actor
		local animName = args.animName

		local identifier
		if actor:IsDescendantOf(Players) then
			identifier = actor.UserId
		else
			identifier = actor:GetAttribute("AnimateIdentifier")
		end

		if not identifier then
			warn("StopAnimation: No identifier found", args)
			return
		end

		local onServer = args.onServer or true
		if not onServer then
			self.AllClients:StopAnimation(args)
			return
		end

		if not animTracks[identifier][animName] then
			warn("StopAnimation: No animation found", args)
			return
		end

		animTracks[identifier][animName]:Stop()
	else
		local actor = args.actor
		local animName = args.animName
		local identifier
		if actor:IsDescendantOf(Players) then
			identifier = actor.UserId
		else
			identifier = actor:GetAttribute("AnimateIdentifier")
		end

		if not identifier then
			warn("StopAnimation: No identifier found", args)
			return
		end

		if not animTracks[identifier][animName] then
			-- warn("StopAnimation: No animation found", args)
			return
		end

		animTracks[identifier][animName]:Stop()
	end
end

function AnimateSystem:StopAllAnimation(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local actor = args.actor
		if not actor:IsDescendantOf(Players) then
			local identifier = actor:GetAttribute("AnimateIdentifier")
			if not animTracks[identifier] then
				animTracks[identifier] = {}
			end
			for animName, track in pairs(animTracks[identifier]) do
				track:Stop()
			end
			self.AllClients:StopAllAnimation(args)
			return
		else
			actor = actor.Character
		end

		if not animTracks[player.UserId] then
			animTracks[player.UserId] = {}
		end

		for animName, track in pairs(animTracks[player.UserId]) do
			track:Stop()
		end
	else
		local actor = args.actor
		local identifier = actor:GetAttribute("AnimateIdentifier")
		if not animTracks[identifier] then
			animTracks[identifier] = {}
		end

		for animName, track in pairs(animTracks[identifier]) do
			track:Stop()
		end
	end
end

return AnimateSystem
