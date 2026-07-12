local Replicated = game:GetService("ReplicatedStorage")

local CoinFlipPresets = require(Replicated.Systems.CoinFlipSystem.Presets)

local Presets = {}

Presets.ScenarioOrder = table.freeze({
	"freshRun",
	"upgradeReady",
	"rebirthReady",
	"coinSpreadReady",
	"multiCoin2",
	"multiCoin3",
	"multiCoin4",
	"multiCoin5",
	"perfectFive",
	"edgeStand",
	"notificationPriority",
	"longSession",
})

Presets.Scenarios = table.freeze({
	freshRun = { cash = 9, rebirth = 0, fateShards = 0, coinSpread = 0 },
	upgradeReady = { cash = 500, rebirth = 0, fateShards = 0, coinSpread = 0 },
	rebirthReady = { cash = 250, rebirth = 0, fateShards = 0, coinSpread = 0 },
	coinSpreadReady = { cash = 30, rebirth = 1, fateShards = 1, coinSpread = 0 },
	multiCoin2 = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 1 },
	multiCoin3 = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 2 },
	multiCoin4 = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 3 },
	multiCoin5 = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 4 },
	perfectFive = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 4, forcedOutcome = "perfectFive" },
	edgeStand = { cash = 30, rebirth = 1, fateShards = 0, coinSpread = 1, forcedOutcome = "edgeStand" },
	notificationPriority = { cash = 30, rebirth = 0, fateShards = 0, coinSpread = 0, qaAction = "notificationPriority" },
	longSession = { cash = 500, rebirth = 1, fateShards = 0, coinSpread = 4, autoFlipUnlocked = true },
})

function Presets.BuildForcedOutcome(outcomeName, runData, bonusStats)
	local coinCount = CoinFlipPresets.GetCoinCount(runData, bonusStats)
	local coinResults = {}
	local headsCount = 0
	if outcomeName == "perfectFive" then
		coinCount = 5
		headsCount = coinCount
		for coinIndex = 1, coinCount do
			coinResults[coinIndex] = "Heads"
		end
	elseif outcomeName == "edgeStand" then
		for coinIndex = 1, coinCount do
			coinResults[coinIndex] = "Tails"
		end
	else
		return nil
	end

	local successThreshold = CoinFlipPresets.GetRoundSuccessThreshold(coinCount)
	local perfect = headsCount == coinCount
	local comboKey = CoinFlipPresets.GetComboKey(headsCount, coinCount, perfect)
	return {
		coinCount = coinCount,
		coinResults = coinResults,
		headsCount = headsCount,
		tailsCount = coinCount - headsCount,
		roundSuccess = headsCount >= successThreshold,
		successThreshold = successThreshold,
		perfect = perfect,
		comboKey = comboKey,
		comboTier = CoinFlipPresets.GetComboTier(comboKey),
		comboName = CoinFlipPresets.GetComboName(headsCount, coinCount, perfect),
		comboMultiplier = CoinFlipPresets.GetComboMultiplier(headsCount),
		edgeStand = outcomeName == "edgeStand",
		edgeStandChance = outcomeName == "edgeStand" and 1 or 0,
		edgeStandBonusReward = outcomeName == "edgeStand" and CoinFlipPresets.GetEdgeStandBonusReward() or 0,
		edgeStandCoinIndex = outcomeName == "edgeStand" and 1 or nil,
	}
end

return Presets
