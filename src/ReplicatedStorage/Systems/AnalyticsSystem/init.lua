---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local CustomFieldKeys = Enum.AnalyticsCustomFieldKeys
local FlipCountMilestones = { 10, 25, 50, 100, 250, 500 }

---- server variables ----
local AnalyticsService

---- client variables ----

local AnalyticsSystem: Types.System = {
	whiteList = {
		"LogSeatAssigned",
		"LogCoinFlipResolved",
		"LogRunUpgradePurchased",
		"LogShopItemPurchased",
		"LogItemEquipped",
		"LogGamePassGranted",
		"LogRewardedAd",
		"LogPotionGranted",
		"LogPotionUsed",
		"LogBuffActive",
		"LogInputAction",
		"LogProfileXp",
		"LogDailyGoalCompleted",
		"LogTableJackpot",
		"LogEdgeStand",
		"LogRebirth",
		"LogRebirthUpgradePurchased",
		"PlayerAdded",
		"PlayerRemoving",
		"_BuildFields",
		"_AccountAgeBand",
		"_CanLog",
		"_CashBand",
		"_ClampEventValue",
		"_DurationBand",
		"_EnsureSession",
		"_LogFlipProgress",
		"_LogCustomEvent",
		"_RoundOutcomeField",
		"_StreakBand",
		"_StringField",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
AnalyticsSystem.__index = AnalyticsSystem

if IsServer then
	AnalyticsSystem.Client = setmetatable({}, AnalyticsSystem)
	AnalyticsService = game:GetService("AnalyticsService")
else
	AnalyticsSystem.Server = setmetatable({}, AnalyticsSystem)
end

local function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function AnalyticsSystem:Init()
	GetSystemMgr()
end

function AnalyticsSystem:PlayerAdded(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local session = self:_EnsureSession(player)
	self:_LogCustomEvent(player, "coinflip_session_start", 1, self:_BuildFields("join", self:_AccountAgeBand(player.AccountAge)))
end

function AnalyticsSystem:PlayerRemoving(sender, player, args)
	if not IsServer or sender ~= SENDER then
		return
	end

	local session = self.players[player.UserId]
	if not session then
		return
	end

	local duration = math.max(math.floor(os.clock() - session.startedAt), 0)
	self:_LogCustomEvent(
		player,
		"coinflip_session_end",
		duration,
		self:_BuildFields(self:_DurationBand(duration), session.flipCount or 0, session.lastMilestone or 0)
	)
	self.players[player.UserId] = nil
end

function AnalyticsSystem:LogSeatAssigned(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local source = args and args.autoAssigned and "auto" or "manual"
	self:_LogCustomEvent(player, "coinflip_seat_assigned", 1, self:_BuildFields(source, args and args.seatId))
end

function AnalyticsSystem:LogCoinFlipResolved(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local reward = args and args.reward or 0
	local streak = args and args.streak or 0
	local result = args and args.result or "Unknown"
	local fields = self:_BuildFields(result, self:_RoundOutcomeField(args), args and args.equippedCoin)
	self:_LogCustomEvent(player, "coinflip_flip_resolved", reward, fields)
	self:_LogFlipProgress(player, args)

	local streakMilestone = args and args.streakMilestone
	if streakMilestone then
		self:_LogCustomEvent(player, "coinflip_streak_milestone", streak, self:_BuildFields(streak, result, args.equippedCoin))
	end
end

function AnalyticsSystem:LogRunUpgradePurchased(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_run_upgrade",
		args and args.cost or 0,
		self:_BuildFields(args and args.upgradeKey, args and args.newLevel, self:_CashBand(args and args.cashAfterPurchase))
	)
end

function AnalyticsSystem:LogShopItemPurchased(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_shop_purchase",
		args and args.cost or 0,
		self:_BuildFields(args and args.category, args and args.itemId, args and args.rarity)
	)
end

function AnalyticsSystem:LogItemEquipped(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_item_equip",
		1,
		self:_BuildFields(args and args.category, args and args.itemId, args and args.source)
	)
end

function AnalyticsSystem:LogGamePassGranted(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_gamepass_granted",
		args and args.price or 0,
		self:_BuildFields(args and args.gamePassName, args and args.source, args and args.effect)
	)
end

function AnalyticsSystem:LogRewardedAd(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_rewarded_ad",
		1,
		self:_BuildFields(args and args.stage, args and args.result, args and args.reason)
	)
end

function AnalyticsSystem:LogPotionGranted(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_potion_granted",
		args and args.count or 1,
		self:_BuildFields(args and args.source, args and args.potionId, args and args.buffName)
	)
end

function AnalyticsSystem:LogPotionUsed(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_potion_used",
		args and args.duration or 0,
		self:_BuildFields(args and args.source, args and args.potionId, args and args.buffName)
	)
end

function AnalyticsSystem:LogBuffActive(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_buff_active",
		args and args.duration or 0,
		self:_BuildFields(args and args.source, args and args.buffName, args and args.potionId)
	)
end

function AnalyticsSystem:LogInputAction(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_input_action",
		1,
		self:_BuildFields(args and args.action, args and args.source, args and args.inputType)
	)
end

function AnalyticsSystem:LogProfileXp(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_profile_xp",
		args and args.expGained or 0,
		self:_BuildFields(args and args.level, args and args.levelsGained, args and args.outcome)
	)
end

function AnalyticsSystem:LogDailyGoalCompleted(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_daily_goal_completed",
		args and args.reward or 0,
		self:_BuildFields(args and args.goalId, args and args.day, args and args.reward)
	)
end

function AnalyticsSystem:LogTableJackpot(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_table_jackpot",
		args and args.reward or 0,
		self:_BuildFields(args and args.source, args and args.comboKey, args and args.recipientCount)
	)
end

function AnalyticsSystem:LogEdgeStand(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_edge_stand",
		args and args.bonusReward or 0,
		self:_BuildFields(args and args.coinCount, args and args.failureStreak, args and args.pityActive)
	)
end

function AnalyticsSystem:LogRebirth(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_rebirth",
		args and args.pointGain or 0,
		self:_BuildFields(args and args.rebirthLevel, self:_CashBand(args and args.cashBeforeReset), args and args.pointGain)
	)
end

function AnalyticsSystem:LogRebirthUpgradePurchased(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogCustomEvent(
		player,
		"coinflip_rebirth_upgrade",
		args and args.cost or 0,
		self:_BuildFields(args and args.upgradeKey, args and args.newLevel, args and args.remainingPoints)
	)
end

---- [[ Server Only ]] ----

function AnalyticsSystem:_BuildFields(field01, field02, field03)
	local fields = {}

	if field01 ~= nil then
		fields[CustomFieldKeys.CustomField01.Name] = self:_StringField(field01)
	end
	if field02 ~= nil then
		fields[CustomFieldKeys.CustomField02.Name] = self:_StringField(field02)
	end
	if field03 ~= nil then
		fields[CustomFieldKeys.CustomField03.Name] = self:_StringField(field03)
	end

	return fields
end

function AnalyticsSystem:_AccountAgeBand(accountAge)
	local days = tonumber(accountAge) or 0
	if days < 1 then
		return "0d"
	end
	if days < 7 then
		return "1_6d"
	end
	if days < 30 then
		return "7_29d"
	end
	if days < 180 then
		return "30_179d"
	end
	if days < 365 then
		return "180_364d"
	end

	return "365d_plus"
end

function AnalyticsSystem:_CanLog(sender, player)
	if not IsServer then
		return false
	end
	if sender ~= SENDER then
		return false
	end
	if not player or not player:IsDescendantOf(Players) then
		return false
	end

	return true
end

function AnalyticsSystem:_CashBand(cash)
	local amount = tonumber(cash) or 0
	if amount < 100 then
		return "0_99"
	end
	if amount < 1000 then
		return "100_999"
	end
	if amount < 10000 then
		return "1000_9999"
	end
	if amount < 100000 then
		return "10000_99999"
	end

	return "100000_plus"
end

function AnalyticsSystem:_ClampEventValue(value)
	local numberValue = tonumber(value)
	if not numberValue or numberValue ~= numberValue then
		return 0
	end

	return numberValue
end

function AnalyticsSystem:_DurationBand(seconds)
	local duration = tonumber(seconds) or 0
	if duration < 10 then
		return "0_9s"
	end
	if duration < 30 then
		return "10_29s"
	end
	if duration < 60 then
		return "30_59s"
	end
	if duration < 180 then
		return "1_2m"
	end
	if duration < 600 then
		return "3_9m"
	end
	if duration < 1800 then
		return "10_29m"
	end

	return "30m_plus"
end

function AnalyticsSystem:_EnsureSession(player)
	local session = self.players[player.UserId]
	if not session then
		session = {
			startedAt = os.clock(),
			flipCount = 0,
			lastMilestone = 0,
			milestones = {},
		}
		self.players[player.UserId] = session
	end

	return session
end

function AnalyticsSystem:_LogFlipProgress(player, args)
	local session = self:_EnsureSession(player)
	session.flipCount += 1

	local elapsed = math.max(math.floor(os.clock() - session.startedAt), 0)
	if not session.firstFlipLogged then
		self:_LogCustomEvent(
			player,
			"coinflip_first_flip_latency",
			elapsed,
			self:_BuildFields(self:_DurationBand(elapsed), self:_RoundOutcomeField(args), args and args.equippedCoin)
		)
		session.firstFlipLogged = true
	end

	for _, milestone in ipairs(FlipCountMilestones) do
		if session.flipCount >= milestone and not session.milestones[milestone] then
			session.milestones[milestone] = true
			session.lastMilestone = milestone
			self:_LogCustomEvent(
				player,
				"coinflip_flip_count_milestone",
				milestone,
				self:_BuildFields(milestone, self:_DurationBand(elapsed), self:_RoundOutcomeField(args))
			)
		end
	end
end

function AnalyticsSystem:_LogCustomEvent(player, eventName, value, fields)
	if not AnalyticsService then
		return
	end

	local success, result = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, self:_ClampEventValue(value), fields)
	end)
	if not success then
		warn(`[AnalyticsSystem] Failed to log {eventName}: {result}`)
	end
end

function AnalyticsSystem:_RoundOutcomeField(args)
	if typeof(args) ~= "table" then
		return "round_unknown"
	end

	local coinCount = tonumber(args.coinCount) or 1
	local headsCount = tonumber(args.headsCount)
	if not headsCount then
		headsCount = if args.result == "Heads" then 1 else 0
	end
	local roundState = if args.roundSuccess == true or args.result == "Heads" then "success" else "reset"
	local comboKey = args.comboKey
	if typeof(comboKey) ~= "string" then
		if headsCount >= 5 then
			comboKey = "jackpot"
		elseif args.perfect == true and coinCount >= 3 then
			comboKey = "perfect"
		elseif headsCount >= 4 then
			comboKey = "fourHeads"
		elseif headsCount >= 3 then
			comboKey = "triple"
		elseif headsCount >= 2 then
			comboKey = "pair"
		elseif headsCount >= 1 then
			comboKey = "heads"
		else
			comboKey = "none"
		end
	end

	local pityState = if args.pityActive == true then "pity" else "normal"
	local edgeState = if args.edgeStand == true then "edge" else "normal"
	local luckyState = if args.luckyCoinReroll == true then "lucky" else "normal"
	return `c{coinCount}_h{headsCount}_{roundState}_s{self:_StreakBand(args.streak)}_{comboKey}_{pityState}_{edgeState}_{luckyState}`
end

function AnalyticsSystem:_StreakBand(streak)
	local value = tonumber(streak) or 0
	if value <= 0 then
		return "0"
	end
	if value == 1 then
		return "1"
	end
	if value < 5 then
		return "2_4"
	end
	if value < 10 then
		return "5_9"
	end
	if value < 20 then
		return "10_19"
	end

	return "20_plus"
end

function AnalyticsSystem:_StringField(value)
	local text = tostring(value)
	if #text > 50 then
		return string.sub(text, 1, 50)
	end

	return text
end

return AnalyticsSystem
