---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local CharacterPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local Buttons = Main:WaitForChild("Buttons")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local CharacterUi = {}
local unreadCount = 0
local selectedCharKey = ""

function CharacterUi.Init() end

return CharacterUi
