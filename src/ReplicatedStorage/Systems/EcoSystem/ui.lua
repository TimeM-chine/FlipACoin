---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SocialService = game:GetService("SocialService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local Util = require(Replicated.modules.Util)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ItemType = Keys.ItemType
local Textures = require(Replicated.configs.Textures)
local EcoPresets = require(script.Parent.Presets)
local TableModule = require(Replicated.modules.TableModule)
local GameConfig = require(Replicated.configs.GameConfig)
local Icon = require(Replicated.Packages.topbarplus)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local Buttons = Main:WaitForChild("Buttons")
local Elements = Main:WaitForChild("Elements")
local StoreFrame = Frames:WaitForChild("Store")
local storeScroll = StoreFrame:WaitForChild("ScrollingFrame")
local cardPack1Frame = storeScroll:WaitForChild("5cardPack1")
local cardPack2Frame = storeScroll:WaitForChild("4cardPack2")
local uiController = require(Main:WaitForChild("uiController"))
local cashText = Elements:WaitForChild("cash")

---- logic variables ----
local Gradients = PlayerGui:WaitForChild("Gradients")

local EcoUi = {}

function EcoUi.Init()
	local storeIcon: any = Icon.new()
		:setName("Store")
		:setImageScale(0.8)
		:setImage(117630742937824, "Selected")
		:setImage(117630742937824, "Deselected")
		:autoDeselect(false)
	storeIcon.toggled:Connect(function(): ()
		if not GuiService.MenuIsOpen then
			if StoreFrame.Visible then
				uiController.CloseFrame("Store")
			else
				uiController.OpenFrame("Store")
			end
		end
	end)

	cashText.Text = `{Util.FormatNumber(ClientData:GetOneData(dataKey.wins))}`
	InitStoreFrame()
end

function EcoUi.UpdateWins(args)
	cashText.Text = `{Util.FormatNumber(ClientData:GetOneData(dataKey.wins))}`
	uiController.SetUnitJump(cashText)

	if args.count > 0 then
		local WinsIcon = cashText
		local flyWins = PlayerGui:WaitForChild("Templates"):WaitForChild("flyWins")

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

function EcoUi.GiveItem(args)
	local itemType = args.itemType
	local count = args.count
	local name = args.name

	local icon = Textures.GetIcon(args)

	uiController.AddReward({
		icon = icon,
		count = count,
	})

	SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, {
		musicName = "reward",
	})
end

function EcoUi.UpdateWinsStore()
	local wins = storeScroll:WaitForChild("Wins")
	local rebirth = ClientData:GetOneData(dataKey.rebirth) + 1
	for i = 1, 4 do
		local card = wins.List:WaitForChild(i)
		card.cost.TextLabel.Text = Util.GetRobuxText(EcoPresets.Products.wins[i].price)
		card.count.Text = Util.FormatNumber(EcoPresets.Products.wins[i].count * rebirth * rebirth) .. " Wins"
	end
end

function EcoUi.BuyLimitedPet(args)
	local petsStock = ClientData:GetOneData("limitedPets")
	local petName = args.petName
	local petInfo = EcoPresets.Products.limitedPets[petName]
	local LimitedPets = storeScroll:WaitForChild("LimitedPets")
	local Holder = LimitedPets:WaitForChild("Holder")

	if petInfo.InStore then
		local card = Holder:FindFirstChild(petName)
		if not card then
			return
		end
		local left = EcoPresets.Products.limitedPets[petName].limit - petsStock[petName]
		card:WaitForChild("Top"):WaitForChild("TextLabel").Text =
			`{left}/{EcoPresets.Products.limitedPets[petName].limit} LEFT!`
	end

	if petInfo.InWorkspace then
		local petModel = workspace:WaitForChild("LimitedPets"):FindFirstChild(petName)
		if not petModel then
			return
		end

		local UI = petModel:FindFirstChild("UI")
		if not UI then
			return
		end

		local Billboard = UI:FindFirstChild("Billboard")
		local limit = EcoPresets.Products.limitedPets[petName].limit
		local left = limit - petsStock[petName]
		Billboard:WaitForChild("Price").Text = `{left}/{limit} LEFT!`
	end
end

function EcoUi.BuyGamePass(args)
	local gamePassName = args.gamePassName
	local gamePassFrame = storeScroll:WaitForChild("3GamePasses")
	local card = gamePassFrame:WaitForChild(gamePassName, 10)
	if not card then
		return
	end
	card.buy.price.Text = "Owned"
	-- card.GpCost.TextColor3 = Textures.ButtonColors.green
	uiController.SetButtonHoverAndClick(card.buy, function() end)

	local boxModel = workspace:WaitForChild("Boxes"):WaitForChild(gamePassName, 3)
	if not boxModel then
		return
	end
	local prompt = boxModel:WaitForChild("Prompt")
	prompt:WaitForChild("price"):WaitForChild("TextLabel").Text = "Owned"
end

function EcoUi.BuyStarterPack(args)
	-- StarterPackButton.Visible = false
	uiController.CloseFrame("StarterPack")
end

function EcoUi.UpdatePotion(args)
	local potionName = args.potionName
	local count = args.count
	local potionsFrame = storeScroll:WaitForChild("Potions")
	local card = potionsFrame.List:FindFirstChild(potionName)
	if not card then
		return
	end
	card.UseBoost.TextLabel.Text = `Use({count})`
end

function EcoUi.UpdateGamePassesBar() end

local function InitGamePasses()
	local gamePassFrame = storeScroll:WaitForChild("3GamePasses")
	local gpTpl = gamePassFrame:WaitForChild("Template")
	gpTpl.Visible = false
	local gamePasses = ClientData:GetOneData(dataKey.gamePasses)
	for gamePassName, config in EcoPresets.GamePasses do
		if config.hideInShop then
			continue
		end
		Util.Clone(gpTpl, gamePassFrame, function(card)
			card.LayoutOrder = config.order
			card.UIGradient.Color = Gradients[config.gradient].Color
			card.Visible = true
			card.Name = gamePassName
			card.title.Text = config.title
			-- card.description.Text = config.description
			card.buy.price.Text = Util.GetRobuxText(config.price)
			card.icon.Image = Textures.GamePasses[gamePassName].icon

			if gamePassName == "vip" then
				uiController.AddRotateGradient(card.UIGradient)
			end

			if gamePasses[gamePassName] then
				card.buy.price.Text = "Owned"
				uiController.SetButtonHoverAndClick(card.buy, function() end)
			else
				uiController.SetButtonHoverAndClick(card.buy, function()
					MarketplaceService:PromptGamePassPurchase(LocalPlayer, config.gamePassId)
				end)
			end

			uiController.SetOneLineTip(card.icon, {
				text = config.description,
			})
		end)
	end
end

local function InitWins()
	local wins = storeScroll:WaitForChild("Wins")
	for i = 1, 4 do
		local card = wins.List:WaitForChild(i)
		uiController.SetButtonHoverAndClick(card.cost, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.wins[i].productId)
		end)
	end
	EcoUi.UpdateWinsStore()
end

local function InitCodes()
	local codes = storeScroll:WaitForChild("Codes")
	uiController.SetButtonHoverAndClick(codes.Holder.Redeem, function()
		SystemMgr.systems.EcoSystem.Server:RedeemCode({ code = codes.Holder.Enter.Text })
	end)
end

local function InitPotions()
	local potionsFrame = storeScroll:WaitForChild("Potions")
	local potionTpl = potionsFrame:WaitForChild("Template")
	potionTpl.Visible = false
	local potions = ClientData:GetOneData(dataKey.potions)
	for potionName, config in EcoPresets.Products.potions do
		Util.Clone(potionTpl, potionsFrame, function(card)
			card.Visible = true
			card.Name = potionName
			local own = potions[potionName] or 0
			card.title.Text = config.title
			card.description.Text = config.description
			card.use.TextLabel.Text = `Use({own})`
			card.robux.price.Text = Util.GetRobuxText(config.price)
			card.Content.UIGradient.Color = Gradients[config.gradientColor].Color
			card.LayoutOrder = config.order
			card.icon.Image = Textures.Potions[potionName].icon

			uiController.SetButtonHoverAndClick(card.robux, function()
				MarketplaceService:PromptProductPurchase(LocalPlayer, config.productId)
			end)

			card.wins.price.Text = `{Util.FormatNumber(config.winsPrice)}`
			uiController.SetButtonHoverAndClick(card.wins, function()
				SystemMgr.systems.EcoSystem.Server:BuyPotionByWins({ potionName = potionName, count = 1 })
			end)

			uiController.SetButtonHoverAndClick(card.use, function()
				SystemMgr.systems.PotionSystem.Server:UsePotion({ potionId = potionName })
			end)
		end)
	end
end

function InitStoreFrame()
	---- [[ side bar ]] ----
	-- local sideBar = StoreFrame:WaitForChild("SideBar")

	-- for _, button in ipairs(sideBar:GetChildren()) do
	-- 	if button:IsA("TextButton") then
	-- 		uiController.SetButtonHoverAndClick(button, function()
	-- 			local frame = storeScroll:FindFirstChild(button.Name)
	-- 			if frame then
	-- 				storeScroll.CanvasPosition = Vector2.new(
	-- 					storeScroll.CanvasPosition.X + frame.AbsolutePosition.X - storeScroll.AbsolutePosition.X,
	-- 					0
	-- 				)
	-- 			end
	-- 		end)
	-- 	end
	-- end

	-- InitFeatured()
	InitGamePasses()
	-- InitWins()
	-- InitCodes()
	-- InitLimitedPets()
	-- InitSidePassButtons()
	-- InitSingleGamePass()
	-- InitCardPacks()
	-- InitPotions()
	-- InitStarterPack()
end

function InitAds()
	task.spawn(function()
		local Ads = workspace:WaitForChild("Ads")

		for _, model in Ads:GetChildren() do
			model:WaitForChild("surface"):WaitForChild("SurfaceGui"):WaitForChild("icon")
		end
		while true do
			local passes = EcoPresets.GamePasses
			local gamePasses = ClientData:GetOneData(dataKey.gamePasses)
			for _, model in Ads:GetChildren() do
				local randomPass
				if gamePasses[model.Name] then
					randomPass = model.Name
				else
					randomPass = TableModule.Keys(passes)[math.random(1, TableModule.Length(passes))]
				end
				local pass = passes[randomPass]
				local surface = model:WaitForChild("surface", 5)
				if not surface then
					continue
				end
				local surfaceGui = surface:WaitForChild("SurfaceGui")
				surfaceGui.Container.Purchase.Price.Text = Util.GetRobuxText(pass.price)
				surfaceGui.icon.ImageLabel.Image = Textures.GamePasses[randomPass].icon
				surfaceGui.Container.Info.Text = pass.description
				surfaceGui.Container:FindFirstChild("Name").Text = pass.title
				if gamePasses[randomPass] then
					surfaceGui.Container.Purchase.Price.Text = "Owned"
					uiController.SetButtonHoverAndClick(surfaceGui.Container.Purchase, function() end)
				else
					uiController.SetButtonHoverAndClick(surfaceGui.Container.Purchase, function()
						MarketplaceService:PromptGamePassPurchase(LocalPlayer, pass.gamePassId)
					end)
				end
			end
			task.wait(60)
		end
	end)
end

function InitCardPacks()
	local CardPresets = require(Replicated.Systems.CardSystem.Presets)
	local pack1Preset = EcoPresets.Products.cardPacks.cardPack1
	local cards1Preset = CardPresets.CardPacks[pack1Preset.name]
	cardPack1Frame.packName.Text = pack1Preset.name
	cardPack1Frame.packIcon.Image = Textures.CardPacks[pack1Preset.name].icon
	for i = 1, 3 do
		local buyBtn = cardPack1Frame:WaitForChild("buy" .. i)
		uiController.SetButtonHoverAndClick(buyBtn, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, pack1Preset["buy" .. i].productId)
		end)
		buyBtn.price.Text = Util.GetRobuxText(pack1Preset["buy" .. i].price)
	end

	local pack1Scroll = cardPack1Frame:WaitForChild("ScrollingFrame")
	local pack1Tpl = pack1Scroll:WaitForChild("Template")
	pack1Tpl.Visible = false
	for _, card in cards1Preset.cards do
		Util.Clone(pack1Tpl, pack1Scroll, function(clone: ImageLabel)
			local cardPreset = CardPresets.CardsList[card.name]
			clone.Visible = true
			clone.Image = Textures.Cards[card.name].icon
			clone.Name = card.name
			clone.LayoutOrder = cardPreset.cashPerSec
			clone.cashPerSec.Text = `{Util.FormatNumber(cardPreset.cashPerSec)}/s`
		end)
	end

	local pack2Preset = EcoPresets.Products.cardPacks.cardPack2
	local cards2Preset = CardPresets.CardPacks[pack2Preset.name]
	cardPack2Frame.packName.Text = pack2Preset.name
	cardPack2Frame.packIcon.Image = Textures.CardPacks[pack2Preset.name].icon
	for i = 1, 4 do
		local buyBtn = cardPack2Frame:WaitForChild("buy" .. i)
		uiController.SetButtonHoverAndClick(buyBtn, function()
			MarketplaceService:PromptProductPurchase(LocalPlayer, pack2Preset["buy" .. i].productId)
		end)
		buyBtn.price.Text = Util.GetRobuxText(pack2Preset["buy" .. i].price)
	end

	local pack2Scroll = cardPack2Frame:WaitForChild("ScrollingFrame")
	local pack2Tpl = pack2Scroll:WaitForChild("Template")
	pack2Tpl.Visible = false
	for _, card in cards2Preset.cards do
		Util.Clone(pack2Tpl, pack2Scroll, function(clone: ImageLabel)
			clone.Visible = true
			local cardPreset = CardPresets.CardsList[card.name]
			clone.Image = Textures.Cards[card.name].icon
			clone.Name = card.name
			clone.LayoutOrder = cardPreset.cashPerSec
			clone.cashPerSec.Text = `{Util.FormatNumber(cardPreset.cashPerSec)}/s`
		end)
	end
end

return EcoUi
