local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Common = require(Replicated.Systems.WeatherSystem.Weathers.Common)
local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)
local Rainy = require(script.Parent.Rainy)

local currentRate, isRaining, rainClone
local rainModel = script.Parent.Parent.Assets:WaitForChild("Rain")
local rainSound = game.SoundService.weather:WaitForChild("Raining")
local thunderSound = game.SoundService.weather:WaitForChild("Thunder Rumbling 3 (SFX)")
local wind = game.SoundService.weather:WaitForChild("Long Wind Loop")

local Stormy = {}

function Stormy:Start()
	Common.adjustDarkness(game.Lighting, "Ambient", 0.1)
	Common.adjustDarkness(game.Lighting, "OutdoorAmbient", 0.1)
	Common.animateColor(game.Lighting, "FogColor", Color3.new(0.623529, 0.678431, 0.737255))
	Common.animateColor(game.Lighting, "Brightness", -4)
	Common.setClouds(1, 0.9)
	Common.setFog(0, 150)

	task.wait(WeatherPresets.PARTICLE_DELAY)

	-- script.Script.RemoteEvent:FireAllClients(true, 5000)

	currentRate = 5000
	rainSound.Volume = 0
	rainClone = rainModel:Clone()
	rainSound:Play()
	TweenService:Create(rainSound, TweenInfo.new(1), { ["Volume"] = 0.5 }):Play()

	wind:Play()
	thunderSound:Play()

	isRaining = true
	rainClone.Parent = workspace.Weather
	toggleRainAnimation(currentRate)
	if isRaining then
		checkInOpen()
	end
end

function Stormy:Stop(nextWeather)
	if rainClone then
		rainClone:Destroy()
	end
	if nextWeather ~= "Rainy" then
		wind:Stop()
		thunderSound:Stop()
		isRaining = false
		toggleRainAnimation(0)
		if rainSound then
			rainSound:Stop()
		end
	end
end

function toggleRainAnimation(rate)
	if rainClone then
		for i, v in pairs(rainClone:GetChildren()) do
			if v:IsA("ParticleEmitter") and v.Name ~= "ParticleEmitter" then
				local tween = TweenService:Create(v, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { ["Rate"] = rate })
				tween:Play()
			end
		end
		task.wait(0.05)
	end
end

function checkInOpen()
	local previous = true

	while isRaining and rainClone do
		if workspace.CurrentCamera then
			local params = RaycastParams.new()
			params.RespectCanCollide = false
			if
				game.Players.LocalPlayer
				and game.Players.LocalPlayer.Character
				and game.Players.LocalPlayer:FindFirstChild("Humanoid")
			then
				params.FilterDescendantsInstances = { game.Players.LocalPlayer.Character }
			end

			local isOpen = workspace:Raycast(
				game.Players.LocalPlayer.Character:GetPivot().Position + Vector3.new(0, 3.5, 0),
				Vector3.new(0, 1000, 0),
				params
			)

			if isOpen == nil and not previous then
				toggleRainAnimation(currentRate)
			elseif isOpen ~= nil and previous then
				toggleRainAnimation(0)
			end

			previous = isOpen

			rainClone.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 5, 0)
		end
		task.wait(0.1)
	end
end

return Stormy
