local Replicated = game:GetService("ReplicatedStorage")

local Keys = require(Replicated.configs.Keys)

local dataKey = Keys.DataKey

local Onboarding = {}

Onboarding.RequiredFlipCount = 3

Onboarding.StepOrder = table.freeze({
	{
		key = "autoSeat",
		label = "Seat Ready",
		title = "Get seated at the table",
		analyticsStep = 2,
		analyticsName = "coinflip_auto_seated",
		toastText = "Seat ready. Flip 3 times to earn your first upgrade.",
	},
	{
		key = "firstFlip",
		label = "First Flip",
		title = "Make your first flip",
		analyticsStep = 3,
		analyticsName = "coinflip_first_flip",
		toastText = "Good. Keep flipping until you can buy Value.",
	},
	{
		key = "flipThree",
		label = "Flip x3",
		title = "Flip 3 times",
		analyticsStep = 4,
		analyticsName = "coinflip_flip_three",
		toastText = "Great. You have enough Cash for the first upgrade.",
	},
	{
		key = "buyUpgrade",
		label = "Buy Upgrade",
		title = "Buy your first upgrade",
		analyticsStep = 5,
		analyticsName = "coinflip_buy_upgrade",
		toastText = "Upgrade bought. Flip again and try to build a streak.",
	},
	{
		key = "tryStreak",
		label = "Try Streak",
		title = "Try for a Heads streak",
		analyticsStep = 6,
		analyticsName = "coinflip_try_streak",
		toastText = "Guide complete. Chase bigger streaks now.",
	},
})

local StepLookup = {}
for _, step in ipairs(Onboarding.StepOrder) do
	StepLookup[step.key] = step
end

local DefaultState = table.freeze({
	version = 2,
	autoSeated = false,
	firstFlip = false,
	flipCount = 0,
	boughtUpgrade = false,
	triedStreak = false,
	completed = false,
})

local function cloneDefaultState()
	return table.clone(DefaultState)
end

local function isStateComplete(state)
	return state.autoSeated
		and state.firstFlip
		and state.flipCount >= Onboarding.RequiredFlipCount
		and state.boughtUpgrade
		and state.triedStreak
end

function Onboarding.IsStepComplete(state, stepKey)
	if stepKey == "autoSeat" then
		return state.autoSeated == true
	end
	if stepKey == "firstFlip" then
		return state.firstFlip == true
	end
	if stepKey == "flipThree" then
		return (state.flipCount or 0) >= Onboarding.RequiredFlipCount
	end
	if stepKey == "buyUpgrade" then
		return state.boughtUpgrade == true
	end
	if stepKey == "tryStreak" then
		return state.triedStreak == true
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

function Onboarding.GetCurrentStepKey(state)
	for _, step in ipairs(Onboarding.StepOrder) do
		if not Onboarding.IsStepComplete(state, step.key) then
			return step.key
		end
	end
	return nil
end

function Onboarding.GetStepConfig(stepKey)
	return stepKey and StepLookup[stepKey] or nil
end

function Onboarding.GetCurrentStepConfig(state)
	return Onboarding.GetStepConfig(Onboarding.GetCurrentStepKey(state))
end

local function getCurrentStepKeyFromState(state)
	if typeof(state) ~= "table" then
		return nil
	end

	if typeof(state.currentStep) == "string" then
		return state.currentStep
	end

	return Onboarding.GetCurrentStepKey(state)
end

function Onboarding.BuildActionText(state, context)
	local stepKey = getCurrentStepKeyFromState(state)
	if not stepKey then
		return "Free Play"
	end

	if stepKey == "autoSeat" then
		return "Finding Seat"
	end
	if stepKey == "firstFlip" then
		return "First Flip"
	end
	if stepKey == "flipThree" then
		local flipCount = math.min(state.flipCount or 0, Onboarding.RequiredFlipCount)
		return `Flip {flipCount}/{Onboarding.RequiredFlipCount}`
	end
	if stepKey == "buyUpgrade" then
		return "Buy Upgrade"
	end
	if stepKey == "tryStreak" then
		return "Try Streak"
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

	if stepKey == "autoSeat" then
		return "Auto seating"
	end
	if stepKey == "firstFlip" then
		return "Tap FLIP"
	end
	if stepKey == "flipThree" then
		return "Earn first upgrade"
	end
	if stepKey == "buyUpgrade" then
		local cash = context and context.cash
		if typeof(cash) == "number" then
			return `$ {cash}`
		end
		if typeof(cash) == "string" and cash ~= "" then
			return `$ {cash}`
		end
		return "Spend your Cash"
	end
	if stepKey == "tryStreak" then
		return "Flip after upgrading"
	end

	return "Keep Going"
end

local function persistState(playerIns, guideData, state)
	guideData.coinFlipOnboarding = state
	playerIns:SetOneData(dataKey.guideData, guideData)
end

local function migrateState(state)
	local migratedState = cloneDefaultState()
	local flipCount = state.flipCount or 0

	if state.completed == true then
		migratedState.autoSeated = true
		migratedState.firstFlip = true
		migratedState.flipCount = Onboarding.RequiredFlipCount
		migratedState.boughtUpgrade = true
		migratedState.triedStreak = true
		migratedState.completed = true
		return migratedState
	end

	migratedState.autoSeated = state.autoSeated == true or state.sitDown == true or state.approachSeat == true
	migratedState.firstFlip = state.firstFlip == true or flipCount >= 1
	migratedState.flipCount = flipCount
	migratedState.boughtUpgrade = state.boughtUpgrade == true
	migratedState.triedStreak = state.triedStreak == true or state.reachedTwoStreak == true
	migratedState.completed = isStateComplete(migratedState)

	return migratedState
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
	else
		if state.version ~= DefaultState.version then
			state = migrateState(state)
			needsSave = true
		end
		if typeof(state.autoSeated) ~= "boolean" then
			state.autoSeated = false
			needsSave = true
		end
		if typeof(state.firstFlip) ~= "boolean" then
			state.firstFlip = false
			needsSave = true
		end
		if typeof(state.flipCount) ~= "number" then
			state.flipCount = 0
			needsSave = true
		end
		if typeof(state.boughtUpgrade) ~= "boolean" then
			state.boughtUpgrade = false
			needsSave = true
		end
		if typeof(state.triedStreak) ~= "boolean" then
			state.triedStreak = false
			needsSave = true
		end
		if typeof(state.completed) ~= "boolean" then
			state.completed = false
			needsSave = true
		end
	end

	local clampedFlipCount = math.clamp(math.floor(state.flipCount or 0), 0, Onboarding.RequiredFlipCount)
	if clampedFlipCount ~= state.flipCount then
		state.flipCount = clampedFlipCount
		needsSave = true
	end

	local completed = isStateComplete(state)
	if state.completed ~= completed then
		state.completed = completed
		needsSave = true
	end

	if needsSave then
		persistState(playerIns, guideData, state)
	end

	return guideData, state
end

function Onboarding.BuildState(playerIns)
	local _, state = Onboarding.EnsureState(playerIns)
	local currentStepKey = Onboarding.GetCurrentStepKey(state)
	local currentStep = currentStepKey and StepLookup[currentStepKey] or nil
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
		flipCount = math.clamp(state.flipCount or 0, 0, Onboarding.RequiredFlipCount),
		requiredFlips = Onboarding.RequiredFlipCount,
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

	if action == "autoSeat" or action == "approachSeat" or action == "sitDown" then
		if not state.autoSeated then
			state.autoSeated = true
			changed = true
			table.insert(milestones, StepLookup.autoSeat)
		end
	elseif action == "flip" then
		if not state.firstFlip then
			state.firstFlip = true
			changed = true
			table.insert(milestones, StepLookup.firstFlip)
		end
		local previousCount = state.flipCount or 0
		local targetCount = context and context.flipCount
		if typeof(targetCount) ~= "number" then
			targetCount = previousCount + 1
		end
		targetCount = math.clamp(math.floor(targetCount), 0, Onboarding.RequiredFlipCount)
		if targetCount ~= previousCount then
			state.flipCount = targetCount
			changed = true
		end
		if previousCount < Onboarding.RequiredFlipCount and state.flipCount >= Onboarding.RequiredFlipCount then
			table.insert(milestones, StepLookup.flipThree)
		end
	elseif action == "buyUpgrade" then
		if not state.boughtUpgrade then
			state.boughtUpgrade = true
			changed = true
			table.insert(milestones, StepLookup.buyUpgrade)
		end
	elseif action == "streak" then
		if state.boughtUpgrade and state.flipCount >= Onboarding.RequiredFlipCount and not state.triedStreak then
			state.triedStreak = true
			changed = true
			table.insert(milestones, StepLookup.tryStreak)
		end
	end

	local completed = isStateComplete(state)
	if state.completed ~= completed then
		state.completed = completed
		changed = true
	end

	if changed then
		persistState(playerIns, guideData, state)
	end

	return changed, milestones
end

return Onboarding
