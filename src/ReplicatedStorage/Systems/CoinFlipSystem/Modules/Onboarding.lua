local Replicated = game:GetService("ReplicatedStorage")

local Keys = require(Replicated.configs.Keys)

local dataKey = Keys.DataKey

local Onboarding = {}

Onboarding.RequiredFlipCount = 3
Onboarding.RequiredStreak = 2

Onboarding.StepOrder = table.freeze({
	{
		key = "approachSeat",
		label = "Find Seat",
		title = "Find an open seat",
		analyticsStep = 2,
		analyticsName = "coinflip_approach_seat",
		toastText = "Open seat found. Sit down to start your run.",
	},
	{
		key = "sitDown",
		label = "Sit Down",
		title = "Sit down at the table",
		analyticsStep = 3,
		analyticsName = "coinflip_sit_down",
		toastText = "Nice. Flip 3 times to warm up your run.",
	},
	{
		key = "flipThree",
		label = "Flip x3",
		title = "Flip 3 times",
		analyticsStep = 4,
		analyticsName = "coinflip_flip_three",
		toastText = "Great. Spend your Cash on the first upgrade.",
	},
	{
		key = "buyUpgrade",
		label = "Buy Upgrade",
		title = "Buy your first upgrade",
		analyticsStep = 5,
		analyticsName = "coinflip_buy_upgrade",
		toastText = "Now chase a 2 Heads streak.",
	},
	{
		key = "reachTwoStreak",
		label = "2 Streak",
		title = "Reach a 2 Heads streak",
		analyticsStep = 6,
		analyticsName = "coinflip_reach_two_streak",
		toastText = "Guide complete. Push for a bigger streak now.",
	},
})

local StepLookup = {}
for _, step in ipairs(Onboarding.StepOrder) do
	StepLookup[step.key] = step
end

local DefaultState = table.freeze({
	version = 1,
	approachSeat = false,
	sitDown = false,
	flipCount = 0,
	boughtUpgrade = false,
	reachedTwoStreak = false,
	completed = false,
})

local function cloneDefaultState()
	return table.clone(DefaultState)
end

local function isStateComplete(state)
	return state.approachSeat
		and state.sitDown
		and state.flipCount >= Onboarding.RequiredFlipCount
		and state.boughtUpgrade
		and state.reachedTwoStreak
end

function Onboarding.IsStepComplete(state, stepKey)
	if stepKey == "approachSeat" then
		return state.approachSeat == true
	end
	if stepKey == "sitDown" then
		return state.sitDown == true
	end
	if stepKey == "flipThree" then
		return (state.flipCount or 0) >= Onboarding.RequiredFlipCount
	end
	if stepKey == "buyUpgrade" then
		return state.boughtUpgrade == true
	end
	if stepKey == "reachTwoStreak" then
		return state.reachedTwoStreak == true
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

function Onboarding.BuildActionText(state, context)
	local stepKey = Onboarding.GetCurrentStepKey(state)
	if not stepKey then
		return "Free Play"
	end

	if stepKey == "approachSeat" then
		return "Take Seat"
	end
	if stepKey == "sitDown" then
		return "Sit Down"
	end
	if stepKey == "flipThree" then
		local flipCount = math.min(state.flipCount or 0, Onboarding.RequiredFlipCount)
		return `Flip {flipCount}/{Onboarding.RequiredFlipCount}`
	end
	if stepKey == "buyUpgrade" then
		return "Buy Upgrade"
	end
	if stepKey == "reachTwoStreak" then
		local streak = math.min((context and context.streak) or 0, Onboarding.RequiredStreak)
		return `2 Streak {streak}/{Onboarding.RequiredStreak}`
	end

	return "Keep Going"
end

function Onboarding.BuildHeadSecondaryText(state, context)
	local stepKey = Onboarding.GetCurrentStepKey(state)
	if not stepKey then
		local cash = context and context.cash
		if typeof(cash) == "number" then
			return `$ {cash}`
		end
		return "Cash Run"
	end

	if stepKey == "approachSeat" then
		return "Start your first run"
	end
	if stepKey == "sitDown" then
		return "Use the seat prompt"
	end
	if stepKey == "flipThree" then
		return "Warm up your run"
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
	if stepKey == "reachTwoStreak" then
		return "Chain 2 Heads"
	end

	return "Keep Going"
end

local function persistState(playerIns, guideData, state)
	guideData.coinFlipOnboarding = state
	playerIns:SetOneData(dataKey.guideData, guideData)
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
		if typeof(state.version) ~= "number" then
			state.version = DefaultState.version
			needsSave = true
		end
		if typeof(state.approachSeat) ~= "boolean" then
			state.approachSeat = false
			needsSave = true
		end
		if typeof(state.sitDown) ~= "boolean" then
			state.sitDown = false
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
		if typeof(state.reachedTwoStreak) ~= "boolean" then
			state.reachedTwoStreak = false
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
		requiredStreak = Onboarding.RequiredStreak,
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

	if action == "approachSeat" then
		if not state.approachSeat then
			state.approachSeat = true
			changed = true
			table.insert(milestones, StepLookup.approachSeat)
		end
	elseif action == "sitDown" then
		if not state.approachSeat then
			state.approachSeat = true
			changed = true
		end
		if not state.sitDown then
			state.sitDown = true
			changed = true
			table.insert(milestones, StepLookup.sitDown)
		end
	elseif action == "flip" then
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
		local streak = context and context.streak or 0
		if streak >= Onboarding.RequiredStreak and not state.reachedTwoStreak then
			state.reachedTwoStreak = true
			changed = true
			table.insert(milestones, StepLookup.reachTwoStreak)
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
