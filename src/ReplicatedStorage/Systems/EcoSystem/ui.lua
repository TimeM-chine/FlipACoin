local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local AdService = game:GetService("AdService")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local EcoPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local Icon = require(Replicated.Packages.topbarplus)

local dataKey = Keys.DataKey
local PANEL_COLOR = Color3.fromRGB(5, 5, 6)
local CREAM_COLOR = Color3.fromRGB(255, 244, 220)
local BUY_BUTTON_COLOR = Color3.fromRGB(198, 158, 68)
local OWNED_BUTTON_COLOR = Color3.fromRGB(88, 92, 98)
local EQUIP_BUTTON_COLOR = Color3.fromRGB(57, 118, 180)
local EQUIPPED_BUTTON_COLOR = Color3.fromRGB(61, 148, 87)
local DISABLED_BUTTON_COLOR = Color3.fromRGB(72, 72, 76)
local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 218, 110)
local IDLE_STROKE_COLOR = Color3.fromRGB(84, 68, 42)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Buttons = Main:WaitForChild("Buttons")
local Frames = Main:WaitForChild("Frames")
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipMenu = Buttons:WaitForChild("CoinFlipMenu")
local ShopFrame = Frames:WaitForChild("Shop")
local InventoryFrame = Frames:WaitForChild("Inventory")

local ShopBody = ShopFrame:WaitForChild("Body")
local ShopTabs = ShopBody:WaitForChild("Tabs")
local ShopBoostTab = ShopTabs:FindFirstChild("BoostTab") or ShopTabs:FindFirstChild("RobuxTab")
local ShopItems = ShopBody:WaitForChild("Items")
local ShopPreview = ShopBody:WaitForChild("Preview")
local ShopItemTemplate = ShopItems:WaitForChild("Template")

local InventoryBody = InventoryFrame:WaitForChild("Body")
local InventoryTabs = InventoryBody:WaitForChild("Tabs")
local InventoryItems = InventoryBody:WaitForChild("Items")
local InventoryLoadout = InventoryBody:WaitForChild("Loadout")
local InventoryItemTemplate = InventoryItems:WaitForChild("Template")

local EcoUi = {}
local initialized = false
local currentCash = 0
local currentLoadoutState = {}
local currentGamePasses = {}
local currentRewardedAdState = {}
local selectedShopCategory = "coin"
local selectedInventoryCategory = "coin"
local selectedTabBackgroundColor = Color3.fromRGB(198, 158, 68)
local idleTabBackgroundColor = PANEL_COLOR
local selectedTabTextColor = Color3.fromRGB(36, 32, 26)
local idleTabTextColor = CREAM_COLOR
local suppressTopbarToggle = false
local shopTopbarIcon
local inventoryTopbarIcon
local boostsTopbarIcon
local selectedShopItemKeys = {}
local generatedShopCards = {}
local generatedInventoryCards = {}
local rewardedAdAvailabilityToken = 0

local function getGeneratedCardKey(category, itemId)
	return `{category}:{itemId}`
end

local function getOwnedItems(category)
	if category == "coin" then
		return currentLoadoutState.ownedCoins or {}
	end
	if category == "desk" then
		return currentLoadoutState.ownedDeskSetups or {}
	end
	if category == "chair" then
		return currentLoadoutState.ownedChairs or {}
	end

	return {}
end

local function getEquippedItem(category)
	if category == "coin" then
		return currentLoadoutState.equippedCoin or EcoPresets.LoadoutDefaults.equippedCoin
	end
	if category == "desk" then
		return currentLoadoutState.equippedDeskSetup or EcoPresets.LoadoutDefaults.equippedDeskSetup
	end
	if category == "chair" then
		return currentLoadoutState.equippedChair or EcoPresets.LoadoutDefaults.equippedChair
	end

	return ""
end

local function getOrderedBoostItems()
	local items = {}
	table.insert(items, {
		itemType = "rewardedAd",
		key = "adCash2x5m",
		order = 0,
		displayName = "Watch Ad: 2x Cash 5m",
		description = "Watch a rewarded video to use a 2x Cash potion instantly",
		configured = true,
	})
	for productKey, productInfo in pairs(EcoPresets.Products.flipACoin) do
		table.insert(items, {
			itemType = "product",
			key = productKey,
			order = productInfo.order or 100,
			displayName = productInfo.productName,
			description = productInfo.description,
			price = productInfo.price,
			storeId = productInfo.productId,
			configured = typeof(productInfo.productId) == "number" and productInfo.productId > 0,
		})
	end
	for gamePassName, gamePassInfo in pairs(EcoPresets.GamePasses) do
		if not gamePassInfo.hideInShop then
			table.insert(items, {
				itemType = "gamePass",
				key = gamePassName,
				order = 100 + (gamePassInfo.order or 100),
				displayName = gamePassInfo.title,
				description = gamePassInfo.description,
				price = gamePassInfo.price,
				storeId = gamePassInfo.gamePassId,
				configured = typeof(gamePassInfo.gamePassId) == "number" and gamePassInfo.gamePassId > 0,
			})
		end
	end

	table.sort(items, function(a, b)
		return a.order < b.order
	end)
	return items
end

local function formatSeconds(seconds)
	local remaining = math.max(math.ceil(seconds or 0), 0)
	local minutes = math.floor(remaining / 60)
	local secondRemainder = remaining % 60
	local paddedSeconds = secondRemainder < 10 and `0{secondRemainder}` or tostring(secondRemainder)
	return `{minutes}:{paddedSeconds}`
end

local function getRewardedAdCooldownRemaining()
	if typeof(currentRewardedAdState.cooldownEndsAt) ~= "number" then
		return currentRewardedAdState.cooldownRemaining or 0
	end

	return math.max(currentRewardedAdState.cooldownEndsAt - os.time(), 0)
end

local function formatMultiplier(multiplier)
	return `x{math.round((multiplier or 1) * 100) / 100}`
end

local function formatLuck(luckBonus)
	return `+{math.round((luckBonus or 0) * 1000) / 10}% Luck`
end

local function describeItemStats(stats)
	return `{formatMultiplier(stats and stats.coinMultiplier or 1)} Cash | {formatLuck(stats and stats.luckBonus or 0)}`
end

local function setTextIfPresent(parent, childName, text)
	local label = parent:FindFirstChild(childName)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function setButtonText(button, text, isEnabled, backgroundColor)
	button.Text = text
	button.AutoButtonColor = isEnabled
	button.Active = isEnabled
	if backgroundColor then
		button.BackgroundColor3 = backgroundColor
	end
end

local function setCardIcon(card, icon)
	local holder = card:FindFirstChild("Icon") or card:FindFirstChild("Art")
	if not holder then
		return
	end

	local imageObject = holder:FindFirstChild("Image")
	if holder:IsA("ImageLabel") or holder:IsA("ImageButton") then
		imageObject = holder
	end
	if imageObject and (imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton")) then
		imageObject.Image = icon
		imageObject.Visible = icon ~= ""
	end
end

local function getItemIcon(category, item)
	if category == "boost" then
		return Textures.GetFlipACoinItemIcon(item.itemType, item.key)
	end

	return Textures.GetFlipACoinItemIcon(category, item.id)
end

local function getShopSelectionKey(category, item)
	if category == "boost" then
		return `{item.itemType}:{item.key}`
	end

	return item.id
end

local function getSelectedShopItem(items)
	local selectedKey = selectedShopItemKeys[selectedShopCategory]
	for _, item in ipairs(items) do
		if getShopSelectionKey(selectedShopCategory, item) == selectedKey then
			return item
		end
	end

	local firstItem = items[1]
	if firstItem then
		selectedShopItemKeys[selectedShopCategory] = getShopSelectionKey(selectedShopCategory, firstItem)
	end
	return firstItem
end

local function setPreviewIcon(icon)
	local holder = ShopPreview:FindFirstChild("Icon") or ShopPreview.PreviewScene:FindFirstChild("Icon")
	if holder and (holder:IsA("ImageLabel") or holder:IsA("ImageButton")) then
		holder.Image = icon
		holder.Visible = icon ~= ""
	end
end

local function clearGeneratedCards(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:GetAttribute("GeneratedItemCard") == true then
			child:Destroy()
		elseif child:IsA("GuiObject") and child.Name ~= "Template" then
			child.Visible = false
		end
	end
end

local function createGeneratedCard(template, container, layoutOrder)
	local card = template:Clone()
	card:SetAttribute("GeneratedItemCard", true)
	card.LayoutOrder = layoutOrder
	card.Visible = true
	card.Parent = container
	return card
end

local function updateCardSelection(card, isSelected)
	local viewBorder = card:FindFirstChild("viewBorder")
	if viewBorder then
		local stroke = viewBorder:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = isSelected and SELECTED_STROKE_COLOR or IDLE_STROKE_COLOR
			stroke.Transparency = isSelected and 0 or 0.2
		end
	end
end

local function updateShopPreview(item, ownedItems)
	if not item then
		ShopPreview.Title.Text = "Select Item"
		ShopPreview.Equipped.Text = ""
		ShopPreview.TotalBonus.Text = ""
		setPreviewIcon("")
		return
	end

	setPreviewIcon(getItemIcon(selectedShopCategory, item))
	ShopPreview.Title.Text = item.displayName
	if selectedShopCategory == "boost" then
		local isOwnedPass = item.itemType == "gamePass" and currentGamePasses[item.key] == true
		ShopPreview.Equipped.Text = item.description or "Premium boost"
		if isOwnedPass then
			ShopPreview.TotalBonus.Text = "Owned"
		elseif item.configured then
			ShopPreview.TotalBonus.Text = item.price and Util.GetRobuxText(item.price) or "Robux"
		else
			ShopPreview.TotalBonus.Text = "Set ID"
		end
		return
	end

	local isOwned = ownedItems[item.id] == true
	local priceText = item.cost == 0 and "Starter" or `$ {Util.FormatNumber(item.cost, true)}`
	ShopPreview.Equipped.Text = `{item.rarity} | {item.role}`
	ShopPreview.TotalBonus.Text = `{describeItemStats(item.stats)} | {isOwned and "Owned" or priceText}`
end

local function playSfx(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return
	end

	SystemMgr.systems.MusicSystem:PlayLocalSfx({
		musicName = soundName,
	})
end

local function updateTabButton(button, isSelected)
	button.AutoButtonColor = not isSelected
	button.BackgroundTransparency = isSelected and 0.08 or 0.26
	button.BackgroundColor3 = isSelected and selectedTabBackgroundColor or idleTabBackgroundColor
	button.TextColor3 = isSelected and selectedTabTextColor or idleTabTextColor
end

local function resetScrollPosition(scrollingFrame)
	if scrollingFrame:IsA("ScrollingFrame") then
		scrollingFrame.CanvasPosition = Vector2.zero
	end
end

local function setTopbarIconSelected(icon, isSelected)
	if not icon then
		return
	end

	suppressTopbarToggle = true
	if isSelected then
		icon:select()
	else
		icon:deselect()
	end
	suppressTopbarToggle = false
end

local function refreshTopbarIconState()
	setTopbarIconSelected(shopTopbarIcon, ShopFrame.Visible and selectedShopCategory ~= "boost")
	setTopbarIconSelected(boostsTopbarIcon, ShopFrame.Visible and selectedShopCategory == "boost")
	setTopbarIconSelected(inventoryTopbarIcon, InventoryFrame.Visible)
end

local function updateLoadoutSummary()
	local equippedCoin = getEquippedItem("coin")
	local equippedDesk = getEquippedItem("desk")
	local equippedChair = getEquippedItem("chair")
	local equippedCoinName = EcoPresets.GetShopItemDisplayName("coin", equippedCoin)
	local equippedDeskName = EcoPresets.GetShopItemDisplayName("desk", equippedDesk)
	local equippedChairName = EcoPresets.GetShopItemDisplayName("chair", equippedChair)
	local bonuses = EcoPresets.BuildLoadoutBonuses(equippedCoin, equippedDesk, equippedChair, currentGamePasses)
	InventoryLoadout.CoinSlot.Value.Text = equippedCoinName
	InventoryLoadout.DeskSlot.Value.Text = equippedDeskName
	InventoryLoadout.ChairSlot.Value.Text = equippedChairName
	InventoryLoadout.TotalBonus.Text = describeItemStats(bonuses)
end

local function updateShopPanel()
	updateTabButton(ShopTabs.CoinTab, selectedShopCategory == "coin")
	updateTabButton(ShopTabs.DeskTab, selectedShopCategory == "desk")
	updateTabButton(ShopTabs.ChairTab, selectedShopCategory == "chair")
	if ShopBoostTab and ShopBoostTab:IsA("TextButton") then
		updateTabButton(ShopBoostTab, selectedShopCategory == "boost")
	end

	local ownedItems = getOwnedItems(selectedShopCategory)
	local items = selectedShopCategory == "boost" and getOrderedBoostItems()
		or (EcoPresets.GrowthShopItems[selectedShopCategory] or {})
	local selectedItem = getSelectedShopItem(items)
	clearGeneratedCards(ShopItems)
	generatedShopCards = {}

	for index, item in ipairs(items) do
		local card = createGeneratedCard(ShopItemTemplate, ShopItems, index)
		local itemKey = getShopSelectionKey(selectedShopCategory, item)
		generatedShopCards[getGeneratedCardKey(selectedShopCategory, itemKey)] = card
		updateCardSelection(card, selectedItem and itemKey == getShopSelectionKey(selectedShopCategory, selectedItem))
		setCardIcon(card, getItemIcon(selectedShopCategory, item))
		setTextIfPresent(card, "Name", item.displayName)
		card.Price.Visible = false
		if selectedShopCategory == "boost" then
			card.Bonus.Text = item.description or "Premium boost"
			card.Price.Text = item.price and Util.GetRobuxText(item.price) or "Robux"
			if item.itemType == "rewardedAd" then
				card.Price.Text = "Free"
				local cooldownRemaining = getRewardedAdCooldownRemaining()
				if currentRewardedAdState.available == true then
					setButtonText(card.BuyButton, "Watch", true, BUY_BUTTON_COLOR)
				elseif cooldownRemaining > 0 then
					setButtonText(
						card.BuyButton,
						`Wait {formatSeconds(cooldownRemaining)}`,
						false,
						DISABLED_BUTTON_COLOR
					)
				else
					setButtonText(card.BuyButton, "Unavailable", false, DISABLED_BUTTON_COLOR)
				end
			elseif item.itemType == "gamePass" and currentGamePasses[item.key] == true then
				setButtonText(card.BuyButton, "Owned", false, OWNED_BUTTON_COLOR)
			elseif item.configured then
				setButtonText(
					card.BuyButton,
					item.price and Util.GetRobuxText(item.price) or "Robux",
					true,
					BUY_BUTTON_COLOR
				)
			else
				setButtonText(card.BuyButton, "Set ID", false, DISABLED_BUTTON_COLOR)
			end
		else
			local isOwned = ownedItems[item.id] == true
			local priceText = item.cost == 0 and "Free" or `$ {Util.FormatNumber(item.cost, true)}`
			card.Bonus.Text = `{item.rarity} | {item.role} | {describeItemStats(item.stats)}`
			card.Price.Text = priceText
			if isOwned then
				setButtonText(card.BuyButton, "Owned", false, OWNED_BUTTON_COLOR)
			else
				setButtonText(
					card.BuyButton,
					priceText,
					currentCash >= item.cost,
					currentCash >= item.cost and BUY_BUTTON_COLOR or DISABLED_BUTTON_COLOR
				)
			end
		end

		local selectButton = card:FindFirstChild("SelectButton")
		if selectButton and selectButton:IsA("GuiButton") then
			uiController.SetButtonHoverAndClick(selectButton, function()
				selectedShopItemKeys[selectedShopCategory] = getShopSelectionKey(selectedShopCategory, item)
				updateShopPanel()
			end)
		end
		uiController.SetButtonHoverAndClick(card.BuyButton, function()
			selectedShopItemKeys[selectedShopCategory] = getShopSelectionKey(selectedShopCategory, item)
			if selectedShopCategory == "boost" then
				if item.itemType == "rewardedAd" then
					if currentRewardedAdState.available == true then
						SystemMgr.systems.EcoSystem.Server:RequestRewardedCashPotionAd()
					end
					updateShopPanel()
					return
				end
				if not item.configured then
					updateShopPanel()
					return
				end
				if item.itemType == "product" then
					MarketplaceService:PromptProductPurchase(LocalPlayer, item.storeId)
				elseif item.itemType == "gamePass" and not currentGamePasses[item.key] then
					MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.storeId)
				end
			elseif not ownedItems[item.id] then
				SystemMgr.systems.EcoSystem.Server:RequestShopPurchase({
					category = selectedShopCategory,
					itemId = item.id,
				})
			end
			updateShopPanel()
		end)
	end

	updateShopPreview(selectedItem, ownedItems)
	updateLoadoutSummary()
end

local function updateInventoryPanel()
	updateTabButton(InventoryTabs.CoinTab, selectedInventoryCategory == "coin")
	updateTabButton(InventoryTabs.DeskTab, selectedInventoryCategory == "desk")
	updateTabButton(InventoryTabs.ChairTab, selectedInventoryCategory == "chair")
	updateTabButton(InventoryTabs.OtherTab, selectedInventoryCategory == "other")

	local ownedItems = getOwnedItems(selectedInventoryCategory)
	local equippedItem = getEquippedItem(selectedInventoryCategory)
	local visibleIndex = 0
	clearGeneratedCards(InventoryItems)
	generatedInventoryCards = {}

	if selectedInventoryCategory == "other" then
		local card = createGeneratedCard(InventoryItemTemplate, InventoryItems, 1)
		setCardIcon(card, Textures.Empty)
		setTextIfPresent(card, "Name", "Coming Soon")
		card.Bonus.Text = "Future item types"
		setButtonText(card.EquipButton, "Locked", false, DISABLED_BUTTON_COLOR)
		updateLoadoutSummary()
		return
	end

	for _, item in ipairs(EcoPresets.GrowthShopItems[selectedInventoryCategory] or {}) do
		if ownedItems[item.id] then
			visibleIndex += 1
			local card = createGeneratedCard(InventoryItemTemplate, InventoryItems, visibleIndex)
			generatedInventoryCards[getGeneratedCardKey(selectedInventoryCategory, item.id)] = card
			setCardIcon(card, getItemIcon(selectedInventoryCategory, item))
			setTextIfPresent(card, "Name", item.displayName)
			card.Bonus.Text = describeItemStats(item.stats)
			if equippedItem == item.id then
				setButtonText(card.EquipButton, "Equipped", false, EQUIPPED_BUTTON_COLOR)
			else
				setButtonText(card.EquipButton, "Equip", true, EQUIP_BUTTON_COLOR)
			end
			uiController.SetButtonHoverAndClick(card.EquipButton, function()
				if equippedItem == item.id then
					return
				end
				SystemMgr.systems.EcoSystem.Server:RequestEquipItem({
					category = selectedInventoryCategory,
					itemId = item.id,
				})
			end)
		end
	end

	updateLoadoutSummary()
end

local function updatePanels()
	updateShopPanel()
	updateInventoryPanel()
	refreshTopbarIconState()
end

local function refreshRewardedAdAvailability()
	rewardedAdAvailabilityToken += 1
	local token = rewardedAdAvailabilityToken
	if currentRewardedAdState.available ~= true or currentRewardedAdState.reason ~= "ready" then
		return
	end

	local serverState = currentRewardedAdState
	currentRewardedAdState = table.clone(serverState)
	currentRewardedAdState.available = false
	currentRewardedAdState.reason = "checking"
	ClientData:SetOneData("rewardedAdState", currentRewardedAdState)
	if initialized and selectedShopCategory == "boost" then
		updateShopPanel()
	end

	task.spawn(function()
		local success, availability = pcall(function()
			return AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)
		end)
		if token ~= rewardedAdAvailabilityToken then
			return
		end

		local updatedState = table.clone(serverState)
		local result = success and availability and availability.AdAvailabilityResult
		updatedState.available = result == Enum.AdAvailabilityResult.IsAvailable
		updatedState.reason = result and result.Name or "availabilityError"
		currentRewardedAdState = updatedState
		ClientData:SetOneData("rewardedAdState", currentRewardedAdState)
		SystemMgr.systems.EcoSystem.Server:ReportRewardedAdAvailability({
			available = currentRewardedAdState.available,
			reason = currentRewardedAdState.reason,
		})
		if initialized and selectedShopCategory == "boost" then
			updateShopPanel()
		end
	end)
end

local function syncTopbarIcon(frame)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		refreshTopbarIconState()
	end)
end

local function createTopbarFrameIcon(name, label, order, frame, beforeOpen)
	local icon: any = Icon.new()
		:align("Left")
		:setName(name)
		:setLabel(label)
		:setOrder(order)
		:setCaption(name)
		:autoDeselect(false)

	icon.toggled:Connect(function(isSelected): ()
		if suppressTopbarToggle or GuiService.MenuIsOpen then
			return
		end
		if isSelected then
			beforeOpen()
			uiController.OpenFrame(frame.Name)
		else
			uiController.CloseFrame(frame.Name)
		end
	end)
	syncTopbarIcon(frame)
	return icon
end

local function bindTopbarIcons()
	shopTopbarIcon = createTopbarFrameIcon("Shop", "S", 20, ShopFrame, function()
		if selectedShopCategory == "boost" then
			selectedShopCategory = "coin"
		end
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	boostsTopbarIcon = createTopbarFrameIcon("Boosts", "R$", 21, ShopFrame, function()
		selectedShopCategory = "boost"
		SystemMgr.systems.EcoSystem.Server:RequestRewardedAdState()
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	inventoryTopbarIcon = createTopbarFrameIcon("Inventory", "B", 22, InventoryFrame, function()
		resetScrollPosition(InventoryItems)
		updatePanels()
	end)
end

local function bindButtons()
	uiController.SetButtonHoverAndClick(CoinFlipMenu.ShopButton, function()
		if selectedShopCategory == "boost" then
			selectedShopCategory = "coin"
		end
		resetScrollPosition(ShopItems)
		updatePanels()
		uiController.OpenFrame("Shop")
	end)
	uiController.SetButtonHoverAndClick(CoinFlipMenu.InventoryButton, function()
		resetScrollPosition(InventoryItems)
		updatePanels()
		uiController.OpenFrame("Inventory")
	end)

	uiController.SetButtonHoverAndClick(ShopFrame.X, function()
		uiController.CloseFrame("Shop")
	end)
	uiController.SetButtonHoverAndClick(InventoryFrame.X, function()
		uiController.CloseFrame("Inventory")
	end)

	uiController.SetButtonHoverAndClick(ShopTabs.CoinTab, function()
		selectedShopCategory = "coin"
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	uiController.SetButtonHoverAndClick(ShopTabs.DeskTab, function()
		selectedShopCategory = "desk"
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	uiController.SetButtonHoverAndClick(ShopTabs.ChairTab, function()
		selectedShopCategory = "chair"
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	if ShopBoostTab and ShopBoostTab:IsA("TextButton") then
		uiController.SetButtonHoverAndClick(ShopBoostTab, function()
			selectedShopCategory = "boost"
			SystemMgr.systems.EcoSystem.Server:RequestRewardedAdState()
			resetScrollPosition(ShopItems)
			updatePanels()
		end)
	end

	uiController.SetButtonHoverAndClick(InventoryTabs.CoinTab, function()
		selectedInventoryCategory = "coin"
		resetScrollPosition(InventoryItems)
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.DeskTab, function()
		selectedInventoryCategory = "desk"
		resetScrollPosition(InventoryItems)
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.ChairTab, function()
		selectedInventoryCategory = "chair"
		resetScrollPosition(InventoryItems)
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.OtherTab, function()
		selectedInventoryCategory = "other"
		resetScrollPosition(InventoryItems)
		updateInventoryPanel()
	end)
end

function EcoUi.Init()
	if initialized then
		return
	end
	initialized = true

	ShopFrame.Visible = false
	InventoryFrame.Visible = false
	ShopItemTemplate.Visible = false
	ShopItemTemplate.Parent = nil
	InventoryItemTemplate.Visible = false
	InventoryItemTemplate.Parent = nil
	currentCash = ClientData:GetOneData(dataKey.wins) or 0
	currentLoadoutState = ClientData:GetOneData("loadoutState") or currentLoadoutState
	currentGamePasses = ClientData:GetOneData(dataKey.gamePasses) or currentGamePasses
	currentRewardedAdState = ClientData:GetOneData("rewardedAdState") or currentRewardedAdState
	bindButtons()
	bindTopbarIcons()
	updatePanels()
	refreshRewardedAdAvailability()
end

function EcoUi.SyncLoadoutState(args)
	if args and args.cash then
		currentCash = args.cash
	else
		currentCash = ClientData:GetOneData(dataKey.wins) or currentCash
	end

	if args and args.loadoutState then
		currentLoadoutState = args.loadoutState
	end
	if args and args.rewardedAdState then
		currentRewardedAdState = args.rewardedAdState
	end
	currentGamePasses = ClientData:GetOneData(dataKey.gamePasses) or currentGamePasses

	if initialized then
		updatePanels()
	end

	if args and args.purchasedItem then
		playSfx("shopPurchase")
	elseif args and args.equippedItem then
		playSfx("equipItem")
	end
end

function EcoUi.SyncRewardedAdState(args)
	currentRewardedAdState = args or {}
	ClientData:SetOneData("rewardedAdState", currentRewardedAdState)
	if initialized and selectedShopCategory == "boost" then
		updateShopPanel()
	end
	refreshRewardedAdAvailability()
end

function EcoUi.OpenGuideShopItem(args)
	if not initialized then
		return nil
	end

	currentCash = ClientData:GetOneData(dataKey.wins) or currentCash
	currentLoadoutState = ClientData:GetOneData("loadoutState") or currentLoadoutState
	local category = args and args.category or "coin"
	local itemId = args and args.itemId
	if not EcoPresets.GrowthShopItems[category] then
		return nil
	end

	selectedShopCategory = category
	if typeof(itemId) == "string" then
		selectedShopItemKeys[category] = itemId
	end
	resetScrollPosition(ShopItems)
	updatePanels()
	uiController.OpenFrame("Shop")

	local card = typeof(itemId) == "string" and generatedShopCards[getGeneratedCardKey(category, itemId)] or nil
	return card and card:FindFirstChild("BuyButton")
end

function EcoUi.OpenGuideInventoryItem(args)
	if not initialized then
		return nil
	end

	currentCash = ClientData:GetOneData(dataKey.wins) or currentCash
	currentLoadoutState = ClientData:GetOneData("loadoutState") or currentLoadoutState
	local category = args and args.category or "coin"
	local itemId = args and args.itemId
	if not EcoPresets.GrowthShopItems[category] then
		return nil
	end

	selectedInventoryCategory = category
	resetScrollPosition(InventoryItems)
	updatePanels()
	uiController.OpenFrame("Inventory")

	local card = typeof(itemId) == "string" and generatedInventoryCards[getGeneratedCardKey(category, itemId)] or nil
	return card and card:FindFirstChild("EquipButton")
end

function EcoUi.UpdateWins(args)
	if args and args.total then
		currentCash = args.total
	end
	if initialized then
		updatePanels()
	end
end

function EcoUi.GiveItem() end

function EcoUi.UpdateWinsStore() end

function EcoUi.BuyLimitedPet() end

function EcoUi.BuyGamePass(args)
	if args and args.gamePasses then
		currentGamePasses = args.gamePasses
	else
		currentGamePasses = ClientData:GetOneData(dataKey.gamePasses) or currentGamePasses
	end

	if initialized then
		updatePanels()
	end
end

function EcoUi.BuyStarterPack() end

function EcoUi.UpdatePotion() end

function EcoUi.UpdateGamePassesBar() end

function EcoUi.UpdateStrengthBoost() end

return EcoUi
