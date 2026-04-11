--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-02-21 11:07:53
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local GuiPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, PlayerGui, uiController, Main

local GuiSystem: Types.System = {
	Remotes = {},
	whiteList = {},
	IsLoaded = false,
}
GuiSystem.__index = GuiSystem

if IsServer then
	GuiSystem.Client = setmetatable({}, GuiSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	GuiSystem.Server = setmetatable({}, GuiSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function GuiSystem:Init()
	GetSystemMgr()
end

function GuiSystem:SetNotification(
	sender,
	player,
	args: { text: string, soundName: string, lastTime: number, textColor: Color3 }
)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.Client:SetNotification(player, args)
	else
		if not uiController then
			PlayerGui = LocalPlayer.PlayerGui
			Main = PlayerGui:WaitForChild("Main")
			uiController = require(Main:WaitForChild("uiController"))
		end
		uiController.SetNotification(args)
	end
end

---- server -----

---- client -----

return GuiSystem
