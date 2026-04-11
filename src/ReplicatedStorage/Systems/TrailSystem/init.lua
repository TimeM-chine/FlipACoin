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
local TrailPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData, TrailUi


local TrailSystem:Types.System = {
    whiteList = {},
    players = {},
    tasks = {},
    IsLoaded = false
}
TrailSystem.__index = TrailSystem

if IsServer then
    TrailSystem.Client = setmetatable({}, TrailSystem)
    -- Template.AllClients = setmetatable({}, Template)
    local ServerStorage = game:GetService("ServerStorage")
    PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
    TrailSystem.Server = setmetatable({}, TrailSystem)
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

function TrailSystem:Init()
    GetSystemMgr()
end

function TrailSystem:PlayerAdded(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        self.Client:PlayerAdded(player, args)

        local playerIns = PlayerServerClass.GetIns(player)
        local trailEquipped = playerIns:GetOneData(Keys.DataKey.trailEquipped)
        if trailEquipped ~= "" then
            local Character = player.Character or player.CharacterAdded:Wait()
            self:EquipTrail(SENDER, player, {name = trailEquipped})
        end

    else
        TrailUi = require(script.ui)
        TrailUi.Init()
    end
end

function TrailSystem:BuyTrail(sender, player, args)
    if IsServer then
        player = player or sender

        local name = args.name
        local playerIns = PlayerServerClass.GetIns(player)
        local trails = playerIns:GetOneData(Keys.DataKey.trails)
        if trails[name] then
            warn("Trail already owned")
            return
        end

        local trailConfig = TrailPresets.Trails[name]

        -- check cost
        local wins = playerIns:GetOneData(Keys.DataKey.wins)
        if wins < trailConfig.cost then
            SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                text = "Not enough wins",
            })
            return
        end

        SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
            resourceType = "wins",
            count = -trailConfig.cost,
            reason = "buyTrail"
        })
        
        trails[name] = true
        self.Client:BuyTrail(player, {
            trails = trails,
            name = name
        })
    else
        ClientData:SetOneData(Keys.DataKey.trails, args.trails)
        TrailUi.BuyTrail(args)
    end
end

function TrailSystem:EquipTrail(sender, player, args)
    if IsServer then
        player = player or sender
        local name = args.name
        local Character = player.Character or player.CharacterAdded:Wait()
        
        if not Character then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local trails = playerIns:GetOneData(Keys.DataKey.trails)
        if not trails[name] then
            warn("Trail not owned")
            return
        end

        local oldTrail = Character:FindFirstChildOfClass("Trail", true)

        if oldTrail then
            if oldTrail.Name == name then
                return
            else
                oldTrail:Destroy()
            end
        end

        local newTrail = script.Assets.Trails:FindFirstChild(name):Clone()
        newTrail.Parent = player.Character
            
        local attachment0 = player.Character.Head:FindFirstChild("Attachment0")
        if not attachment0 then
            attachment0 = Instance.new("Attachment")
            attachment0.Name = "Attachment0"
            attachment0.Parent = player.Character.Head
        end

        local attachment1 = player.Character.PrimaryPart:FindFirstChild("Attachment1")
        if not attachment1 then
            attachment1 = Instance.new("Attachment")
            attachment1.Name = "Attachment1"
            attachment1.Parent = player.Character.PrimaryPart
        end

        newTrail.Attachment0 = attachment0
        newTrail.Attachment1 = attachment1

        local trailConfig = TrailPresets.Trails[name]
        local humanoid = Character:FindFirstChild("Humanoid")
        local premiumBoost = player.MembershipType == Enum.MembershipType.Premium and 0.1 or 0
        humanoid.WalkSpeed = 16 * (1 + trailConfig.speedBoost/100 + premiumBoost)

        playerIns:SetOneData(Keys.DataKey.trailEquipped, name)
        self.Client:EquipTrail(player, {
            name = name,
            trailEquipped = name
        })
    else
        ClientData:SetOneData(Keys.DataKey.trailEquipped, args.trailEquipped)
        TrailUi.EquipTrail(args)
    end
end

return TrailSystem