--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: player data manager based on ProfileService
--Version: 1.3
--Last Modified: 2026-03-23
--]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Replicated = game:GetService("ReplicatedStorage")

----- requires -----
local ProfileService = require(ServerStorage.libs.ProfileService)
local DEFAULT_DATA = require(Replicated.configs.DefaultData)
local DEBUG_DATA = require(Replicated.configs.DebugData)
local GameConfig = require(Replicated.configs.GameConfig)

---- remote functions ----
-- local ClientGetData = game.ReplicatedStorage.RemoteFunctions.ClientGetData

----- variables -----

local Players = game:GetService("Players")
local TableModule = require(Replicated.modules.TableModule)
local ProfileStore = ProfileService.GetProfileStore("PlayerData", DEFAULT_DATA)
local profiles = {}
local snapshots = {} -- read-only data snapshots for recently left players

----- main code -----
local DataManager = {}

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		if GameConfig.IsDebug then
			warn("------ [[ Debug mode, using debug data ]] ------")
			profile.Data = TableModule.DeepCopy(DEBUG_DATA)
		end
		print("PlayerAdded profile ->", player.Name, profile.Data)
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			profiles[player] = profile
			-- A profile has been successfully loaded:
			local profileTag = Instance.new("BoolValue")
			profileTag.Name = "profileLoaded"
			profileTag.Parent = player
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick()
	end
end

----- Initialize -----

-- In case Players have joined the server earlier than this script ran:
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

----- Connections -----
Players.PlayerAdded:Connect(PlayerAdded)

-- NOTE: PlayerRemoving is NOT handled here.
-- SystemMgr orchestrates the correct order:
--   1. All systems' PlayerRemoving run first (data is still writable)
--   2. SystemMgr calls DataManager:ReleaseProfile() last (snapshot + release)

----- APIs -----

-- Check if the player has an active (not yet released) profile
function DataManager:IsProfileActive(player: Player): boolean
	return profiles[player] ~= nil
end

function DataManager:GetPlayerAllData(player: Player)
	if profiles[player] then
		return profiles[player].Data
	end
	-- fallback: read-only snapshot for recently left players
	local snapshot = snapshots[player.UserId]
	if snapshot then
		return snapshot
	end
	warn(`There is no player {player.Name}'s data `)
	return
end

function DataManager:GetPlayerOneData(player, key)
	if typeof(player) == "string" then
		print("You forgot the 'player' param, key is", player)
		return
	end
	local profile = DataManager:GetPlayerAllData(player)
	if not profile then
		warn(`{player.Name} Asking for key: {key}, but data is not ready.`)
		return
	end
	assert(profile[key] ~= nil, `Can't find key {key} in {player.Name}'s data`)
	return profile[key]
end

function DataManager:ResetPlayerData(player)
	print("reset player data", player.Name)
	profiles[player].Data = table.clone(DEFAULT_DATA)
end

function DataManager:ResetPlayerOneData(player, key)
	print(`reset player {player.Name} key {key}`)
	self:SetPlayerOneData(player, key, DEFAULT_DATA[key])
end

function DataManager:SetPlayerOneData(player, key, value)
	if typeof(player) == "string" then
		warn(`You forgot the 'player' param, key is {player}, value is {key}`)
		return
	end
	local profile = DataManager:GetPlayerAllData(player)
	assert(profile[key] ~= nil, `Can't find key {key} in {player.Name}'s data`)
	assert(type(profile[key]) == type(value), `data types don't match, param key:{key}, param value:{value} `)
	profile[key] = value
end

function DataManager:AddPlayerOneData(player, key, addValue)
	local nowValue = DataManager:GetPlayerOneData(player, key)
	local newValue = nowValue + addValue
	DataManager:SetPlayerOneData(player, key, newValue)
end

-- Called by SystemMgr AFTER all systems have finished their PlayerRemoving
function DataManager:ReleaseProfile(player)
	local profile = profiles[player]
	if profile ~= nil then
		print("ReleaseProfile ->", player.Name, profile.Data)
		-- snapshot before release, so other systems can still read data briefly
		snapshots[player.UserId] = TableModule.DeepCopy(profile.Data)
		profiles[player] = nil
		profile:Release()
		task.delay(5, function()
			snapshots[player.UserId] = nil
		end)
	end
end

---- offline player ----
function DataManager:SetOfflinePlayerOneData(playerId, key, value)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. playerId)
	if profile then
		profile.Data[key] = value
		profile:Release()
	else
		warn(`[Error] Failed to set offline {playerId} data, id wrong or player is in another server now.`)
	end
end

function DataManager:GetOfflinePlayerOneData(playerId, key)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. playerId)
	if profile then
		local value = profile.Data[key]
		profile:Release()
		return value
	else
		warn(`[Error] Failed to get offline {playerId} data, id wrong or player is in another server now.`)
	end
end

-- for client requesting data
-- function ClientGetData.OnServerInvoke(player, key)
-- 	return DataManager:GetPlayerOneData(player, key)
-- end

return DataManager
