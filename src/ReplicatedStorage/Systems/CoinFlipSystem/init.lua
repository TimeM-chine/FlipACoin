local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseSystem = require(Replicated.Systems.BaseSystem)
local Keys = require(Replicated.configs.Keys)
local Presets = require(script.Presets)

local IsServer = RunService:IsServer()
local dataKey = Keys.DataKey

local CoinFlipSystem = BaseSystem.new("CoinFlipSystem")

local function getPlayerState(self, player)
	local playerState = self.players[player.UserId]
	if not playerState then
		playerState = {
			nextFlipAt = 0,
		}
		self.players[player.UserId] = playerState
	end

	return playerState
end

local function normalizeRunData(playerIns)
	local runData = playerIns:GetOneData(dataKey.runData)
	local needsUpdate = false

	if typeof(runData) ~= "table" then
		runData = table.clone(Presets.RunDataDefaults)
		needsUpdate = true
	else
		for key, defaultValue in pairs(Presets.RunDataDefaults) do
			if typeof(runData[key]) ~= typeof(defaultValue) then
				runData[key] = defaultValue
				needsUpdate = true
			end
		end
	end

	if needsUpdate then
		playerIns:SetOneData(dataKey.runData, runData)
	end

	return runData
end

local function getSeatState(self, player)
	local systemMgr = self:GetSystemMgr()
	local seatId = systemMgr.systems.TableSeatSystem:GetPlayerSeatId(player)

	return {
		isSeated = seatId ~= nil,
		seatId = seatId,
	}
end

local function buildClientState(self, player)
	local playerIns = self:GetPlayerIns(player)
	if not playerIns then
		return nil
	end

	local runData = normalizeRunData(playerIns)
	local wins = playerIns:GetOneData(dataKey.wins)

	return {
		cash = wins,
		wins = wins,
		runData = table.clone(runData),
		derivedStats = Presets.BuildDerivedStats(runData),
		nextCosts = Presets.GetNextCosts(runData),
		seatState = getSeatState(self, player),
	}
end

local function syncPlayerState(self, player, extraArgs, useFlipResolved)
	local payload = buildClientState(self, player)
	if not payload then
		return
	end

	if extraArgs then
		for key, value in pairs(extraArgs) do
			payload[key] = value
		end
	end

	if useFlipResolved then
		self.Client:FlipResolved(player, payload)
	else
		self.Client:SyncRunState(player, payload)
	end
end

local function refreshCashDisplays(self, player)
	local systemMgr = self:GetSystemMgr()
	systemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
	systemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
end

local function emitObservedFlip(self, player, args)
	local audiencePlayers = self:GetSystemMgr().systems.TableSeatSystem:GetAudiencePlayers(args.seatId)

	for _, audiencePlayer in ipairs(audiencePlayers) do
		if audiencePlayer ~= player then
			self.Client:ObservedFlip(audiencePlayer, args)
		end
	end
end

function CoinFlipSystem:Init()
	BaseSystem.Init(self)
end

function CoinFlipSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if not self:CheckSender(sender) then
			return
		end

		getPlayerState(self, player)
		self.Client:PlayerAdded(player, {
			state = buildClientState(self, player),
		})
	else
		self._Ui = self:InitUI(script.ui)
		if args and args.state then
			self._Ui.SyncRunState(args.state)
			self._Ui.SeatStateChanged({
				seatState = args.state.seatState,
			})
		end
	end
end

function CoinFlipSystem:PlayerRemoving(sender, player)
	if not IsServer then
		return
	end
	if not self:CheckSender(sender) then
		return
	end

	self.players[player.UserId] = nil
end

function CoinFlipSystem:RequestFlip(sender, player)
	if not IsServer then
		return
	end
	if not self:CheckSender(sender) then
		return
	end

	local systemMgr = self:GetSystemMgr()
	local seatSystem = systemMgr.systems.TableSeatSystem
	if not seatSystem:IsPlayerSeated(player) then
		return
	end

	local playerState = getPlayerState(self, player)
	local now = os.clock()
	if playerState.nextFlipAt > now then
		return
	end

	local playerIns = self:GetPlayerIns(player)
	if not playerIns then
		return
	end

	local seatId = seatSystem:GetPlayerSeatId(player)
	local runData = normalizeRunData(playerIns)
	local isHeads = math.random() < Presets.GetHeadsChance(runData)
	local reward = 0
	playerIns:SetOneData(dataKey.lifetimeFlips, playerIns:GetOneData(dataKey.lifetimeFlips) + 1)
	runData.flipsThisRun += 1

	if isHeads then
		runData.currentStreak += 1
		runData.headsThisRun += 1
		reward = Presets.GetHeadsReward(runData)
		runData.cashEarnedThisRun += reward
		runData.bestStreakThisRun = math.max(runData.bestStreakThisRun, runData.currentStreak)

		playerIns:SetOneData(dataKey.wins, playerIns:GetOneData(dataKey.wins) + reward)
		playerIns:SetOneData(dataKey.lifetimeHeads, playerIns:GetOneData(dataKey.lifetimeHeads) + 1)
		playerIns:SetOneData(
			dataKey.lifetimeCashEarned,
			playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward
		)
		playerIns:SetOneData(dataKey.bestStreak, math.max(playerIns:GetOneData(dataKey.bestStreak), runData.bestStreakThisRun))
	else
		runData.currentStreak = 0
	end

	playerState.nextFlipAt = now + Presets.GetFlipInterval(runData)
	playerIns:SetOneData(dataKey.runData, runData)

	seatSystem:RegisterActivity(systemMgr.SENDER, player)
	refreshCashDisplays(self, player)

	local observedPayload = {
		userId = player.UserId,
		seatId = seatId,
		result = isHeads and "Heads" or "Tails",
		reward = reward,
		streak = runData.currentStreak,
		bestStreakThisRun = runData.bestStreakThisRun,
	}

	emitObservedFlip(self, player, observedPayload)
	systemMgr.systems.AnnouncementSystem:HandleFlipResolved(systemMgr.SENDER, player, observedPayload)

	syncPlayerState(self, player, {
		result = observedPayload.result,
		reward = reward,
		streak = runData.currentStreak,
	}, true)
end

function CoinFlipSystem:BuyUpgrade(sender, player, args)
	if not IsServer then
		return
	end
	if not self:CheckSender(sender) then
		return
	end

	local systemMgr = self:GetSystemMgr()
	local seatSystem = systemMgr.systems.TableSeatSystem
	if not seatSystem:IsPlayerSeated(player) then
		return
	end

	local upgradeKey = Presets.ResolveUpgradeKey(args and args.upgradeType)
	if not upgradeKey then
		return
	end

	local playerIns = self:GetPlayerIns(player)
	if not playerIns then
		return
	end

	local runData = normalizeRunData(playerIns)
	local currentLevel = runData[upgradeKey]
	if Presets.IsUpgradeMaxed(upgradeKey, currentLevel) then
		return
	end

	local cost = Presets.GetUpgradeCost(upgradeKey, currentLevel)
	local wins = playerIns:GetOneData(dataKey.wins)
	if wins < cost then
		return
	end

	playerIns:SetOneData(dataKey.wins, wins - cost)
	runData[upgradeKey] += 1
	playerIns:SetOneData(dataKey.runData, runData)

	seatSystem:RegisterActivity(systemMgr.SENDER, player)
	refreshCashDisplays(self, player)
	syncPlayerState(self, player, {
		upgradePurchased = upgradeKey,
	})
end

function CoinFlipSystem:SyncRunState(sender, player, args)
	if IsServer or not self._Ui then
		return
	end

	self._Ui.SyncRunState(args)
end

function CoinFlipSystem:FlipResolved(sender, player, args)
	if IsServer or not self._Ui then
		return
	end

	self._Ui.FlipResolved(args)
end

function CoinFlipSystem:SeatStateChanged(sender, player, args)
	if IsServer or not self._Ui then
		return
	end

	self._Ui.SeatStateChanged(args)
end

function CoinFlipSystem:ObservedFlip(sender, player, args)
	if IsServer or not self._Ui then
		return
	end

	self._Ui.ObservedFlip(args)
end

return CoinFlipSystem
