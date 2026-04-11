---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local PetPresets = require(Replicated.Systems.PetSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local TradeFrame = Frames:WaitForChild("Trade")
local TradeScroll = TradeFrame:WaitForChild("ScrollingFrame")
local TradeComing = Frames:WaitForChild("TradeInComing")
local Trading = Frames:WaitForChild("Trading")
local myOffer = Trading:WaitForChild("LeftBar")
local myScroll = myOffer:WaitForChild("Pets")
local targetOffer = Trading:WaitForChild("RightBar")
local targetScroll = targetOffer:WaitForChild("Pets")
local tradeTimer = Trading:WaitForChild("timer")
local PetsFrame = Frames:WaitForChild("Pets")
local petsScroll = PetsFrame.Container.ScrollingFrame

---- logic variables ----
local textChangeTask = nil

local TradeUi = {}

function TradeUi.Init()
	InitTradeFrame()
	InitTradeComing()
	InitTrading()
end

function TradeUi.TradeComing(args)
	local from = args.from

	uiController.OpenFrame("TradeInComing")
	TradeComing.Description.Text = `{from.DisplayName} sent you a Trade Request. Do you accept?`
end

function TradeUi.StartTrading(args)
	uiController.OpenFrame("Trading")
	uiController.ClearScrollChildren(myScroll)
	uiController.ClearScrollChildren(targetScroll)
	myOffer.Ready.Visible = false
	targetOffer.Ready.Visible = false
	tradeTimer.Visible = false
	Trading.Buttons.Ready.TextLabel.Text = "Ready"

	for _, child in petsScroll:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Template" then
			Util.Clone(myScroll.Template, myScroll, function(card)
				card.Visible = true
				card.Name = child.Name
				card.name.Text = child.name.Text
				card.power.Text = child.power.Text
				local newVP = child.ViewportFrame:Clone()
				newVP.ZIndex = card.ZIndex + 2
				newVP.Parent = card

				uiController.SetButtonHoverAndClick(card, function()
					if card.Selected.Visible then
						card.Selected.Visible = false
						SystemMgr.systems.TradeSystem.Server:DeleteTradingItem({
							itemType = Keys.ItemType.pet,
							itemName = card.Name,
						})
					else
						card.Selected.Visible = true
						SystemMgr.systems.TradeSystem.Server:AddTradingItem({
							itemType = Keys.ItemType.pet,
							itemName = card.Name,
						})
					end
				end)
			end)
		end
	end
end

function TradeUi.CancelTrade(args)
	local cancelPlr = args.cancelPlr
	uiController.CloseFrame("Trading")
	uiController.SetNotification({
		text = `{cancelPlr.DisplayName} canceled the trade`,
		textColor = Color3.fromRGB(255, 0, 0),
	})
end

function TradeUi.PlayerReady(args)
	targetOffer.Ready.Visible = true
end

function TradeUi.PlayerUnready(args)
	if args.unReadyPlayer ~= LocalPlayer then
		targetOffer.Ready.Visible = false
	end
	if textChangeTask then
		task.cancel(textChangeTask)
	end
	tradeTimer.Visible = false
end

function TradeUi.TargetAddItem(args)
	local itemType = args.itemType
	local itemName = args.itemName
	local pet = args.pet
	Util.Clone(targetScroll.Template, targetScroll, function(card)
		card.Visible = true
		card.Name = itemType .. itemName
		card.name.Text = pet.name
		card.power.Text = "x" .. Util.FormatNumber(pet.power)
		card.ViewportFrame.Visible = true
		local petMesh = PetPresets.PetsList[pet.name].mesh:Clone()
		uiController.PetViewport(petMesh, card.ViewportFrame)
	end)
end

function TradeUi.TargetDeleteItem(args)
	local itemType = args.itemType
	local itemName = args.itemName
	local card = targetScroll:FindFirstChild(itemType .. itemName)
	if card then
		card:Destroy()
	end
end

function TradeUi.CompleteTrading(args)
	local tradingInfo = args.tradingInfo
	local from = tradingInfo.from
	local items
	if LocalPlayer == from then
		items = tradingInfo.toItems
	else
		items = tradingInfo.fromItems
	end

	for _, item in items do
		if item.itemType == Keys.ItemType.pet then
			uiController.SetNotification({
				text = `You received {item.pet.name}`,
				textColor = Color3.fromRGB(0, 255, 0),
			})
		end
	end

	uiController.CloseFrame("Trading")
end

function TradeUi.CountDown()
	tradeTimer.Visible = true
	if textChangeTask then
		task.cancel(textChangeTask)
	end

	textChangeTask = task.spawn(function()
		local text = "Trading"
		local i = 0
		while task.wait(0.3) do
			text = text .. "."
			tradeTimer.title.Text = text
			i += 1
			if i == 2 then
				i = 0
				text = "Trading"
			end
		end
	end)

	uiController.AddTimerLabel({
		textLabel = tradeTimer,
		duration = 5,
		callback = function()
			tradeTimer.Visible = false
		end,
	})
end

function InitTradeFrame()
	local template = TradeScroll.Template
	template.Visible = false

	local function CreatePlrCard(plr)
		Util.Clone(template, TradeScroll, function(card)
			card.Visible = true
			card.Name = plr.UserId
			card:WaitForChild("Name").Text = plr.Name
			card.LayoutOrder = plr.UserId

			card:FindFirstChild("Name").Text = string.format("@%s", plr.Name)
			card:FindFirstChild("Display").Text = plr.DisplayName
			card:FindFirstChild("Avatar").Image = Util.GetPlayerAvatar(plr.UserId)

			plr:GetAttributeChangedSignal("trade"):Connect(function()
				if plr:GetAttribute("trade") then
					card:FindFirstChild("Disable").Visible = false
				else
					card:FindFirstChild("Disable").Visible = true
				end
			end)

			uiController.SetButtonHoverAndClick(card, function()
				if card.Disable.Visible then
					return
				end
				SystemMgr.systems.TradeSystem.Server:RequestTrade({ targetPlr = plr })
			end)
		end)
	end

	for _, plr in Players:GetPlayers() do
		if plr == LocalPlayer then
			continue
		end
		CreatePlrCard(plr)
	end

	Players.PlayerAdded:Connect(function(plr)
		if plr == LocalPlayer then
			return
		end
		CreatePlrCard(plr)
	end)

	Players.PlayerRemoving:Connect(function(plr)
		local card = TradeScroll:FindFirstChild(plr.UserId)
		if card then
			card:Destroy()
		end
	end)
end

function InitTradeComing()
	uiController.SetButtonHoverAndClick(TradeComing.Accept, function()
		SystemMgr.systems.TradeSystem.Server:RespondTradeRequest({ respond = "accept" })
		uiController.CloseFrame("TradeInComing")
	end)

	uiController.SetButtonHoverAndClick(TradeComing.Decline, function()
		SystemMgr.systems.TradeSystem.Server:RespondTradeRequest({ respond = "decline" })
		uiController.CloseFrame("TradeInComing")
	end)
end

function InitTrading()
	myScroll.Template.Visible = false
	targetScroll.Template.Visible = false

	uiController.SetButtonHoverAndClick(Trading.Buttons.Cancel, function()
		SystemMgr.systems.TradeSystem.Server:CancelTrade()
		uiController.CloseFrame("Trading")
	end)

	Trading:GetPropertyChangedSignal("Visible"):Connect(function()
		if not Trading.Visible then
			SystemMgr.systems.TradeSystem.Server:CancelTrade()
		end
	end)

	local readyText = Trading.Buttons.Ready.TextLabel
	uiController.SetButtonHoverAndClick(Trading.Buttons.Ready, function()
		if readyText.Text == "Ready" then
			readyText.Text = "Unready"
			SystemMgr.systems.TradeSystem.Server:PlayerReady()
			myOffer.Ready.Visible = true
		elseif readyText.Text == "Unready" then
			readyText.Text = "Ready"
			SystemMgr.systems.TradeSystem.Server:PlayerUnready()
			tradeTimer.Visible = false
			myOffer.Ready.Visible = false
			if textChangeTask then
				task.cancel(textChangeTask)
			end
		end
	end)
end

return TradeUi
