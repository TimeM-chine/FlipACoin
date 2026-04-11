local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)
local Common = require(script.Parent.Common)

local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local rainClone, currentRate, isRaining
local rainModel = script.Parent.Parent.Assets:WaitForChild("Rain")
local rainSound = rainModel:WaitForChild("Raining")
local thunderSound = rainModel["Thunder Rumbling 3 (SFX)"]
local wind = rainModel["Long Wind Loop"]

local soundGroup = game.SoundService:WaitForChild("weather")
if not soundGroup:FindFirstChild("Raining") then
	rainSound.Parent = soundGroup
	rainSound.SoundGroup = soundGroup
else
	rainSound = soundGroup:FindFirstChild("Raining")
end

if not soundGroup:FindFirstChild("Thunder Rumbling 3 (SFX)") then
	thunderSound.Parent = soundGroup
	thunderSound.SoundGroup = soundGroup
else
	thunderSound = soundGroup:FindFirstChild("Thunder Rumbling 3 (SFX)")
end

if not soundGroup:FindFirstChild("Long Wind Loop") then
	wind.Parent = soundGroup
	wind.SoundGroup = soundGroup
else
	wind = soundGroup:FindFirstChild("Long Wind Loop")
end

local Rainy = {}

function Rainy:Start()
	game.Lighting.Brightness = originalBrightness - 2

	Common.adjustDarkness(game.Lighting, "Ambient", 0.7)

	if game.Lighting["FogColor"] then
		game.Lighting["FogColor"] = Color3.new(0.890196, 0.894118, 0.921569)
	end

	Common.setClouds(0.8, 0.8)
	Common.setFog(20, 1000)

	task.wait(WeatherPresets.PARTICLE_DELAY)

	if currentRate ~= 50 then
		-- rainSound.Volume = 0
		rainClone = rainModel:Clone()
		rainSound:Play()
		-- TweenService:Create(rainSound, TweenInfo.new(1), {["Volume"] = 0.5}):Play()
	end

	if currentRate == 5000 then
		wind:Play()
		thunderSound:Play()
	elseif currentRate == 50 then
		rainClone = script["Snow Particles"]:Clone()
		wind:Play()
	end

	isRaining = true
	rainClone.Parent = workspace.Weather
	toggleRainAnimation(currentRate)
	if isRaining then
		checkInOpen()
	end
end

function Rainy:Stop(nextWeather)
	isRaining = false

	if rainClone then
		rainClone:Destroy()
	end

	if nextWeather ~= "Stormy" then
		if wind then
			wind:Stop()
		end

		if thunderSound then
			thunderSound:Stop()
		end

		toggleRainAnimation(0)
		-- TweenService:Create(rainSound, TweenInfo.new(1), {["Volume"] = 0}):Play()
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

return Rainy
