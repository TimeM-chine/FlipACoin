local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Replicated = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
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
local GrowthFrames = {
	Frames:WaitForChild("Shop"),
	Frames:WaitForChild("Inventory"),
	Frames:WaitForChild("Rebirth"),
}
local Content = Hud:WaitForChild("Content")
local LeftPanel = Content:WaitForChild("LeftPanel")
local CenterPanel = Content:WaitForChild("CenterPanel")
local RightPanel = Content:WaitForChild("RightPanel")
local RightStatsFrame = RightPanel:WaitForChild("Stats")
local UpgradeButtons = RightPanel:WaitForChild("UpgradeButtons")
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
local AutoButton = CenterPanel:WaitForChild("AutoButton")
if not AutoButton or not AutoButton:IsA("GuiButton") then
	error("CoinFlipHUD is missing AutoButton")
end

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
	biasLevel = "Bias",
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
local FlipInputActionName = "COIN_FLIP_REQUEST"

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

local function buildFailureFollowUpText()
	local seatState = currentSeatState or {}
	local suggestedUpgrade = getRecommendedUpgradeKey()

	if not seatState.isSeated then
		return "Next: wait for your seat and start again."
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
		soundName = "notification",
		textColor = Color3.fromRGB(255, 223, 153),
	})
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
	local title = UpgradeTitles[upgradeKey] or "Upgrade"
	lastUpgradePromptKey = upgradeKey
	upgradePromptToken += 1
	local token = upgradePromptToken
	local originalColor = button.BackgroundColor3
	local originalTitleColor = button.Title.TextColor3

	uiController.SetNotification({
		text = `Upgrade {title} to make your next Heads stronger.`,
		lastTime = 2.6,
		soundName = "notification",
		textColor = Color3.fromRGB(255, 231, 163),
	})

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

	local sfxGroup = SoundService:FindFirstChild("SFX")
	local sound = sfxGroup and sfxGroup:FindFirstChild(soundName)
	if not sound or not sound:IsA("Sound") or sound.SoundId == "" then
		return
	end

	sound:Play()
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

	return Vector2.new(
		math.clamp(targetWidth / viewportSize.X, 0, 1),
		math.clamp(targetHeight / viewportSize.Y, 0, 1)
	)
end

local function resolveHudLayoutProfile()
	local layout = Presets.UiLayout
	local hudLayout = layout.Hud
	local viewportSize = getViewportSize()
	local aspectRatio = viewportSize.X / viewportSize.Y
	local isMobile = UserInputService.TouchEnabled
		and (viewportSize.X <= layout.MobileMaxWidth or aspectRatio <= layout.MobileMaxAspect)

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

local function hideOnboardingPanel()
	uiController.SetGuideButton(nil)

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
	SeatLabel.Visible = showHud
	InputHints.Visible = canRequestFlip and not UserInputService.TouchEnabled
	ResultLabel.Visible = showHud
	FlipButton.Visible = showHud
	FlipButton.Active = canRequestFlip
	FlipButton.AutoButtonColor = canRequestFlip
	AutoButton.Visible = showHud
	AutoButton.Active = showHud
	AutoButton.AutoButtonColor = showHud
	LegacyCashText.Visible = showHud
	LegacyRebirthText.Visible = showHud

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
	hideOnboardingPanel()
	applyHudLayout()
	applyGameplayVisibility(currentSeatId ~= nil)

	if currentSeatState then
		updateTableOverview(currentSeatState)
	end
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
		end)
	end
end

function CoinFlipUi.Init()
	if initialized then
		return
	end
	initialized = true

	setVisible(false)
	hideOnboardingPanel()
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
			requestFlip()
		end
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
		ClientData:SetOneData(dataKey.equippedCoin, args.loadoutState.equippedCoin)
		ClientData:SetOneData(dataKey.ownedCoins, args.loadoutState.ownedCoins)
		ClientData:SetOneData(dataKey.equippedDeskSetup, args.loadoutState.equippedDeskSetup)
		ClientData:SetOneData(dataKey.ownedDeskSetups, args.loadoutState.ownedDeskSetups)
		ClientData:SetOneData(dataKey.equippedChair, args.loadoutState.equippedChair)
		ClientData:SetOneData(dataKey.ownedChairs, args.loadoutState.ownedChairs)
	end
	if args.rebirthState then
		ClientData:SetOneData(dataKey.rebirth, args.rebirthState.rebirth)
		ClientData:SetOneData(dataKey.fateShards, args.rebirthState.fateShards)
		ClientData:SetOneData(dataKey.rebirthTree, args.rebirthState.rebirthTree)
	end
	CashValue.Text = `$ {Util.FormatNumber(cash, true)}`
	LegacyCashText.Text = Util.FormatNumber(cash, true)
	LegacyRebirthText.Text = Util.FormatNumber(
		(args.rebirthState and (args.rebirthState.rebirthPoints or args.rebirthState.fateShards))
			or ClientData:GetOneData(dataKey.fateShards)
			or 0,
		true
	)
	ChanceValue.Text = `{math.round((args.derivedStats.headsChance or 0) * 1000) / 10}%`
	StreakValue.Text = tostring(args.runData.currentStreak or 0)
	SpeedValue.Text = `{math.round((args.derivedStats.flipInterval or 0) * 100) / 100}s`
	SeatLabel.Text = seatState.seatId and tostring(seatState.seatId):gsub("^Seat", "Seat ") or "Seat --"

	for upgradeKey, button in pairs(UpgradeMap) do
		local level = args.runData[upgradeKey] or 0
		local cost = args.nextCosts[upgradeKey]
		updateUpgradeButton(button, UpgradeTitles[upgradeKey], level, cost, cost == nil)
	end

	setVisible(isSeated)
	updateTableOverview(seatState)
	CoinFlipUi.UpdateOnboarding(args.onboarding)
	pulseRecommendedUpgrade(args.onboarding)
	if isSeated and ResultLabel.Text == "Waiting for seat assignment..." then
		updateResultText(getReadyPrompt(), "Neutral")
	end
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
			local failureFollowUpText = buildFailureFollowUpText()

			if args.result == "Heads" then
				updateResultText(`Heads! +$ {Util.FormatNumber(args.reward or 0, true)}`, "Heads")
				if (args.reward or 0) > 0 then
					playSfx("cashReward")
				end
			elseif (args.reward or 0) > 0 then
				updateResultText(`Tails! +$ {Util.FormatNumber(args.reward, true)}`, "Tails")
				playSfx("cashReward")
				maybeShowFailureFollowUpNotification(failureFollowUpText)
			else
				updateResultText("Tails! Streak reset.", "Tails")
				maybeShowFailureFollowUpNotification(failureFollowUpText)
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
	hideOnboardingPanel()
	if isSeated then
		SeatLabel.Text = args.seatState.seatId and tostring(args.seatState.seatId):gsub("^Seat", "Seat ") or "Seat --"
		if ResultLabel.Text == "Waiting for seat assignment..." then
			updateResultText(getReadyPrompt(), "Neutral")
		end
	end
end

function CoinFlipUi.UpdateOnboarding(_)
	hideOnboardingPanel()
	if currentSeatState then
		hideLegacySeatBillboards(currentSeatState)
	end
end

function CoinFlipUi.ObservedFlip(args)
	if args.userId == LocalPlayer.UserId then
		return
	end

	EffectSystem:PlayCoinFlipVisual(nil, nil, {
		seatId = args.seatId,
		result = args.result,
		coinId = args.equippedCoin,
		shouldFollowCamera = false,
		visualOptions = {
			isObserved = true,
			streak = args.streak or 0,
		},
		landedCallback = function()
			EffectSystem:PlayStreakMilestone(nil, nil, args.streakMilestone)
		end,
	})
end

return CoinFlipUi
