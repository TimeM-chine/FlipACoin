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

---- client variables ----
local uiController
local AnnouncementUi = { pendingCalls = {} }
setmetatable(AnnouncementUi, Types.mt)

local AnnouncementSystem: Types.System = {
	whiteList = {
		"HandleFlipResolved",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
AnnouncementSystem.__index = AnnouncementSystem

if IsServer then
	AnnouncementSystem.Client = setmetatable({}, AnnouncementSystem)
else
	AnnouncementSystem.Server = setmetatable({}, AnnouncementSystem)
end

local function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function AnnouncementSystem:Init()
	GetSystemMgr()
	self.recentAnnouncements = self.recentAnnouncements or {}
end

function AnnouncementSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, {})
	else
		local pendingCalls = AnnouncementUi.pendingCalls

		AnnouncementUi = require(script.ui)
		AnnouncementUi.Init()

		for _, call in ipairs(pendingCalls) do
			AnnouncementUi[call.functionName](table.unpack(call.args))
		end
	end
end

function AnnouncementSystem:HandleFlipResolved(sender, player, args)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if args.result ~= "Heads" then
		return
	end

	local thresholdConfig = Presets.Thresholds[args.streak]
	if not thresholdConfig then
		return
	end

	local dedupeKey = `{player.UserId}:{args.streak}`
	local now = os.clock()
	if self.recentAnnouncements[dedupeKey] and now - self.recentAnnouncements[dedupeKey] < Presets.DebounceSeconds then
		return
	end
	self.recentAnnouncements[dedupeKey] = now

	local text = Presets.BuildText(player, args.streak)
	local audiencePlayers = GetSystemMgr().systems.TableSeatSystem:GetAudiencePlayers(args.seatId)
	for _, audiencePlayer in ipairs(audiencePlayers) do
		self.Client:PlayAnnouncement(audiencePlayer, {
			userId = player.UserId,
			seatId = args.seatId,
			streak = args.streak,
			tier = thresholdConfig.tier,
			text = text,
			textColor = thresholdConfig.color,
		})
	end
end

function AnnouncementSystem:PlayAnnouncement(sender, player, args)
	if IsServer then
		return
	end

	if not uiController then
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local main = playerGui:WaitForChild("Main")
		uiController = require(main:WaitForChild("uiController"))
	end

	uiController.SetNotification({
		text = args.text,
		lastTime = 2.2,
		textColor = args.textColor,
	})
end

return AnnouncementSystem
