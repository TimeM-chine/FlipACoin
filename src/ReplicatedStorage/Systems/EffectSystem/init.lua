--[[
--Author: TimeM_chine
--Created Date: Sat Mar 16 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-05-25 10:18:29
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

---- requires ----
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer

---- [[ UI ]] ----
local PlayerGui, Main, uiController

local EffectSystem: Types.System = {
	whiteList = {
		"PlayInsideEffects",
		"ToggleInsideEffects",
	},
	players = {},
	IsLoaded = false,
}
EffectSystem.__index = EffectSystem

if IsServer then
	EffectSystem.Client = setmetatable({}, EffectSystem)
	EffectSystem.AllClients = setmetatable({}, EffectSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	EffectSystem.Server = setmetatable({}, EffectSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function EffectSystem:Init()
	GetSystemMgr()
end

function EffectSystem:PlayEffects(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		args.unreliable = true
		self.AllClients:PlayEffects(args)
	else
		local effectName = args.effectName
		local folderName = args.folderName
		local targetPart = args.targetPart
		local targetCFrame = args.targetCFrame
		local lifeTime = args.lifeTime or 5
		if not targetCFrame then
			targetCFrame = targetPart.CFrame
		end
		local bind = args.bind

		local folder
		if folderName then
			folder = script.Assets.Effects:FindFirstChild(folderName)
			if not folder then
				warn("Folder not found: ", folderName)
				return
			end
		else
			folder = script.Assets.Effects
		end
		local effectPart = folder:FindFirstChild(effectName)
		if not effectPart then
			warn("Effect not found: ", effectName)
			return
		end
		local effectP = effectPart:Clone()
		if effectPart:IsA("BasePart") then
			effectP.Massless = true
			effectP.CFrame = targetCFrame
		elseif effectP:IsA("Model") then
			for _, part in effectP:GetDescendants() do
				if part:IsA("BasePart") then
					part.Massless = true
				end
			end
			effectP:PivotTo(targetCFrame)
		else
			warn("Effect not supported: ", effectName)
			return
		end
		if bind then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = effectP:IsA("Model") and effectP.PrimaryPart or effectP
			weld.Part1 = targetPart
			weld.Parent = effectP
			effectP.Parent = workspace
		else
			effectP.Parent = workspace
		end
		self:PlayInsideEffects(effectP)
		Debris:AddItem(effectP, lifeTime)
		return effectP
	end
end

---- [[ Client ]] ----
function EffectSystem:PlayInsideEffects(container)
	-- local particleRateFactor = SystemMgr.systems.SettingsSystem:GetParticleRateFactor()
	local particleRateFactor = 1
	if particleRateFactor == 0 then
		return
	end
	local nValue = container:FindFirstChild("totalDelay")
	local totalDelay = nValue and nValue.Value or 0

	task.delay(totalDelay, function()
		for _, particle in container:GetDescendants() do
			if particle:IsA("ParticleEmitter") then
				particle.Rate = math.max(math.floor(particle.Rate * particleRateFactor + 1e-5), 1)
				if particle:GetAttribute("EmitDelay") then
					task.delay(particle:GetAttribute("EmitDelay"), function()
						if particle:GetAttribute("EmitDuration") then
							particle.Enabled = true
							task.delay(particle:GetAttribute("EmitDuration"), function()
								particle.Enabled = false
							end)
						else
							-- particle:Emit(math.ceil(particle.Rate * 0.1))
							particle:Emit(particle.Rate)
						end
					end)
				else
					-- particle:Emit(math.ceil(particle.Rate * 0.1))
					particle:Emit(particle.Rate)
				end
			end

			if particle:IsA("Beam") then
				if particle:GetAttribute("EmitDelay") then
					task.delay(particle:GetAttribute("EmitDelay"), function()
						particle.Enabled = true
					end)
				else
					particle.Enabled = true
				end

				if particle:GetAttribute("EmitDuration") then
					task.delay(particle:GetAttribute("EmitDuration"), function()
						particle.Enabled = false
					end)
				else
					task.delay(5, function()
						particle.Enabled = false
					end)
				end
			end
		end
	end)
end

function EffectSystem:ToggleInsideEffects(container, toggle)
	for _, particle in container:GetDescendants() do
		if
			particle:IsA("ParticleEmitter")
			or particle:IsA("Beam")
			or particle:IsA("Trail")
			or particle:IsA("PointLight")
		then
			particle.Enabled = toggle
		end
	end
end

return EffectSystem
