---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local WeatherPresets = require(script.Parent.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local BuffPresets = require(Replicated.Systems.BuffSystem.Presets)
local Util = require(Replicated.modules.Util)
local Common = require(Replicated.Systems.WeatherSystem.Weathers.Common)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Buttons = Main:WaitForChild("Buttons")
local uiController = require(Main:WaitForChild("uiController"))
local WeatherFrame = Buttons:WaitForChild("RightBottom"):WaitForChild("Weather")
local WeatherReroll = Main:WaitForChild("Frames"):WaitForChild("WeatherReroll")
local timer = WeatherFrame:WaitForChild("timer")

---- logic variables ----
local weatherRemain = 0
local TRANSITION_SPEED = WeatherPresets.TRANSITION_SPEED
local originalBrightness = Common.originalBrightness
local originalOutdoorAmbient = Common.originalOutdoorAmbient
local originalAmbience = Common.originalAmbience

local WeatherUi = {}

function WeatherUi.Init()
	uiController.SetButtonHoverAndClick(WeatherFrame, function()
		uiController.OpenFrame("WeatherReroll")
	end)
	-- Use ScheduleModule instead of while loop for better performance
	ScheduleModule.AddSchedule(1, function()
		weatherRemain = math.max(0, weatherRemain - 1)
		timer.Text = string.format("Time Remaining: %d", weatherRemain)
		--Util.FormatCountDown(weatherRemain)
	end)

	local WeatherRerollFrame = WeatherReroll:WaitForChild("WeatherRerollFrame")
	local List = WeatherRerollFrame:WaitForChild("List"):WaitForChild("Rarity")

	local function Round(number, decimals: number)
		decimals = decimals or 1
		return string.format(`%.{decimals}f`, number)
	end

	local totalChance = 0
	for _, weather in pairs(WeatherPresets.WeatherList) do
		totalChance += weather.chance
	end

	local template = List:WaitForChild("Template")
	template.Visible = false
	for weather, weatherInfo in pairs(WeatherPresets.WeatherList) do
		local card = template:Clone()
		card.Visible = true
		card.BackgroundColor3 = weatherInfo.color
		-- card.TextLabel.Text = weather
		card.LayoutOrder = weatherInfo.chance * 100 * -1
		local chance = Round(WeatherPresets.WeatherList[weather].chance / totalChance * 100, 2)
		-- card.chance.Text = `{chance}%`
		card.TextLabel.Text = `{weatherInfo.name}: {chance}%`
		card.Parent = List
	end

	local OpenBtn = WeatherRerollFrame:WaitForChild("Info"):WaitForChild("OpenBtn")
	uiController.SetButtonHoverAndClick(OpenBtn, function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.transitWeather.productId)
	end)
	OpenBtn.TextLabel.Text = `\u{E002} {EcoPresets.Products.transitWeather.price}`
end

function WeatherUi.TransitWeather(weather)
	local lastWeather = weather.lastWeather.name
	local currentWeather = weather.currentWeather.name
	weatherRemain = weather.currentWeather.endTime - os.time()

	local boostText = ""
	for _, boost in ipairs(WeatherPresets.WeatherList[currentWeather].buffs) do
		local buff = BuffPresets.Buffs[boost.buffName]
		if boostText == "" then
			boostText ..= `+{buff.boost * 100}% {buff.boostType}`
		else
			boostText ..= `, +{buff.boost * 100}% {buff.boostType}`
		end
	end
	WeatherFrame.Boost.Text = boostText
	WeatherFrame.Weather.Text = `[  {WeatherPresets.WeatherList[currentWeather].name}  ]`

	for i, v in pairs(game.Lighting:GetChildren()) do
		if v.Name == "TemporaryWeather" then
			if v:IsA("SunRaysEffect") then
				TweenService:Create(v, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), { ["Intensity"] = 0 })
					:Play()
			elseif v:IsA("BlurEffect") then
				TweenService:Create(v, TweenInfo.new(TRANSITION_SPEED, Enum.EasingStyle.Quad), { ["Size"] = 0 }):Play()
			end
		end
	end

	TweenService:Create(game.Lighting, TweenInfo.new(TRANSITION_SPEED), { ["OutdoorAmbient"] = originalOutdoorAmbient })
		:Play()
	TweenService:Create(game.Lighting, TweenInfo.new(TRANSITION_SPEED), { ["Ambient"] = originalAmbience }):Play()
	TweenService:Create(game.Lighting, TweenInfo.new(TRANSITION_SPEED), { ["Brightness"] = originalBrightness }):Play()

	for i, v in pairs(game.Lighting:GetChildren()) do
		if v.Name == "TemporaryWeather" then
			v:Destroy()
		end
	end

	if lastWeather then
		local lastModule = require(Replicated.Systems.WeatherSystem.Weathers[lastWeather])
		lastModule:Stop(currentWeather)
	end
	local module = require(Replicated.Systems.WeatherSystem.Weathers[currentWeather])
	module:Start()
end

local Lighting = game:GetService("Lighting")
Lighting:GetAttributeChangedSignal("TimeOfDay"):Connect(function()
	Lighting.TimeOfDay = Lighting:GetAttribute("TimeOfDay")
end)

return WeatherUi
