local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Common = require(Replicated.Systems.WeatherSystem.Weathers.Common)
local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)
local Rainy = require(Replicated.Systems.WeatherSystem.Weathers.Rainy)

local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local rainClone, currentRate, isRaining
local wind = game.SoundService.weather:WaitForChild("Long Wind Loop")

local Snowy = {}

function Snowy:Start()
	game.Lighting.Brightness = originalBrightness - 2

	Common.colorGrassPartsToWhite()

	Common.adjustDarkness(game.Lighting, "OutdoorAmbient", 0.7)

	Common.adjustDarkness(game.Lighting, "Ambient", 0.6)
	if game.Lighting["FogColor"] then
		game.Lighting["FogColor"] = Color3.new(0.968627, 0.917647, 1)
	end

	Common.setClouds(0.2, 0.9)
	Common.setFog(10, 70)
	task.wait(WeatherPresets.PARTICLE_DELAY)
	-- script.Script.RemoteEvent:FireAllClients(true, 50)
	currentRate = 50
	rainClone = script.Parent.Parent.Assets:WaitForChild("Snow Particles"):Clone()
	wind:Play()

	isRaining = true
	rainClone.Parent = workspace.Weather
	toggleRainAnimation(currentRate)
	if isRaining then
		checkInOpen()
	end
end

function Snowy:Stop(nextWeather)
	wind:Stop()
	isRaining = false
	toggleRainAnimation(0)
	if rainClone then
		rainClone:Destroy()
	end
	if nextWeather ~= "Snowy" then
		Common.resetGrassParts()
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

return Snowy
