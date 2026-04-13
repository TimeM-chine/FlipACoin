local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipSystem = SystemMgr.systems.CoinFlipSystem
local TableSeatSystem = SystemMgr.systems.TableSeatSystem
local VisualConfig = Presets.Visuals

local Hud = Elements:WaitForChild("CoinFlipHUD")
local Content = Hud:WaitForChild("Content")
local StatsFrame = Content:WaitForChild("Stats")
local CashValue = StatsFrame:WaitForChild("CashCard"):WaitForChild("CashValue")
local ChanceValue = StatsFrame:WaitForChild("ChanceCard"):WaitForChild("ChanceValue")
local StreakValue = StatsFrame:WaitForChild("StreakCard"):WaitForChild("StreakValue")
local SpeedValue = StatsFrame:WaitForChild("SpeedCard"):WaitForChild("SpeedValue")
local SeatValue = StatsFrame:WaitForChild("SeatCard"):WaitForChild("SeatValue")
local ResultLabel = Content:WaitForChild("ResultLabel")
local FlipButton = Content:WaitForChild("FlipButton")
local UpgradeButtons = Content:WaitForChild("UpgradeButtons")

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
local spectatorFeed
local spectatorFeedToken = 0
local tableOverview
local tableOverviewRows = {}
local visualFolder
local activeVisuals = {}
local currentSeatId
local currentFlipInterval = 1.8
local localFlipCooldownEndsAt = 0
local activeFlipRequestToken = 0
local awaitingFlipResponse = false
local resultFlashToken = 0
local defaultResultTextTransparency = ResultLabel.TextTransparency
local defaultResultStrokeTransparency = ResultLabel.TextStrokeTransparency

local function ensureVisualFolder()
	if visualFolder and visualFolder.Parent then
		return visualFolder
	end

	visualFolder = Workspace:FindFirstChild("CoinFlipClientVisuals")
	if not visualFolder then
		visualFolder = Instance.new("Folder")
		visualFolder.Name = "CoinFlipClientVisuals"
		visualFolder.Parent = Workspace
	end

	return visualFolder
end

local function getTableModel()
	return Workspace:FindFirstChild("CoinFlipTable")
end

local function getSeatAttachment(seatId)
	local tableModel = getTableModel()
	local attachmentsFolder = tableModel and tableModel:FindFirstChild("Attachments")
	local marker = attachmentsFolder and attachmentsFolder:FindFirstChild(`${seatId}Marker`)
	return marker and marker:FindFirstChildWhichIsA("Attachment")
end

local function getSeatPart(seatId)
	local tableModel = getTableModel()
	local seatsFolder = tableModel and tableModel:FindFirstChild("Seats")
	return seatsFolder and seatsFolder:FindFirstChild(seatId)
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

local function getFlipPositions(seatId)
	local tableModel = getTableModel()
	if not tableModel then
		return nil, nil, nil
	end

	local tableTop = tableModel:FindFirstChild("TableTop")
	local centerAttachment = tableTop and tableTop:FindFirstChild("TableCenterAttachment")
	if not tableTop or not centerAttachment then
		return nil, nil, nil
	end

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
		+ (tableNormal * ((VisualConfig.CoinSize.X * 0.5) + VisualConfig.CoinSurfaceGap))

	return startPos, endPos, tableNormal
end

local function createCoinFace(coin, face, text, backgroundColor, accentColor)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = `{face.Name}Face`
	surfaceGui.Face = face
	surfaceGui.AlwaysOnTop = false
	surfaceGui.LightInfluence = 1
	surfaceGui.CanvasSize = Vector2.new(256, 256)
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 240
	surfaceGui.Parent = coin

	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.BackgroundColor3 = backgroundColor
	badge.BorderSizePixel = 0
	badge.Position = UDim2.fromScale(0.5, 0.5)
	badge.Size = UDim2.fromScale(0.84, 0.84)
	badge.Parent = surfaceGui

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = badge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accentColor
	badgeStroke.Thickness = 4
	badgeStroke.Parent = badge

	local label = Instance.new("TextLabel")
	label.Name = "FaceLabel"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.82, 0.82)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = accentColor
	label.TextScaled = true
	label.Parent = badge

	local labelStroke = Instance.new("UIStroke")
	labelStroke.Color = Color3.fromRGB(255, 248, 221)
	labelStroke.Thickness = 2
	labelStroke.Transparency = 0.35
	labelStroke.Parent = label
end

local function createCoinPart(seatId)
	local coin = Instance.new("Part")
	coin.Name = `${seatId}CoinVisual`
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CanTouch = false
	coin.CastShadow = false
	coin.Material = VisualConfig.RimMaterial
	coin.Reflectance = VisualConfig.RimReflectance
	coin.Color = VisualConfig.RimColor
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = VisualConfig.CoinSize
	coin.Parent = ensureVisualFolder()

	createCoinFace(coin, Enum.NormalId.Top, "HEADS", VisualConfig.HeadsColor, VisualConfig.HeadsAccentColor)
	createCoinFace(coin, Enum.NormalId.Bottom, "TAILS", VisualConfig.TailsColor, VisualConfig.TailsAccentColor)

	return coin
end

local function createCoinShadow(seatId)
	local shadow = Instance.new("Part")
	shadow.Name = `${seatId}CoinShadow`
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanQuery = false
	shadow.CanTouch = false
	shadow.CastShadow = false
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Color = VisualConfig.ShadowColor
	shadow.Shape = Enum.PartType.Cylinder
	shadow.Transparency = VisualConfig.ShadowBaseTransparency
	shadow.Size = Vector3.new(VisualConfig.ShadowHeight, VisualConfig.CoinSize.Y, VisualConfig.CoinSize.Z)
	shadow.Parent = ensureVisualFolder()

	return shadow
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
	pulse.Parent = ensureVisualFolder()

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
	if visual.coin then
		visual.coin:Destroy()
	end
	if visual.shadow then
		visual.shadow:Destroy()
	end
end

local function playCoinVisual(seatId, result, landedCallback)
	if typeof(seatId) ~= "string" then
		if landedCallback then
			landedCallback()
		end
		return
	end

	local startPos, endPos, tableNormal = getFlipPositions(seatId)
	if not startPos or not endPos or not tableNormal then
		if landedCallback then
			landedCallback()
		end
		return
	end

	clearCoinVisual(seatId)

	local coin = createCoinPart(seatId)
	local shadow = createCoinShadow(seatId)

	local visual = {
		coin = coin,
		shadow = shadow,
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
		- (tableNormal * ((VisualConfig.CoinSize.X * 0.5) + VisualConfig.CoinSurfaceGap))
		+ (tableNormal * ((VisualConfig.ShadowHeight * 0.5) + VisualConfig.ShadowSurfaceGap))

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
			VisualConfig.ShadowHeight,
			VisualConfig.CoinSize.Y * shadowScale,
			VisualConfig.CoinSize.Z * shadowScale
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
				Size = Vector3.new(VisualConfig.ShadowHeight, VisualConfig.CoinSize.Y, VisualConfig.CoinSize.Z),
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
	if spectatorFeed then
		return spectatorFeed
	end

	spectatorFeed = Instance.new("TextLabel")
	spectatorFeed.Name = "CoinFlipSpectatorFeed"
	spectatorFeed.AnchorPoint = Vector2.new(0.5, 1)
	spectatorFeed.BackgroundColor3 = Color3.fromRGB(17, 20, 26)
	spectatorFeed.BackgroundTransparency = 0.15
	spectatorFeed.BorderSizePixel = 0
	spectatorFeed.Font = Enum.Font.GothamSemibold
	spectatorFeed.TextColor3 = Color3.fromRGB(245, 245, 245)
	spectatorFeed.TextScaled = true
	spectatorFeed.Visible = false
	spectatorFeed.Size = UDim2.new(0, 420, 0, 38)
	spectatorFeed.Position = UDim2.new(0.5, 0, 0.9, 0)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = spectatorFeed
	spectatorFeed.Parent = Elements
	return spectatorFeed
end

local function showSpectatorFeed(text)
	local label = ensureSpectatorFeed()
	spectatorFeedToken += 1
	local token = spectatorFeedToken
	label.Text = text
	label.Visible = true
	task.delay(2.2, function()
		if spectatorFeedToken ~= token then
			return
		end
		label.Visible = false
	end)
end

local function createOverviewRow(parent)
	local row = Instance.new("Frame")
	row.Name = "SeatRow"
	row.BackgroundColor3 = Color3.fromRGB(23, 27, 35)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 52)
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 214, 124)
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = row

	local seatLabel = Instance.new("TextLabel")
	seatLabel.Name = "SeatLabel"
	seatLabel.BackgroundTransparency = 1
	seatLabel.Font = Enum.Font.GothamBold
	seatLabel.TextColor3 = Color3.fromRGB(255, 233, 186)
	seatLabel.TextSize = 13
	seatLabel.TextXAlignment = Enum.TextXAlignment.Left
	seatLabel.Position = UDim2.fromOffset(10, 6)
	seatLabel.Size = UDim2.new(0, 64, 0, 14)
	seatLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(245, 247, 250)
	nameLabel.TextSize = 15
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.fromOffset(10, 20)
	nameLabel.Size = UDim2.new(1, -92, 0, 16)
	nameLabel.Parent = row

	local detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "DetailLabel"
	detailLabel.BackgroundTransparency = 1
	detailLabel.Font = Enum.Font.GothamSemibold
	detailLabel.TextColor3 = Color3.fromRGB(194, 204, 219)
	detailLabel.TextSize = 12
	detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.Position = UDim2.fromOffset(10, 36)
	detailLabel.Size = UDim2.new(1, -20, 0, 12)
	detailLabel.Parent = row

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.AnchorPoint = Vector2.new(1, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 13
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.Position = UDim2.new(1, -10, 0, 6)
	statusLabel.Size = UDim2.new(0, 84, 0, 14)
	statusLabel.Parent = row

	return row
end

local function ensureTableOverview()
	if tableOverview then
		return tableOverview
	end

	tableOverview = Instance.new("Frame")
	tableOverview.Name = "CoinFlipTableOverview"
	tableOverview.AnchorPoint = Vector2.new(1, 0)
	tableOverview.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	tableOverview.BackgroundTransparency = 0.08
	tableOverview.BorderSizePixel = 0
	tableOverview.Position = UDim2.new(1, -18, 0, 92)
	tableOverview.Size = UDim2.fromOffset(338, 278)
	tableOverview.Parent = Elements

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = tableOverview

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 214, 124)
	stroke.Thickness = 1.4
	stroke.Transparency = 0.38
	stroke.Parent = tableOverview

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "Table View"
	title.TextColor3 = Color3.fromRGB(255, 245, 213)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(14, 12)
	title.Size = UDim2.new(1, -28, 0, 20)
	title.Parent = tableOverview

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamSemibold
	subtitle.Text = "Live seats, streaks, and equipped coins."
	subtitle.TextColor3 = Color3.fromRGB(187, 198, 214)
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Position = UDim2.fromOffset(14, 36)
	subtitle.Size = UDim2.new(1, -28, 0, 16)
	subtitle.Parent = tableOverview

	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(14, 62)
	list.Size = UDim2.new(1, -28, 1, -76)
	list.Parent = tableOverview

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Font = Enum.Font.GothamSemibold
	emptyLabel.Text = "No one is seated yet. Walk to any open seat to start."
	emptyLabel.TextColor3 = Color3.fromRGB(194, 204, 219)
	emptyLabel.TextSize = 14
	emptyLabel.TextWrapped = true
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
	emptyLabel.TextYAlignment = Enum.TextYAlignment.Top
	emptyLabel.Position = UDim2.fromOffset(14, 62)
	emptyLabel.Size = UDim2.new(1, -28, 0, 40)
	emptyLabel.Parent = tableOverview

	return tableOverview
end

local function updateTableOverview(seatState)
	local panel = ensureTableOverview()
	local list = panel:FindFirstChild("List")
	local title = panel:FindFirstChild("Title")
	local subtitle = panel:FindFirstChild("Subtitle")
	local emptyLabel = panel:FindFirstChild("EmptyLabel")
	local seatDisplayEntries = seatState and seatState.seatDisplayEntries or {}
	local occupiedCount = 0
	local totalSeatCount = seatState and seatState.seatOrder and #seatState.seatOrder or #seatDisplayEntries

	for _, entry in ipairs(seatDisplayEntries) do
		if entry.isOccupied then
			occupiedCount += 1
		end
	end

	if title then
		title.Text = seatState and seatState.isSeated and `Seat {seatState.seatId} Live Table` or "Spectator View"
	end

	if subtitle then
		if seatState and seatState.isSeated then
			subtitle.Text = `${occupiedCount}/{math.max(totalSeatCount, occupiedCount)} seats occupied. Space flips, click upgrades.`
		else
			subtitle.Text = occupiedCount > 0 and `Watching {occupiedCount} active seats in real time.` or "The table is empty right now."
		end
	end

	if emptyLabel then
		emptyLabel.Visible = occupiedCount == 0
	end

	for index, entry in ipairs(seatDisplayEntries) do
		local row = tableOverviewRows[index]
		if not row then
			row = createOverviewRow(list)
			tableOverviewRows[index] = row
		end

		row.Visible = true
		row.SeatLabel.Text = entry.seatId or `Seat {index}`
		row.NameLabel.Text = entry.displayName or "Open Seat"
		row.StatusLabel.Text = entry.statusText or ""
		row.StatusLabel.TextColor3 = entry.statusColor or Color3.fromRGB(145, 221, 160)

		if entry.isOccupied then
			row.DetailLabel.Text = `Streak {entry.streak or 0} | {entry.coinName or "Rusty Penny"} | $ {Util.FormatNumber(entry.cash or 0, true)}`
		else
			row.DetailLabel.Text = "Open seat. Walk up and sit to start flipping."
		end
	end

	for index = #seatDisplayEntries + 1, #tableOverviewRows do
		tableOverviewRows[index].Visible = false
	end

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

function CoinFlipUi.Init()
	if initialized then
		return
	end
	initialized = true

	setVisible(false)
	uiController.HideUnitWhenPush(Hud)
	local leaveButton = ensureLeaveButton()

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
	CashValue.Text = `$ {Util.FormatNumber(args.cash or args.wins or 0, true)}`
	ChanceValue.Text = `${math.round((args.derivedStats.headsChance or 0) * 1000) / 10}%`
	StreakValue.Text = tostring(args.runData.currentStreak or 0)
	SpeedValue.Text = `${math.round((args.derivedStats.flipInterval or 0) * 100) / 100}s`
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
	else
		text = `{actorName} hit Tails at {args.seatId}`
	end

	playCoinVisual(args.seatId, args.result, function()
		showSpectatorFeed(text)
	end)
end

return CoinFlipUi
