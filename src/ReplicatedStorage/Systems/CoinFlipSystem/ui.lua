local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Replicated = game:GetService("ReplicatedStorage")
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
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipSystem = SystemMgr.systems.CoinFlipSystem
local TableSeatSystem = SystemMgr.systems.TableSeatSystem
local EffectSystem = SystemMgr.systems.EffectSystem
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

local Hud = Elements:WaitForChild("CoinFlipHUD")
local CoinFlipMenu = Buttons:WaitForChild("CoinFlipMenu")
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
local currentRunSnapshot = {
	cash = 0,
	runData = {},
	nextCosts = {},
	derivedStats = {},
}
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
	hideOnboardingPanel()

	if currentSeatState then
		updateTableOverview(currentSeatState)
	end
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
	hideOnboardingPanel()
	uiController.HideUnitWhenPush(Hud)
	uiController.HideUnitWhenPush(CoinFlipMenu)
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
	if args.loadoutState then
		ClientData:SetOneData(dataKey.equippedCoin, args.loadoutState.equippedCoin)
		ClientData:SetOneData(dataKey.ownedCoins, args.loadoutState.ownedCoins)
		ClientData:SetOneData(dataKey.equippedDeskSetup, args.loadoutState.equippedDeskSetup)
		ClientData:SetOneData(dataKey.ownedDeskSetups, args.loadoutState.ownedDeskSetups)
	end
	if args.rebirthState then
		ClientData:SetOneData(dataKey.rebirth, args.rebirthState.rebirth)
		ClientData:SetOneData(dataKey.fateShards, args.rebirthState.fateShards)
		ClientData:SetOneData(dataKey.rebirthTree, args.rebirthState.rebirthTree)
	end
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
	EffectSystem:PlayCoinFlipVisual(nil, nil, {
		seatId = args.seatState and args.seatState.seatId,
		result = args.result,
		shouldFollowCamera = true,
		landedCallback = function()
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
	end
	setVisible(isSeated)
	if leaveButton then
		leaveButton.Visible = false
	end
	updateTableOverview(args and args.seatState)
	hideOnboardingPanel()
	if isSeated then
		SeatLabel.Text = args.seatState.seatId and `Seat {args.seatState.seatId}` or "Seat --"
		if ResultLabel.Text == "Waiting for seat assignment..." then
			updateResultText("Click FLIP, press Space, or press RT to flip.", "Neutral")
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
		shouldFollowCamera = false,
		visualOptions = {
			isObserved = true,
			streak = args.streak or 0,
		},
	})
end

return CoinFlipUi
