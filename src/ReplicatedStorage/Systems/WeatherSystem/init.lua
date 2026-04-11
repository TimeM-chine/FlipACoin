--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.2 Analysis
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local WeatherPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local GameConfig = require(Replicated.configs.GameConfig)
local Util = require(Replicated.modules.Util)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, AnalyticsService
local weatherRemain = 5
local currentWeather = {
	name = "Normal",
	endTime = 0,
}

---- client variables ----
local LocalPlayer, ClientData, WeatherUi

local WeatherSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
WeatherSystem.__index = WeatherSystem

if IsServer then
	WeatherSystem.Client = setmetatable({}, WeatherSystem)
	WeatherSystem.AllClients = setmetatable({}, WeatherSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	-- AnalyticsService = game:GetService("AnalyticsService")
else
	WeatherSystem.Server = setmetatable({}, WeatherSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function WeatherSystem:Init()
	GetSystemMgr()
	if IsServer then
		if not workspace:FindFirstChild("Weather") then
			local weather = Instance.new("Folder")
			weather.Name = "Weather"
			weather.Parent = workspace
		end
		-- Use ScheduleModule instead of while loop for better performance
		ScheduleModule.AddSchedule(1, function()
			weatherRemain -= 1
			if weatherRemain < 1 then
				self:TransitWeather(SENDER, nil, {})
			end
		end)
	end
end

function WeatherSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, {
			lastWeather = {},
			currentWeather = currentWeather,
		})
	else
		WeatherUi = require(script.ui)
		WeatherUi.Init()
	end
end

function WeatherSystem:TransitWeather(sender, player, args)
	if IsServer then
		local nextWeather = GetNextWeather()
		weatherRemain = nextWeather.endTime - os.time()
		if args.isBuy then
			local currentChance = WeatherPresets.WeatherList[currentWeather.name].chance
			local nextChance = WeatherPresets.WeatherList[nextWeather.name].chance
			-- print(`currentChance: {currentChance.name} {currentChance}, nextChance: {nextWeather.name} {nextChance}`)
			if nextChance > currentChance then
				-- print("Bad Weather")
				return
			end
		end
		self.AllClients:TransitWeather({
			lastWeather = currentWeather,
			currentWeather = nextWeather,
			player = player,
		})
		currentWeather = nextWeather
	else
		print(`Transiting Weather, {args.lastWeather.name} -> {args.currentWeather.name}`)
		if not WeatherUi then
			WeatherUi = require(script.ui)
		end
		WeatherUi.TransitWeather(args)
	end
end

function WeatherSystem:ChangeWeatherTo(sender, player, args)
	local weatherName = args.weatherName
	if not WeatherPresets.WeatherList[weatherName] then
		return
	end
	local weatherDuration = WeatherPresets.WeatherList[weatherName].duration
	args = {
		lastWeather = currentWeather,
		currentWeather = { name = weatherName, endTime = os.time() + weatherDuration },
		player = nil,
	}
	self.AllClients:TransitWeather(args)
	currentWeather = args.currentWeather
	weatherRemain = weatherDuration
end

function GetNextWeather()
	local pool = {}
	for weather, weatherData in pairs(WeatherPresets.WeatherList) do
		pool[weather] = weatherData.chance
	end

	local newWeather = Util.randomByProbability(pool)
	local weatherDuration = WeatherPresets.WeatherList[newWeather].duration
	return { name = newWeather, endTime = os.time() + weatherDuration }
end

---- [[ server ]] ----
function WeatherSystem:GetWeather()
	return currentWeather
end

return WeatherSystem
