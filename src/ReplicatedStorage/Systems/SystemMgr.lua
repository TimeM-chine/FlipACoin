--[[
--Author: TimeM_chine
--Created Date: Mon Apr 08 2024
--Description: SystemMgr.lua
--Version: 5.0  orchestrated PlayerRemoving lifecycle, player-alive guard on remotes
--Last Modified: 2026-03-23
--]]

local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(Replicated.configs.GameConfig)

local IsServer = RunService:IsServer()
local IsStudio = RunService:IsStudio()
local ListenAdded = {}
local ListenMoving = {}

local SENDER = math.random(1, 18965235)

-- Lazy-loaded references for lifecycle management (server only)
local DataMgr
local PlayerServerClass

local mt = {
	__index = function(t, k)
		-- when access unloaded system, return a safe proxy object
		warn(string.format("[SystemMgr] Unloaded system: %s\nStack trace:\n%s", k, debug.traceback()))

		local safeProxy = {}
		local safeMt = {
			__index = function(_, methodName)
				-- when call unloaded system method, return a empty function and show stack trace
				warn(
					string.format(
						"[SystemMgr] Unloaded system %s method: %s\nStack trace:\n%s",
						k,
						methodName,
						debug.traceback()
					)
				)
				return function(...)
					return nil
				end
			end,
		}
		setmetatable(safeProxy, safeMt)
		safeProxy.Client = setmetatable({}, safeMt)
		safeProxy.Server = setmetatable({}, safeMt)
		safeProxy.AllClients = setmetatable({}, safeMt)
		return safeProxy
	end,
}

local systems = {
	AnimateSystem = require(Replicated.Systems.AnimateSystem),
	-- BackpackSystem = require(Replicated.Systems.BackpackSystem),
	AnnouncementSystem = require(Replicated.Systems.AnnouncementSystem),
	-- BoxSystem = require(Replicated.Systems.BoxSystem),
	-- BuffSystem = require(Replicated.Systems.BuffSystem), -- buff
	CharacterSystem = require(Replicated.Systems.CharacterSystem),
	CoinFlipSystem = require(Replicated.Systems.CoinFlipSystem),
	-- DailySystem = require(Replicated.Systems.DailySystem),
	-- DoorSystem = require(Replicated.Systems.DoorSystem),
	-- EcoSystem = require(Replicated.Systems.EcoSystem),
	-- EffectSystem = require(Replicated.Systems.EffectSystem),
	-- EventSystem = require(Replicated.Systems.EventSystem),
	-- FreeRewardSystem = require(Replicated.Systems.FreeRewardSystem),
	-- GiftSystem = require(Replicated.Systems.GiftSystem),
	-- -- GuideSystem = require(Replicated.Systems.GuideSystem),  -- 引导
	GuiSystem = require(Replicated.Systems.GuiSystem),
	MusicSystem = require(Replicated.Systems.MusicSystem), -- 音效
	-- NPCSystem = require(Replicated.Systems.NPCSystem),
	-- PetSystem = require(Replicated.Systems.PetSystem),
	PlayerSystem = require(Replicated.Systems.PlayerSystem),
	TableSeatSystem = require(Replicated.Systems.TableSeatSystem),
	-- PotionSystem = require(Replicated.Systems.PotionSystem),
	-- QuestSystem = require(Replicated.Systems.QuestSystem),
	-- RebirthSystem = require(Replicated.Systems.RebirthSystem),
	-- SeasonSystem = require(Replicated.Systems.SeasonSystem),
	-- SettingSystem = require(Replicated.Systems.SettingSystem), -- 设置
	-- -- SiteSystem = require(Replicated.Systems.SiteSystem),
	-- SpinSystem = require(Replicated.Systems.SpinSystem), -- 转盘
	-- TradeSystem = require(Replicated.Systems.TradeSystem),
	-- TrailSystem = require(Replicated.Systems.TrailSystem),
	-- TrainSystem = require(Replicated.Systems.TrainSystem),
	-- WeaponSystem = require(Replicated.Systems.WeaponSystem),
	-- WeatherSystem = require(Replicated.Systems.WeatherSystem),
}

setmetatable(systems, mt)

local LoadOrder = {
	"PlayerSystem",
	"TableSeatSystem",
	"CoinFlipSystem",
	"CharacterSystem",
	"AnnouncementSystem",
}

local SystemMgr = {}
SystemMgr.systems = systems

local RemoteEvent, UnreliableRemoteEvent, BindableEvent

-- Helper: process a server remote event with player-alive guard
local function HandleServerRemote(args)
	local player = args[1]
	local info = args[#args]
	local sysName = info.sysName
	local fName = info.funName
	table.remove(args, #args)

	-- Player-alive guard: reject requests from players who are leaving
	if not player or not player:IsDescendantOf(game.Players) then
		return
	end

	-- whiteList check: block remote calls to whitelisted functions
	local system = systems[sysName]
	if system and system.whiteList and table.find(system.whiteList, fName) then
		warn(`[SystemMgr] Blocked remote call to whitelisted function: {sysName}.{fName}`)
		return
	end
	if IsStudio then
		systems[sysName][fName](systems[sysName], table.unpack(args))
	else
		local success, result = pcall(function()
			systems[sysName][fName](systems[sysName], table.unpack(args))
		end)
		if not success then
			warn(`Failed to call {fName} for {sysName}: {result}`)
		end
	end
end

if IsServer then
	RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Parent = script

	RemoteEvent.OnServerEvent:Connect(function(...)
		HandleServerRemote({ ... })
	end)

	UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
	UnreliableRemoteEvent.Parent = script
	UnreliableRemoteEvent.OnServerEvent:Connect(function(...)
		HandleServerRemote({ ... })
	end)

	BindableEvent = Instance.new("BindableEvent")
else
	RemoteEvent = script:WaitForChild("RemoteEvent")
	UnreliableRemoteEvent = script:WaitForChild("UnreliableRemoteEvent")

	RemoteEvent.OnClientEvent:Connect(function(...)
		local args = { ... }

		--print("---------OnClientEvent ------------", args)
		local info = args[#args]
		local sysName = info.sysName
		local fName = info.funName
		table.remove(args, #args)
		if not systems[sysName].IsLoaded then
			Replicated.Systems[sysName]:WaitForChild("IsLoaded")
		end
		if IsStudio then
			systems[sysName][fName](systems[sysName], table.unpack(args))
		else
			local success, result = pcall(function()
				systems[sysName][fName](systems[sysName], table.unpack(args))
			end)
			if not success then
				warn(`Failed to call {fName} for {sysName}: {result}`)
			end
		end
	end)

	UnreliableRemoteEvent.OnClientEvent:Connect(function(...)
		local args = { ... }
		local info = args[#args]
		local sysName = info.sysName
		local fName = info.funName
		table.remove(args, #args)
		if not systems[sysName].IsLoaded then
			Replicated.Systems[sysName]:WaitForChild("IsLoaded")
		end
		if IsStudio then
			systems[sysName][fName](systems[sysName], table.unpack(args))
		else
			local success, result = pcall(function()
				systems[sysName][fName](systems[sysName], table.unpack(args))
			end)
			if not success then
				warn(`Failed to call {fName} for {sysName}: {result}`)
			end
		end
	end)
end

SystemMgr.SENDER = SENDER

function LoadSystem(name)
	local system = systems[name]
	if IsServer then
		local function MakeRemotes(ins)
			for funName, fun in ins do
				if typeof(fun) ~= "function" then
					continue
				end

				if funName == "Init" then
					continue
				end

				if table.find(system.whiteList, funName) then
					continue
				end

				system.Client[funName] = function(inst, player, ...)
					local args = { ... }
					table.insert(args, { sysName = name, funName = funName })
					if args.unreliable then
						UnreliableRemoteEvent:FireClient(player, nil, nil, table.unpack(args))
					else
						RemoteEvent:FireClient(player, nil, nil, table.unpack(args))
					end
				end

				if system.AllClients then
					system.AllClients[funName] = function(inst, ...)
						local args = { ... }
						table.insert(args, { sysName = name, funName = funName })
						if args.unreliable then
							print("Unreliable")
							UnreliableRemoteEvent:FireAllClients(nil, nil, table.unpack(args))
						else
							RemoteEvent:FireAllClients(nil, nil, table.unpack(args))
						end
					end
				end
			end

			if ins.PlayerAdded and (not table.find(ListenAdded, name)) then
				table.insert(ListenAdded, name)
			end

			if ins.PlayerRemoving and (not table.find(ListenMoving, name)) then
				table.insert(ListenMoving, name)
			end

			ins.IsLoaded = true
		end

		MakeRemotes(system)
		if system.Init then
			system:Init()
		end
	else
		local function MakeRemotes(ins)
			for funName, fun in ins do
				if typeof(fun) ~= "function" then
					continue
				end

				if funName == "Init" then
					continue
				end

				if table.find(system.whiteList, funName) then
					continue
				end

				system.Server[funName] = function(inst, ...)
					local args = { ... }
					table.insert(args, { sysName = name, funName = funName })
					if args.unreliable then
						UnreliableRemoteEvent:FireServer(nil, table.unpack(args))
					else
						RemoteEvent:FireServer(nil, table.unpack(args))
					end
				end
			end
			ins.IsLoaded = true
			local IsLoaded = Instance.new("Folder")
			IsLoaded.Name = "IsLoaded"
			IsLoaded.Parent = Replicated.Systems[name]
		end
		MakeRemotes(system)
		if system.Init then
			system:Init()
		end
	end
end

function SystemMgr.Start()
	for _, name in ipairs(LoadOrder) do
		if not systems[name].IsLoaded then
			LoadSystem(name)
		end
	end
	for name, system in pairs(systems) do
		if systems[name].IsLoaded then
			continue
		end
		LoadSystem(name)
	end

	if IsServer then
		-- Lazy-load lifecycle dependencies
		local ServerStorage = game:GetService("ServerStorage")
		DataMgr = require(ServerStorage.modules.DataManager)
		PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)

		-- Fix: use task.spawn for existing players (same as PlayerAdded event)
		for _, player in ipairs(game.Players:GetPlayers()) do
			for _, name in ipairs(ListenAdded) do
				task.spawn(function()
					systems[name]:PlayerAdded(SENDER, player)
				end)
			end
		end

		game.Players.PlayerAdded:Connect(function(player)
			for _, name in ipairs(ListenAdded) do
				task.spawn(function()
					systems[name]:PlayerAdded(SENDER, player)
				end)

				if not table.find(ListenMoving, name) then
					table.insert(ListenMoving, name)
				end
			end
		end)

		-- Orchestrated PlayerRemoving lifecycle:
		-- 1. All systems' PlayerRemoving run first (profile data is still writable)
		-- 2. DataManager releases the profile (snapshot + release)
		-- 3. PlayerServerClass removes the instance
		game.Players.PlayerRemoving:Connect(function(player)
			-- Step 1: All systems cleanup (data still writable)
			for _, name in ipairs(ListenMoving) do
				if systems[name].PlayerRemoving then
					systems[name]:PlayerRemoving(SENDER, player)
				else
					local cache = systems[name].players
					if not cache then
						continue
					end
					local playerCache = cache[player.UserId]
					if playerCache then
						for key, value in pairs(playerCache) do
							playerCache[key] = nil
						end
						systems[name].players[player.UserId] = nil
					end
				end
			end

			-- Step 2: Release profile (creates snapshot, releases ProfileService lock)
			DataMgr:ReleaseProfile(player)

			-- Step 3: Remove PlayerServerClass instance
			PlayerServerClass.RemoveIns(player)
		end)
	end
end

return SystemMgr
