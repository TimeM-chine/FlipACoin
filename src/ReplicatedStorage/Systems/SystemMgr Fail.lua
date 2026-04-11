--[[
--Author: TimeM_chine
--Created Date: Tue Aug 15 2023
--Description: SystemMgr.lua
--Last Modified: 2024-03-21 4:35:23
--]]

local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ClonedModules = Replicated.ClonedModules
ClonedModules.ChildRemoved:Connect(function(child)
    local name = child.Name
    print("child removed", name)
end)

local IsServer = RunService:IsServer()
local ListenAdded = {}
local ListenMoving = {}

local SENDER = math.random(1, 18965235)

local systems = {
    AnimateSystem = require(Replicated.Systems.AnimateSystem:Clone()),
    -- TestSystem = require(Replicated.Systems.TestSystem:Clone()),
    CharacterSystem = require(Replicated.Systems.CharacterSystem:Clone()),
    DamageSystem = require(Replicated.Systems.DamageSystem:Clone()),
    EffectSystem = require(Replicated.Systems.EffectSystem:Clone()),
    GuiSystem = require(Replicated.Systems.GuiSystem:Clone()),
    MonsterSystem = require(Replicated.Systems.MonsterSystem:Clone()),
    PetSystem = require(Replicated.Systems.PetSystem:Clone()),
    SkillSystem = require(Replicated.Systems.SkillSystem:Clone()),
    TrainSystem = require(Replicated.Systems.TrainSystem:Clone()),
}

for key, _ in pairs(systems) do
    systems.key = nil
end

local SystemMgr = {}

local RemoteEvent
if IsServer then
    RemoteEvent = Instance.new("RemoteEvent")
    RemoteEvent.Parent = script

    RemoteEvent.OnServerEvent:Connect(function(...)
        local args = {...}
        local info = args[#args]
        local sysName = info.sysName
        local fName = info.funName
        table.remove(args, #args)
        SystemMgr.systems[sysName][fName](SystemMgr.systems[sysName], table.unpack(args))
    end)
else
    RemoteEvent = script:WaitForChild("RemoteEvent")

    RemoteEvent.OnClientEvent:Connect(function(...)
        local args = {...}
        local info = args[#args]
        local sysName = info.sysName
        local fName = info.funName
        table.remove(args, #args)
        SystemMgr.systems[sysName][fName](SystemMgr.systems[sysName], table.unpack(args))
    end)
end

SystemMgr.SENDER = SENDER

function LoadSystem(name)
    local system = systems[name]
    if IsServer then
        system:Init()
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
                    print("client", funName, player, ...)
                    local args = {...}
                    table.insert(args, {sysName = name, funName = funName})
                    RemoteEvent:FireClient(player, nil, nil, table.unpack(args))
                end

                if system.AllClients then
                    system.AllClients[funName] = function(inst, ...)
                        local args = {...}
                        table.insert(args, {sysName = name, funName = funName})
                        RemoteEvent:FireAllClients(nil, nil, table.unpack(args))
                    end
                end
            end

            if ins.PlayerAdded and (not table.find(ListenAdded, name))then
                table.insert(ListenAdded, name)
            end

            if ins.PlayerRemoving and (not table.find(ListenMoving, name)) then
                table.insert(ListenMoving, name)
            end

            ins.IsLoaded = true
        end
    
        MakeRemotes(system)
    else
        system:Init()
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
                    RemoteEvent:FireServer(nil, ..., {sysName = name, funName = funName})
                end
            end
            ins.IsLoaded = true
        end
    
        MakeRemotes(system)
    end
end

function RestartSystem(name)
    if systems[name].tasks then
        for _, t in ipairs(systems[name].tasks) do
            task.cancel(t)
        end
    end

    for _, property in pairs(systems[name]) do
        systems[name][property] = nil
    end
    systems[name] = nil

    if IsServer then
        ClonedModules:FindFirstChild(name):Destroy()
        local moduleScript = Replicated.Systems[name]
        local newModule = CreateSystemModule(moduleScript)
        systems[name] = require(newModule)
    else
        local newModule = ClonedModules:WaitForChild(name)
        systems[name] = require(newModule)
    end

    LoadSystem(name)

    if IsServer and systems[name].PlayerAdded then
        for _, player in ipairs(game.Players:GetPlayers()) do
            systems[name]:PlayerAdded(SENDER, player)
        end
    end
end

function CreateSystemModule(module)
    local newModule = module:Clone()
    newModule.Parent = ClonedModules
    return newModule
end

function SystemMgr.Start()
    for name, system in pairs(systems) do
        if IsServer then
            local moduleScript = Replicated.Systems[name]
            local newModule = CreateSystemModule(moduleScript)
            systems[name] = require(newModule)
            LoadSystem(name)
            moduleScript.Changed:Connect(function(property)
                if property == "Source" then
                    RestartSystem(name)
                end
            end)
        else
            local newModule = ClonedModules:WaitForChild(name)
            systems[name] = require(newModule)
            LoadSystem(name)
            local moduleScript = Replicated.Systems[name]
            moduleScript.Changed:Connect(function(property)
                if property == "Source" then
                    RestartSystem(name)
                end
            end)
        end
    end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        for _, ins in ipairs(ListenAdded) do
            ins:PlayerAdded(SENDER, player)
        end
    end
    
    game.Players.PlayerAdded:Connect(function(player)
        for _, name in ipairs(ListenAdded) do
            systems[name]:PlayerAdded(SENDER, player)
        end
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        for _, name in ipairs(ListenMoving) do
            systems[name]:PlayerRemoving(SENDER, player)
        end
    end)
end

SystemMgr.systems = systems

return SystemMgr