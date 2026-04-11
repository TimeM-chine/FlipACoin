local Replicated = game:GetService("ReplicatedStorage")
local Common = require(Replicated.Systems.WeatherSystem.Weathers.Common)
local Rainy = require(Replicated.Systems.WeatherSystem.Weathers.Rainy)
local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)


local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local Foggy = {}


function Foggy:Start()
	Common.animateColor(game.Lighting, "OutdoorAmbient", originalOutdoorAmbient)

	game.Lighting.Brightness = originalBrightness

	Common.adjustDarkness(game.Lighting, "Ambient", 0.55)

	if game.Lighting["FogColor"] then
		game.Lighting["FogColor"] = Color3.new(0.752941, 0.752941, 0.752941)
	end
	
	-- script.Script.RemoteEvent:FireAllClients(false)

	Common.setClouds(0.3, 0.8)
	Common.setFog(0,100)
end

function Foggy:Stop()
    
end

return Foggy
