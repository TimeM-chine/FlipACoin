local Common = require(script.Parent.Common)
local Rainy = require(script.Parent.Rainy)

local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local Cloudy = {}

function Cloudy:Start()
	game.Lighting.Brightness = originalBrightness-2
	
	Common.adjustDarkness(game.Lighting, "OutdoorAmbient", 0.1)
	Common.adjustDarkness(game.Lighting, "Ambient", 0.2)

	-- script.Script.RemoteEvent:FireAllClients(false)
	if game.Lighting["FogColor"] then
		game.Lighting["FogColor"] = Color3.new(0.752941, 0.752941, 0.752941)
	end

	Common.setFog(0, 10000)
	Common.setClouds(0.3, 0.72)
end

function Cloudy:Stop()

end


return Cloudy