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
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local TemplateUi = { pendingCalls = {} }
setmetatable(TemplateUi, Types.mt)

local Template: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
Template.__index = Template

if IsServer then
	Template.Client = setmetatable({}, Template)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	-- AnalyticsService = game:GetService("AnalyticsService")
else
	Template.Server = setmetatable({}, Template)
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

function Template:Init()
	GetSystemMgr()
end

function Template:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, args)
	else
		local pendingCalls = TemplateUi.pendingCalls

		TemplateUi = require(script.ui)
		TemplateUi.Init()

		for _, call in ipairs(pendingCalls) do
			TemplateUi[call.functionName](table.unpack(call.args))
		end
	end
end

---- [[ Both Sides ]] ----

---- [[ Server Only ]] ----

---- [[ Client Only ]] ----

return Template
