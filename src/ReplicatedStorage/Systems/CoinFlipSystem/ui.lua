local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local Util = require(Replicated.modules.Util)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipSystem = SystemMgr.systems.CoinFlipSystem

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
local visualFolder
local activeVisuals = {}
local currentSeatId
local currentFlipInterval = 1.8
local localFlipCooldownEndsAt = 0

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

local function getFlipPositions(seatId)
	local tableModel = getTableModel()
	if not tableModel then
		return nil, nil
	end

	local tableTop = tableModel:FindFirstChild("TableTop")
	local centerAttachment = tableTop and tableTop:FindFirstChild("TableCenterAttachment")
	if not tableTop or not centerAttachment then
		return nil, nil
	end

	local seatAttachment = getSeatAttachment(seatId)
	local seatPart = getSeatPart(seatId)
	local startPos
	if seatAttachment then
		startPos = seatAttachment.WorldPosition + Vector3.new(0, 0.35, 0)
	elseif seatPart then
		startPos = seatPart.Position + Vector3.new(0, 1.6, 0)
	else
		return nil, nil
	end

	local centerPos = centerAttachment.WorldPosition
	local outward = startPos - centerPos
	if outward.Magnitude < 0.001 then
		outward = Vector3.new(1, 0, 0)
	else
		outward = outward.Unit
	end

	local endPos = centerPos + outward * 1.6
	endPos = Vector3.new(endPos.X, tableTop.Position.Y + (tableTop.Size.Y * 0.5) + 0.08, endPos.Z)

	return startPos, endPos
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
	if visual.part then
		visual.part:Destroy()
	end
end

local function playCoinVisual(seatId, result)
	if typeof(seatId) ~= "string" then
		return
	end

	local startPos, endPos = getFlipPositions(seatId)
	if not startPos or not endPos then
		return
	end

	clearCoinVisual(seatId)

	local coin = Instance.new("Part")
	coin.Name = `${seatId}CoinVisual`
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CanTouch = false
	coin.CastShadow = false
	coin.Material = Enum.Material.Metal
	coin.Color = Color3.fromRGB(215, 176, 64)
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.16, 0.72, 0.72)
	coin.CFrame = CFrame.new(startPos) * CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = ensureVisualFolder()

	local token = tostring(os.clock())
	local visual = {
		part = coin,
		token = token,
	}
	activeVisuals[seatId] = visual

	local startTime = os.clock()
	local duration = 0.42
	local arcHeight = math.max(2.4, (startPos - endPos).Magnitude * 0.3)
	local travel = endPos - startPos
	local finalRotation = CFrame.Angles(0, 0, math.rad(90))

	visual.connection = RunService.RenderStepped:Connect(function()
		local currentVisual = activeVisuals[seatId]
		if currentVisual ~= visual then
			if visual.connection then
				visual.connection:Disconnect()
			end
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local height = math.sin(alpha * math.pi) * arcHeight
		local position = startPos + (travel * alpha) + Vector3.new(0, height, 0)
		local spin = alpha * math.pi * 12
		coin.CFrame = CFrame.new(position) * CFrame.Angles(spin, 0, math.rad(90))

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil

		if result == "Tails" then
			coin.Color = Color3.fromRGB(124, 94, 82)
			coin.Material = Enum.Material.Slate
		end

		local settleTween = TweenService:Create(
			coin,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(endPos) * finalRotation,
			}
		)
		settleTween:Play()
		settleTween.Completed:Once(function()
			task.delay(0.35, function()
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
	if now < localFlipCooldownEndsAt then
		return
	end

	localFlipCooldownEndsAt = now + math.max(0.15, currentFlipInterval * 0.85)
	CoinFlipSystem.Server:RequestFlip()
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

local function setResultText(text)
	ResultLabel.Text = text
end

local function setVisible(isVisible)
	Hud.Visible = isVisible == true
	if not isVisible then
		setResultText("Approach a seat to reveal the flip HUD.")
	end
end

local function updateUpgradeButton(button, title, level, cost, isMaxed)
	button.Title.Text = title
	button.Level.Text = `Lv.{level}`
	button.Cost.Text = isMaxed and "MAX" or `$ {Util.FormatNumber(cost, true)}`
	button.AutoButtonColor = not isMaxed
end

function CoinFlipUi.Init()
	if initialized then
		return
	end
	initialized = true

	setVisible(false)
	uiController.HideUnitWhenPush(Hud)

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

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or not Hud.Visible then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space then
			requestFlip()
		end
	end)
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
		updateUpgradeButton(
			button,
			UpgradeTitles[upgradeKey],
			level,
			cost,
			cost == nil
		)
	end
end

function CoinFlipUi.FlipResolved(args)
	CoinFlipUi.SyncRunState(args)
	playCoinVisual(args.seatState and args.seatState.seatId, args.result)

	if args.result == "Heads" then
		setResultText(`Heads! +$ {Util.FormatNumber(args.reward or 0, true)}`)
	else
		setResultText("Tails! Streak reset.")
	end
end

function CoinFlipUi.SeatStateChanged(args)
	local isSeated = args and args.seatState and args.seatState.isSeated
	currentSeatId = isSeated and args.seatState.seatId or nil
	if not isSeated then
		localFlipCooldownEndsAt = 0
	end
	setVisible(isSeated)
	if isSeated then
		SeatValue.Text = args.seatState.seatId or "--"
		if ResultLabel.Text == "Approach a seat to reveal the flip HUD." then
			setResultText("Click FLIP or press Space.")
		end
	end
end

function CoinFlipUi.ObservedFlip(args)
	if args.userId == LocalPlayer.UserId then
		return
	end

	playCoinVisual(args.seatId, args.result)

	local actor = Players:GetPlayerByUserId(args.userId)
	local actorName = actor and actor.DisplayName or tostring(args.userId)
	local text
	if args.result == "Heads" then
		text = `{actorName} hit Heads at {args.seatId} for $ {Util.FormatNumber(args.reward or 0, true)}`
	else
		text = `{actorName} hit Tails at {args.seatId}`
	end

	showSpectatorFeed(text)
end

return CoinFlipUi
