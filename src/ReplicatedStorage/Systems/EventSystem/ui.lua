---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local EventPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local GameConfig = require(Replicated.configs.GameConfig)
local CardPresets = require(Replicated.Systems.CardSystem.Presets)
local Zone = require(Replicated.modules.Zone)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local EventFrame = Frames:WaitForChild("Event")
local MenuButtons = EventFrame:WaitForChild("Buttons")
local MenuFrames = EventFrame:WaitForChild("Frames")
local eventWinsText = EventFrame:WaitForChild("CandyValue"):WaitForChild("TextLabel")
local Elements = Main:WaitForChild("Elements")
local candyText = Elements:WaitForChild("candy")

---- logic variables ----
local eventTask = nil
local rotateTask
local nowMenu = nil
local santaBillboardGui = nil
local santaTimerLabel = nil
local santaTitleLabel = nil
local santaPrompt = nil
local santaIsPresent = false
local santaRemainingSeconds = EventPresets.SantaArrivalInterval
local highlight = Instance.new("Highlight")

function RotatePlate(plate)
	local ti = TweenInfo.new(3, Enum.EasingStyle.Linear)
	rotateTask = task.spawn(function()
		while true do
			local tween = TweenService:Create(plate, ti, { Rotation = plate.Rotation + 180 })
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

local EventUi = {}

function EventUi.Init(santaState)
	local event = ClientData:GetOneData(Keys.DataKey.event)
	eventWinsText.Text = Util.FormatNumber(event.wins)
	candyText.Text = Util.FormatNumber(event.wins)

	for _, frame in ipairs(MenuFrames:GetChildren()) do
		frame.Visible = false
	end
	SelectMenu("CandyShop")

	InitCandyShop()
	InitRobuxShop()
	InitWinsMultiplier()

	for _, btn in ipairs(MenuButtons:GetChildren()) do
		uiController.SetButtonHoverAndClick(btn, function()
			SelectMenu(btn.Name)
		end)
	end

	local container = workspace:WaitForChild("Boxes"):WaitForChild("Event"):WaitForChild("Container")
	local zone = Zone.new(container)
	zone.localPlayerEntered:Connect(function()
		uiController.OpenFrame("Event")
	end)

	-- 初始化Santa相关UI
	EventUi.SetSantaState(santaState)
	InitSantaUI()
end

function EventUi.BuyWinsMultiplier(args)
	local event = args.event
	local multiplierIndex = event.multiplierIndex
	local multiplierFolder = EventFrame:WaitForChild("Multiplier")
	for i = 1, 3 do
		local card = multiplierFolder:WaitForChild(i)
		card.Visible = i == multiplierIndex + 1
	end
end

function EventUi.AddWins(args)
	local event = args.event
	eventWinsText.Text = Util.FormatNumber(event.wins)
	candyText.Text = Util.FormatNumber(event.wins)
	uiController.SetUnitJump(candyText)

	if args.count > 0 then
		local WinsIcon = candyText
		local flyWins = PlayerGui:WaitForChild("Templates"):WaitForChild("flyCandy")

		local cloneCount = math.min(args.count, 20)
		local camera = game.Workspace.CurrentCamera
		local character = Players.LocalPlayer.Character
		if not character then
			return
		end

		local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
		if not HumanoidRootPart then
			return
		end

		local tipPosition, onScreen = camera:WorldToViewportPoint(HumanoidRootPart.Position)
		local targetPosition = WinsIcon.AbsolutePosition
		local targetSize = WinsIcon.AbsoluteSize

		-- fly from tipPosition to WinsIcon
		for i = 1, cloneCount do
			task.wait(0.1)
			local clone = flyWins:Clone()
			clone.Visible = true
			clone.AnchorPoint = Vector2.new(0.5, 0)
			clone.Position = UDim2.fromOffset(tipPosition.X, tipPosition.Y)
			clone.Size = UDim2.fromOffset(targetSize.X * 1.5, targetSize.Y * 1.5)
			clone.Parent = Main

			clone:TweenPosition(
				UDim2.fromOffset(tipPosition.X + math.random(-300, 300), tipPosition.Y - 80),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.05,
				true,
				function()
					clone:TweenPosition(
						UDim2.fromOffset(targetPosition.X + targetSize.X / 2, targetPosition.Y + 28),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true,
						function()
							clone:Destroy()
						end
					)
				end
			)
		end
	end
end

function InitCandyShop()
	local candyShopFrame = MenuFrames:FindFirstChild("CandyShop")
	local itemsListFrame = candyShopFrame:WaitForChild("Items")
	for i, item in ipairs(EventPresets.CandyShop) do
		local card = itemsListFrame:WaitForChild(i)
		card.icon.Image = Textures.GetIcon(item.item)
		card.Price.Text = Util.FormatNumber(item.price)
		card.ItemName.Text = item.name
		if item.desc then
			card.desc.Text = item.desc
		end
		uiController.SetButtonHoverAndClick(card, function()
			SystemMgr.systems.EventSystem.Server:TryBuyEventItem({
				itemIndex = i,
			})
		end)
	end

	local chestFrame = candyShopFrame:WaitForChild("Chest")
	local cards = {}
	for cardName, cardPreset in CardPresets.CardPacks[EventPresets.CardPack1].cards do
		table.insert(cards, {
			cardName = cardName,
			cashPerSec = cardPreset.cashPerSec,
		})
	end
	table.sort(cards, function(a, b)
		return a.cashPerSec > b.cashPerSec
	end)
	for i, cardInfo in ipairs(cards) do
		local card = chestFrame.Tools:WaitForChild(i)
		card.ToolImage.Image = Textures.Cards[cardInfo.cardName].icon
		card.Power.Text = `{Util.FormatNumber(cardInfo.cashPerSec)}/s`
	end

	for _, count in { 1, 5, 10 } do
		local buyBtn = chestFrame.Items:WaitForChild(`buy{count}`)
		buyBtn.Price.Text = Util.FormatNumber(EventPresets.ChestPrice * count)
		uiController.SetButtonHoverAndClick(buyBtn, function()
			SystemMgr.systems.EventSystem.Server:TryBuyEventChest({
				count = count,
			})
		end)
	end
end

function InitRobuxShop()
	local robuxShopFrame = MenuFrames:FindFirstChild("RobuxShop"):WaitForChild("ScrollingFrame")
	local chestFrame = robuxShopFrame:WaitForChild("Chest")

	local cards = {}
	for cardName, cardPreset in CardPresets.CardPacks[EventPresets.CardPack2].cards do
		table.insert(cards, {
			cardName = cardName,
			cashPerSec = cardPreset.cashPerSec,
		})
	end
	table.sort(cards, function(a, b)
		return a.cashPerSec > b.cashPerSec
	end)
	for i, cardInfo in ipairs(cards) do
		local card = chestFrame.Tools:WaitForChild(i)
		card.ToolImage.Image = Textures.Cards[cardInfo.cardName].icon
		card.Power.Text = `{Util.FormatNumber(cardInfo.cashPerSec)}/s`
	end

	for i, count in { 1, 5, 10 } do
		local buyBtn = chestFrame.Items:WaitForChild(`buy{count}`)
		buyBtn.Price.Text = Util.GetRobuxText(EcoPresets.Products.eventChest[i].price)
		uiController.SetButtonHoverAndClick(buyBtn, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.eventChest[i].productId)
		end)
	end

	local productFrame = robuxShopFrame:WaitForChild("Product")
	for i = 1, 5 do
		local card = productFrame:WaitForChild(`Tier{i}`)
		card.buy.Price.Text = Util.GetRobuxText(EcoPresets.Products.eventWins[i].price)
		card.value.Text = `{EcoPresets.Products.eventWins[i].count} Candies`
		uiController.SetButtonHoverAndClick(card.buy, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.eventWins[i].productId)
		end)
	end
end

function InitWinsMultiplier()
	local event = ClientData:GetOneData(Keys.DataKey.event)
	local multiplierIndex = event.multiplierIndex
	local multiplierFolder = EventFrame:WaitForChild("Multiplier")
	for i = 1, 3 do
		local card = multiplierFolder:WaitForChild(i)
		card.Visible = i == multiplierIndex + 1
		if i < multiplierIndex then
			continue
		end
		card.Price.Text = Util.GetRobuxText(EcoPresets.Products.eventWinsMultiplier[i].price)
		card.TextLabel.Text = EcoPresets.Products.eventWinsMultiplier[i].name
		uiController.SetButtonHoverAndClick(card, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.eventWinsMultiplier[i].productId)
		end)
	end
end

function SelectMenu(menuName)
	if nowMenu then
		MenuFrames:FindFirstChild(nowMenu).Visible = false
	end
	local frame = MenuFrames:FindFirstChild(menuName)
	frame.Visible = true
	nowMenu = frame.Name
end

function EventUi.SetSantaState(state)
	if not state then
		return
	end

	santaIsPresent = state.isPresent
	santaRemainingSeconds = state.remaining or EventPresets.SantaArrivalInterval
end

function InitSantaUI()
	local eventFolder = workspace:WaitForChild("Boxes"):WaitForChild("Event")
	local santaModel = eventFolder:WaitForChild("Santa")

	-- 获取BillboardGui
	santaBillboardGui = eventFolder:WaitForChild("BillboardGui")
	santaTimerLabel = santaBillboardGui:WaitForChild("Frame"):WaitForChild("TextLabel")
	santaTitleLabel = santaBillboardGui:WaitForChild("Frame"):WaitForChild("Title")

	-- 获取ProximityPrompt
	local primaryPart = santaModel.PrimaryPart or santaModel:FindFirstChildOfClass("BasePart")
	if primaryPart then
		santaPrompt = primaryPart:WaitForChild("ProximityPrompt")

		-- 监听ProximityPrompt触发
		santaPrompt.Triggered:Connect(function()
			SystemMgr.systems.EventSystem.Server:TryInteractWithSanta({})
		end)
	end

	-- 初始状态：显示倒计时
	santaBillboardGui.Enabled = true
	UpdateSantaTimer()
end

function UpdateSantaTimer()
	if not santaTimerLabel then
		return
	end

	if santaIsPresent then
		-- Santa在场，隐藏BillboardGui
		santaTitleLabel.Text = "Come to get candy!"
		santaTimerLabel.Visible = false
		highlight.Parent = workspace.Boxes:WaitForChild("Event"):WaitForChild("Santa"):WaitForChild("gift")
		uiController.CancelTimer({ textLabel = santaTimerLabel })
	else
		-- Santa不在，显示倒计时
		santaTitleLabel.Text = "Santa comes in"
		santaTimerLabel.Visible = true
		highlight.Parent = workspace.CurrentCamera
		uiController.CancelTimer({ textLabel = santaTimerLabel })
		local duration = santaRemainingSeconds or EventPresets.SantaArrivalInterval
		santaRemainingSeconds = duration
		uiController.AddTimerLabel({
			textLabel = santaTimerLabel,
			startTime = os.time(),
			duration = duration,
			format = "clock",
		})
	end
end

function EventUi.SantaArrive(args)
	santaIsPresent = true
	santaRemainingSeconds = EventPresets.SantaStayDuration
	UpdateSantaTimer()
end

function EventUi.SantaLeave(args)
	santaIsPresent = false
	santaRemainingSeconds = EventPresets.SantaArrivalInterval
	UpdateSantaTimer()
end

return EventUi
