--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local SettingPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData, SettingUi


local SettingSystem:Types.System = {
    whiteList = {},
    players = {},
    tasks = {},
    IsLoaded = false
}
SettingSystem.__index = SettingSystem

if IsServer then
    SettingSystem.Client = setmetatable({}, SettingSystem)
    -- Template.AllClients = setmetatable({}, Template)
    local ServerStorage = game:GetService("ServerStorage")
    PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
    SettingSystem.Server = setmetatable({}, SettingSystem)
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

function SettingSystem:Init()
    GetSystemMgr()
end

function SettingSystem:PlayerAdded(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local settingsData = playerIns:GetOneData(Keys.DataKey.settingsData)
        for key, value in SettingPresets.Default do
            if not settingsData[key] then
                settingsData[key] = value
            end
        end

        if settingsData.trade ~= nil then
            player:SetAttribute("trade", settingsData.trade)
        end

        self.Client:PlayerAdded(player, {settingsData = settingsData})
    else
        ClientData:SetOneData(Keys.DataKey.settingsData, args.settingsData)
        SettingUi = require(script.ui)
        SettingUi.Init()
    end
end

function SettingSystem:ChangeSetting(sender, player, args)
    if IsServer then
        player = player or sender

        local settingName = args.settingName
        local value = args.value

        if settingName == "trade" then
            player:SetAttribute("trade", value)
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local settingsData = playerIns:GetOneData(Keys.DataKey.settingsData)

        settingsData[settingName] = value

        args = {
            settingsData = settingsData,
            settingName = settingName,
            value = value
        }
        self.Client:ChangeSetting(player, args)
    else
        ClientData:SetOneData(Keys.DataKey.settingsData, args.settingsData)
        SettingUi.ChangeSetting(args)
    end
end

return SettingSystem