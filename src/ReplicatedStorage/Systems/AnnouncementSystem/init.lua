local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseSystem = require(Replicated.Systems.BaseSystem)
local Presets = require(script.Presets)

local IsServer = RunService:IsServer()

local AnnouncementSystem = BaseSystem.new("AnnouncementSystem", {
	whiteList = {
		"HandleFlipResolved",
	},
})

local uiController

function AnnouncementSystem:Init()
	BaseSystem.Init(self)
	self._recentAnnouncements = self._recentAnnouncements or {}
end

function AnnouncementSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if not self:CheckSender(sender) then
			return
		end
		self.Client:PlayerAdded(player, {})
	else
		self._Ui = self:InitUI(script.ui)
	end
end

function AnnouncementSystem:HandleFlipResolved(sender, player, args)
	if not IsServer then
		return
	end
	if not self:CheckSender(sender) then
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
	if self._recentAnnouncements[dedupeKey] and now - self._recentAnnouncements[dedupeKey] < Presets.DebounceSeconds then
		return
	end
	self._recentAnnouncements[dedupeKey] = now

	local text = Presets.BuildText(player, args.streak)
	local audiencePlayers = self:GetSystemMgr().systems.TableSeatSystem:GetAudiencePlayers(args.seatId)
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
