--[[
--Author: TimeM_chine
--Created Date: Thu Sep 11 2025
--Description: BaseSystem.lua - base class for all systems, eliminates boilerplate
--Version: 2.0
--Last Modified: 2026-03-23
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()

local BaseSystem = {}
BaseSystem.__index = BaseSystem

--[[
	Creates a new system with all the standard boilerplate.

	Usage:
		local MySystem = BaseSystem.new("MySystem", {
			whiteList = { "SomeServerOnlyMethod" },
			hasAllClients = true,  -- optional, creates AllClients proxy
		})

		-- Override methods as needed:
		function MySystem:Init() ... end
		function MySystem:PlayerAdded(sender, player, args) ... end

	The returned system has:
		- .whiteList, .players, .tasks, .IsLoaded
		- .Client / .Server / .AllClients proxies (depending on side)
		- .PlayerServerClass (server only)
		- .LocalPlayer, .ClientData (client only)
		- :GetSystemMgr(), :CheckSender(), :GetPlayerIns(), :InitUI()
		- ._Ui (client only, for pendingCalls pattern)
--]]
function BaseSystem.new(systemName: string, options: { whiteList: { string }?, hasAllClients: boolean? }?)
	options = options or {}

	local self = {
		whiteList = options.whiteList or {},
		players = {},
		tasks = {},
		IsLoaded = false,
		_systemName = systemName,
		_SENDER = nil,
		_SystemMgr = nil,
	}

	setmetatable(self, BaseSystem)

	if IsServer then
		self.Client = setmetatable({}, self)
		if options.hasAllClients then
			self.AllClients = setmetatable({}, self)
		end
		local ServerStorage = game:GetService("ServerStorage")
		self.PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	else
		self.Server = setmetatable({}, self)
		self.LocalPlayer = Players.LocalPlayer
		self.ClientData = require(Replicated.Systems.ClientData)
		-- Default UI proxy with pendingCalls support
		self._Ui = { pendingCalls = {} }
		setmetatable(self._Ui, Types.mt)
	end

	return self
end

-- Lazy-load SystemMgr (avoids circular dependency)
function BaseSystem:GetSystemMgr()
	if not self._SystemMgr then
		self._SystemMgr = require(Replicated.Systems.SystemMgr)
		self._SENDER = self._SystemMgr.SENDER
	end
	return self._SystemMgr
end

-- Default Init: just loads SystemMgr. Override in subclass if needed.
function BaseSystem:Init()
	self:GetSystemMgr()
end

-- Check if sender is the trusted SENDER token (server-side security)
function BaseSystem:CheckSender(sender): boolean
	if IsServer then
		return sender == self._SENDER
	end
	return true
end

-- Get PlayerServerClass instance for a player (server only, safe)
function BaseSystem:GetPlayerIns(player)
	if not IsServer then
		return nil
	end
	return self.PlayerServerClass.GetIns(player)
end

-- Check if a player is still in the game
function BaseSystem:IsPlayerAlive(player): boolean
	return player and player:IsDescendantOf(Players)
end

--[[
	Initialize UI on the client side (handles pendingCalls pattern).
	Call this in your :PlayerAdded() client branch.

	Usage:
		-- in PlayerAdded, client branch:
		self._Ui = self:InitUI(script.ui)

	Returns the loaded UI module.
--]]
function BaseSystem:InitUI(uiModule, initArgs: any?)
	if IsServer then
		return nil
	end

	local pendingCalls = self._Ui.pendingCalls

	local ui = require(uiModule)
	if ui.Init then
		if initArgs ~= nil then
			ui.Init(initArgs)
		else
			ui.Init()
		end
	end

	for _, call in ipairs(pendingCalls) do
		if ui[call.functionName] then
			ui[call.functionName](table.unpack(call.args))
		end
	end

	return ui
end

--[[
	Wait for a player's character with a timeout.
	Returns the character, or nil if timed out / player left.

	Usage:
		local character = BaseSystem.WaitForCharacter(player, 15)
		if not character then return end
--]]
function BaseSystem.WaitForCharacter(player: Player, timeout: number?): Model?
	if player.Character then
		return player.Character
	end

	timeout = timeout or 15
	local thread = coroutine.running()
	local done = false
	local conn
	conn = player.CharacterAdded:Connect(function(char)
		if done then return end
		done = true
		conn:Disconnect()
		task.spawn(thread, char)
	end)
	task.delay(timeout, function()
		if done then return end
		done = true
		conn:Disconnect()
		task.spawn(thread, nil)
	end)
	return coroutine.yield()
end

return BaseSystem
