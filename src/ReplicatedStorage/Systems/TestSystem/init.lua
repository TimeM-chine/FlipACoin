---- types ----
type System = {
    Remotes:{RemoteEvent},
    whiteList:table,
    IsLoaded:boolean
}

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Presets = require(script.Presets)

---- variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr, PlayerServerClass, LocalPlayer

local TestSystem:System = {
    tasks = {},
    whiteList = {},
    IsLoaded = false
}
TestSystem.__index = TestSystem

if IsServer then
    TestSystem.Client = setmetatable({}, TestSystem)
    TestSystem.AllClients = setmetatable({}, TestSystem)
    local ServerStorage = game:GetService("ServerStorage")
    PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
    TestSystem.Server = setmetatable({}, TestSystem)
    LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
    if not SystemMgr then
        SystemMgr = require(Replicated.Systems.SystemMgr)
        SENDER = SystemMgr.SENDER
    end
    return SystemMgr
end

function TestSystem:Init()
    GetSystemMgr()

    if IsServer then
        local LuaEncode = require(script.LuaEncode)
        local model1 = Instance.new("Model")
        model1.Parent = workspace

        local model2 = Instance.new("Model")
        model2.Parent = workspace

        print(LuaEncode(model1))
        print(LuaEncode(model2))
    end
end

-- print("run TestSystem", TestSystem)

return TestSystem