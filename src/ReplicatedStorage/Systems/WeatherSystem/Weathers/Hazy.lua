local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Common = require(Replicated.Systems.WeatherSystem.Weathers.Common)
local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)
local Rainy = require(Replicated.Systems.WeatherSystem.Weathers.Rainy)


local lighting = game.Lighting
local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient

local Hazy = {}


function Hazy:Start()
    game.Lighting.Brightness = originalBrightness
	Common.animateColor(game.Lighting, "OutdoorAmbient", originalOutdoorAmbient)
	Common.adjustDarkness(game.Lighting, "Ambient", 0.4)
	-- script.Script.RemoteEvent:FireAllClients(false)
			
	local tween = {}
	Common.setFog(10,1000)
	Common.setClouds(0.3, 0.2)
	
	game.Lighting.FogColor = Color3.new(0.752941, 0.678431, 0.67451)
	
	table.insert(tween, TweenService:Create(lighting:FindFirstChild("Blur"), TweenInfo.new(10), {["Size"] = 5}))
	table.insert(tween, TweenService:Create(lighting:FindFirstChild("SunRays"), TweenInfo.new(10), {["Intensity"] = 0.3}))

	for i,v in pairs(tween) do
		v:Play()
	end
	
	task.wait(WeatherPresets.TRANSITION_SPEED)
end


function Hazy:Stop()
	-- if lighting:FindFirstChild("TemporaryBlurEffect") then
	-- 	lighting:FindFirstChild("TemporaryBlurEffect"):Destroy()
	-- end
	-- if lighting:FindFirstChild("TemporarySunRaysEffect") then
	-- 	lighting:FindFirstChild("TemporarySunRaysEffect"):Destroy()
	-- end
end

return Hazy