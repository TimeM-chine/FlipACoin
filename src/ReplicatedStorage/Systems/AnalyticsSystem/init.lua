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
local EarlySessionDuration = 180
local FlipCountMilestones = { 10, 25, 50, 100, 250, 500 }
local CustomEventFlushInterval = 15
local AnalyticsRateLimitBase = 120
local AnalyticsRateLimitPerPlayer = 20
local AnalyticsRateLimitSafetyMultiplier = 0.8

---- server variables ----
local AnalyticsService
local ScheduleModule

---- client variables ----
local UserInputService
local WorkspaceService

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
		"LogFirstAutoToggle",
		"LogFirstRunUpgrade",
		"LogFirstGrowthPanelOpen",
		"LogProfileXp",
		"LogDailyGoalCompleted",
		"LogTableJackpot",
		"LogEdgeStand",
		"LogRebirth",
		"LogRebirthUpgradePurchased",
		"PlayerAdded",
		"PlayerRemoving",
		"_BuildFields",
		"_BuildCustomEventKey",
		"_AccountAgeBand",
		"_CanLog",
		"_CashBand",
		"_ClampEventValue",
		"_DeviceClassField",
		"_DurationBand",
		"_EarlySessionStage",
		"_EnsureSession",
		"_FlushCustomEvents",
		"_GetFlushBudget",
		"_GetLocalDeviceClass",
		"_GetLocalViewportBand",
		"_GetSessionElapsed",
		"_InputTypeField",
		"_LogEarlySessionEnd",
		"_LogFirstSessionEvent",
		"_LogFlipProgress",
		"_LogCustomEvent",
		"_ReportLocalDeviceProfile",
		"_RoundOutcomeField",
		"_SendCustomEvent",
		"_StreakBand",
		"_StringField",
		"_ViewportBandField",
	},
	players = {},
	pendingCustomEvents = {},
	pendingCustomEventOrder = {},
	tasks = {},
	IsLoaded = false,
}
AnalyticsSystem.__index = AnalyticsSystem

if IsServer then
	AnalyticsSystem.Client = setmetatable({}, AnalyticsSystem)
	AnalyticsService = game:GetService("AnalyticsService")
	ScheduleModule = require(Replicated.modules.ScheduleModule)
else
	AnalyticsSystem.Server = setmetatable({}, AnalyticsSystem)
	UserInputService = game:GetService("UserInputService")
	WorkspaceService = game:GetService("Workspace")
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
	if IsServer then
		if not self.customEventFlushScheduleId then
			self.customEventFlushScheduleId = ScheduleModule.AddSchedule(CustomEventFlushInterval, function()
				self:_FlushCustomEvents()
			end)
		end

		if not self.customEventBindToCloseConnected then
			self.customEventBindToCloseConnected = true
			game:BindToClose(function()
				self:_FlushCustomEvents(nil, math.huge)
			end)
		end
	else
		task.defer(function()
			self:_ReportLocalDeviceProfile()
		end)
	end
end

function AnalyticsSystem:PlayerAdded(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local session = self:_EnsureSession(player)
	self:_LogCustomEvent(player, "coinflip_session_start", 1, self:_BuildFields("join", self:_AccountAgeBand(player.AccountAge)))
end

function AnalyticsSystem:ReportDeviceProfile(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) or typeof(args) ~= "table" then
		return
	end

	local deviceClass = self:_DeviceClassField(args.deviceClass)
	local viewportBand = self:_ViewportBandField(args.viewportBand)
	local inputType = self:_InputTypeField(args.inputType)
	local session = self:_EnsureSession(player)
	session.deviceClass = deviceClass
	session.viewportBand = viewportBand
	session.inputType = inputType
	self:_LogFirstSessionEvent(
		player,
		"deviceProfileLogged",
		"coinflip_device_profile",
		self:_BuildFields(deviceClass, viewportBand, inputType)
	)
end

function AnalyticsSystem:PlayerRemoving(sender, player, args)
	if not IsServer or sender ~= SENDER then
		return
	end

	local session = self.players[player.UserId]
	if session then
		local duration = math.max(math.floor(os.clock() - session.startedAt), 0)
		self:_LogEarlySessionEnd(player, session, duration)
		self:_LogCustomEvent(
			player,
			"coinflip_session_end",
			duration,
			self:_BuildFields(self:_DurationBand(duration), session.flipCount or 0, session.lastMilestone or 0)
		)
		self.players[player.UserId] = nil
	end

	self:_FlushCustomEvents(player, math.huge)
end

function AnalyticsSystem:LogSeatAssigned(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local source = args and args.autoAssigned and "auto" or "manual"
	self:_LogCustomEvent(player, "coinflip_seat_assigned", 1, self:_BuildFields(source, args and args.seatId))
	self:_LogFirstSessionEvent(
		player,
		"firstSeatAssignedLogged",
		"coinflip_first_seat_assigned_latency",
		self:_BuildFields(self:_DurationBand(self:_GetSessionElapsed(player)), source, args and args.seatId)
	)
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

function AnalyticsSystem:LogFirstAutoToggle(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogFirstSessionEvent(
		player,
		"firstAutoToggleLogged",
		"coinflip_first_auto_toggle",
		self:_BuildFields(args and args.source, args and args.inputType, args and args.enabled)
	)
end

function AnalyticsSystem:LogFirstRunUpgrade(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	self:_LogFirstSessionEvent(
		player,
		"firstRunUpgradeLogged",
		"coinflip_first_run_upgrade",
		self:_BuildFields(args and args.upgradeKey, args and args.newLevel, self:_CashBand(args and args.cashAfterPurchase))
	)
end

function AnalyticsSystem:LogFirstGrowthPanelOpen(sender, player, args)
	if not self:_CanLog(sender, player) then
		return
	end

	local panel = args and args.panel
	if panel ~= "Shop" and panel ~= "Boosts" and panel ~= "Inventory" and panel ~= "Rebirth" then
		return
	end

	self:_LogFirstSessionEvent(
		player,
		`first{panel}OpenLogged`,
		"coinflip_first_growth_panel_open",
		self:_BuildFields(panel, args and args.source, args and args.inputType)
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

function AnalyticsSystem:_BuildCustomEventKey(player, eventName, fields)
	local field01 = fields and fields[CustomFieldKeys.CustomField01.Name] or ""
	local field02 = fields and fields[CustomFieldKeys.CustomField02.Name] or ""
	local field03 = fields and fields[CustomFieldKeys.CustomField03.Name] or ""
	return `{player.UserId}|{eventName}|{field01}|{field02}|{field03}`
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

function AnalyticsSystem:_DeviceClassField(deviceClass)
	if deviceClass == "touch" or deviceClass == "keyboard" or deviceClass == "gamepad" or deviceClass == "hybrid" then
		return deviceClass
	end

	return "unknown"
end

function AnalyticsSystem:_EarlySessionStage(session)
	if
		session.firstShopOpenLogged
		or session.firstBoostsOpenLogged
		or session.firstInventoryOpenLogged
		or session.firstRebirthOpenLogged
	then
		return "opened_growth_panel"
	end
	if session.firstRunUpgradeLogged then
		return "upgraded_run"
	end
	if session.firstFlipLogged then
		return "flipped_no_upgrade"
	end
	if session.firstSeatAssignedLogged then
		return "seated_no_flip"
	end

	return "joined_no_seat"
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

function AnalyticsSystem:_FlushCustomEvents(targetPlayer, limit)
	if not AnalyticsService then
		return 0
	end

	local remaining = limit or self:_GetFlushBudget()
	if remaining <= 0 then
		return 0
	end

	local flushed = 0
	local pendingCustomEventOrder = {}
	for _, key in ipairs(self.pendingCustomEventOrder) do
		local bucket = self.pendingCustomEvents[key]
		if bucket then
			local shouldFlush = not targetPlayer or bucket.player == targetPlayer
			if shouldFlush and remaining > 0 then
				self.pendingCustomEvents[key] = nil
				self:_SendCustomEvent(bucket.player, bucket.eventName, bucket.value, bucket.fields)
				flushed += 1
				remaining -= 1
			else
				table.insert(pendingCustomEventOrder, key)
			end
		end
	end

	self.pendingCustomEventOrder = pendingCustomEventOrder
	return flushed
end

function AnalyticsSystem:_GetFlushBudget()
	local requestsPerMinute = AnalyticsRateLimitBase + AnalyticsRateLimitPerPlayer * #Players:GetPlayers()
	local budget = math.floor(
		requestsPerMinute * AnalyticsRateLimitSafetyMultiplier * CustomEventFlushInterval / 60
	)
	return math.max(budget, 1)
end

function AnalyticsSystem:_GetSessionElapsed(player)
	local session = self:_EnsureSession(player)
	return math.max(math.floor(os.clock() - session.startedAt), 0)
end

function AnalyticsSystem:_InputTypeField(inputType)
	if typeof(inputType) ~= "string" then
		return "unknown"
	end
	if string.find(inputType, "Gamepad") == 1 then
		return "gamepad"
	end
	if inputType == "Touch" then
		return "touch"
	end
	if string.find(inputType, "Mouse") == 1 or inputType == "Keyboard" then
		return "keyboard"
	end

	return "unknown"
end

function AnalyticsSystem:_LogFirstSessionEvent(player, flagName, eventName, fields)
	local session = self:_EnsureSession(player)
	if session[flagName] == true then
		return false
	end

	local elapsed = self:_GetSessionElapsed(player)
	session[flagName] = true
	self:_LogCustomEvent(player, eventName, elapsed, fields)
	return true
end

function AnalyticsSystem:_LogEarlySessionEnd(player, session, duration)
	if duration >= EarlySessionDuration or session.earlySessionEndLogged == true then
		return
	end

	session.earlySessionEndLogged = true
	self:_LogCustomEvent(
		player,
		"coinflip_early_session_end",
		duration,
		self:_BuildFields(session.deviceClass or "unknown", session.viewportBand or "unknown", self:_EarlySessionStage(session))
	)
end

function AnalyticsSystem:_LogFlipProgress(player, args)
	local session = self:_EnsureSession(player)
	session.flipCount += 1

	local elapsed = self:_GetSessionElapsed(player)
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
	if not player then
		return
	end

	local key = self:_BuildCustomEventKey(player, eventName, fields)
	local bucket = self.pendingCustomEvents[key]
	if not bucket then
		bucket = {
			player = player,
			eventName = eventName,
			value = 0,
			fields = fields,
		}
		self.pendingCustomEvents[key] = bucket
		table.insert(self.pendingCustomEventOrder, key)
	end

	bucket.value += self:_ClampEventValue(value)
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

function AnalyticsSystem:_ViewportBandField(viewportBand)
	if
		viewportBand == "small_portrait"
		or viewportBand == "phone_landscape"
		or viewportBand == "tablet"
		or viewportBand == "desktop"
	then
		return viewportBand
	end

	return "unknown"
end

function AnalyticsSystem:_StringField(value)
	local text = tostring(value)
	if #text > 50 then
		return string.sub(text, 1, 50)
	end

	return text
end

function AnalyticsSystem:_SendCustomEvent(player, eventName, value, fields)
	local success, result = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, self:_ClampEventValue(value), fields)
	end)
	if not success then
		warn(`[AnalyticsSystem] Failed to log {eventName}: {result}`)
	end
end

---- [[ Client Only ]] ----

function AnalyticsSystem:_GetLocalDeviceClass(lastInputType)
	local lastInputName = lastInputType.Name
	local isGamepadInput = string.find(lastInputName, "Gamepad") == 1
	if UserInputService.TouchEnabled and (UserInputService.KeyboardEnabled or UserInputService.GamepadEnabled) then
		return "hybrid"
	end
	if isGamepadInput or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled) then
		return "gamepad"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "touch"
	end
	if UserInputService.KeyboardEnabled then
		return "keyboard"
	end

	return "unknown"
end

function AnalyticsSystem:_GetLocalViewportBand(deviceClass)
	local camera = WorkspaceService.CurrentCamera
	if not camera then
		return "unknown"
	end

	local viewportSize = camera.ViewportSize
	local width = viewportSize.X
	local height = viewportSize.Y
	local shortSide = math.min(width, height)
	local longSide = math.max(width, height)
	if deviceClass == "touch" or deviceClass == "hybrid" then
		if height > width and shortSide <= 700 then
			return "small_portrait"
		end
		if width > height and longSide <= 1200 then
			return "phone_landscape"
		end
		return "tablet"
	end

	return "desktop"
end

function AnalyticsSystem:_ReportLocalDeviceProfile()
	if IsServer then
		return
	end

	local lastInputType = UserInputService:GetLastInputType()
	local deviceClass = self:_GetLocalDeviceClass(lastInputType)
	self.Server:ReportDeviceProfile({
		deviceClass = deviceClass,
		viewportBand = self:_GetLocalViewportBand(deviceClass),
		inputType = lastInputType.Name,
	})
end

return AnalyticsSystem
