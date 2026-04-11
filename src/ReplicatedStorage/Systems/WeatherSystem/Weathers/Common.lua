local TweenService = game:GetService("TweenService")
local Replicated = game:GetService("ReplicatedStorage")


local WeatherPresets = require(Replicated.Systems.WeatherSystem.Presets)
local TRANSITION_SPEED = WeatherPresets.TRANSITION_SPEED

local clouds = workspace.Terrain:FindFirstChild("Clouds")
if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Parent = workspace.Terrain
end

local grass = {}

local Common = {}

Common.originalBrightness = game.Lighting.Brightness
Common.originalOutdoorAmbient = game.Lighting.OutdoorAmbient
Common.originalAmbience = game.Lighting.Ambient


function Common.animateColor(object, property, newColor)
	TweenService:Create(object, TweenInfo.new(TRANSITION_SPEED), {[property]=newColor}):Play()
end

function Common.adjustDarkness(object, property, darknessRange)
    -- Ensure the darknessRange is between 0 and 1
	darknessRange = math.clamp(darknessRange, 0, 1)

	-- Get the current color of the property
	local currentColor = object[property]

	-- Interpolate between the current color and black
	local newColor = Color3.new(
		currentColor.R * (1 - darknessRange),
		currentColor.G * (1 - darknessRange),
		currentColor.B * (1 - darknessRange)
	)
	
	-- Set the new color back to the object's property
	Common.animateColor(object, property, newColor)
end

function Common.setFog(fogStart,fogEnd)
	local tween = TweenService:Create(game.Lighting, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), {["FogEnd"] = fogEnd})
	local tween2 = TweenService:Create(game.Lighting, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), {["FogStart"] = fogStart})

	tween:Play()
	tween2:Play()
end

function Common.setClouds(Density, Cover)
	if clouds then
		local tween = TweenService:Create(clouds, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), {["Density"] = Density})
		local tween2 = TweenService:Create(clouds, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), {["Cover"] = Cover})

		tween:Play()
		tween2:Play()
		
	end
end


function Common.colorGrassPartsToWhite()
	-- Function to check if a part is a grass-like part and change its color to white
	local function isGrassPart(part)
		if part:IsA("BasePart") then
			-- Proportional Size Check
			local size = part.Size
			local xzRatio = math.max(size.X, size.Z) / size.Y
			local sizeThreshold = 2 -- Threshold for proportional size, adjust as needed
			local isProportionallyLarger = xzRatio > sizeThreshold

			-- Color Check
			local color = part.Color
			local isGreenShade = color.G > color.R and color.G > color.B

			-- If both conditions are met, return true
			return isProportionallyLarger and isGreenShade
		end
		return false
	end

	-- Apply the function to all parts in the specified container
	for _, obj in pairs(workspace:GetDescendants()) do
		if isGrassPart(obj) then
			if not table.find(grass, obj) then
				table.insert(grass, obj)
			end
			obj:SetAttribute("setToWhite", obj.Color)
			Common.animateColor(obj, "Color", Color3.new(1,1,1))
		end
	end
end

function Common.resetGrassParts()
	for _, obj in pairs(grass) do
		Common.animateColor(obj, "Color", obj:GetAttribute("setToWhite"))
		obj:SetAttribute("setToWhite", nil)
	end
end

return Common
