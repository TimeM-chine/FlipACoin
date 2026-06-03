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

	local comboMilestone = args.comboMilestone or self:BuildComboMilestonePayload(SENDER, player, args)
	local milestone = args.streakMilestone
		or self:BuildBestStreakPayload(SENDER, player, args)
		or self:BuildStreakMilestonePayload(SENDER, player, args)
	if comboMilestone and comboMilestone.announce == true and (not milestone or milestone.kind ~= "bestStreak") then
		milestone = comboMilestone
	end
	if not milestone then
		return
	end

	local dedupeKey = `{player.UserId}:{milestone.kind or "milestone"}:{milestone.streak or milestone.comboKey or "none"}:{milestone.coinCount or 0}:{milestone.headsCount or 0}`
	local now = os.clock()
	if self.recentAnnouncements[dedupeKey] and now - self.recentAnnouncements[dedupeKey] < Presets.DebounceSeconds then
		return
	end
	self.recentAnnouncements[dedupeKey] = now

	local audiencePlayers = GetSystemMgr().systems.TableSeatSystem:GetAudiencePlayers(args.seatId)
	for _, audiencePlayer in ipairs(audiencePlayers) do
		self.Client:PlayAnnouncement(audiencePlayer, milestone)
	end
end

function AnnouncementSystem:BuildStreakMilestonePayload(sender, player, args)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end
	if args.result ~= "Heads" then
		return nil
	end

	local effectConfig = Presets.StreakEffects[args.streak]
	if not effectConfig then
		return nil
	end

	return {
		kind = "streakMilestone",
		userId = player.UserId,
		seatId = args.seatId,
		streak = args.streak,
		text = Presets.BuildText(player, args.streak),
		textColor = Presets.NotificationColor,
		duration = Presets.NotificationDuration,
		sfx = effectConfig.sfx,
		vfx = effectConfig.vfx,
		cameraShake = effectConfig.cameraShake,
	}
end

function AnnouncementSystem:BuildBestStreakPayload(sender, player, args)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end
	if args.result ~= "Heads" then
		return nil
	end
	if args.isBestStreak ~= true then
		return nil
	end
	if args.streak < Presets.MinBestStreakAnnouncement then
		return nil
	end

	local effectConfig = Presets.BestStreakEffect

	return {
		kind = "bestStreak",
		userId = player.UserId,
		seatId = args.seatId,
		streak = args.streak,
		bestStreak = args.bestStreak,
		text = Presets.BuildBestStreakText(player, args.streak),
		textColor = Presets.NotificationColor,
		duration = Presets.NotificationDuration,
		sfx = effectConfig.sfx,
		vfx = effectConfig.vfx,
		cameraShake = effectConfig.cameraShake,
	}
end

function AnnouncementSystem:BuildComboMilestonePayload(sender, player, args)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end
	if args.roundSuccess ~= true then
		return nil
	end

	local effectConfig = Presets.ComboEffects[args.comboKey]
	if not effectConfig then
		return nil
	end

	return {
		kind = "comboMilestone",
		userId = player.UserId,
		seatId = args.seatId,
		streak = args.streak,
		comboKey = args.comboKey,
		comboTier = args.comboTier,
		comboName = args.comboName,
		coinCount = args.coinCount,
		headsCount = args.headsCount,
		reward = args.reward,
		text = Presets.BuildComboText(player, args),
		textColor = Presets.NotificationColor,
		duration = Presets.NotificationDuration,
		sfx = effectConfig.sfx,
		vfx = effectConfig.vfx,
		cameraShake = effectConfig.cameraShake,
		announce = effectConfig.announce == true,
	}
end

function AnnouncementSystem:PlayAnnouncement(sender, player, args)
	if IsServer then
		return
	end

	AnnouncementUi.PlayAnnouncement(args)
end

return AnnouncementSystem
