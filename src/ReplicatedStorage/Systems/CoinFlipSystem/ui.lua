local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Keys = require(Replicated.configs.Keys)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local dataKey = Keys.DataKey

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local uiController = require(Main:WaitForChild("uiController"))
local FirstPersonCamera =
	require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"):WaitForChild("FirstPersonCamera"))

local CoinFlipSystem = SystemMgr.systems.CoinFlipSystem
local TableSeatSystem = SystemMgr.systems.TableSeatSystem
local VisualConfig = Presets.Visuals
local LayoutConfig = Presets.UiLayout

local function findFirstByNames(parent, names)
	for _, name in ipairs(names) do
		local child = parent:FindFirstChild(name)
		if child then
			return child
		end
	end

	return nil
end

local function ensureCorner(guiObject, radius)
	local corner = guiObject:FindFirstChildOfClass("UICorner")
	if corner then
		return corner
	end

	corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 12)
	corner.Parent = guiObject
	return corner
end

local function ensureStroke(guiObject, color, thickness, transparency)
	local stroke = guiObject:FindFirstChildOfClass("UIStroke")
	if stroke then
		return stroke
	end

	stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(255, 214, 124)
	stroke.Thickness = thickness or 1.2
	stroke.Transparency = transparency or 0.4
	stroke.Parent = guiObject
	return stroke
end

local function ensureTextLabel(parent, name, config)
	local label = parent:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		return label
	end

	label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = (config and config.font) or Enum.Font.GothamMedium
	label.Text = (config and config.text) or ""
	label.TextColor3 = (config and config.textColor) or Color3.fromRGB(245, 247, 250)
	label.TextSize = (config and config.textSize) or 14
	label.TextWrapped = config and config.textWrapped == true or false
	label.TextXAlignment = (config and config.textXAlignment) or Enum.TextXAlignment.Left
	label.TextYAlignment = (config and config.textYAlignment) or Enum.TextYAlignment.Center
	label.Visible = config == nil or config.visible ~= false
	if config and config.layoutOrder then
		label.LayoutOrder = config.layoutOrder
	end
	if config and config.size then
		label.Size = config.size
	end
	if config and config.position then
		label.Position = config.position
	end
	label.Parent = parent
	return label
end

local Hud = Elements:WaitForChild("CoinFlipHUD")
local Content = Hud:WaitForChild("Content")
local ContentListLayout = Content:WaitForChild("PanelListLayout")
local LeftPanel = Content:WaitForChild("LeftPanel")
local CenterPanel = Content:WaitForChild("CenterPanel")
local RightPanel = Content:WaitForChild("RightPanel")
local LeftPanelListLayout = LeftPanel:WaitForChild("LeftPanelListLayout")
local CenterPanelListLayout = CenterPanel:WaitForChild("CenterPanelListLayout")
local RightPanelListLayout = RightPanel:WaitForChild("RightPanelListLayout")
local RightStatsFrame = RightPanel:WaitForChild("Stats")
local RightStatsGridLayout = RightStatsFrame:WaitForChild("RightStatsGridLayout")
local UpgradeButtons = RightPanel:WaitForChild("UpgradeButtons")
local UpgradeGridLayout = UpgradeButtons:WaitForChild("UpgradeGridLayout")
local SeatLabel = CenterPanel:WaitForChild("SeatLabel")
local InputHints = CenterPanel:WaitForChild("InputHints")

local function resolveStatLabel(card)
	return findFirstByNames(card, { "Title", "Label" })
end

local function resolveStatValue(card)
	return findFirstByNames(card, { "Value", "CashValue", "ChanceValue", "StreakValue", "SpeedValue", "SeatValue" })
end

local CashCard = LeftPanel:WaitForChild("Cash")
local StreakCard = LeftPanel:WaitForChild("Streak")
local ChanceCard = RightStatsFrame:WaitForChild("Chance")
local SpeedCard = RightStatsFrame:WaitForChild("Speed")

local CashValue = resolveStatValue(CashCard)
local StreakValue = resolveStatValue(StreakCard)
local ChanceValue = resolveStatValue(ChanceCard)
local SpeedValue = resolveStatValue(SpeedCard)
local ResultLabel = CenterPanel:WaitForChild("ResultLabel")
local FlipButton = CenterPanel:WaitForChild("FlipButton")
if not FlipButton or not FlipButton:IsA("GuiButton") then
	error("CoinFlipHUD is missing FlipButton")
end

local SpectatorFeed = Elements:FindFirstChild("CoinFlipSpectatorFeed")
local TableOverview = Elements:FindFirstChild("CoinFlipTableOverview")
if SpectatorFeed and SpectatorFeed:IsA("GuiObject") then
	SpectatorFeed.Visible = false
end
if TableOverview and TableOverview:IsA("GuiObject") then
	TableOverview.Visible = false
end

local OnboardingPanel = Elements:WaitForChild("CoinFlipOnboarding")
local OnboardingTitle = OnboardingPanel:WaitForChild("Title")
local OnboardingTaskLabel = OnboardingPanel:WaitForChild("TaskLabel")
local OnboardingHintLabel = OnboardingPanel:WaitForChild("HintLabel")
local OnboardingProgressBar = OnboardingPanel:WaitForChild("ProgressBar")
local OnboardingProgressFill = OnboardingProgressBar:WaitForChild("Fill")

local function ensureOnboardingProgressText()
	local progressText = OnboardingPanel:FindFirstChild("ProgressText")
	if progressText and progressText:IsA("TextLabel") then
		return progressText
	end

	progressText = ensureTextLabel(OnboardingPanel, "ProgressText", {
		text = "0 / 5",
		font = Enum.Font.GothamBold,
		textColor = Color3.fromRGB(255, 231, 163),
		textSize = 13,
		textXAlignment = Enum.TextXAlignment.Right,
		layoutOrder = 2,
	})
	progressText.Size = UDim2.new(1, 0, 0, 18)
	return progressText
end

local function ensureOnboardingSteps()
	local steps = OnboardingPanel:FindFirstChild("Steps")
	if steps and steps:IsA("Frame") then
		return steps
	end

	steps = Instance.new("Frame")
	steps.Name = "Steps"
	steps.BackgroundTransparency = 1
	steps.LayoutOrder = 6
	steps.Size = UDim2.new(1, 0, 0, 26)
	steps.Parent = OnboardingPanel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = steps

	for index = 1, 5 do
		local chip = ensureTextLabel(steps, string.format("Step%02d", index), {
			text = tostring(index),
			font = Enum.Font.GothamBold,
			textColor = Color3.fromRGB(174, 184, 198),
			textSize = 11,
		})
		chip.BackgroundColor3 = Color3.fromRGB(28, 33, 42)
		chip.BackgroundTransparency = 0.08
		chip.BorderSizePixel = 0
		chip.Size = UDim2.fromOffset(44, 24)
		ensureCorner(chip, UDim.new(0, 999))
		ensureStroke(chip, Color3.fromRGB(255, 214, 124), 1, 0.78)
	end

	return steps
end

local OnboardingProgressText = ensureOnboardingProgressText()
local OnboardingSteps = ensureOnboardingSteps()

local UpgradeMap = {
	valueLevel = UpgradeButtons:WaitForChild("ValueButton"),
	comboLevel = UpgradeButtons:WaitForChild("ComboButton"),
	speedLevel = UpgradeButtons:WaitForChild("SpeedButton"),
	biasLevel = UpgradeButtons:WaitForChild("BiasButton"),
}
local UpgradeTitles = {
	valueLevel = "Value",
	comboLevel = "Combo",
	speedLevel = "Speed",
	biasLevel = "Bias",
}

local CoinFlipUi = {}
local initialized = false
local flipInputBound = false
local activeVisuals = {}
local currentSeatId
local currentFlipInterval = 1.8
local localFlipCooldownEndsAt = 0
local activeFlipRequestToken = 0
local awaitingFlipResponse = false
local resultFlashToken = 0
local defaultResultTextTransparency = ResultLabel.TextTransparency
local defaultResultStrokeTransparency = ResultLabel.TextStrokeTransparency
local currentSeatState
local currentLayoutProfile
local viewportChangedConnection
local cameraChangedConnection
local currentOnboardingState
local currentRunSnapshot = {
	cash = 0,
	runData = {},
	nextCosts = {},
	derivedStats = {},
}
local lastOnboardingStepKey
local FlipInputActionName = "COIN_FLIP_REQUEST"

local StatsCards = {
	{
		key = "cash",
		card = CashCard,
		label = resolveStatLabel(CashCard),
		value = CashValue,
	},
	{
		key = "streak",
		card = StreakCard,
		label = resolveStatLabel(StreakCard),
		value = StreakValue,
	},
	{
		key = "chance",
		card = ChanceCard,
		label = resolveStatLabel(ChanceCard),
		value = ChanceValue,
	},
	{
		key = "speed",
		card = SpeedCard,
		label = resolveStatLabel(SpeedCard),
		value = SpeedValue,
	},
}

for layoutOrder, entry in ipairs(StatsCards) do
	entry.card.LayoutOrder = layoutOrder
end

local OnboardingStepLabels = {}
for index = 1, 5 do
	OnboardingStepLabels[index] = OnboardingSteps:WaitForChild(string.format("Step%02d", index))
end

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1920, 1080)
end

local function ensureSizeConstraint(guiObject, name)
	local constraint = guiObject:FindFirstChild(name)
	if constraint then
		return constraint
	end

	constraint = Instance.new("UISizeConstraint")
	constraint.Name = name
	constraint.Parent = guiObject
	return constraint
end

local function ensureTextConstraint(label, name)
	local constraint = label:FindFirstChild(name)
	if constraint then
		return constraint
	end

	constraint = Instance.new("UITextSizeConstraint")
	constraint.Name = name
	constraint.Parent = label
	return constraint
end

local function applyClampConstraint(guiObject, name, minSize, maxSize)
	local constraint = ensureSizeConstraint(guiObject, name)
	constraint.MinSize = Vector2.new(minSize.X, minSize.Y)
	constraint.MaxSize = Vector2.new(maxSize.X, maxSize.Y)
	return constraint
end

local function getLayoutProfile()
	local viewport = getViewportSize()
	local aspect = viewport.X / math.max(viewport.Y, 1)
	local isPortrait = aspect < 1
	local isTouchDevice = UserInputService.TouchEnabled
	local isMobile = isTouchDevice
		or viewport.X <= LayoutConfig.MobileMaxWidth
		or aspect <= LayoutConfig.MobileMaxAspect
	local isNarrow = viewport.X <= LayoutConfig.NarrowWidth

	local hudSize = LayoutConfig.Hud.DesktopSize
	local hudY = LayoutConfig.Hud.DesktopY
	if isMobile then
		hudSize = isPortrait and LayoutConfig.Hud.MobilePortraitSize or LayoutConfig.Hud.MobileLandscapeSize
		hudY = isPortrait and LayoutConfig.Hud.MobilePortraitY or LayoutConfig.Hud.MobileLandscapeY
	elseif isNarrow then
		hudSize = LayoutConfig.Hud.NarrowSize
	end

	return {
		viewport = viewport,
		aspect = aspect,
		isPortrait = isPortrait,
		isTouchDevice = isTouchDevice,
		isMobile = isMobile,
		isNarrow = isNarrow,
		hudSize = hudSize,
		hudY = hudY,
		hudMinSize = isMobile and LayoutConfig.Hud.MobileMinSize or LayoutConfig.Hud.MinSize,
		hudMaxSize = isMobile and LayoutConfig.Hud.MobileMaxSize or LayoutConfig.Hud.MaxSize,
		statsColumns = isMobile and 2 or 5,
		statsCellSize = isMobile and UDim2.fromScale(0.48, 0.44) or UDim2.fromScale(0.192, 1),
		statsCellPadding = isMobile and UDim2.fromScale(0.03, 0.06) or UDim2.fromScale(0.01, 0),
		upgradeColumns = isMobile and 2 or 4,
		upgradeCellSize = isMobile and UDim2.fromScale(0.48, 0.42) or UDim2.fromScale(0.235, 1),
		upgradeCellPadding = isMobile and UDim2.fromScale(0.03, 0.08) or UDim2.fromScale(0.02, 0),
	}
end

local function getRecommendedUpgradeKey()
	local runData = currentRunSnapshot.runData or {}
	local nextCosts = currentRunSnapshot.nextCosts or Presets.GetNextCosts(runData)
	local cash = currentRunSnapshot.cash or 0

	for _, upgradeKey in ipairs(Presets.UpgradeOrder or {}) do
		local cost = nextCosts[upgradeKey]
		if cost and cash >= cost then
			return upgradeKey
		end
	end

	return nil
end

local function buildFailureFollowUpText()
	local seatState = currentSeatState or {}
	local suggestedUpgrade = getRecommendedUpgradeKey()

	if currentOnboardingState and not currentOnboardingState.isComplete then
		local step = currentOnboardingState.currentStep
		if step == "flipThree" then
			local requiredFlips = currentOnboardingState.requiredFlips or 3
			local flipCount = math.min(currentOnboardingState.flipCount or 0, requiredFlips)
			return `Next: keep flipping to reach {requiredFlips}. ({flipCount}/{requiredFlips})`
		end
		if step == "buyUpgrade" then
			local buttonLabel = suggestedUpgrade and UpgradeTitles[suggestedUpgrade] or "an upgrade"
			return `Next: buy {buttonLabel}.`
		end
		if step == "reachTwoStreak" then
			local streak = math.min(
				(currentRunSnapshot.runData and currentRunSnapshot.runData.currentStreak or 0),
				currentOnboardingState.requiredStreak or 2
			)
			return `Next: rebuild to 2 Heads. ({streak}/{currentOnboardingState.requiredStreak or 2})`
		end
	end

	if not seatState.isSeated then
		return "Next: take a seat and start again."
	end

	if suggestedUpgrade then
		return `Next: buy {UpgradeTitles[suggestedUpgrade]} or flip again.`
	end

	return "Next: flip again and rebuild your streak."
end

local function maybeShowFailureFollowUpNotification(text)
	if typeof(text) ~= "string" or text == "" then
		return
	end

	uiController.SetNotification({
		text = text,
		lastTime = 2.4,
		textColor = Color3.fromRGB(255, 223, 153),
	})
end

local function buildOnboardingHint()
	if not currentOnboardingState or currentOnboardingState.isComplete then
		return ""
	end

	local step = currentOnboardingState.currentStep
	local seatState = currentSeatState or {}
	local streak = currentRunSnapshot.runData and (currentRunSnapshot.runData.currentStreak or 0) or 0

	if step == "approachSeat" then
		if seatState.isSeated then
			return "Seat found. Locking you into the table now."
		end
		return "Finding an open seat for you now."
	end

	if step == "sitDown" then
		return seatState.isSeated and "Seat locked in. You're ready to start flipping."
			or "Dropping you into the table automatically."
	end

	if step == "flipThree" then
		local flipCount = math.min(currentOnboardingState.flipCount or 0, currentOnboardingState.requiredFlips or 3)
		if seatState.isSeated then
			return `Flip from this seat 3 times to warm up. {flipCount}/{currentOnboardingState.requiredFlips or 3} done.`
		end
		return `Seat assignment in progress, then flip 3 times. {flipCount}/{currentOnboardingState.requiredFlips or 3} done.`
	end

	if step == "buyUpgrade" then
		local suggestedUpgrade = getRecommendedUpgradeKey()
		local buttonLabel = suggestedUpgrade and UpgradeTitles[suggestedUpgrade] or "any upgrade"
		if seatState.isSeated then
			return `Spend your Cash on {buttonLabel} to keep the run moving.`
		end
		return "Seat assignment in progress, then buy your first upgrade with the Cash you earned."
	end

	if step == "reachTwoStreak" then
		if seatState.isSeated then
			return `Chain 2 Heads in a row to finish the guide. Current streak: {streak}.`
		end
		return "Seat assignment in progress, then chain 2 Heads in a row to finish the guide."
	end

	return ""
end

local function refreshGuideButtonHighlight()
	if not currentOnboardingState or currentOnboardingState.isComplete then
		uiController.SetGuideButton(nil)
		return
	end

	if currentOnboardingState.currentStep == "flipThree" and currentSeatState and currentSeatState.isSeated then
		uiController.SetGuideButton(FlipButton)
		return
	end

	if currentOnboardingState.currentStep == "buyUpgrade" and currentSeatState and currentSeatState.isSeated then
		local upgradeKey = getRecommendedUpgradeKey()
		local button = upgradeKey and UpgradeMap[upgradeKey] or UpgradeMap.valueLevel
		if button then
			uiController.SetGuideButton(button)
			return
		end
	end

	uiController.SetGuideButton(nil)
end

local function updateOnboardingPanel()
	if not currentOnboardingState or currentOnboardingState.isComplete then
		OnboardingPanel.Visible = false
		refreshGuideButtonHighlight()
		return
	end

	local completedCount = currentOnboardingState.completedCount or 0
	local totalSteps = math.max(currentOnboardingState.totalSteps or 5, 1)
	local progressValue = completedCount
	if currentOnboardingState.currentStep == "flipThree" then
		progressValue += math.min(
			(currentOnboardingState.flipCount or 0) / math.max(currentOnboardingState.requiredFlips or 3, 1),
			0.95
		)
	end

	OnboardingTitle.Text = "First Run Guide"
	OnboardingProgressText.Text = `{completedCount} / {totalSteps}`
	OnboardingTaskLabel.Text = currentOnboardingState.currentTitle or "Keep going"
	OnboardingHintLabel.Text = buildOnboardingHint()
	OnboardingProgressFill.Size = UDim2.fromScale(math.clamp(progressValue / totalSteps, 0, 1), 1)

	for index, step in ipairs(currentOnboardingState.steps or {}) do
		local chip = OnboardingStepLabels[index]
		if not chip then
			continue
		end
		chip.Text = step.label or chip.Text
		if step.isComplete then
			chip.BackgroundColor3 = Color3.fromRGB(63, 96, 67)
			chip.TextColor3 = Color3.fromRGB(226, 255, 229)
			chip.UIStroke.Transparency = 0.1
		elseif step.key == currentOnboardingState.currentStep then
			chip.BackgroundColor3 = Color3.fromRGB(90, 66, 25)
			chip.TextColor3 = Color3.fromRGB(255, 239, 188)
			chip.UIStroke.Transparency = 0.02
		else
			chip.BackgroundColor3 = Color3.fromRGB(28, 33, 42)
			chip.TextColor3 = Color3.fromRGB(174, 184, 198)
			chip.UIStroke.Transparency = 0.78
		end
	end

	OnboardingPanel.Visible = true
	refreshGuideButtonHighlight()
end

local function applyOnboardingLayout(profile)
	OnboardingTitle.LayoutOrder = 1
	OnboardingProgressText.LayoutOrder = 2
	OnboardingTaskLabel.LayoutOrder = 3
	OnboardingHintLabel.LayoutOrder = 4
	local spacer = OnboardingPanel:FindFirstChild("Spacer")
	if spacer and spacer:IsA("GuiObject") then
		spacer.LayoutOrder = 5
	end
	if OnboardingSteps then
		OnboardingSteps.LayoutOrder = 6
	end
	OnboardingProgressBar.LayoutOrder = 7

	if profile.isMobile then
		OnboardingPanel.Position = profile.isPortrait and UDim2.fromScale(0.02, 0.085) or UDim2.fromScale(0.02, 0.12)
		OnboardingPanel.Size = profile.isPortrait and UDim2.fromOffset(230, 168) or UDim2.fromOffset(250, 156)
		OnboardingTitle.TextSize = profile.isPortrait and 14 or 15
		OnboardingProgressText.TextSize = profile.isPortrait and 12 or 13
		OnboardingTaskLabel.TextSize = profile.isPortrait and 14 or 15
		OnboardingHintLabel.TextSize = 11
	else
		OnboardingPanel.Position = UDim2.fromScale(0.016, 0.11)
		OnboardingPanel.Size = UDim2.fromOffset(328, 188)
		OnboardingTitle.TextSize = 18
		OnboardingProgressText.TextSize = 14
		OnboardingTaskLabel.TextSize = 17
		OnboardingHintLabel.TextSize = 13
	end

	if OnboardingProgressText then
		OnboardingProgressText.Size = UDim2.new(1, 0, 0, profile.isMobile and 16 or 18)
	end
	if OnboardingSteps then
		OnboardingSteps.Size = UDim2.new(1, 0, 0, profile.isMobile and 22 or 26)
	end
end

local function getTableModel()
	return Workspace:FindFirstChild("CoinFlipTable")
end

local function getSeatRecord(seatId)
	if typeof(seatId) ~= "string" then
		return nil
	end

	return TableSeatSystem:GetSeatRecordByDisplayId(seatId)
end

local function getCoinVisualsFolder(seatId)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local assets = tableModel and tableModel:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("CoinVisuals") or nil
end

local function getSeatAttachment(seatId)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local attachmentsFolder = tableModel and tableModel:FindFirstChild("Attachments")
	local marker = attachmentsFolder and attachmentsFolder:FindFirstChild(`{rawSeatId}Marker`)
	return marker and marker:FindFirstChildWhichIsA("Attachment") or nil
end

local function getSeatPart(seatId)
	local seatRecord = getSeatRecord(seatId)
	if seatRecord and seatRecord.seat then
		return seatRecord.seat
	end

	local tableModel = getTableModel()
	local seatsFolder = tableModel and tableModel:FindFirstChild("Seats")
	return seatsFolder and seatsFolder:FindFirstChild(seatId)
end

local function hideLegacySeatBillboards(seatState)
	if not seatState or not seatState.seatDisplayEntries then
		return
	end

	for _, entry in ipairs(seatState.seatDisplayEntries) do
		local seatPart = getSeatPart(entry.seatId)
		local billboard = seatPart and seatPart:FindFirstChild("SeatInfoBillboard")
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = false
		end
	end
end

local function applyStatCardLayout(profile)
	for _, entry in ipairs(StatsCards) do
		local labelConstraint = entry.label:WaitForChild("ResponsiveConstraint")
		local valueConstraint = entry.value:WaitForChild("ResponsiveConstraint")
		local isPrimaryCard = entry.key == "cash" or entry.key == "streak"

		entry.card.Visible = true
		entry.card.Size = UDim2.new(1, 0, isPrimaryCard and 0.5 or 1, isPrimaryCard and -5 or 0)
		entry.card.BackgroundTransparency = profile.isMobile and 0.12 or 0.08

		entry.label.TextSize = profile.isMobile and 10 or 14
		entry.label.Position = UDim2.new(0, 8, 0, profile.isMobile and 5 or 7)
		entry.label.Size = UDim2.new(1, -16, 0, profile.isMobile and 12 or 18)
		labelConstraint.MinTextSize = profile.isMobile and 8 or 11
		labelConstraint.MaxTextSize = profile.isMobile and 14 or 20

		entry.value.TextScaled = true
		entry.value.Position = UDim2.new(0, 8, 0, profile.isMobile and 17 or 28)
		entry.value.Size = UDim2.new(1, -16, 0, profile.isMobile and 18 or 22)
		valueConstraint.MinTextSize = profile.isMobile and 10 or 14
		valueConstraint.MaxTextSize = profile.isMobile and 20 or 32
	end
end

local function applyUpgradeButtonLayout(profile)
	for _, button in pairs(UpgradeMap) do
		local titleConstraint = button.Title:WaitForChild("ResponsiveConstraint")
		local levelConstraint = button.Level:WaitForChild("ResponsiveConstraint")
		local costConstraint = button.Cost:WaitForChild("ResponsiveConstraint")

		button.Text = ""
		button.TextScaled = false
		button.ClipsDescendants = true
		button.Title.TextScaled = true
		button.Level.TextScaled = true
		button.Cost.TextScaled = true

		if profile.isMobile then
			if profile.isPortrait then
				button.Title.Position = UDim2.new(0, 6, 0, 4)
				button.Title.Size = UDim2.new(1, -12, 0, 11)
				button.Level.Position = UDim2.new(0, 6, 0, 16)
				button.Level.Size = UDim2.new(1, -12, 0, 10)
				button.Cost.Position = UDim2.new(0, 6, 0, 27)
				button.Cost.Size = UDim2.new(1, -12, 0, 11)

				titleConstraint.MinTextSize = 8
				titleConstraint.MaxTextSize = 13
				levelConstraint.MinTextSize = 8
				levelConstraint.MaxTextSize = 11
				costConstraint.MinTextSize = 8
				costConstraint.MaxTextSize = 12
			else
				button.Title.Position = UDim2.new(0, 8, 0, 8)
				button.Title.Size = UDim2.new(1, -16, 0, 14)
				button.Level.Position = UDim2.new(0, 8, 0, 22)
				button.Level.Size = UDim2.new(1, -16, 0, 12)
				button.Cost.Position = UDim2.new(0, 8, 0, 36)
				button.Cost.Size = UDim2.new(1, -16, 0, 14)

				titleConstraint.MinTextSize = 9
				titleConstraint.MaxTextSize = 16
				levelConstraint.MinTextSize = 8
				levelConstraint.MaxTextSize = 12
				costConstraint.MinTextSize = 8
				costConstraint.MaxTextSize = 13
			end
		else
			button.Title.Position = UDim2.new(0, 8, 0, 8)
			button.Title.Size = UDim2.new(1, -16, 0, 22)
			button.Level.Position = UDim2.new(0, 8, 0, 34)
			button.Level.Size = UDim2.new(1, -16, 0, 22)
			button.Cost.Position = UDim2.new(0, 8, 0, 58)
			button.Cost.Size = UDim2.new(1, -16, 0, 22)

			titleConstraint.MinTextSize = 13
			titleConstraint.MaxTextSize = 24
			levelConstraint.MinTextSize = 11
			levelConstraint.MaxTextSize = 19
			costConstraint.MinTextSize = 11
			costConstraint.MaxTextSize = 21
		end
	end

	local flipConstraint = FlipButton:WaitForChild("ResponsiveConstraint")
	FlipButton.TextScaled = true
	flipConstraint.MinTextSize = profile.isMobile and (profile.isPortrait and 12 or 14) or 22
	flipConstraint.MaxTextSize = profile.isMobile and (profile.isPortrait and 24 or 30) or 64

	if ResultLabel then
		local resultConstraint = ResultLabel:WaitForChild("ResponsiveConstraint")
		ResultLabel.TextScaled = true
		ResultLabel.TextWrapped = true
		resultConstraint.MinTextSize = profile.isMobile and (profile.isPortrait and 9 or 10) or 16
		resultConstraint.MaxTextSize = profile.isMobile and (profile.isPortrait and 16 or 18) or 34
	end
end

local function applyHudLayout(profile)
	Hud.AnchorPoint = Vector2.new(0.5, 1)
	Hud.Position = UDim2.fromScale(0.5, profile.hudY)
	Hud.Size = UDim2.fromScale(profile.hudSize.X, profile.hudSize.Y)
	applyClampConstraint(Hud, "ResponsiveHudConstraint", profile.hudMinSize, profile.hudMaxSize)
	SeatLabel.Visible = true

	Content.Size = UDim2.fromScale(1, 1)

	ContentListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	ContentListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	ContentListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LeftPanelListLayout.Padding = UDim.new(0, profile.isMobile and 6 or 10)
	CenterPanelListLayout.Padding = UDim.new(0, profile.isMobile and 5 or 8)
	RightPanelListLayout.Padding = UDim.new(0, profile.isMobile and 6 or 10)

	if profile.isPortrait then
		ContentListLayout.FillDirection = Enum.FillDirection.Vertical
		ContentListLayout.Padding = UDim.new(0, 6)
		CenterPanel.LayoutOrder = 1
		LeftPanel.LayoutOrder = 2
		RightPanel.LayoutOrder = 3
		CenterPanel.Size = UDim2.new(1, 0, 0.24, -6)
		LeftPanel.Size = UDim2.new(1, 0, 0.21, -5)
		RightPanel.Size = UDim2.new(1, 0, 0.55, -8)
		LeftPanelListLayout.FillDirection = Enum.FillDirection.Vertical
		LeftPanelListLayout.Padding = UDim.new(0, 4)
		CenterPanelListLayout.Padding = UDim.new(0, 4)
		RightStatsFrame.Size = UDim2.new(1, 0, 0, 44)
		UpgradeButtons.Size = UDim2.new(1, 0, 1, -48)
		ResultLabel.Size = UDim2.new(1, 0, 0, 18)
		FlipButton.Size = UDim2.new(1, 0, 0, 40)
		SeatLabel.Size = UDim2.new(1, 0, 0, 16)
		SeatLabel.Visible = false
	else
		ContentListLayout.FillDirection = Enum.FillDirection.Horizontal
		ContentListLayout.Padding = UDim.new(0, profile.isMobile and 8 or 12)
		LeftPanel.LayoutOrder = 1
		CenterPanel.LayoutOrder = 2
		RightPanel.LayoutOrder = 3
		LeftPanel.Size = UDim2.new(0.22, -8, 1, 0)
		CenterPanel.Size = UDim2.new(0.36, -8, 1, 0)
		RightPanel.Size = UDim2.new(0.42, -8, 1, 0)
		LeftPanelListLayout.FillDirection = Enum.FillDirection.Vertical
		RightStatsFrame.Size = UDim2.new(1, 0, 0, profile.isMobile and 54 or 72)
		UpgradeButtons.Size = UDim2.new(1, 0, 1, profile.isMobile and -62 or -82)
		ResultLabel.Size = UDim2.new(1, 0, 0, profile.isMobile and 28 or 42)
		FlipButton.Size = UDim2.new(1, 0, 0, profile.isMobile and 58 or 92)
		SeatLabel.Size = UDim2.new(1, 0, 0, profile.isMobile and 18 or 22)
	end

	RightStatsGridLayout.FillDirectionMaxCells = 2
	RightStatsGridLayout.CellSize = UDim2.new(0.5, -5, 1, 0)
	RightStatsGridLayout.CellPadding = UDim2.fromOffset(profile.isMobile and 6 or 10, 0)
	UpgradeGridLayout.FillDirectionMaxCells = 2
	UpgradeGridLayout.CellSize = UDim2.new(0.5, profile.isMobile and -4 or -5, 0.5, profile.isMobile and -4 or -5)
	UpgradeGridLayout.CellPadding = UDim2.fromOffset(profile.isMobile and 6 or 10, profile.isMobile and 6 or 10)

	InputHints.Visible = not profile.isTouchDevice
	if profile.isTouchDevice and profile.isPortrait then
		SeatLabel.Visible = false
	end

	applyStatCardLayout(profile)
	applyUpgradeButtonLayout(profile)
end

local function getTableSurfaceData(tableTop)
	local axisRecords = {
		{
			size = tableTop.Size.X,
			normal = tableTop.CFrame.RightVector,
		},
		{
			size = tableTop.Size.Y,
			normal = tableTop.CFrame.UpVector,
		},
		{
			size = tableTop.Size.Z,
			normal = -tableTop.CFrame.LookVector,
		},
	}

	table.sort(axisRecords, function(a, b)
		return a.size < b.size
	end)

	local normal = axisRecords[1].normal
	if normal:Dot(Vector3.yAxis) < 0 then
		normal = -normal
	end

	return normal, axisRecords[1].size * 0.5
end

local function getFlipPositions(seatId, coinSize)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return nil, nil, nil
	end

	local centerAttachment = tableTop.TableCenterAttachment
	local seatAttachment = getSeatAttachment(seatId)
	local seatPart = getSeatPart(seatId)
	local startPos
	if seatAttachment then
		startPos = seatAttachment.WorldPosition + Vector3.new(0, VisualConfig.CoinStartHeight, 0)
	elseif seatPart then
		startPos = seatPart.Position + Vector3.new(0, 1.25 + VisualConfig.CoinStartHeight, 0)
	else
		return nil, nil, nil
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + (tableNormal * halfThickness)
	local centerPos = surfaceCenter
	local outward = startPos - surfaceCenter
	outward = outward - (tableNormal * outward:Dot(tableNormal))
	if outward.Magnitude < 0.001 then
		outward = Vector3.new(1, 0, 0)
	else
		outward = outward.Unit
	end

	local endPos = centerPos
		+ (outward * VisualConfig.LandingRadius)
		+ (tableNormal * ((coinSize.X * 0.5) + VisualConfig.CoinSurfaceGap))

	return startPos, endPos, tableNormal
end

local function getCoinVisual(seatId)
	local seatRecord = getSeatRecord(seatId)
	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local coinVisualsFolder = getCoinVisualsFolder(seatId)
	local visualModel = coinVisualsFolder and coinVisualsFolder:FindFirstChild(`{rawSeatId}CoinVisual`)
	if not visualModel then
		return nil
	end

	return visualModel, visualModel:WaitForChild("Coin"), visualModel:WaitForChild("Shadow")
end

local function setCoinVisualEnabled(coin, shadow, enabled)
	coin.Transparency = enabled and 0 or 1
	shadow.Transparency = enabled and VisualConfig.ShadowBaseTransparency or 1
	coin.TopFace.Enabled = enabled
	coin.BottomFace.Enabled = enabled
end

local function spawnLandingPulse(position, color, parent)
	local pulse = Instance.new("Part")
	pulse.Name = "CoinLandingPulse"
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanQuery = false
	pulse.CanTouch = false
	pulse.CastShadow = false
	pulse.Material = Enum.Material.Neon
	pulse.Color = color
	pulse.Shape = Enum.PartType.Cylinder
	pulse.Transparency = 0.18
	pulse.Size = Vector3.new(VisualConfig.ShadowHeight, VisualConfig.PulseStartSize, VisualConfig.PulseStartSize)
	pulse.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	pulse.Parent = parent or Workspace

	local tween = TweenService:Create(
		pulse,
		TweenInfo.new(VisualConfig.PulseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(VisualConfig.ShadowHeight, VisualConfig.PulseEndSize, VisualConfig.PulseEndSize),
			Transparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Once(function()
		pulse:Destroy()
	end)
end

local function updateResultText(text, tone)
	resultFlashToken += 1
	local token = resultFlashToken
	local resultColor = VisualConfig.ResultNeutralColor

	if tone == "Heads" then
		resultColor = VisualConfig.ResultHeadsColor
	elseif tone == "Tails" then
		resultColor = VisualConfig.ResultTailsColor
	end

	ResultLabel.Text = text
	ResultLabel.TextColor3 = resultColor
	ResultLabel.TextTransparency = 0.24
	ResultLabel.TextStrokeTransparency = 0.45

	local tween =
		TweenService:Create(ResultLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = defaultResultTextTransparency,
			TextStrokeTransparency = defaultResultStrokeTransparency,
		})
	tween:Play()
	tween.Completed:Once(function()
		if resultFlashToken ~= token then
			return
		end
		ResultLabel.TextColor3 = resultColor
	end)
end

local function clearCoinVisual(seatId)
	local visual = activeVisuals[seatId]
	if not visual then
		return
	end

	activeVisuals[seatId] = nil
	if visual.connection then
		visual.connection:Disconnect()
	end
	if visual.shouldFollowCamera then
		FirstPersonCamera.ReturnToFirstPerson(visual.coin)
	end
	visual.shadow.Size = visual.baseShadowSize
	setCoinVisualEnabled(visual.coin, visual.shadow, false)
end

local function playCoinVisual(seatId, result, landedCallback, shouldFollowCamera)
	if typeof(seatId) ~= "string" then
		if landedCallback then
			landedCallback()
		end
		return
	end

	local coinVisualsFolder = getCoinVisualsFolder(seatId)
	local visualModel, coin, shadow = getCoinVisual(seatId)
	if not visualModel or not coin or not shadow then
		if landedCallback then
			landedCallback()
		end
		return
	end
	local baseCoinSize = coin.Size
	local baseShadowSize = shadow.Size
	local startPos, endPos, tableNormal = getFlipPositions(seatId, baseCoinSize)
	if not startPos or not endPos or not tableNormal then
		if landedCallback then
			landedCallback()
		end
		return
	end

	clearCoinVisual(seatId)
	setCoinVisualEnabled(coin, shadow, true)
	shadow.Size = baseShadowSize

	local visual = {
		model = visualModel,
		coin = coin,
		shadow = shadow,
		baseShadowSize = baseShadowSize,
		shouldFollowCamera = shouldFollowCamera == true,
	}
	activeVisuals[seatId] = visual

	local startTime = os.clock()
	local arcHeight =
		math.max(VisualConfig.ArcHeight, (startPos - endPos).Magnitude * VisualConfig.ArcHeightTravelFactor)
	local travel = endPos - startPos
	local airborneDuration = VisualConfig.TravelDuration
	local finalRotation = math.rad(VisualConfig.SpinTurns * 360) + (result == "Tails" and math.pi or 0)
	local airborneRotation = math.rad((VisualConfig.SpinTurns + 0.35) * 360) + (result == "Tails" and math.pi or 0)
	local shadowPos = endPos
		- (tableNormal * ((baseCoinSize.X * 0.5) + VisualConfig.CoinSurfaceGap))
		+ (tableNormal * ((baseShadowSize.X * 0.5) + VisualConfig.ShadowSurfaceGap))

	coin.CFrame = CFrame.new(startPos) * CFrame.Angles(0, 0, math.rad(90))
	shadow.CFrame = CFrame.new(startPos.X, shadowPos.Y, startPos.Z) * CFrame.Angles(0, 0, math.rad(90))
	if visual.shouldFollowCamera then
		FirstPersonCamera.FollowCoin(coin, {
			duration = airborneDuration + VisualConfig.LandingDuration + (VisualConfig.ResultRevealDelay or 0) + 0.08,
		})
	end

	visual.connection = RunService.RenderStepped:Connect(function()
		local currentVisual = activeVisuals[seatId]
		if currentVisual ~= visual then
			if visual.connection then
				visual.connection:Disconnect()
			end
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / airborneDuration, 0, 1)
		local height = math.sin(alpha * math.pi) * arcHeight
		local position = startPos + (travel * alpha) + Vector3.new(0, height, 0)
		local flipAngle = airborneRotation * alpha
		local bankAngle = math.sin(alpha * math.pi) * VisualConfig.BankAngle
		local shadowAlpha = math.clamp(height / arcHeight, 0, 1)
		local shadowScale = VisualConfig.ShadowMaxScale
			- ((VisualConfig.ShadowMaxScale - VisualConfig.ShadowMinScale) * shadowAlpha)
		local shadowTransparency = VisualConfig.ShadowBaseTransparency
			+ ((VisualConfig.ShadowMaxTransparency - VisualConfig.ShadowBaseTransparency) * shadowAlpha)

		coin.CFrame = CFrame.new(position) * CFrame.Angles(flipAngle, 0, math.rad(90)) * CFrame.Angles(0, bankAngle, 0)
		shadow.CFrame = CFrame.new(position.X, shadowPos.Y, position.Z) * CFrame.Angles(0, 0, math.rad(90))
		shadow.Size = Vector3.new(baseShadowSize.X, baseCoinSize.Y * shadowScale, baseCoinSize.Z * shadowScale)
		shadow.Transparency = shadowTransparency

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil

		local pulseColor = result == "Heads" and VisualConfig.HeadsPulseColor or VisualConfig.TailsPulseColor
		spawnLandingPulse(shadowPos, pulseColor, coinVisualsFolder)

		local settleTween = TweenService:Create(
			coin,
			TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(endPos) * CFrame.Angles(finalRotation, 0, math.rad(90)),
			}
		)
		settleTween:Play()

		local shadowTween = TweenService:Create(
			shadow,
			TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(shadowPos) * CFrame.Angles(0, 0, math.rad(90)),
				Size = baseShadowSize,
				Transparency = VisualConfig.ShadowBaseTransparency,
			}
		)
		shadowTween:Play()

		settleTween.Completed:Once(function()
			if visual.shouldFollowCamera then
				FirstPersonCamera.ReturnToFirstPerson(coin)
			end
			if landedCallback then
				task.delay(VisualConfig.ResultRevealDelay or 0, landedCallback)
			end
			task.delay(VisualConfig.CleanupDelay, function()
				local latestVisual = activeVisuals[seatId]
				if latestVisual == visual then
					clearCoinVisual(seatId)
				end
			end)
		end)
	end)
end

local function requestFlip()
	if not currentSeatId then
		return
	end

	local now = os.clock()
	if awaitingFlipResponse or now < localFlipCooldownEndsAt then
		return
	end

	awaitingFlipResponse = true
	activeFlipRequestToken += 1
	local requestToken = activeFlipRequestToken
	localFlipCooldownEndsAt = now + math.max(0.15, currentFlipInterval + 0.05)
	CoinFlipSystem.Server:RequestFlip()
	updateResultText("Flipping...", "Neutral")

	task.delay(0.45, function()
		if activeFlipRequestToken ~= requestToken or not awaitingFlipResponse then
			return
		end

		awaitingFlipResponse = false
		localFlipCooldownEndsAt = os.clock() + 0.05
		updateResultText("Flip not ready yet. Click FLIP again.", "Neutral")
	end)
end

local function handleFlipInput(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end

	requestFlip()
	return Enum.ContextActionResult.Sink
end

local function bindFlipInput()
	if flipInputBound then
		return
	end

	flipInputBound = true
	ContextActionService:BindActionAtPriority(
		FlipInputActionName,
		handleFlipInput,
		false,
		3,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonR2
	)
end

local function updateTableOverview(seatState)
	currentSeatState = seatState
	hideLegacySeatBillboards(seatState)
	if TableOverview and TableOverview:IsA("GuiObject") then
		TableOverview.Visible = false
	end
	if SpectatorFeed and SpectatorFeed:IsA("GuiObject") then
		SpectatorFeed.Visible = false
	end
end

local function setVisible(isVisible)
	Hud.Visible = isVisible == true
	if not isVisible then
		updateResultText("Waiting for seat assignment...", "Neutral")
	end
end

local function updateUpgradeButton(button, title, level, cost, isMaxed)
	button.Title.Text = title
	button.Level.Text = `Lv.{level}`
	button.Cost.Text = isMaxed and "MAX" or `$ {Util.FormatNumber(cost, true)}`
	button.AutoButtonColor = not isMaxed
end

local function ensureLeaveButton()
	local leaveButton = Content:FindFirstChild("LeaveSeatButton")
	if leaveButton then
		leaveButton.Visible = false
		leaveButton.Active = false
		leaveButton.AutoButtonColor = false
		return leaveButton
	end

	return nil
end

local function applyResponsiveLayout()
	currentLayoutProfile = getLayoutProfile()
	applyHudLayout(currentLayoutProfile)
	applyOnboardingLayout(currentLayoutProfile)

	if currentSeatState then
		updateTableOverview(currentSeatState)
	end
	updateOnboardingPanel()
end

local function bindViewportLayout()
	if cameraChangedConnection then
		cameraChangedConnection:Disconnect()
	end
	if viewportChangedConnection then
		viewportChangedConnection:Disconnect()
	end

	local function connectViewport(camera)
		if viewportChangedConnection then
			viewportChangedConnection:Disconnect()
			viewportChangedConnection = nil
		end

		if camera then
			viewportChangedConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applyResponsiveLayout()
			end)
		end

		applyResponsiveLayout()
	end

	cameraChangedConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		connectViewport(Workspace.CurrentCamera)
	end)

	connectViewport(Workspace.CurrentCamera)
end

function CoinFlipUi.Init()
	if initialized then
		return
	end
	initialized = true

	setVisible(false)
	OnboardingPanel.Visible = false
	uiController.HideUnitWhenPush(Hud)
	ensureLeaveButton()
	bindViewportLayout()
	bindFlipInput()

	uiController.SetButtonHoverAndClick(FlipButton, function()
		requestFlip()
	end)

	for upgradeKey, button in pairs(UpgradeMap) do
		uiController.SetButtonHoverAndClick(button, function()
			CoinFlipSystem.Server:BuyUpgrade({
				upgradeType = upgradeKey,
			})
		end)
	end
end

function CoinFlipUi.SyncRunState(args)
	currentSeatId = args.seatState and args.seatState.seatId or nil
	currentFlipInterval = (args.derivedStats and args.derivedStats.flipInterval) or currentFlipInterval
	local cash = args.cash or args.wins or 0
	currentRunSnapshot = {
		cash = cash,
		runData = args.runData or {},
		nextCosts = args.nextCosts or {},
		derivedStats = args.derivedStats or {},
	}
	ClientData:SetOneData(dataKey.wins, cash)
	ClientData:SetOneData(dataKey.runData, args.runData)
	CashValue.Text = `$ {Util.FormatNumber(cash, true)}`
	ChanceValue.Text = `{math.round((args.derivedStats.headsChance or 0) * 1000) / 10}%`
	StreakValue.Text = tostring(args.runData.currentStreak or 0)
	SpeedValue.Text = `{math.round((args.derivedStats.flipInterval or 0) * 100) / 100}s`
	SeatLabel.Text = args.seatState.seatId and `Seat {args.seatState.seatId}` or "Seat --"

	for upgradeKey, button in pairs(UpgradeMap) do
		local level = args.runData[upgradeKey] or 0
		local cost = args.nextCosts[upgradeKey]
		updateUpgradeButton(button, UpgradeTitles[upgradeKey], level, cost, cost == nil)
	end

	updateTableOverview(args.seatState)
	CoinFlipUi.UpdateOnboarding(args.onboarding)
end

function CoinFlipUi.FlipResolved(args)
	awaitingFlipResponse = false
	playCoinVisual(args.seatState and args.seatState.seatId, args.result, function()
		CoinFlipUi.SyncRunState(args)
		local failureFollowUpText = buildFailureFollowUpText()

		if args.result == "Heads" then
			updateResultText(`Heads! +$ {Util.FormatNumber(args.reward or 0, true)}`, "Heads")
		elseif (args.reward or 0) > 0 then
			updateResultText(
				`Tails! +$ {Util.FormatNumber(args.reward, true)} | Streak reset. {failureFollowUpText}`,
				"Tails"
			)
			maybeShowFailureFollowUpNotification(failureFollowUpText)
		else
			updateResultText(`Tails! Streak reset. {failureFollowUpText}`, "Tails")
			maybeShowFailureFollowUpNotification(failureFollowUpText)
		end
	end, true)
end

function CoinFlipUi.SeatStateChanged(args)
	local isSeated = args and args.seatState and args.seatState.isSeated
	currentSeatId = isSeated and args.seatState.seatId or nil
	local leaveButton = ensureLeaveButton()
	if not isSeated then
		localFlipCooldownEndsAt = 0
		awaitingFlipResponse = false
	end
	setVisible(isSeated)
	if leaveButton then
		leaveButton.Visible = false
	end
	updateTableOverview(args and args.seatState)
	updateOnboardingPanel()
	if isSeated then
		SeatLabel.Text = args.seatState.seatId and `Seat {args.seatState.seatId}` or "Seat --"
		if ResultLabel.Text == "Waiting for seat assignment..." then
			updateResultText("Click FLIP, press Space, or press RT to flip.", "Neutral")
		end
	end
end

function CoinFlipUi.UpdateOnboarding(onboarding)
	currentOnboardingState = onboarding
	if not onboarding or onboarding.isComplete then
		lastOnboardingStepKey = nil
	else
		if lastOnboardingStepKey ~= onboarding.currentStep then
			uiController.SetUnitJump(OnboardingPanel, 0.08)
		end
		lastOnboardingStepKey = onboarding.currentStep
	end

	updateOnboardingPanel()
	if currentSeatState then
		hideLegacySeatBillboards(currentSeatState)
	end
end

function CoinFlipUi.ObservedFlip(args)
	if args.userId == LocalPlayer.UserId then
		return
	end

	playCoinVisual(args.seatId, args.result, function()
	end)
end

return CoinFlipUi
