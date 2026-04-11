local Common = require(script.Parent.Common)

local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local Normal = {}

function Normal:Start()
    Common.animateColor(game.Lighting, "OutdoorAmbient", originalOutdoorAmbient)
	game.Lighting.Brightness = originalBrightness
	-- script.Script.RemoteEvent:FireAllClients(false)
	Common.adjustDarkness(game.Lighting, "Ambient", 0.5)
	Common.setFog(0, 10000)
	Common.setClouds(0.3, 0.2)
end

function Normal:Stop()
    
end

return Normal