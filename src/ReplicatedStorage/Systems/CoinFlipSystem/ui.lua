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
local Buttons = Main:WaitForChild("Buttons")
local Frames = Main:WaitForChild("Frames")
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipSystem = SystemMgr.systems.CoinFlipSystem
local TableSeatSystem = SystemMgr.systems.TableSeatSystem
local EffectSystem = SystemMgr.systems.EffectSystem
local FirstPersonCamera =
	require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"):WaitForChild("FirstPersonCamera"))

local function findFirstByNames(parent, names)
	for _, name in ipairs(names) do
		local child = parent:FindFirstChild(name)
		if child then
			return child
		end
	end

	return nil
end

local Hud = Elements:WaitForChild("CoinFlipHUD")
local CoinFlipMenu = Buttons:WaitForChild("CoinFlipMenu")
local LegacyCashText = Elements:WaitForChild("cash")
local LegacyRebirthText = Elements:WaitForChild("candy")
local TopBar = Buttons:FindFirstChild("TopBar")
local RightBottom = Buttons:FindFirstChild("RightBottom")
local LegacyInventoryButton = Buttons:FindFirstChild("InventoryButton")
local ShopFrame = Frames:WaitForChild("Shop")
local InventoryFrame = Frames:WaitForChild("Inventory")
local RebirthFrame = Frames:WaitForChild("Rebirth")
local GrowthFrames = {
	ShopFrame,
	InventoryFrame,
	RebirthFrame,
}
local Content = Hud:WaitForChild("Content")
local LeftPanel = Content:WaitForChild("LeftPanel")
local CenterPanel = Content:WaitForChild("CenterPanel")
local RightPanel = Content:WaitForChild("RightPanel")
local RightStatsFrame = RightPanel:WaitForChild("Stats")
local UpgradeButtons = RightPanel:WaitForChild("UpgradeButtons")
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
local AutoButton = CenterPanel:WaitForChild("AutoButton")
if not AutoButton or not AutoButton:IsA("GuiButton") then
	error("CoinFlipHUD is missing AutoButton")
end
local AutoButtonStroke = AutoButton:WaitForChild("UIStroke")
local GuidePrompt = CenterPanel:WaitForChild("GuidePrompt")
local GuideMessage = GuidePrompt:WaitForChild("Message")
local GuideActionButton = GuidePrompt:WaitForChild("ActionButton")

local SpectatorFeed = Elements:FindFirstChild("CoinFlipSpectatorFeed")
local TableOverview = Elements:FindFirstChild("CoinFlipTableOverview")
if SpectatorFeed and SpectatorFeed:IsA("GuiObject") then
	SpectatorFeed.Visible = false
end
if TableOverview and TableOverview:IsA("GuiObject") then
	TableOverview.Visible = false
end

local OnboardingPanel = Elements:FindFirstChild("CoinFlipOnboarding")

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
	biasLevel = "Luck",
}

local CoinFlipUi = {}
local initialized = false
local flipInputBound = false
local responsiveLayoutBound = false
local viewportSizeConnection
local cameraChangedConnection
local currentSeatId
local currentFlipInterval = 1.8
local localFlipCooldownEndsAt = 0
local activeFlipRequestToken = 0
local awaitingFlipResponse = false
local resultFlashToken = 0
local defaultResultTextTransparency = ResultLabel.TextTransparency
local defaultResultStrokeTransparency = ResultLabel.TextStrokeTransparency
local currentSeatState
local currentFlipInProgress = false
local currentLayoutIsMobilePortrait = false
local autoFlipEnabled = false
local autoFlipToken = 0
local upgradePromptToken = 0
local lastUpgradePromptKey = nil
local currentRunSnapshot = {
	cash = 0,
	runData = {},
	nextCosts = {},
	derivedStats = {},
}
local currentOnboarding
local currentGuideButton
local currentGuideFrame
local latestRunStateVersion = 0
local initialTableLookRequested = false
local FlipInputActionName = "COIN_FLIP_REQUEST"
local AUTO_BUTTON_ON_COLOR = Color3.fromRGB(92, 255, 132)
local AUTO_BUTTON_OFF_COLOR = Color3.fromRGB(255, 255, 255)
local FAKE_COIN_LOOK_DURATION = 1.02
local FAKE_COIN_LOOK_RESTORE_DURATION = 0.18
local FAKE_COIN_LOOK_PITCH_LIMIT = math.rad(35)
local FAKE_COIN_LOOK_YAW_LIMIT = math.rad(50)
local FAKE_COIN_LOOK_NECK_PITCH_WEIGHT = 0.7
local FAKE_COIN_LOOK_NECK_YAW_WEIGHT = 0.72
local FAKE_COIN_LOOK_WAIST_YAW_WEIGHT = 0.2
local fakeCoinLookTokens = {}

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

local function isGrowthFrameOpen()
	for _, frame in ipairs(GrowthFrames) do
		if frame.Visible then
			return true
		end
	end

	return false
end

local function pulseRecommendedUpgrade(onboarding)
	if not onboarding or onboarding.currentStep ~= "buyUpgrade" then
		lastUpgradePromptKey = nil
		return
	end

	local upgradeKey = getRecommendedUpgradeKey()
	if not upgradeKey or lastUpgradePromptKey == upgradeKey then
		return
	end

	local button = UpgradeMap[upgradeKey]
	lastUpgradePromptKey = upgradeKey
	upgradePromptToken += 1
	local token = upgradePromptToken
	local originalColor = button.BackgroundColor3
	local originalTitleColor = button.Title.TextColor3

	TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(255, 197, 73),
	}):Play()
	TweenService:Create(button.Title, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = Color3.fromRGB(26, 22, 12),
	}):Play()

	task.delay(0.7, function()
		if token ~= upgradePromptToken then
			return
		end

		TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = originalColor,
		}):Play()
		TweenService:Create(button.Title, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextColor3 = originalTitleColor,
		}):Play()
	end)
end

local function playSfx(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return
	end

	SystemMgr.systems.MusicSystem:PlayLocalSfx({
		musicName = soundName,
	})
end

local function getReadyPrompt()
	return UserInputService.TouchEnabled and "Tap FLIP" or "Click FLIP"
end

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function resolveHudSizeScale(baseSize, minSize, maxSize, viewportSize)
	local targetWidth = viewportSize.X * baseSize.X
	local targetHeight = viewportSize.Y * baseSize.Y

	if minSize then
		targetWidth = math.max(targetWidth, minSize.X)
		targetHeight = math.max(targetHeight, minSize.Y)
	end
	if maxSize then
		targetWidth = math.min(targetWidth, maxSize.X)
		targetHeight = math.min(targetHeight, maxSize.Y)
	end

	return Vector2.new(math.clamp(targetWidth / viewportSize.X, 0, 1), math.clamp(targetHeight / viewportSize.Y, 0, 1))
end

local function resolveHudLayoutProfile()
	local layout = Presets.UiLayout
	local hudLayout = layout.Hud
	local viewportSize = getViewportSize()
	local isMobile = false
	-- Mobile HUD redistribution is temporarily disabled while mobile layout is being reworked.
	-- local aspectRatio = viewportSize.X / viewportSize.Y
	-- local isMobile = UserInputService.TouchEnabled
	-- 	and (viewportSize.X <= layout.MobileMaxWidth or aspectRatio <= layout.MobileMaxAspect)

	if not isMobile then
		local size = hudLayout.DesktopSize
		if viewportSize.X <= layout.NarrowWidth then
			size = hudLayout.NarrowSize
		end

		return {
			size = size,
			y = hudLayout.DesktopY,
			viewportSize = viewportSize,
			isMobilePortrait = false,
		}
	end

	local isPortrait = viewportSize.Y >= viewportSize.X
	local size = hudLayout.MobileLandscapeSize
	local y = hudLayout.MobileLandscapeY
	if isPortrait then
		size = hudLayout.MobilePortraitSize
		y = hudLayout.MobilePortraitY
	end

	return {
		size = size,
		y = y,
		minSize = hudLayout.MobileMinSize,
		maxSize = hudLayout.MobileMaxSize,
		viewportSize = viewportSize,
		isMobilePortrait = isPortrait,
	}
end

local function applyHudLayout()
	local profile = resolveHudLayoutProfile()
	local sizeScale = resolveHudSizeScale(profile.size, profile.minSize, profile.maxSize, profile.viewportSize)

	currentLayoutIsMobilePortrait = profile.isMobilePortrait
	Hud.AnchorPoint = Vector2.new(0.5, 1)
	Hud.Position = UDim2.fromScale(0.5, profile.y)
	Hud.Size = UDim2.fromScale(sizeScale.X, sizeScale.Y)
end

local function hideLegacyOnboardingPanel()
	if OnboardingPanel and OnboardingPanel:IsA("GuiObject") then
		OnboardingPanel.Visible = false
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

local function applyGameplayVisibility(isVisible)
	local showHud = isVisible == true and not isGrowthFrameOpen()
	local canRequestFlip = showHud and not currentFlipInProgress and not awaitingFlipResponse

	Hud.Visible = showHud
	CoinFlipMenu.Visible = false
	LeftPanel.Visible = showHud
	RightPanel.Visible = showHud
	RightStatsFrame.Visible = showHud and not currentLayoutIsMobilePortrait
	UpgradeButtons.Visible = showHud
	CenterPanel.Visible = showHud
	InputHints.Visible = canRequestFlip and not UserInputService.TouchEnabled
	ResultLabel.Visible = showHud
	FlipButton.Visible = showHud
	FlipButton.Active = canRequestFlip
	FlipButton.AutoButtonColor = canRequestFlip
	AutoButton.Visible = showHud
	AutoButton.Active = showHud
	AutoButton.AutoButtonColor = showHud
	LegacyCashText.Visible = false
	LegacyRebirthText.Visible = false

	if TopBar and TopBar:IsA("GuiObject") then
		TopBar.Visible = false
	end
	if RightBottom and RightBottom:IsA("GuiObject") then
		RightBottom.Visible = false
	end
	if LegacyInventoryButton and LegacyInventoryButton:IsA("GuiObject") then
		LegacyInventoryButton.Visible = false
	end
	if not showHud then
		currentFlipInProgress = false
	end
end

local function updateAutoButtonText()
	AutoButton.Text = autoFlipEnabled and "Auto:On" or "Auto:Off"
	local color = autoFlipEnabled and AUTO_BUTTON_ON_COLOR or AUTO_BUTTON_OFF_COLOR
	AutoButton.TextColor3 = color
	AutoButtonStroke.Color = color
end

local function setAutoFlipEnabled(isEnabled)
	local shouldEnable = isEnabled == true and currentSeatId ~= nil and not isGrowthFrameOpen()
	if autoFlipEnabled == shouldEnable then
		updateAutoButtonText()
		return
	end

	autoFlipEnabled = shouldEnable
	autoFlipToken += 1
	updateAutoButtonText()
end

local function updateResultText(text, tone)
	resultFlashToken += 1
	local token = resultFlashToken
	local resultColor = Color3.fromRGB(232, 236, 242)

	if tone == "Heads" then
		resultColor = Color3.fromRGB(255, 225, 109)
	elseif tone == "Tails" then
		resultColor = Color3.fromRGB(255, 173, 156)
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

local function requestFlip()
	local now = os.clock()
	if awaitingFlipResponse or now < localFlipCooldownEndsAt then
		return false
	end

	awaitingFlipResponse = true
	currentFlipInProgress = true
	activeFlipRequestToken += 1
	local requestToken = activeFlipRequestToken
	local hadSeatWhenRequested = currentSeatId ~= nil
	localFlipCooldownEndsAt = now + math.max(0.15, currentFlipInterval + 0.05)
	if currentSeatId then
		applyGameplayVisibility(true)
	end
	CoinFlipSystem.Server:RequestFlip()
	updateResultText(hadSeatWhenRequested and "Flipping..." or "Checking your seat...", "Neutral")
	if hadSeatWhenRequested then
		playSfx("flipPress")
	end

	task.delay(0.45, function()
		if activeFlipRequestToken ~= requestToken or not awaitingFlipResponse then
			return
		end

		awaitingFlipResponse = false
		currentFlipInProgress = false
		localFlipCooldownEndsAt = os.clock() + 0.05
		applyGameplayVisibility(currentSeatId ~= nil)
		if hadSeatWhenRequested then
			updateResultText("Flip not ready.", "Neutral")
		else
			updateResultText("Waiting for seat...", "Neutral")
		end
	end)

	return true
end

local function clearGuideHighlight()
	if not currentGuideButton then
		return
	end

	uiController.SetGuideButton(nil)
	currentGuideButton = nil
	currentGuideFrame = nil
end

local function setGuideHighlight(button, frame)
	local resolvedFrame = frame or button
	if currentGuideButton == button and currentGuideFrame == resolvedFrame then
		return
	end

	clearGuideHighlight()
	if not button then
		return
	end

	uiController.SetGuideButton(button, frame)
	currentGuideButton = button
	currentGuideFrame = resolvedFrame
end

local function getGuideCopy(onboarding)
	local stepKey = onboarding and onboarding.currentStep
	if stepKey == "firstFlip" then
		return "Heads pay Cash. Streaks boost your payout.", "FLIP"
	end
	if stepKey == "rebirth" then
		return "Rebirth turns this run into permanent points.", "REBIRTH"
	end
	if stepKey == "coinBuy" then
		return `Buy {onboarding.targetCoinName or "a new Coin"} for better Cash and Luck.`, "BUY COIN"
	end
	if stepKey == "coinEquip" then
		return `Equip {onboarding.targetCoinName or "your new Coin"} to use its bonus.`, "EQUIP"
	end

	return "", ""
end

local function openCurrentGuideTarget()
	if not currentOnboarding or currentOnboarding.shouldGuide ~= true then
		return nil
	end

	local stepKey = currentOnboarding.currentStep
	if stepKey == "firstFlip" then
		requestFlip()
		return FlipButton
	end
	if stepKey == "rebirth" then
		return SystemMgr.systems.RebirthSystem:OpenGuideRebirth()
	end
	if stepKey == "coinBuy" then
		return SystemMgr.systems.EcoSystem:OpenGuideShopItem({
			category = "coin",
			itemId = currentOnboarding.targetCoinId,
		})
	end
	if stepKey == "coinEquip" then
		return SystemMgr.systems.EcoSystem:OpenGuideInventoryItem({
			category = "coin",
			itemId = currentOnboarding.targetCoinId,
		})
	end

	return nil
end

local function refreshGuide()
	hideLegacyOnboardingPanel()
	if
		not currentOnboarding
		or currentOnboarding.isComplete == true
		or currentOnboarding.shouldGuide ~= true
		or currentSeatId == nil
	then
		GuidePrompt.Visible = false
		clearGuideHighlight()
		return
	end

	local message, actionText = getGuideCopy(currentOnboarding)
	GuideMessage.Text = message
	GuideActionButton.Text = actionText
	GuideActionButton.Visible = true

	local stepKey = currentOnboarding.currentStep
	if stepKey == "rebirth" and RebirthFrame.Visible then
		GuidePrompt.Visible = false
		setGuideHighlight(SystemMgr.systems.RebirthSystem:OpenGuideRebirth())
		return
	end
	if stepKey == "coinBuy" and ShopFrame.Visible then
		GuidePrompt.Visible = false
		setGuideHighlight(SystemMgr.systems.EcoSystem:OpenGuideShopItem({
			category = "coin",
			itemId = currentOnboarding.targetCoinId,
		}))
		return
	end
	if stepKey == "coinEquip" and InventoryFrame.Visible then
		GuidePrompt.Visible = false
		setGuideHighlight(SystemMgr.systems.EcoSystem:OpenGuideInventoryItem({
			category = "coin",
			itemId = currentOnboarding.targetCoinId,
		}))
		return
	end
	if isGrowthFrameOpen() then
		GuidePrompt.Visible = false
		clearGuideHighlight()
		return
	end
	if stepKey == "firstFlip" then
		GuideActionButton.Visible = false
		GuidePrompt.Visible = Hud.Visible
		setGuideHighlight(FlipButton)
		return
	end

	GuidePrompt.Visible = Hud.Visible
	setGuideHighlight(GuideActionButton, GuidePrompt)
end

local function scheduleAutoFlipRequest()
	if not autoFlipEnabled then
		return
	end
	if currentSeatId == nil or isGrowthFrameOpen() then
		setAutoFlipEnabled(false)
		return
	end

	autoFlipToken += 1
	local token = autoFlipToken
	local delaySeconds = math.max(localFlipCooldownEndsAt - os.clock(), 0.05)

	task.delay(delaySeconds, function()
		if token ~= autoFlipToken or not autoFlipEnabled then
			return
		end
		if currentSeatId == nil or isGrowthFrameOpen() then
			setAutoFlipEnabled(false)
			return
		end

		requestFlip()
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
	if seatState and seatState.seatDisplayEntries then
		EffectSystem:RefreshPersistentSeatCoins(nil, nil, {
			seatDisplayEntries = seatState.seatDisplayEntries,
		})
	end
	if TableOverview and TableOverview:IsA("GuiObject") then
		TableOverview.Visible = false
	end
	if SpectatorFeed and SpectatorFeed:IsA("GuiObject") then
		SpectatorFeed.Visible = false
	end
end

local function setVisible(isVisible)
	applyGameplayVisibility(isVisible)
	if not isVisible then
		setAutoFlipEnabled(false)
		currentFlipInProgress = false
		updateResultText("Waiting for seat assignment...", "Neutral")
	end
	refreshGuide()
end

local function requestInitialTableLookIfNeeded(isSeated)
	if initialTableLookRequested or not isSeated then
		return
	end

	initialTableLookRequested = true
	FirstPersonCamera.RequestInitialTableLook()
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
	hideLegacyOnboardingPanel()
	applyHudLayout()
	applyGameplayVisibility(currentSeatId ~= nil)

	if currentSeatState then
		updateTableOverview(currentSeatState)
	end
	refreshGuide()
end

local function bindResponsiveLayout()
	if responsiveLayoutBound then
		return
	end

	responsiveLayoutBound = true
	local camera = Workspace.CurrentCamera
	if camera then
		viewportSizeConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyResponsiveLayout()
		end)
	end

	cameraChangedConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if viewportSizeConnection then
			viewportSizeConnection:Disconnect()
			viewportSizeConnection = nil
		end

		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			viewportSizeConnection = currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applyResponsiveLayout()
			end)
		end
		applyResponsiveLayout()
	end)
end

local function bindGrowthFrameVisibility()
	for _, frame in ipairs(GrowthFrames) do
		frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if frame.Visible then
				setAutoFlipEnabled(false)
			end
			applyGameplayVisibility(currentSeatId ~= nil)
			refreshGuide()
		end)
	end
end

function CoinFlipUi.Init()
	if initialized then
		return
	end
	initialized = true

	setVisible(false)
	updateAutoButtonText()
	hideLegacyOnboardingPanel()
	GuidePrompt.Visible = false
	ensureLeaveButton()
	applyResponsiveLayout()
	bindResponsiveLayout()
	bindGrowthFrameVisibility()
	bindFlipInput()

	uiController.SetButtonHoverAndClick(FlipButton, function()
		requestFlip()
	end)
	uiController.SetButtonHoverAndClick(AutoButton, function()
		setAutoFlipEnabled(not autoFlipEnabled)
		if autoFlipEnabled then
			local didRequestFlip = requestFlip()
			if not didRequestFlip and not currentFlipInProgress then
				scheduleAutoFlipRequest()
			end
		end
	end)
	uiController.SetButtonHoverAndClick(GuideActionButton, function()
		clearGuideHighlight()
		openCurrentGuideTarget()
		refreshGuide()
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
	local stateVersion = args.stateVersion
	if typeof(stateVersion) == "number" then
		if stateVersion < latestRunStateVersion then
			return false
		end
		latestRunStateVersion = stateVersion
	end

	local seatState = args.seatState or {}
	local payloadIsSeated = seatState.isSeated == true or seatState.seatId ~= nil
	if payloadIsSeated then
		currentSeatId = seatState.seatId
	elseif currentSeatId then
		seatState = table.clone(seatState)
		seatState.seatId = currentSeatId
		seatState.isSeated = true
	end
	local isSeated = currentSeatId ~= nil
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
	if args.loadoutState then
		ClientData:SetOneData("loadoutState", args.loadoutState)
		ClientData:SetOneData(dataKey.equippedCoin, args.loadoutState.equippedCoin)
		ClientData:SetOneData(dataKey.ownedCoins, args.loadoutState.ownedCoins)
		ClientData:SetOneData(dataKey.equippedDeskSetup, args.loadoutState.equippedDeskSetup)
		ClientData:SetOneData(dataKey.ownedDeskSetups, args.loadoutState.ownedDeskSetups)
		ClientData:SetOneData(dataKey.equippedChair, args.loadoutState.equippedChair)
		ClientData:SetOneData(dataKey.ownedChairs, args.loadoutState.ownedChairs)
	end
	if args.rebirthState then
		ClientData:SetOneData("rebirthState", args.rebirthState)
		ClientData:SetOneData(dataKey.rebirth, args.rebirthState.rebirth)
		ClientData:SetOneData(dataKey.fateShards, args.rebirthState.fateShards)
		ClientData:SetOneData(dataKey.rebirthTree, args.rebirthState.rebirthTree)
	end
	CashValue.Text = `$ {Util.FormatNumber(cash, true)}`
	ChanceValue.Text = `{math.round((args.derivedStats.headsChance or 0) * 1000) / 10}%`
	StreakValue.Text = tostring(args.runData.currentStreak or 0)
	SpeedValue.Text = `{math.round((args.derivedStats.flipInterval or 0) * 100) / 100}s`

	for upgradeKey, button in pairs(UpgradeMap) do
		local level = args.runData[upgradeKey] or 0
		local cost = args.nextCosts[upgradeKey]
		updateUpgradeButton(button, UpgradeTitles[upgradeKey], level, cost, cost == nil)
	end

	setVisible(isSeated)
	updateTableOverview(seatState)
	requestInitialTableLookIfNeeded(isSeated)
	CoinFlipUi.UpdateOnboarding(args.onboarding)
	pulseRecommendedUpgrade(args.onboarding)
	if isSeated and ResultLabel.Text == "Waiting for seat assignment..." then
		updateResultText(getReadyPrompt(), "Neutral")
	end

	return true
end

function CoinFlipUi.FlipResolved(args)
	awaitingFlipResponse = false
	currentFlipInProgress = true
	EffectSystem:PlayCoinFlipVisual(nil, nil, {
		seatId = args.seatState and args.seatState.seatId,
		result = args.result,
		coinId = args.equippedCoin or (args.loadoutState and args.loadoutState.equippedCoin),
		shouldFollowCamera = not autoFlipEnabled,
		landedCallback = function()
			currentFlipInProgress = false
			CoinFlipUi.SyncRunState(args)
			applyGameplayVisibility(currentSeatId ~= nil)

			if args.result == "Heads" then
				updateResultText(`Heads! +$ {Util.FormatNumber(args.reward or 0, true)}`, "Heads")
				if (args.reward or 0) > 0 then
					playSfx("cashReward")
				end
			elseif (args.reward or 0) > 0 then
				updateResultText(`Tails! +$ {Util.FormatNumber(args.reward, true)}`, "Tails")
				playSfx("cashReward")
			else
				updateResultText("Tails! Streak reset.", "Tails")
			end

			EffectSystem:PlayStreakMilestone(nil, nil, args.streakMilestone)
			scheduleAutoFlipRequest()
		end,
	})
end

function CoinFlipUi.SeatStateChanged(args)
	local isSeated = args and args.seatState and args.seatState.isSeated
	currentSeatId = isSeated and args.seatState.seatId or nil
	local leaveButton = ensureLeaveButton()
	if not isSeated then
		localFlipCooldownEndsAt = 0
		awaitingFlipResponse = false
		currentFlipInProgress = false
		setAutoFlipEnabled(false)
	end
	setVisible(isSeated)
	if leaveButton then
		leaveButton.Visible = false
	end
	updateTableOverview(args and args.seatState)
	requestInitialTableLookIfNeeded(isSeated)
	hideLegacyOnboardingPanel()
	refreshGuide()
	if isSeated then
		if ResultLabel.Text == "Waiting for seat assignment..." then
			updateResultText(getReadyPrompt(), "Neutral")
		end
	end
end

function CoinFlipUi.UpdateOnboarding(onboarding)
	currentOnboarding = onboarding
	hideLegacyOnboardingPanel()
	if currentSeatState then
		hideLegacySeatBillboards(currentSeatState)
	end
	refreshGuide()
end

local function findFakeActorModel(fakeId)
	local tableModel = Workspace:FindFirstChild("CoinFlipTable")
	local assetsFolder = tableModel and tableModel:FindFirstChild("Assets")
	local runtimeFolder = assetsFolder and assetsFolder:FindFirstChild("FakePlayersRuntime")
	local model = runtimeFolder and runtimeFolder:FindFirstChild(fakeId)
	if model and model:IsA("Model") then
		return model
	end

	model = Workspace:FindFirstChild(fakeId, true)
	if model and model:IsA("Model") then
		return model
	end

	return nil
end

local function getFakeHeadPoseMotor(model, motorName)
	for _, descendant in ipairs(model:GetDescendants()) do
		if
			descendant.Name == motorName
			and (descendant:IsA("Motor6D") or descendant.ClassName == "AnimationConstraint")
		then
			return descendant
		end
	end

	return nil
end

local function getFakeHeadPoseJointBase(joint)
	if joint.ClassName == "AnimationConstraint" then
		return joint.Transform
	end

	return joint.C0
end

local function setFakeHeadPoseJoint(joint, baseCFrame, offsetCFrame)
	if joint.ClassName == "AnimationConstraint" then
		joint.Transform = baseCFrame * offsetCFrame
	else
		joint.C0 = baseCFrame * offsetCFrame
	end
end

local function restoreFakeCoinLookMotor(joint, baseCFrame)
	if not joint or not joint.Parent then
		return
	end

	local propertyName = joint.ClassName == "AnimationConstraint" and "Transform" or "C0"
	TweenService:Create(joint, TweenInfo.new(FAKE_COIN_LOOK_RESTORE_DURATION, Enum.EasingStyle.Quad), {
		[propertyName] = baseCFrame,
	}):Play()
end

local function playFakeActorCoinLook(fakeId, focusPart)
	if typeof(fakeId) ~= "string" or not focusPart or not focusPart:IsA("BasePart") then
		return
	end

	local model = findFakeActorModel(fakeId)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not model or not root or not root:IsA("BasePart") then
		return
	end

	local neck = getFakeHeadPoseMotor(model, "Neck")
	if not neck then
		return
	end
	local waist = getFakeHeadPoseMotor(model, "Waist")
	local neckBaseC0 = getFakeHeadPoseJointBase(neck)
	local waistBaseC0 = waist and getFakeHeadPoseJointBase(waist) or nil
	local token = (fakeCoinLookTokens[fakeId] or 0) + 1
	fakeCoinLookTokens[fakeId] = token
	local startedAt = os.clock()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		if fakeCoinLookTokens[fakeId] ~= token then
			connection:Disconnect()
			return
		end
		if not model:IsDescendantOf(Workspace) or not focusPart:IsDescendantOf(Workspace) then
			fakeCoinLookTokens[fakeId] = nil
			connection:Disconnect()
			restoreFakeCoinLookMotor(neck, neckBaseC0)
			if waist and waistBaseC0 then
				restoreFakeCoinLookMotor(waist, waistBaseC0)
			end
			return
		end

		local alpha = (os.clock() - startedAt) / FAKE_COIN_LOOK_DURATION
		if alpha >= 1 then
			fakeCoinLookTokens[fakeId] = nil
			connection:Disconnect()
			restoreFakeCoinLookMotor(neck, neckBaseC0)
			if waist and waistBaseC0 then
				restoreFakeCoinLookMotor(waist, waistBaseC0)
			end
			return
		end

		local target = root.CFrame:PointToObjectSpace(focusPart.Position)
		local horizontalMagnitude = math.max(Vector2.new(target.X, target.Z).Magnitude, 0.1)
		local pitch = math.clamp(
			math.atan2(target.Y, horizontalMagnitude),
			-FAKE_COIN_LOOK_PITCH_LIMIT,
			FAKE_COIN_LOOK_PITCH_LIMIT
		)
		local yaw = math.clamp(math.atan2(-target.X, -target.Z), -FAKE_COIN_LOOK_YAW_LIMIT, FAKE_COIN_LOOK_YAW_LIMIT)
		local blend = math.clamp(alpha / 0.12, 0, 1)

		setFakeHeadPoseJoint(
			neck,
			neckBaseC0,
			CFrame.Angles(
				pitch * FAKE_COIN_LOOK_NECK_PITCH_WEIGHT * blend,
				yaw * FAKE_COIN_LOOK_NECK_YAW_WEIGHT * blend,
				0
			)
		)
		if waist and waistBaseC0 then
			setFakeHeadPoseJoint(waist, waistBaseC0, CFrame.Angles(0, yaw * FAKE_COIN_LOOK_WAIST_YAW_WEIGHT * blend, 0))
		end
	end)
end

function CoinFlipUi.ObservedFlip(args)
	if args.userId == LocalPlayer.UserId then
		return
	end

	local visual = EffectSystem:PlayCoinFlipVisual(nil, nil, {
		seatId = args.seatId,
		result = args.result,
		coinId = args.equippedCoin,
		shouldFollowCamera = false,
		visualOptions = {
			isObserved = true,
			streak = args.streak or 0,
			isMilestone = args.streakMilestone ~= nil,
		},
		landedCallback = function()
			EffectSystem:PlayStreakMilestone(nil, nil, args.streakMilestone)
		end,
	})
	if args.isFake then
		playFakeActorCoinLook(args.fakeId, visual and visual.focusPart)
	end
end

return CoinFlipUi
