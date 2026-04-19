local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
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
local TableModel = Workspace:WaitForChild("CoinFlipTable")
local TableAssets = TableModel:WaitForChild("Assets")
local CoinVisualsFolder = TableAssets:WaitForChild("CoinVisuals")

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
local ContentListLayout = Content:FindFirstChildOfClass("UIListLayout")
local StatsFrame = Content:WaitForChild("Stats")
local StatsListLayout = StatsFrame:FindFirstChildOfClass("UIListLayout")
local ActionsFrame = Content:FindFirstChild("Actions")
local UpgradeButtons

local function ensureStatCard(cardName, legacyName, titleText)
	local card = findFirstByNames(StatsFrame, { cardName, legacyName })
	if card then
		return card
	end

	local template = findFirstByNames(StatsFrame, {
		"Cash",
		"Chance",
		"Streak",
		"Speed",
		"CashCard",
		"ChanceCard",
		"StreakCard",
		"SpeedCard",
	})
	if template and template:IsA("Frame") then
		card = template:Clone()
		card.Name = cardName
		card.Visible = true
		card.Parent = StatsFrame

		local title = findFirstByNames(card, { "Title", "Label" })
		if title and title:IsA("TextLabel") then
			title.Name = "Title"
			title.Text = titleText
		end

		local value = findFirstByNames(card, { "Value", "CashValue", "ChanceValue", "StreakValue", "SpeedValue", "SeatValue" })
		if value and value:IsA("TextLabel") then
			value.Name = "Value"
			value.Text = "--"
		end

		return card
	end

	card = Instance.new("Frame")
	card.Name = cardName
	card.BackgroundColor3 = Color3.fromRGB(24, 30, 39)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = StatsFrame
	ensureCorner(card, UDim.new(0, 12))

	local title = ensureTextLabel(card, "Title", {
		text = titleText,
		font = Enum.Font.GothamBold,
		textColor = Color3.fromRGB(201, 208, 220),
		textSize = 14,
	})
	title.Size = UDim2.new(1, -16, 0, 16)
	title.Position = UDim2.fromOffset(8, 8)

	local value = ensureTextLabel(card, "Value", {
		text = "--",
		font = Enum.Font.GothamBold,
		textColor = Color3.fromRGB(245, 247, 250),
		textSize = 20,
	})
	value.Size = UDim2.new(1, -16, 0, 22)
	value.Position = UDim2.fromOffset(8, 28)

	return card
end

local function resolveStatLabel(card)
	return findFirstByNames(card, { "Title", "Label" })
end

local function resolveStatValue(card)
	return findFirstByNames(card, { "Value", "CashValue", "ChanceValue", "StreakValue", "SpeedValue", "SeatValue" })
end

local CashCard = ensureStatCard("Cash", "CashCard", "CASH")
local ChanceCard = ensureStatCard("Chance", "ChanceCard", "CHANCE")
local StreakCard = ensureStatCard("Streak", "StreakCard", "STREAK")
local SpeedCard = ensureStatCard("Speed", "SpeedCard", "SPEED")
local SeatCard = ensureStatCard("Seat", "SeatCard", "SEAT")

local CashValue = resolveStatValue(CashCard)
local ChanceValue = resolveStatValue(ChanceCard)
local StreakValue = resolveStatValue(StreakCard)
local SpeedValue = resolveStatValue(SpeedCard)
local SeatValue = resolveStatValue(SeatCard)

local function ensureResultLabel()
	local resultLabel = Content:FindFirstChild("ResultLabel")
	if resultLabel and resultLabel:IsA("TextLabel") then
		return resultLabel
	end

	resultLabel = ensureTextLabel(Content, "ResultLabel", {
		text = "Waiting for seat assignment...",
		font = Enum.Font.GothamSemibold,
		textColor = Color3.fromRGB(232, 236, 242),
		textSize = 16,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Left,
		layoutOrder = 2,
	})
	resultLabel.Size = UDim2.new(1, 0, 0, 32)
	return resultLabel
end

local ResultLabel = ensureResultLabel()
local FlipButton = (ActionsFrame and ActionsFrame:FindFirstChild("FlipButton")) or Content:FindFirstChild("FlipButton")
if not FlipButton or not FlipButton:IsA("GuiButton") then
	error("CoinFlipHUD is missing FlipButton")
end

local function ensureUpgradeButton(buttonName, titleText)
	local button = UpgradeButtons:FindFirstChild(buttonName)
	if button and button:IsA("GuiButton") then
		return button
	end

	button = Instance.new("TextButton")
	button.Name = buttonName
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(30, 37, 48)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = ""
	button.TextSize = 1
	button.Parent = UpgradeButtons
	ensureCorner(button, UDim.new(0, 12))
	ensureStroke(button, Color3.fromRGB(255, 214, 124), 1.1, 0.72)

	local title = ensureTextLabel(button, "Title", {
		text = titleText,
		font = Enum.Font.GothamBold,
		textColor = Color3.fromRGB(245, 247, 250),
		textSize = 14,
	})
	title.Size = UDim2.new(1, -16, 0, 18)
	title.Position = UDim2.fromOffset(8, 8)

	local level = ensureTextLabel(button, "Level", {
		text = "Lv.0",
		font = Enum.Font.GothamMedium,
		textColor = Color3.fromRGB(205, 214, 229),
		textSize = 12,
	})
	level.Size = UDim2.new(1, -16, 0, 14)
	level.Position = UDim2.fromOffset(8, 28)

	local cost = ensureTextLabel(button, "Cost", {
		text = "$ 0",
		font = Enum.Font.GothamBold,
		textColor = Color3.fromRGB(255, 226, 150),
		textSize = 13,
	})
	cost.Size = UDim2.new(1, -16, 0, 16)
	cost.Position = UDim2.fromOffset(8, 46)

	return button
end

local function ensureUpgradeButtons()
	local frame = Content:FindFirstChild("UpgradeButtons")
	if frame and frame:IsA("Frame") then
		return frame
	end

	frame = Instance.new("Frame")
	frame.Name = "UpgradeButtons"
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = 4
	frame.Size = UDim2.new(1, 0, 0, 96)
	frame.Parent = Content
	return frame
end

UpgradeButtons = ensureUpgradeButtons()
local UpgradeGridLayout = UpgradeButtons:FindFirstChildOfClass("UIGridLayout")
if not UpgradeGridLayout then
	UpgradeGridLayout = Instance.new("UIGridLayout")
	UpgradeGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UpgradeGridLayout.Parent = UpgradeButtons
end

local SpectatorFeed = Elements:WaitForChild("CoinFlipSpectatorFeed")
local SpectatorFeedLabel = SpectatorFeed:WaitForChild("Label")
local TableOverview = Elements:WaitForChild("CoinFlipTableOverview")
local TableOverviewTitle = TableOverview:WaitForChild("Title")

local function ensureOverviewSubtitle()
	local subtitle = TableOverview:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		return subtitle
	end

	subtitle = ensureTextLabel(TableOverview, "Subtitle", {
		font = Enum.Font.GothamMedium,
		textColor = Color3.fromRGB(194, 204, 219),
		textSize = 13,
		textWrapped = true,
		textYAlignment = Enum.TextYAlignment.Top,
	})
	subtitle.ZIndex = TableOverviewTitle.ZIndex
	return subtitle
end

local TableOverviewSubtitle = ensureOverviewSubtitle()
local TableOverviewList = TableOverview:WaitForChild("List")
local TableOverviewEmptyLabel = TableOverview:FindFirstChild("EmptyLabel", true)
if not TableOverviewEmptyLabel then
	TableOverviewEmptyLabel = ensureTextLabel(TableOverviewList, "EmptyLabel", {
		text = "No players at the table",
		font = Enum.Font.GothamMedium,
		textColor = Color3.fromRGB(194, 204, 219),
		textSize = 14,
		textWrapped = true,
	})
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
	valueLevel = ensureUpgradeButton("ValueButton", "Value"),
	comboLevel = ensureUpgradeButton("ComboButton", "Combo"),
	speedLevel = ensureUpgradeButton("SpeedButton", "Speed"),
	biasLevel = ensureUpgradeButton("BiasButton", "Bias"),
}
local UpgradeTitles = {
	valueLevel = "Value",
	comboLevel = "Combo",
	speedLevel = "Speed",
	biasLevel = "Bias",
}

local CoinFlipUi = {}
local initialized = false
local spectatorFeed = SpectatorFeed
local spectatorFeedToken = 0
local tableOverview = TableOverview
local tableOverviewRows = {}
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
local promptShownConnection
local currentOnboardingState
local currentRunSnapshot = {
	cash = 0,
	runData = {},
	nextCosts = {},
	derivedStats = {},
}
local onboardingPromptReported = false
local lastOnboardingStepKey

local WorldBillboardTheme = table.freeze({
	Background = Color3.fromRGB(20, 24, 30),
	FeaturedBackground = Color3.fromRGB(45, 31, 21),
	Stroke = Color3.fromRGB(255, 214, 124),
	Seat = Color3.fromRGB(255, 245, 213),
	Name = Color3.fromRGB(248, 248, 248),
	Detail = Color3.fromRGB(205, 214, 229),
	Cash = Color3.fromRGB(134, 255, 178),
	Status = Color3.fromRGB(145, 221, 160),
})

local OverviewRowTheme = table.freeze({
	Background = Color3.fromRGB(23, 27, 35),
	FeaturedBackground = Color3.fromRGB(48, 34, 24),
	Stroke = Color3.fromRGB(255, 214, 124),
	Seat = Color3.fromRGB(255, 233, 186),
	Name = Color3.fromRGB(245, 247, 250),
	Detail = Color3.fromRGB(194, 204, 219),
})

local StatsCards = {
	{
		key = "cash",
		card = CashCard,
		label = resolveStatLabel(CashCard),
		value = CashValue,
	},
	{
		key = "chance",
		card = ChanceCard,
		label = resolveStatLabel(ChanceCard),
		value = ChanceValue,
	},
	{
		key = "streak",
		card = StreakCard,
		label = resolveStatLabel(StreakCard),
		value = StreakValue,
	},
	{
		key = "speed",
		card = SpeedCard,
		label = resolveStatLabel(SpeedCard),
		value = SpeedValue,
	},
	{
		key = "seat",
		card = SeatCard,
		label = resolveStatLabel(SeatCard),
		value = SeatValue,
	},
}

for layoutOrder, entry in ipairs(StatsCards) do
	entry.card.LayoutOrder = layoutOrder
end

local StatsGridLayout = StatsFrame:FindFirstChild("ResponsiveGridLayout") or StatsFrame:FindFirstChildOfClass("UIGridLayout")
if not StatsGridLayout then
	StatsGridLayout = Instance.new("UIGridLayout")
	StatsGridLayout.Name = "ResponsiveGridLayout"
	StatsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	StatsGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	StatsGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	StatsGridLayout.Parent = StatsFrame
else
	StatsGridLayout.Name = "ResponsiveGridLayout"
end

if StatsListLayout and StatsListLayout.Parent then
	StatsListLayout:Destroy()
	StatsListLayout = nil
end

local function ensureOverviewRow(index)
	local rowName = string.format("SeatRow%02d", index)
	local row = TableOverviewList:FindFirstChild(rowName)
	if row then
		return row
	end

	row = Instance.new("Frame")
	row.Name = rowName
	row.BackgroundColor3 = OverviewRowTheme.Background
	row.BackgroundTransparency = 0.08
	row.BorderSizePixel = 0
	row.Visible = false
	row.Parent = TableOverviewList
	ensureCorner(row, UDim.new(0, 10))
	ensureStroke(row, OverviewRowTheme.Stroke, 1, 0.55)

	local seatLabel = ensureTextLabel(row, "SeatLabel", {
		font = Enum.Font.GothamBold,
		textColor = OverviewRowTheme.Seat,
		textSize = 12,
	})
	seatLabel.Position = UDim2.fromOffset(10, 8)
	seatLabel.Size = UDim2.fromOffset(64, 14)

	local statusLabel = ensureTextLabel(row, "StatusLabel", {
		font = Enum.Font.GothamBold,
		textColor = WorldBillboardTheme.Status,
		textSize = 12,
		textXAlignment = Enum.TextXAlignment.Right,
	})
	statusLabel.AnchorPoint = Vector2.new(1, 0)
	statusLabel.Position = UDim2.new(1, -10, 0, 8)
	statusLabel.Size = UDim2.fromOffset(84, 14)

	local nameLabel = ensureTextLabel(row, "NameLabel", {
		font = Enum.Font.GothamBold,
		textColor = OverviewRowTheme.Name,
		textSize = 15,
	})
	nameLabel.Position = UDim2.fromOffset(10, 20)
	nameLabel.Size = UDim2.new(1, -92, 0, 18)

	local detailLabel = ensureTextLabel(row, "DetailLabel", {
		font = Enum.Font.GothamMedium,
		textColor = OverviewRowTheme.Detail,
		textSize = 12,
		textWrapped = true,
	})
	detailLabel.Position = UDim2.fromOffset(10, 36)
	detailLabel.Size = UDim2.new(1, -20, 0, 12)

	return row
end

for index = 1, 8 do
	tableOverviewRows[index] = ensureOverviewRow(index)
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
	local isMobile = isTouchDevice or viewport.X <= LayoutConfig.MobileMaxWidth or aspect <= LayoutConfig.MobileMaxAspect
	local isNarrow = viewport.X <= LayoutConfig.NarrowWidth

	local hudSize = LayoutConfig.Hud.DesktopSize
	local hudY = LayoutConfig.Hud.DesktopY
	if isMobile then
		hudSize = isPortrait and LayoutConfig.Hud.MobilePortraitSize or LayoutConfig.Hud.MobileLandscapeSize
		hudY = isPortrait and LayoutConfig.Hud.MobilePortraitY or LayoutConfig.Hud.MobileLandscapeY
	elseif isNarrow then
		hudSize = LayoutConfig.Hud.NarrowSize
	end

	local overviewSize = LayoutConfig.Overview.DesktopSize
	local overviewPosition = LayoutConfig.Overview.DesktopPosition
	if isMobile then
		overviewSize = isPortrait and LayoutConfig.Overview.MobilePortraitSize or LayoutConfig.Overview.MobileLandscapeSize
		overviewPosition = isPortrait and LayoutConfig.Overview.MobilePortraitPosition or LayoutConfig.Overview.MobileLandscapePosition
	end

	local feedSize = LayoutConfig.SpectatorFeed.DesktopSize
	local feedPosition = LayoutConfig.SpectatorFeed.DesktopPosition
	if isMobile then
		feedSize = isPortrait and LayoutConfig.SpectatorFeed.MobilePortraitSize or LayoutConfig.SpectatorFeed.MobileLandscapeSize
		feedPosition = isPortrait and LayoutConfig.SpectatorFeed.MobilePortraitPosition or LayoutConfig.SpectatorFeed.MobileLandscapePosition
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
		overviewSize = overviewSize,
		overviewPosition = overviewPosition,
		feedSize = feedSize,
		feedPosition = feedPosition,
		hudMinSize = isMobile and LayoutConfig.Hud.MobileMinSize or LayoutConfig.Hud.MinSize,
		hudMaxSize = isMobile and LayoutConfig.Hud.MobileMaxSize or LayoutConfig.Hud.MaxSize,
		overviewMinSize = isMobile and LayoutConfig.Overview.MobileMinSize or LayoutConfig.Overview.MinSize,
		overviewMaxSize = isMobile and LayoutConfig.Overview.MobileMaxSize or LayoutConfig.Overview.MaxSize,
		statsColumns = isMobile and 2 or 5,
		statsCellSize = isMobile and UDim2.fromScale(0.48, 0.44) or UDim2.fromScale(0.192, 1),
		statsCellPadding = isMobile and UDim2.fromScale(0.03, 0.06) or UDim2.fromScale(0.01, 0),
		upgradeColumns = isMobile and 2 or 4,
		upgradeCellSize = isMobile and UDim2.fromScale(0.48, 0.42) or UDim2.fromScale(0.235, 1),
		upgradeCellPadding = isMobile and UDim2.fromScale(0.03, 0.08) or UDim2.fromScale(0.02, 0),
		overviewRowHeight = isMobile and 34 or 56,
		overviewRowPadding = isMobile and 3 or 6,
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
		if (seatState.openSeatCount or 0) > 0 then
			return currentLayoutProfile and currentLayoutProfile.isMobile
				and "Walk to any open seat, then press E."
				or "Walk to any open seat, then press E or ButtonX to take it."
		end
		return "Wait for an open seat, then jump in as soon as one frees up."
	end

	if step == "sitDown" then
		return seatState.isSeated and "Seat locked in. You're ready to start flipping."
			or "Use the table prompt to sit down and begin your first run."
	end

	if step == "flipThree" then
		local flipCount = math.min(currentOnboardingState.flipCount or 0, currentOnboardingState.requiredFlips or 3)
		if seatState.isSeated then
			return `Flip from this seat 3 times to warm up. {flipCount}/{currentOnboardingState.requiredFlips or 3} done.`
		end
		return `Sit at any open seat, then flip 3 times. {flipCount}/{currentOnboardingState.requiredFlips or 3} done.`
	end

	if step == "buyUpgrade" then
		local suggestedUpgrade = getRecommendedUpgradeKey()
		local buttonLabel = suggestedUpgrade and UpgradeTitles[suggestedUpgrade] or "any upgrade"
		if seatState.isSeated then
			return `Spend your Cash on {buttonLabel} to keep the run moving.`
		end
		return "Sit back down, then buy your first upgrade with the Cash you earned."
	end

	if step == "reachTwoStreak" then
		if seatState.isSeated then
			return `Chain 2 Heads in a row to finish the guide. Current streak: {streak}.`
		end
		return "Sit back down and chain 2 Heads in a row to finish the guide."
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
		onboardingPromptReported = false
		return
	end

	local completedCount = currentOnboardingState.completedCount or 0
	local totalSteps = math.max(currentOnboardingState.totalSteps or 5, 1)
	local progressValue = completedCount
	if currentOnboardingState.currentStep == "flipThree" then
		progressValue += math.min((currentOnboardingState.flipCount or 0) / math.max(currentOnboardingState.requiredFlips or 3, 1), 0.95)
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

local function getSeatOrderDistance(seatOrder, seatIdA, seatIdB)
	if not seatOrder or not seatIdA or not seatIdB then
		return nil
	end

	local indexA
	local indexB
	for index, seatId in ipairs(seatOrder) do
		if seatId == seatIdA then
			indexA = index
		elseif seatId == seatIdB then
			indexB = index
		end
	end

	if not indexA or not indexB then
		return nil
	end

	local rawDistance = math.abs(indexA - indexB)
	return math.min(rawDistance, #seatOrder - rawDistance)
end

local function getWorldBillboardVariant(seatState, entry)
	if not entry or not entry.seatId then
		return "hidden"
	end

	local profile = currentLayoutProfile or getLayoutProfile()
	if profile.isMobile and LayoutConfig.Mobile.HideWorldBillboards then
		return "hidden"
	end

	if not seatState or not seatState.isSeated then
		if currentOnboardingState and not currentOnboardingState.isComplete then
			local step = currentOnboardingState.currentStep
			if step == "approachSeat" or step == "sitDown" then
				return entry.isOccupied and "compact" or "full"
			end
		end
		if not entry.isOccupied then
			return "hidden"
		end
		return entry.isFeatured and "full" or "compact"
	end

	if entry.seatId == seatState.seatId then
		return "full"
	end

	if entry.isFeatured then
		return "full"
	end

	local seatDistance = getSeatOrderDistance(seatState.seatOrder, seatState.seatId, entry.seatId)
	if entry.isOccupied then
		if (entry.streak or 0) >= LayoutConfig.WorldBillboard.HighlightStreak then
			return "full"
		end
		if seatDistance and seatDistance <= LayoutConfig.WorldBillboard.HighlightOccupiedNeighborDistance then
			return "full"
		end
		return "compact"
	end

	if seatDistance and seatDistance <= LayoutConfig.WorldBillboard.HighlightNeighborDistance then
		return "compact"
	end

	return "hidden"
end

local function getWorldBillboardGuideOverride(seatState, entry)
	if not currentOnboardingState or currentOnboardingState.isComplete or not entry then
		return nil
	end

	local step = currentOnboardingState.currentStep
	local profile = currentLayoutProfile or getLayoutProfile()

	if (not seatState or not seatState.isSeated) and (step == "approachSeat" or step == "sitDown") then
		if not entry.isOccupied then
			return {
				statusText = "Take Seat",
				statusColor = Color3.fromRGB(255, 214, 124),
				nameText = "Start Here",
				detailText = profile.isMobile and "" or "Press E or ButtonX to sit down.",
				forceDetail = not profile.isMobile,
				forceCash = false,
			}
		end

		return nil
	end

	if seatState and seatState.isSeated and entry.seatId == seatState.seatId then
		if step == "flipThree" then
			return {
				statusText = "Next Up",
				statusColor = Color3.fromRGB(255, 214, 124),
				detailText = `Flip {math.min(currentOnboardingState.flipCount or 0, currentOnboardingState.requiredFlips or 3)}/{currentOnboardingState.requiredFlips or 3}`,
				forceDetail = true,
				forceCash = true,
			}
		end
		if step == "buyUpgrade" then
			return {
				statusText = "Next Up",
				statusColor = Color3.fromRGB(255, 214, 124),
				detailText = "Buy your first upgrade.",
				forceDetail = true,
				forceCash = true,
			}
		end
		if step == "reachTwoStreak" then
			return {
				statusText = "Next Up",
				statusColor = Color3.fromRGB(255, 214, 124),
				detailText = `Hit 2 streak | {math.min(currentRunSnapshot.runData.currentStreak or 0, currentOnboardingState.requiredStreak or 2)}/{currentOnboardingState.requiredStreak or 2}`,
				forceDetail = true,
				forceCash = true,
			}
		end
	end

	return nil
end

local function getTableModel()
	return TableModel
end

local function getSeatAttachment(seatId)
	local marker = TableModel.Attachments:WaitForChild(`{seatId}Marker`)
	return marker:FindFirstChildWhichIsA("Attachment")
end

local function getSeatPart(seatId)
	return TableModel.Seats:WaitForChild(seatId)
end

local function applyStatCardLayout(profile)
	local nextLayoutOrder = 1
	for _, entry in ipairs(StatsCards) do
		local labelConstraint = ensureTextConstraint(entry.label, "ResponsiveConstraint")
		local valueConstraint = ensureTextConstraint(entry.value, "ResponsiveConstraint")
		local isSeatCard = entry.key == "seat"

		entry.card.Visible = not (profile.isMobile and isSeatCard)
		if entry.card.Visible then
			entry.card.LayoutOrder = nextLayoutOrder
			nextLayoutOrder += 1
		end

		entry.card.BackgroundTransparency = profile.isMobile and 0.12 or 0.08
		entry.label.TextSize = profile.isMobile and 11 or 14
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
		local titleConstraint = ensureTextConstraint(button.Title, "ResponsiveConstraint")
		local levelConstraint = ensureTextConstraint(button.Level, "ResponsiveConstraint")
		local costConstraint = ensureTextConstraint(button.Cost, "ResponsiveConstraint")

		button.Text = ""
		button.TextScaled = false
		button.ClipsDescendants = true
		button.Title.TextScaled = true
		button.Level.TextScaled = true
		button.Cost.TextScaled = true

		if profile.isMobile then
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

	local flipConstraint = ensureTextConstraint(FlipButton, "ResponsiveConstraint")
	FlipButton.TextScaled = true
	flipConstraint.MinTextSize = profile.isMobile and 14 or 22
	flipConstraint.MaxTextSize = profile.isMobile and 30 or 64

	if ResultLabel then
		local resultConstraint = ensureTextConstraint(ResultLabel, "ResponsiveConstraint")
		ResultLabel.TextScaled = true
		ResultLabel.TextWrapped = true
		resultConstraint.MinTextSize = profile.isMobile and 10 or 16
		resultConstraint.MaxTextSize = profile.isMobile and 18 or 34
	end
end

local function applyHudLayout(profile)
	StatsGridLayout.FillDirectionMaxCells = profile.statsColumns
	StatsGridLayout.CellSize = profile.statsCellSize
	StatsGridLayout.CellPadding = profile.statsCellPadding

	Hud.AnchorPoint = Vector2.new(0.5, 1)
	Hud.Position = UDim2.fromScale(0.5, profile.hudY)
	Hud.Size = UDim2.fromScale(profile.hudSize.X, profile.hudSize.Y)
	applyClampConstraint(Hud, "ResponsiveHudConstraint", profile.hudMinSize, profile.hudMaxSize)

	Content.Size = UDim2.fromScale(1, 1)

	if ContentListLayout and ActionsFrame then
		ContentListLayout.Padding = UDim.new(0, profile.isMobile and 8 or 10)
		ContentListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		ContentListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		ContentListLayout.SortOrder = Enum.SortOrder.LayoutOrder

		StatsFrame.LayoutOrder = 1
		StatsFrame.Position = UDim2.new()
		StatsFrame.Size = UDim2.new(1, 0, 0, profile.isMobile and 92 or 108)

		ResultLabel.LayoutOrder = 2
		ResultLabel.Position = UDim2.new()
		ResultLabel.Size = UDim2.new(1, 0, 0, profile.isMobile and 28 or 34)

		ActionsFrame.LayoutOrder = 3
		ActionsFrame.Position = UDim2.new()
		ActionsFrame.Size = UDim2.new(1, 0, 0, profile.isMobile and 78 or 84)
		local actionsLayout = ActionsFrame:FindFirstChildOfClass("UIListLayout")
		if actionsLayout then
			actionsLayout.Padding = UDim.new(0, profile.isMobile and 6 or 8)
			actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		end

		FlipButton.Size = UDim2.new(1, 0, 0, profile.isMobile and 36 or 40)
		FlipButton.Position = UDim2.new()
		UpgradeButtons.LayoutOrder = 4
		UpgradeButtons.Position = UDim2.new()
		UpgradeButtons.Size = UDim2.new(1, 0, 0, profile.isMobile and 126 or 96)
	else
		StatsFrame.Position = UDim2.fromScale(0.02, 0.05)
		StatsFrame.Size = UDim2.fromScale(0.76, 0.22)
		ResultLabel.Position = UDim2.fromScale(0.02, 0.31)
		ResultLabel.Size = UDim2.fromScale(0.96, 0.1)
		FlipButton.Position = UDim2.fromScale(0.02, 0.45)
		FlipButton.Size = UDim2.fromScale(0.24, 0.25)
		UpgradeButtons.Position = UDim2.fromScale(0.29, 0.44)
		UpgradeButtons.Size = UDim2.fromScale(0.69, 0.46)
	end

	UpgradeGridLayout.FillDirectionMaxCells = profile.upgradeColumns
	UpgradeGridLayout.CellSize = profile.upgradeCellSize
	UpgradeGridLayout.CellPadding = profile.upgradeCellPadding

	local leaveButton = Content:FindFirstChild("LeaveSeatButton")
	if not leaveButton and ActionsFrame then
		leaveButton = ActionsFrame:FindFirstChild("LeaveButton") or ActionsFrame:FindFirstChild("LeaveSeatButton")
	end
	if leaveButton then
		local leaveConstraint = ensureTextConstraint(leaveButton, "ResponsiveConstraint")
		leaveButton.TextScaled = true
		leaveConstraint.MinTextSize = profile.isMobile and 12 or 11
		leaveConstraint.MaxTextSize = profile.isMobile and 22 or 18

		if ContentListLayout and ActionsFrame then
			leaveButton.Size = UDim2.new(1, 0, 0, profile.isMobile and 32 or 34)
			leaveButton.Position = UDim2.new()
		elseif profile.isMobile then
			leaveButton.AnchorPoint = Vector2.new(0, 0)
			leaveButton.Position = UDim2.fromScale(0.53, 0.48)
			leaveButton.Size = UDim2.fromScale(0.43, 0.16)
		else
			leaveButton.AnchorPoint = Vector2.new(1, 0)
			leaveButton.Position = UDim2.fromScale(0.98, 0.05)
			leaveButton.Size = UDim2.fromScale(0.16, 0.14)
		end
	end

	applyStatCardLayout(profile)
	applyUpgradeButtonLayout(profile)
end

local function getSeatBillboard(seatId)
	return getSeatPart(seatId):WaitForChild("SeatInfoBillboard")
end

local function buildFeaturedSeatSummary(seatState, profile)
	if not seatState or not seatState.featuredSeatId or not seatState.featuredSeatPlayerName then
		return nil
	end

	local label = seatState.featuredSeatLabel or "Featured"
	local playerName = seatState.featuredSeatPlayerName
	local seatId = seatState.featuredSeatId
	local streak = seatState.featuredSeatStreak or 0
	local streakText = streak > 0 and (profile.isMobile and ` S{streak}` or ` with {streak} streak`) or ""

	if profile.isMobile then
		return `{label}: {playerName}{streakText}`
	end

	return `{label}: {playerName} at {seatId}{streakText}.`
end

local function applyOverviewRowStyle(row, entry, profile)
	local stroke = row:FindFirstChildOfClass("UIStroke")
	local highlightColor = entry and (entry.featuredBadgeColor or entry.statusColor) or OverviewRowTheme.Stroke
	local isFeatured = entry and entry.isFeatured

	row.BackgroundColor3 = isFeatured and OverviewRowTheme.FeaturedBackground or OverviewRowTheme.Background
	row.BackgroundTransparency = isFeatured and 0.02 or 0.1
	row.SeatLabel.TextColor3 = isFeatured and highlightColor or OverviewRowTheme.Seat
	row.NameLabel.TextColor3 = OverviewRowTheme.Name
	row.DetailLabel.TextColor3 = OverviewRowTheme.Detail

	if stroke then
		stroke.Color = isFeatured and highlightColor or OverviewRowTheme.Stroke
		stroke.Transparency = isFeatured and 0.08 or 0.6
		stroke.Thickness = isFeatured and (profile.isMobile and 1.35 or 1.6) or 1
	end
end

local function applyWorldBillboardStyle(billboard, variant, entry, seatState)
	local frame = billboard.Frame
	local seatLabel = frame.SeatLabel
	local statusLabel = frame.StatusLabel
	local nameLabel = frame.NameLabel
	local detailLabel = frame.DetailLabel
	local cashLabel = frame.CashLabel
	local guideOverride = getWorldBillboardGuideOverride(seatState, entry)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	local isFeatured = entry and entry.isFeatured and not guideOverride
	local highlightColor = isFeatured and (entry.featuredBadgeColor or entry.statusColor) or WorldBillboardTheme.Stroke

	if variant == "hidden" then
		billboard.Enabled = false
		return
	end

	local billboardConfig = LayoutConfig.WorldBillboard
	billboard.Enabled = true
	frame.BackgroundColor3 = isFeatured and WorldBillboardTheme.FeaturedBackground or WorldBillboardTheme.Background
	seatLabel.TextColor3 = isFeatured and highlightColor or WorldBillboardTheme.Seat
	nameLabel.TextColor3 = WorldBillboardTheme.Name
	detailLabel.TextColor3 = WorldBillboardTheme.Detail
	cashLabel.TextColor3 = WorldBillboardTheme.Cash

	if stroke then
		stroke.Color = highlightColor
		stroke.Transparency = isFeatured and 0.02 or 0.22
		stroke.Thickness = isFeatured and 1.65 or 1.25
	end

	if variant == "compact" then
		billboard.Size = UDim2.fromOffset(billboardConfig.CompactSize.X, billboardConfig.CompactSize.Y)
		billboard.StudsOffsetWorldSpace = billboardConfig.CompactOffset
		frame.BackgroundTransparency = isFeatured and 0.18 or 0.32
		seatLabel.TextSize = 10
		statusLabel.TextSize = 10
		nameLabel.TextSize = 14
		nameLabel.Position = UDim2.fromOffset(0, 16)
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		detailLabel.Visible = guideOverride and guideOverride.forceDetail or false
		cashLabel.Visible = guideOverride and guideOverride.forceCash or false
		nameLabel.Text = guideOverride and guideOverride.nameText or (entry.isOccupied and entry.displayName or "Open")
		statusLabel.Text = guideOverride and guideOverride.statusText
			or (entry.isOccupied and (isFeatured and (entry.featuredBadgeText or entry.statusText) or entry.statusText or "Ready") or "Open")
	else
		billboard.Size = UDim2.fromOffset(billboardConfig.FullSize.X, billboardConfig.FullSize.Y)
		billboard.StudsOffsetWorldSpace = billboardConfig.FullOffset
		frame.BackgroundTransparency = isFeatured and 0.08 or 0.18
		seatLabel.TextSize = 11
		statusLabel.TextSize = 11
		nameLabel.TextSize = 17
		nameLabel.Position = UDim2.fromOffset(0, 18)
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		detailLabel.Visible = (guideOverride and guideOverride.forceDetail) or entry.isOccupied
		cashLabel.Visible = guideOverride and guideOverride.forceCash or entry.isOccupied
		nameLabel.Text = guideOverride and guideOverride.nameText or entry.displayName
		statusLabel.Text = guideOverride and guideOverride.statusText
			or (isFeatured and (entry.featuredBadgeText or entry.statusText) or entry.statusText or "")
	end

	seatLabel.Text = entry.seatId or ""
	statusLabel.TextColor3 = guideOverride and guideOverride.statusColor
		or (isFeatured and (entry.featuredBadgeColor or entry.statusColor) or entry.statusColor or WorldBillboardTheme.Status)
	detailLabel.Text = guideOverride and guideOverride.detailText
		or (isFeatured and (entry.featuredDetailText or entry.detailText) or entry.detailText or "")
	cashLabel.Text = guideOverride and guideOverride.cashText or entry.cashText or ""
end

local function applyWorldBillboardFocus(seatState)
	if not seatState or not seatState.seatDisplayEntries then
		return
	end

	for _, entry in ipairs(seatState.seatDisplayEntries) do
		local billboard = getSeatBillboard(entry.seatId)
		if billboard then
			applyWorldBillboardStyle(billboard, getWorldBillboardVariant(seatState, entry), entry, seatState)
		end
	end
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
	local tableTop = TableModel.TableTop
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
	local visualModel = CoinVisualsFolder:WaitForChild(`{seatId}CoinVisual`)
	return visualModel, visualModel:WaitForChild("Coin"), visualModel:WaitForChild("Shadow")
end

local function setCoinVisualEnabled(coin, shadow, enabled)
	coin.Transparency = enabled and 0 or 1
	shadow.Transparency = enabled and VisualConfig.ShadowBaseTransparency or 1
	coin.TopFace.Enabled = enabled
	coin.BottomFace.Enabled = enabled
end

local function spawnLandingPulse(position, color)
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
	pulse.Parent = CoinVisualsFolder

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
	visual.shadow.Size = visual.baseShadowSize
	setCoinVisualEnabled(visual.coin, visual.shadow, false)
end

local function playCoinVisual(seatId, result, landedCallback)
	if typeof(seatId) ~= "string" then
		if landedCallback then
			landedCallback()
		end
		return
	end

	local visualModel, coin, shadow = getCoinVisual(seatId)
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
		shadow.Size = Vector3.new(
			baseShadowSize.X,
			baseCoinSize.Y * shadowScale,
			baseCoinSize.Z * shadowScale
		)
		shadow.Transparency = shadowTransparency

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil

		local pulseColor = result == "Heads" and VisualConfig.HeadsPulseColor or VisualConfig.TailsPulseColor
		spawnLandingPulse(shadowPos, pulseColor)

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

local function requestStand()
	return
end

local function ensureSpectatorFeed()
	return spectatorFeed
end

local function showSpectatorFeed(text)
	local panel = ensureSpectatorFeed()
	spectatorFeedToken += 1
	local token = spectatorFeedToken
	SpectatorFeedLabel.Text = text
	panel.Visible = true
	task.delay(2.2, function()
		if spectatorFeedToken ~= token then
			return
		end
		panel.Visible = false
	end)
end

local function ensureTableOverview()
	return tableOverview
end

local function applyOverviewLayout(profile, panel)
	panel = panel or ensureTableOverview()
	local title = panel.Title
	local subtitle = panel.Subtitle
	local list = panel.List
	local emptyLabel = panel:FindFirstChild("EmptyLabel", true)
	local stroke = panel:FindFirstChildOfClass("UIStroke")

	panel.Position = UDim2.fromScale(profile.overviewPosition.X, profile.overviewPosition.Y)
	panel.Size = UDim2.fromScale(profile.overviewSize.X, profile.overviewSize.Y)
	applyClampConstraint(panel, "ResponsiveOverviewConstraint", profile.overviewMinSize, profile.overviewMaxSize)

	if title then
		title.TextSize = profile.isMobile and 12 or 18
	end
	if subtitle then
		subtitle.TextSize = profile.isMobile and 9 or 13
		subtitle.Position = UDim2.fromOffset(12, profile.isMobile and 28 or 36)
		subtitle.Size = UDim2.new(1, -24, 0, profile.isMobile and 24 or 32)
	end
	if stroke then
		stroke.Thickness = profile.isMobile and 1.1 or 1.4
	end
	if list then
		local listY = profile.isMobile and 58 or 78
		local listBottomPadding = profile.isMobile and 70 or 96
		if panel:FindFirstChild("Divider") then
			listY = profile.isMobile and 60 or 82
			listBottomPadding = profile.isMobile and 72 or 100
		end
		list.Position = UDim2.fromOffset(12, listY)
		list.Size = UDim2.new(1, profile.isMobile and -24 or -28, 1, -listBottomPadding)
		list.ScrollBarThickness = profile.isMobile and 3 or 6

		local layout = list:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.Padding = UDim.new(0, profile.overviewRowPadding)
		end
	end
	if emptyLabel then
		emptyLabel.TextSize = profile.isMobile and 10 or 14
		emptyLabel.Position = UDim2.fromOffset(0, 8)
		emptyLabel.Size = UDim2.new(1, 0, 0, profile.isMobile and 16 or 20)
	end
end

local function updateTableOverview(seatState)
	currentSeatState = seatState
	local panel = ensureTableOverview()
	local list = TableOverviewList
	local title = TableOverviewTitle
	local subtitle = TableOverviewSubtitle
	local emptyLabel = TableOverviewEmptyLabel
	local profile = currentLayoutProfile or getLayoutProfile()
	local seatDisplayEntries = seatState and seatState.seatDisplayEntries or {}
	local visibleEntries = seatDisplayEntries
	local occupiedCount = 0
	local totalSeatCount = seatState and seatState.seatOrder and #seatState.seatOrder or #seatDisplayEntries

	applyOverviewLayout(profile, panel)

	for _, entry in ipairs(seatDisplayEntries) do
		if entry.isOccupied then
			occupiedCount += 1
		end
	end

	if profile.isMobile and LayoutConfig.Mobile.ShowOnlyOccupiedOverview then
		visibleEntries = {}
		for _, entry in ipairs(seatDisplayEntries) do
			if entry.isOccupied then
				table.insert(visibleEntries, entry)
			end
		end
	end

	if title then
		if profile.isMobile then
			title.Text = seatState and seatState.isSeated and (seatState.seatId or "Seat") or "Spectator"
		else
			title.Text = seatState and seatState.isSeated and `Seat {seatState.seatId} Live Table` or "Spectator View"
		end
	end

	if subtitle then
		if seatState and seatState.isSeated then
			local featuredSummary = buildFeaturedSeatSummary(seatState, profile)
			if seatState.featuredSeatId == seatState.seatId and seatState.featuredSeatLabel then
				subtitle.Text = profile.isMobile
					and `You are {seatState.featuredSeatLabel}.`
					or `You're the {string.lower(seatState.featuredSeatLabel)}. Keep the table watching.`
			elseif featuredSummary then
				subtitle.Text = profile.isMobile
					and featuredSummary
					or `{featuredSummary} {occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seats occupied.`
			else
				subtitle.Text = profile.isMobile
					and `{occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seated.`
					or `{occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seats occupied. Space flips, click upgrades.`
			end
		else
			local featuredSummary = buildFeaturedSeatSummary(seatState, profile)
			subtitle.Text = occupiedCount > 0
				and (featuredSummary
					or (profile.isMobile and `Watching {occupiedCount}.` or `Watching {occupiedCount} active seats in real time.`))
				or (profile.isMobile and "Table empty right now." or "The table is empty right now.")
		end
	end

	if emptyLabel then
		local shouldShowEmpty = false
		if profile.isMobile then
			shouldShowEmpty = #visibleEntries == 0 and not (LayoutConfig.Mobile.HideOverviewWhenEmpty and occupiedCount == 0)
		else
			shouldShowEmpty = occupiedCount == 0
		end
		emptyLabel.Visible = shouldShowEmpty
	end

	if profile.isMobile and LayoutConfig.Mobile.HideOverviewWhenEmpty and occupiedCount == 0 then
		panel.Visible = false
		applyWorldBillboardFocus(seatState)
		return
	end

	for index, entry in ipairs(visibleEntries) do
		local row = tableOverviewRows[index]

		row.LayoutOrder = index
		row.Visible = true
		row.Size = UDim2.new(1, 0, 0, profile.overviewRowHeight)
		row.SeatLabel.TextSize = profile.isMobile and 9 or 12
		row.SeatLabel.Size = UDim2.new(0, profile.isMobile and 42 or 64, 0, 14)
		row.NameLabel.TextSize = profile.isMobile and 10 or 15
		row.NameLabel.Position = UDim2.fromOffset(10, profile.isMobile and 14 or 20)
		row.NameLabel.Size = UDim2.new(1, profile.isMobile and -72 or -92, 0, profile.isMobile and 12 or 18)
		row.StatusLabel.TextSize = profile.isMobile and 9 or 13
		row.StatusLabel.Size = UDim2.new(0, profile.isMobile and 58 or 84, 0, 14)
		row.DetailLabel.TextSize = profile.isMobile and 8 or 12
		row.DetailLabel.Position = UDim2.fromOffset(10, profile.isMobile and 24 or 36)
		row.DetailLabel.Size = UDim2.new(1, -20, 0, profile.isMobile and 8 or 12)
		applyOverviewRowStyle(row, entry, profile)
		row.SeatLabel.Text = entry.seatId or `Seat {index}`
		row.NameLabel.Text = entry.displayName or "Open Seat"
		row.StatusLabel.Text = entry.isFeatured and (entry.featuredBadgeText or entry.statusText) or entry.statusText or ""
		row.StatusLabel.TextColor3 = entry.isFeatured and (entry.featuredBadgeColor or entry.statusColor)
			or entry.statusColor
			or WorldBillboardTheme.Status

		if entry.isOccupied then
			local detailText
			if profile.isMobile and seatState and entry.seatId ~= seatState.seatId then
				detailText = entry.coinName or "Rusty Penny"
			else
				detailText = profile.isMobile
					and `Streak {entry.streak or 0}`
					or `Streak {entry.streak or 0} | {entry.coinName or "Rusty Penny"} | $ {Util.FormatNumber(entry.cash or 0, true)}`
			end
			row.DetailLabel.Text = detailText
			row.DetailLabel.Visible = true
		else
			row.DetailLabel.Text = profile.isMobile and "" or "Walk up to sit."
			row.DetailLabel.Visible = not profile.isMobile
		end
	end

	for index = #visibleEntries + 1, #tableOverviewRows do
		tableOverviewRows[index].Visible = false
	end

	applyWorldBillboardFocus(seatState)
	panel.Visible = true
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
	if ActionsFrame then
		local modernLeaveButton = ActionsFrame:FindFirstChild("LeaveButton") or ActionsFrame:FindFirstChild("LeaveSeatButton")
		if modernLeaveButton then
			modernLeaveButton.Visible = false
			modernLeaveButton.Active = false
			modernLeaveButton.AutoButtonColor = false
			return modernLeaveButton
		end
	end

	local leaveButton = Content:FindFirstChild("LeaveSeatButton")
	if leaveButton then
		leaveButton.Visible = false
		leaveButton.Active = false
		leaveButton.AutoButtonColor = false
		return leaveButton
	end

	leaveButton = Instance.new("TextButton")
	leaveButton.Name = "LeaveSeatButton"
	leaveButton.AnchorPoint = Vector2.new(1, 0)
	leaveButton.AutoButtonColor = true
	leaveButton.BackgroundColor3 = Color3.fromRGB(52, 31, 31)
	leaveButton.BorderSizePixel = 0
	leaveButton.Font = Enum.Font.GothamBold
	leaveButton.Text = "Leave Seat"
	leaveButton.TextColor3 = Color3.fromRGB(255, 236, 236)
	leaveButton.TextSize = 14
	leaveButton.Position = UDim2.new(1, -18, 0, 16)
	leaveButton.Size = UDim2.fromOffset(112, 34)
	leaveButton.Visible = false
	leaveButton.Active = false
	leaveButton.AutoButtonColor = false
	leaveButton.Parent = ActionsFrame or Content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = leaveButton

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 162, 162)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.35
	stroke.Parent = leaveButton

	return leaveButton
end

local function applyResponsiveLayout()
	currentLayoutProfile = getLayoutProfile()
	applyHudLayout(currentLayoutProfile)
	applyOverviewLayout(currentLayoutProfile, tableOverview)
	applyOnboardingLayout(currentLayoutProfile)

	if spectatorFeed then
		spectatorFeed.Position =
			UDim2.fromScale(currentLayoutProfile.feedPosition.X, currentLayoutProfile.feedPosition.Y)
		spectatorFeed.Size = UDim2.fromScale(currentLayoutProfile.feedSize.X, currentLayoutProfile.feedSize.Y)
	end

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
	local leaveButton = ensureLeaveButton()
	bindViewportLayout()

	if promptShownConnection then
		promptShownConnection:Disconnect()
	end
	promptShownConnection = ProximityPromptService.PromptShown:Connect(function(prompt)
		if not currentOnboardingState or currentOnboardingState.isComplete then
			return
		end
		if currentOnboardingState.currentStep ~= "approachSeat" or onboardingPromptReported then
			return
		end
		if prompt:GetAttribute("Occupied") == true then
			return
		end
		if typeof(prompt:GetAttribute("SeatId")) ~= "string" then
			return
		end

		onboardingPromptReported = true
		CoinFlipSystem.Server:ReportGuideAction({
			action = "approachSeat",
			seatId = prompt:GetAttribute("SeatId"),
		})
	end)

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
	SeatValue.Text = args.seatState.seatId or "--"

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
	end)
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
	leaveButton.Visible = false
	updateTableOverview(args and args.seatState)
	updateOnboardingPanel()
	if isSeated then
		SeatValue.Text = args.seatState.seatId or "--"
		if ResultLabel.Text == "Waiting for seat assignment..." then
			updateResultText("Click FLIP to flip.", "Neutral")
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

	if not onboarding or onboarding.currentStep ~= "approachSeat" then
		onboardingPromptReported = false
	end

	updateOnboardingPanel()
	if currentSeatState then
		applyWorldBillboardFocus(currentSeatState)
	end
end

function CoinFlipUi.ObservedFlip(args)
	if args.userId == LocalPlayer.UserId then
		return
	end

	local actor = Players:GetPlayerByUserId(args.userId)
	local actorName = actor and actor.DisplayName or tostring(args.userId)
	local text
	if args.result == "Heads" then
		text = `{actorName} hit Heads at {args.seatId} for $ {Util.FormatNumber(args.reward or 0, true)}`
		if (args.streak or 0) > 1 then
			text ..= ` | {args.streak} streak`
		end
	elseif (args.reward or 0) > 0 then
		text = `{actorName} hit Tails at {args.seatId} | +$ {Util.FormatNumber(args.reward, true)}`
	else
		text = `{actorName} hit Tails at {args.seatId}`
	end

	playCoinVisual(args.seatId, args.result, function()
		showSpectatorFeed(text)
	end)
end

return CoinFlipUi
