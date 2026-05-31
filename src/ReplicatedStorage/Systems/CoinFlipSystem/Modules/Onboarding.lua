local Replicated = game:GetService("ReplicatedStorage")

local Keys = require(Replicated.configs.Keys)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local RebirthPresets = require(Replicated.Systems.RebirthSystem.Presets)

local dataKey = Keys.DataKey

local Onboarding = {}

Onboarding.StepOrder = table.freeze({
	{
		key = "firstFlip",
		label = "Flip",
		title = "Flip your first coin",
		analyticsStep = 3,
		analyticsName = "coinflip_first_flip",
	},
	{
		key = "rebirth",
		label = "Rebirth",
		title = "Make your first rebirth",
		analyticsStep = 7,
		analyticsName = "coinflip_first_rebirth",
	},
	{
		key = "coinBuy",
		label = "Buy Coin",
		title = "Buy a new coin",
		analyticsStep = 8,
		analyticsName = "coinflip_buy_coin",
	},
	{
		key = "coinEquip",
		label = "Equip Coin",
		title = "Equip your new coin",
		analyticsStep = 9,
		analyticsName = "coinflip_equip_coin",
	},
})

local StepLookup = {}
for _, step in ipairs(Onboarding.StepOrder) do
	StepLookup[step.key] = step
end

local DefaultState = table.freeze({
	version = 3,
	firstFlipDone = false,
	rebirthDone = false,
	coinPurchased = false,
	coinEquipped = false,
	completed = false,
})

local function cloneDefaultState()
	return table.clone(DefaultState)
end

local function getDefaultCoinId()
	return EcoPresets.LoadoutDefaults.equippedCoin
end

local function isNonDefaultCoin(coinId)
	return typeof(coinId) == "string" and coinId ~= "" and coinId ~= getDefaultCoinId()
end

local function getOwnedCoins(playerIns)
	local ownedCoins = playerIns:GetOneData(dataKey.ownedCoins)
	if typeof(ownedCoins) == "table" then
		return ownedCoins
	end

	return {}
end

local function getFirstOwnedNonDefaultCoinId(playerIns)
	local ownedCoins = getOwnedCoins(playerIns)
	for _, item in ipairs(EcoPresets.GrowthShopItems.coin or {}) do
		if isNonDefaultCoin(item.id) and ownedCoins[item.id] == true then
			return item.id
		end
	end

	return nil
end

local function getCoinDisplayName(coinId)
	return EcoPresets.GetShopItemDisplayName("coin", coinId)
end

local function hasAnyFlipProgress(playerIns)
	local lifetimeFlips = playerIns:GetOneData(dataKey.lifetimeFlips) or 0
	if lifetimeFlips > 0 then
		return true
	end

	local runData = playerIns:GetOneData(dataKey.runData)
	return typeof(runData) == "table" and (runData.flipsThisRun or 0) > 0
end

function Onboarding.GetCoinPurchaseTarget(playerIns)
	local ownedCoins = getOwnedCoins(playerIns)
	local cash = playerIns:GetOneData(dataKey.wins) or 0

	for _, item in ipairs(EcoPresets.GrowthShopItems.coin or {}) do
		if isNonDefaultCoin(item.id) and ownedCoins[item.id] ~= true and cash >= item.cost then
			return item
		end
	end

	return nil
end

function Onboarding.GetCoinEquipTarget(playerIns, state)
	local ownedCoins = getOwnedCoins(playerIns)
	local preferredCoinId = state and state.coinPurchasedItemId
	if isNonDefaultCoin(preferredCoinId) and ownedCoins[preferredCoinId] == true then
		return EcoPresets.GetShopItem("coin", preferredCoinId)
	end

	local firstOwnedCoinId = getFirstOwnedNonDefaultCoinId(playerIns)
	if firstOwnedCoinId then
		return EcoPresets.GetShopItem("coin", firstOwnedCoinId)
	end

	return nil
end

function Onboarding.CanRebirth(playerIns)
	local cash = playerIns:GetOneData(dataKey.wins) or 0
	return RebirthPresets.GetFlipACoinPointGain(cash) > 0
end

local function isStateComplete(state)
	return state.firstFlipDone and state.rebirthDone and state.coinEquipped
end

local function persistState(playerIns, guideData, state)
	guideData.coinFlipOnboarding = state
	playerIns:SetOneData(dataKey.guideData, guideData)
end

local function migrateState(playerIns, state)
	local migratedState = cloneDefaultState()
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local ownedCoinId = getFirstOwnedNonDefaultCoinId(playerIns)

	if state.completed == true or state.firstFlip == true or (state.flipCount or 0) >= 1 or hasAnyFlipProgress(playerIns) then
		migratedState.firstFlipDone = true
	end
	if (playerIns:GetOneData(dataKey.rebirth) or 0) > 0 then
		migratedState.rebirthDone = true
	end
	if isNonDefaultCoin(equippedCoin) then
		migratedState.coinPurchased = true
		migratedState.coinPurchasedItemId = equippedCoin
		migratedState.coinEquipped = true
	elseif ownedCoinId then
		migratedState.coinPurchased = true
		migratedState.coinPurchasedItemId = ownedCoinId
	end
	migratedState.completed = isStateComplete(migratedState)

	return migratedState
end

local function applyLiveProgress(playerIns, state)
	local changed = false
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local ownedCoinId = getFirstOwnedNonDefaultCoinId(playerIns)

	if not state.firstFlipDone and hasAnyFlipProgress(playerIns) then
		state.firstFlipDone = true
		changed = true
	end
	if not state.rebirthDone and (playerIns:GetOneData(dataKey.rebirth) or 0) > 0 then
		state.rebirthDone = true
		changed = true
	end
	if isNonDefaultCoin(equippedCoin) then
		if not state.coinPurchased or state.coinPurchasedItemId ~= equippedCoin then
			state.coinPurchased = true
			state.coinPurchasedItemId = equippedCoin
			changed = true
		end
		if not state.coinEquipped then
			state.coinEquipped = true
			changed = true
		end
	elseif ownedCoinId and not state.coinPurchased then
		state.coinPurchased = true
		state.coinPurchasedItemId = ownedCoinId
		changed = true
	end

	local completed = isStateComplete(state)
	if state.completed ~= completed then
		state.completed = completed
		changed = true
	end

	return changed
end

function Onboarding.IsStepComplete(state, stepKey)
	if stepKey == "firstFlip" then
		return state.firstFlipDone == true
	end
	if stepKey == "rebirth" then
		return state.rebirthDone == true
	end
	if stepKey == "coinBuy" then
		return state.coinPurchased == true
	end
	if stepKey == "coinEquip" then
		return state.coinEquipped == true
	end

	return false
end

function Onboarding.GetCompletedCount(state)
	local completedCount = 0
	for _, step in ipairs(Onboarding.StepOrder) do
		if Onboarding.IsStepComplete(state, step.key) then
			completedCount += 1
		end
	end
	return completedCount
end

function Onboarding.GetCurrentStepKey(playerIns, state)
	if not state.firstFlipDone then
		return "firstFlip"
	end
	if not state.rebirthDone then
		return "rebirth"
	end
	if not state.coinPurchased then
		return "coinBuy"
	end
	if not state.coinEquipped then
		return "coinEquip"
	end

	return nil
end

function Onboarding.GetStepConfig(stepKey)
	return stepKey and StepLookup[stepKey] or nil
end

function Onboarding.GetCurrentStepConfig(playerIns, state)
	return Onboarding.GetStepConfig(Onboarding.GetCurrentStepKey(playerIns, state))
end

local function getCurrentStepKeyFromState(state)
	if typeof(state) ~= "table" then
		return nil
	end

	if typeof(state.currentStep) == "string" then
		return state.currentStep
	end

	return nil
end

function Onboarding.BuildActionText(state, context)
	local stepKey = getCurrentStepKeyFromState(state)
	if not stepKey then
		return "Free Play"
	end

	if stepKey == "firstFlip" then
		return "First Flip"
	end
	if stepKey == "rebirth" then
		return state.shouldGuide and "Rebirth Ready" or "Build Rebirth"
	end
	if stepKey == "coinBuy" then
		return state.shouldGuide and "Buy Coin" or "Earn Coin"
	end
	if stepKey == "coinEquip" then
		return "Equip Coin"
	end

	return "Keep Going"
end

function Onboarding.BuildHeadSecondaryText(state, context)
	local stepKey = getCurrentStepKeyFromState(state)
	if not stepKey then
		local cash = context and context.cash
		if typeof(cash) == "number" then
			return `$ {cash}`
		end
		return "Cash Run"
	end

	if stepKey == "firstFlip" then
		return "Tap FLIP"
	end
	if stepKey == "rebirth" then
		return state.shouldGuide and "Use Rebirth" or "Build Cash"
	end
	if stepKey == "coinBuy" then
		return state.shouldGuide and `Buy {state.targetCoinName or "Coin"}` or "Save for Coin"
	end
	if stepKey == "coinEquip" then
		return `Equip {state.targetCoinName or "Coin"}`
	end

	return "Keep Going"
end

function Onboarding.EnsureState(playerIns)
	local guideData = playerIns:GetOneData(dataKey.guideData)
	local needsSave = false

	if typeof(guideData) ~= "table" then
		guideData = {}
		needsSave = true
	end

	local state = guideData.coinFlipOnboarding
	if typeof(state) ~= "table" then
		state = cloneDefaultState()
		needsSave = true
	elseif state.version ~= DefaultState.version then
		state = migrateState(playerIns, state)
		needsSave = true
	else
		if typeof(state.firstFlipDone) ~= "boolean" then
			state.firstFlipDone = false
			needsSave = true
		end
		if typeof(state.rebirthDone) ~= "boolean" then
			state.rebirthDone = false
			needsSave = true
		end
		if typeof(state.coinPurchased) ~= "boolean" then
			state.coinPurchased = false
			needsSave = true
		end
		if typeof(state.coinPurchasedItemId) ~= "string" then
			state.coinPurchasedItemId = nil
			needsSave = true
		end
		if typeof(state.coinEquipped) ~= "boolean" then
			state.coinEquipped = false
			needsSave = true
		end
		if typeof(state.completed) ~= "boolean" then
			state.completed = false
			needsSave = true
		end
	end

	if applyLiveProgress(playerIns, state) then
		needsSave = true
	end

	if needsSave then
		persistState(playerIns, guideData, state)
	end

	return guideData, state
end

function Onboarding.BuildState(playerIns)
	local _, state = Onboarding.EnsureState(playerIns)
	local currentStepKey = Onboarding.GetCurrentStepKey(playerIns, state)
	local currentStep = currentStepKey and StepLookup[currentStepKey] or nil
	local purchaseTarget = Onboarding.GetCoinPurchaseTarget(playerIns)
	local equipTarget = Onboarding.GetCoinEquipTarget(playerIns, state)
	local canRebirth = Onboarding.CanRebirth(playerIns)
	local shouldGuide = currentStepKey == "firstFlip"
		or (currentStepKey == "rebirth" and canRebirth)
		or (currentStepKey == "coinBuy" and purchaseTarget ~= nil)
		or (currentStepKey == "coinEquip" and equipTarget ~= nil)
	local targetCoin = currentStepKey == "coinEquip" and equipTarget or purchaseTarget
	local steps = {}

	for _, step in ipairs(Onboarding.StepOrder) do
		table.insert(steps, {
			key = step.key,
			label = step.label,
			title = step.title,
			isComplete = Onboarding.IsStepComplete(state, step.key),
		})
	end

	return {
		isComplete = state.completed,
		currentStep = currentStepKey,
		currentTitle = currentStep and currentStep.title or "Guide complete",
		completedCount = Onboarding.GetCompletedCount(state),
		totalSteps = #Onboarding.StepOrder,
		shouldGuide = shouldGuide,
		canRebirth = canRebirth,
		targetCoinId = targetCoin and targetCoin.id or nil,
		targetCoinName = targetCoin and getCoinDisplayName(targetCoin.id) or nil,
		targetCoinCost = targetCoin and targetCoin.cost or nil,
		steps = steps,
	}
end

function Onboarding.ApplyAction(playerIns, action, context)
	local guideData, state = Onboarding.EnsureState(playerIns)
	local changed = false
	local milestones = {}

	if state.completed then
		return false, milestones
	end

	if action == "flip" then
		if not state.firstFlipDone then
			state.firstFlipDone = true
			changed = true
			table.insert(milestones, StepLookup.firstFlip)
		end
	elseif action == "rebirth" then
		if not state.rebirthDone then
			state.rebirthDone = true
			changed = true
			table.insert(milestones, StepLookup.rebirth)
		end
	elseif action == "coinPurchase" then
		local itemId = context and context.itemId
		if isNonDefaultCoin(itemId) and (not state.coinPurchased or state.coinPurchasedItemId ~= itemId) then
			state.coinPurchased = true
			state.coinPurchasedItemId = itemId
			changed = true
			table.insert(milestones, StepLookup.coinBuy)
		end
	elseif action == "coinEquip" then
		local itemId = context and context.itemId
		if isNonDefaultCoin(itemId) then
			if not state.coinPurchased or state.coinPurchasedItemId ~= itemId then
				state.coinPurchased = true
				state.coinPurchasedItemId = itemId
				table.insert(milestones, StepLookup.coinBuy)
			end
			if not state.coinEquipped then
				state.coinEquipped = true
				table.insert(milestones, StepLookup.coinEquip)
			end
			changed = true
		end
	end

	if applyLiveProgress(playerIns, state) then
		changed = true
	end

	if changed then
		persistState(playerIns, guideData, state)
	end

	return changed, milestones
end

return Onboarding
