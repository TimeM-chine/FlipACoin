local Players = game:GetService("Players")
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

local Hud = Elements:WaitForChild("CoinFlipHUD")
local Content = Hud:WaitForChild("Content")
local StatsFrame = Content:WaitForChild("Stats")
local StatsListLayout = StatsFrame:FindFirstChildOfClass("UIListLayout")
local CashValue = StatsFrame:WaitForChild("CashCard"):WaitForChild("CashValue")
local ChanceValue = StatsFrame:WaitForChild("ChanceCard"):WaitForChild("ChanceValue")
local StreakValue = StatsFrame:WaitForChild("StreakCard"):WaitForChild("StreakValue")
local SpeedValue = StatsFrame:WaitForChild("SpeedCard"):WaitForChild("SpeedValue")
local SeatValue = StatsFrame:WaitForChild("SeatCard"):WaitForChild("SeatValue")
local ResultLabel = Content:WaitForChild("ResultLabel")
local FlipButton = Content:WaitForChild("FlipButton")
local UpgradeButtons = Content:WaitForChild("UpgradeButtons")
local UpgradeGridLayout = UpgradeButtons:WaitForChild("UIGridLayout")
local SpectatorFeed = Elements:WaitForChild("CoinFlipSpectatorFeed")
local SpectatorFeedLabel = SpectatorFeed:WaitForChild("Label")
local TableOverview = Elements:WaitForChild("CoinFlipTableOverview")
local TableOverviewTitle = TableOverview:WaitForChild("Title")
local TableOverviewSubtitle = TableOverview:WaitForChild("Subtitle")
local TableOverviewList = TableOverview:WaitForChild("List")
local TableOverviewEmptyLabel = TableOverview:WaitForChild("EmptyLabel")

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

local StatsCards = {
	{
		key = "cash",
		card = StatsFrame:WaitForChild("CashCard"),
		label = StatsFrame.CashCard:WaitForChild("Label"),
		value = CashValue,
	},
	{
		key = "chance",
		card = StatsFrame:WaitForChild("ChanceCard"),
		label = StatsFrame.ChanceCard:WaitForChild("Label"),
		value = ChanceValue,
	},
	{
		key = "streak",
		card = StatsFrame:WaitForChild("StreakCard"),
		label = StatsFrame.StreakCard:WaitForChild("Label"),
		value = StreakValue,
	},
	{
		key = "speed",
		card = StatsFrame:WaitForChild("SpeedCard"),
		label = StatsFrame.SpeedCard:WaitForChild("Label"),
		value = SpeedValue,
	},
	{
		key = "seat",
		card = StatsFrame:WaitForChild("SeatCard"),
		label = StatsFrame.SeatCard:WaitForChild("Label"),
		value = SeatValue,
	},
}

for layoutOrder, entry in ipairs(StatsCards) do
	entry.card.LayoutOrder = layoutOrder
end

local StatsGridLayout = StatsFrame:FindFirstChild("ResponsiveGridLayout")
if not StatsGridLayout then
	StatsGridLayout = Instance.new("UIGridLayout")
	StatsGridLayout.Name = "ResponsiveGridLayout"
	StatsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	StatsGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	StatsGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	StatsGridLayout.Parent = StatsFrame
end

if StatsListLayout and StatsListLayout.Parent then
	StatsListLayout:Destroy()
	StatsListLayout = nil
end

for index = 1, 8 do
	tableOverviewRows[index] = TableOverviewList:WaitForChild(string.format("SeatRow%02d", index))
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
		return entry.isOccupied and "full" or "hidden"
	end

	if entry.seatId == seatState.seatId then
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

	local resultConstraint = ensureTextConstraint(ResultLabel, "ResponsiveConstraint")
	ResultLabel.TextScaled = true
	ResultLabel.TextWrapped = true
	resultConstraint.MinTextSize = profile.isMobile and 10 or 16
	resultConstraint.MaxTextSize = profile.isMobile and 18 or 34
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

	if profile.isMobile then
		StatsFrame.Position = UDim2.fromScale(0.04, 0.08)
		StatsFrame.Size = UDim2.fromScale(0.5, 0.36)
		ResultLabel.Position = UDim2.fromScale(0.58, 0.09)
		ResultLabel.Size = UDim2.fromScale(0.36, 0.16)
		FlipButton.Position = UDim2.fromScale(0.04, 0.48)
		FlipButton.Size = UDim2.fromScale(0.43, 0.16)
		UpgradeButtons.Position = UDim2.fromScale(0.04, 0.7)
		UpgradeButtons.Size = UDim2.fromScale(0.92, 0.2)
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
	if leaveButton then
		local leaveConstraint = ensureTextConstraint(leaveButton, "ResponsiveConstraint")
		leaveButton.TextScaled = true
		leaveConstraint.MinTextSize = profile.isMobile and 12 or 11
		leaveConstraint.MaxTextSize = profile.isMobile and 22 or 18

		if profile.isMobile then
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

local function applyWorldBillboardStyle(billboard, variant, entry)
	local frame = billboard.Frame
	local seatLabel = frame.SeatLabel
	local statusLabel = frame.StatusLabel
	local nameLabel = frame.NameLabel
	local detailLabel = frame.DetailLabel
	local cashLabel = frame.CashLabel

	if variant == "hidden" then
		billboard.Enabled = false
		return
	end

	local billboardConfig = LayoutConfig.WorldBillboard
	billboard.Enabled = true
	if variant == "compact" then
		billboard.Size = UDim2.fromOffset(billboardConfig.CompactSize.X, billboardConfig.CompactSize.Y)
		billboard.StudsOffsetWorldSpace = billboardConfig.CompactOffset
		frame.BackgroundTransparency = 0.32
		seatLabel.TextSize = 10
		statusLabel.TextSize = 10
		nameLabel.TextSize = 14
		nameLabel.Position = UDim2.fromOffset(0, 16)
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		detailLabel.Visible = false
		cashLabel.Visible = false
		nameLabel.Text = entry.isOccupied and entry.displayName or "Open"
		statusLabel.Text = entry.isOccupied and (entry.statusText or "Ready") or "Open"
	else
		billboard.Size = UDim2.fromOffset(billboardConfig.FullSize.X, billboardConfig.FullSize.Y)
		billboard.StudsOffsetWorldSpace = billboardConfig.FullOffset
		frame.BackgroundTransparency = 0.18
		seatLabel.TextSize = 11
		statusLabel.TextSize = 11
		nameLabel.TextSize = 17
		nameLabel.Position = UDim2.fromOffset(0, 18)
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		detailLabel.Visible = entry.isOccupied
		cashLabel.Visible = entry.isOccupied
		nameLabel.Text = entry.displayName
		statusLabel.Text = entry.statusText or ""
	end

	seatLabel.Text = entry.seatId or ""
	statusLabel.TextColor3 = entry.statusColor or Color3.fromRGB(145, 221, 160)
	detailLabel.Text = entry.detailText or ""
	cashLabel.Text = entry.cashText or ""
end

local function applyWorldBillboardFocus(seatState)
	if not seatState or not seatState.seatDisplayEntries then
		return
	end

	for _, entry in ipairs(seatState.seatDisplayEntries) do
		local billboard = getSeatBillboard(entry.seatId)
		if billboard then
			applyWorldBillboardStyle(billboard, getWorldBillboardVariant(seatState, entry), entry)
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
	if not currentSeatId then
		return
	end

	TableSeatSystem.Server:RequestStand()
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
	local emptyLabel = panel.EmptyLabel
	local stroke = panel:FindFirstChildOfClass("UIStroke")

	panel.Position = UDim2.fromScale(profile.overviewPosition.X, profile.overviewPosition.Y)
	panel.Size = UDim2.fromScale(profile.overviewSize.X, profile.overviewSize.Y)
	applyClampConstraint(panel, "ResponsiveOverviewConstraint", profile.overviewMinSize, profile.overviewMaxSize)

	if title then
		title.TextSize = profile.isMobile and 12 or 18
	end
	if subtitle then
		subtitle.TextSize = profile.isMobile and 9 or 13
	end
	if stroke then
		stroke.Thickness = profile.isMobile and 1.1 or 1.4
	end
	if list then
		list.Position = UDim2.fromOffset(12, profile.isMobile and 48 or 62)
		list.Size = UDim2.new(1, profile.isMobile and -24 or -28, 1, profile.isMobile and -58 or -90)
		list.ScrollBarThickness = profile.isMobile and 3 or 6

		local layout = list:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.Padding = UDim.new(0, profile.overviewRowPadding)
		end
	end
	if emptyLabel then
		emptyLabel.TextSize = profile.isMobile and 10 or 14
		emptyLabel.Position = UDim2.fromOffset(12, profile.isMobile and 48 or 62)
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
			subtitle.Text = profile.isMobile
				and `{occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seated.`
				or `{occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seats occupied. Space flips, click upgrades.`
		else
			subtitle.Text = occupiedCount > 0
				and (profile.isMobile and `Watching {occupiedCount}.` or `Watching {occupiedCount} active seats in real time.`)
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
		row.SeatLabel.Text = entry.seatId or `Seat {index}`
		row.NameLabel.Text = entry.displayName or "Open Seat"
		row.StatusLabel.Text = entry.statusText or ""
		row.StatusLabel.TextColor3 = entry.statusColor or Color3.fromRGB(145, 221, 160)

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
		updateResultText("Approach a seat to reveal the flip HUD.", "Neutral")
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
	leaveButton.Parent = Content

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

	if spectatorFeed then
		spectatorFeed.Position =
			UDim2.fromScale(currentLayoutProfile.feedPosition.X, currentLayoutProfile.feedPosition.Y)
		spectatorFeed.Size = UDim2.fromScale(currentLayoutProfile.feedSize.X, currentLayoutProfile.feedSize.Y)
	end

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
	uiController.HideUnitWhenPush(Hud)
	local leaveButton = ensureLeaveButton()
	bindViewportLayout()

	uiController.SetButtonHoverAndClick(FlipButton, function()
		requestFlip()
	end)

	uiController.SetButtonHoverAndClick(leaveButton, function()
		requestStand()
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
end

function CoinFlipUi.FlipResolved(args)
	awaitingFlipResponse = false
	playCoinVisual(args.seatState and args.seatState.seatId, args.result, function()
		CoinFlipUi.SyncRunState(args)

		if args.result == "Heads" then
			updateResultText(`Heads! +$ {Util.FormatNumber(args.reward or 0, true)}`, "Heads")
		elseif (args.reward or 0) > 0 then
			updateResultText(`Tails! +$ {Util.FormatNumber(args.reward, true)} | Streak reset.`, "Tails")
		else
			updateResultText("Tails! Streak reset.", "Tails")
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
	leaveButton.Visible = isSeated == true
	updateTableOverview(args and args.seatState)
	if isSeated then
		SeatValue.Text = args.seatState.seatId or "--"
		if ResultLabel.Text == "Approach a seat to reveal the flip HUD." then
			updateResultText("Click FLIP to flip. Jump to leave the seat.", "Neutral")
		end
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
