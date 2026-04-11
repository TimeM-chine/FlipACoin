--[[
--Author: TimeM_chine
--Created Date: Fri May 17 2024
--Description: init.lua
--Version: 1.0
--Last Modified: 2024-05-17 6:10:02
--]]

---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local GiftPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
-- local GAModule = require(Replicated.modules.GAModule)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local GiftType = Keys.GiftType

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, GiftUi

local GiftSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
GiftSystem.__index = GiftSystem

if IsServer then
	GiftSystem.Client = setmetatable({}, GiftSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	GiftSystem.Server = setmetatable({}, GiftSystem)
	LocalPlayer = game.Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function GiftSystem:Init()
	GetSystemMgr()
end

function GiftSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		self.players[player.UserId] = {
			joinTime = os.time(),
			claimedGifts = {},
		}

		self.Client:PlayerAdded(player, args)
	else
		GiftUi = require(script.ui)
		GiftUi.Init()
	end
end

function GiftSystem:PlayerRemoving(sender, player)
	if IsServer then
		self.players[player.UserId] = nil
	end
end

function GiftSystem:TryClaimGift(sender, player, args: { giftIndex: number })
	if IsServer then
		player = player or sender
		local giftIndex = args.giftIndex
		local playerCache = self.players[player.UserId]
		local gift = GiftPresets.Gifts[giftIndex]
		if os.time() - playerCache.joinTime <= gift.timer then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `Available in {gift.timer - (os.time() - playerCache.joinTime)} seconds.`,
			})
		else
			if not playerCache.claimedGifts[giftIndex] then
				self:GiveGift(SENDER, player, {
					giftIndex = giftIndex,
				})
			else
				SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
					text = "You have claimed this gift.",
				})
			end
		end
	end
end

function GiftSystem:GiveGift(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local giftIndex = args.giftIndex

		AnalyticsService:LogCustomEvent(player, "ClaimGift", args.giftIndex)

		local gift = GiftPresets.Gifts[giftIndex]
		self.players[player.UserId].claimedGifts[giftIndex] = true

		local playerIns = PlayerServerClass.GetIns(player)
		local rebirth = playerIns:GetOneData(dataKey.rebirth)
		rebirth = rebirth == 0 and 1 or rebirth
		for _, giftInfo in gift.items do
			local count = giftInfo.count
			if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, giftInfo.itemType) then
				count = count * rebirth * rebirth
			end
			SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, {
				itemType = giftInfo.itemType,
				count = count,
				name = giftInfo.name,
				reason = "gift",
			})
		end

		-- GAModule:addDesignEvent(player.UserId, {
		--     eventId = `giftClaim:{giftIndex}`,
		-- })

		self.Client:GiveGift(player, args)
	else
		GiftUi.ReceivedGift(args)
	end
end

return GiftSystem
