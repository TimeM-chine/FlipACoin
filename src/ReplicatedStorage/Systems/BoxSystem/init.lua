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
local HttpService = game:GetService("HttpService")

---- requires ----
local BoxPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local Util = require(Replicated.modules.Util)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local ORIGIN_Y = -6.856
local MAX_Y = 9.144

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData
local BoxUi = { pendingCalls = {} }
setmetatable(BoxUi, Types.mt)

local BoxSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
BoxSystem.__index = BoxSystem

if IsServer then
	BoxSystem.Client = setmetatable({}, BoxSystem)
	BoxSystem.AllClients = setmetatable({}, BoxSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	BoxSystem.Server = setmetatable({}, BoxSystem)
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

function BoxSystem:Init()
	GetSystemMgr()
	-- if IsServer then
	-- 	UpdateLikeCounter()
	-- 	ScheduleModule.AddSchedule(60, UpdateLikeCounter)
	-- end
end

function BoxSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, {
			like = 5,
		})
	else
		local pendingCalls = BoxUi.pendingCalls

		BoxUi = require(script.ui)
		BoxUi.Init()

		for _, call in ipairs(pendingCalls) do
			BoxUi[call.functionName](table.unpack(call.args))
		end
	end
end

function BoxSystem:TryClaimGroupReward(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local groupClaim = playerIns:GetOneData(Keys.DataKey.groupClaim)
		local timeGap = os.time() - groupClaim
		if timeGap < BoxPresets.GroupGiftTime then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You can't claim the reward yet!",
			})
			return
		end
		playerIns:SetOneData(Keys.DataKey.groupClaim, os.time())

		local reward = Util.randomFromList(BoxPresets.GroupRewardList)
		if table.find({ Keys.ItemType.wins }, reward.itemType) then
			local rebirth = playerIns:GetOneData(Keys.DataKey.rebirth)
			rebirth = rebirth == 0 and 1 or rebirth
			reward.count = reward.count * rebirth * rebirth
		end

		SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, reward)

		self.Client:TryClaimGroupReward(player, args)
	else
		ClientData:SetOneData(Keys.DataKey.groupClaim, os.time())
		BoxUi.ClaimGroupReward()
	end
end

-- function UpdateLikeCounter()
-- 	local success, data = pcall(function()
-- 		return HttpService:GetAsync(`https://games.roproxy.com/v1/games/{GameConfig.UniverseId}/votes`)
-- 	end)
-- 	if success and data then
-- 		local like = HttpService:JSONDecode(data).upVotes
-- 		local BoxesFolder = workspace:WaitForChild("Boxes")
-- 		local nextLike = GetNextLike()
-- 		local likeFolder = BoxesFolder:WaitForChild("LikeCounters")
-- 		for _, model in likeFolder:GetChildren() do
-- 			model.surface.SurfaceGui.Container.Like.Text = `{like}/{nextLike}`
-- 			local targetY = ORIGIN_Y + (MAX_Y - ORIGIN_Y) * like / nextLike
-- 			model.progress.CFrame = model.progress.CFrame - Vector3.new(0, model.progress.Position.Y - targetY, 0)
-- 		end
-- 	else
-- 		warn("Failed to update like counter", success, data)
-- 	end
-- end

function GetNextLike()
	return 100
end

return BoxSystem
