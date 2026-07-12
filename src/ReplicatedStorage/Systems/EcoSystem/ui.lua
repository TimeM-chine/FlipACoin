local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

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
local BoostsFrame = Frames:WaitForChild("Boosts")
local InventoryFrame = Frames:WaitForChild("Inventory")

local ShopBody = ShopFrame:WaitForChild("Body")
local ShopTabs = ShopBody:WaitForChild("Tabs")
local ShopItems = ShopBody:WaitForChild("Items")
local ShopPreview = ShopBody:WaitForChild("Preview")
local ShopItemTemplate = ShopItems:WaitForChild("Template")

local BoostsBody = BoostsFrame:WaitForChild("Body")
local BoostsItems = BoostsBody:WaitForChild("Items")
local BoostsPreview = BoostsBody:WaitForChild("Preview")
local BoostsItemTemplate = BoostsItems:WaitForChild("Template")

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
local selectedBoostItemKey

local function reportPurchaseFunnel(stage, purchaseType, storeId, purchased)
	SystemMgr.systems.AnalyticsSystem.Server:ReportPurchaseFunnel({
		stage = stage,
		purchaseType = purchaseType,
		storeId = storeId,
		purchased = purchased,
	})
end
local generatedShopCards = {}
local generatedBoostCards = {}
local generatedInventoryCards = {}

local function getGeneratedCardKey(category, itemId)
	return `{category}:{itemId}`
end

local function getLastInputTypeName()
	local inputType = UserInputService:GetLastInputType()
	return inputType and inputType.Name or "unknown"
end

local function openGrowthFrame(frameName, source)
	SystemMgr.systems.EcoSystem.Server:ReportGrowthPanelOpened({
		panel = frameName,
		source = source,
		inputType = getLastInputTypeName(),
	})
	uiController.OpenFrame(frameName)
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
		if item.id == selectedKey then
			return item
		end
	end

	local firstItem = items[1]
	if firstItem then
		selectedShopItemKeys[selectedShopCategory] = firstItem.id
	end
	return firstItem
end

local function getSelectedBoostItem(items)
	for _, item in ipairs(items) do
		if getShopSelectionKey("boost", item) == selectedBoostItemKey then
			return item
		end
	end

	local firstItem = items[1]
	if firstItem then
		selectedBoostItemKey = getShopSelectionKey("boost", firstItem)
	end
	return firstItem
end

local function setPreviewIcon(preview, icon)
	local previewScene = preview:FindFirstChild("PreviewScene")
	local holder = preview:FindFirstChild("Icon") or (previewScene and previewScene:FindFirstChild("Icon"))
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
		setPreviewIcon(ShopPreview, "")
		return
	end

	setPreviewIcon(ShopPreview, getItemIcon(selectedShopCategory, item))
	ShopPreview.Title.Text = item.displayName
	local isOwned = ownedItems[item.id] == true
	local priceText = item.cost == 0 and "Starter" or `$ {Util.FormatNumber(item.cost, true)}`
	ShopPreview.Equipped.Text = `{item.rarity} | {item.role}`
	ShopPreview.TotalBonus.Text = `{describeItemStats(item.stats)} | {isOwned and "Owned" or priceText}`
end

local function updateBoostsPreview(item)
	if not item then
		BoostsPreview.Title.Text = "Select Boost"
		BoostsPreview.Equipped.Text = ""
		BoostsPreview.TotalBonus.Text = ""
		setPreviewIcon(BoostsPreview, "")
		return
	end

	local isOwnedPass = item.itemType == "gamePass" and currentGamePasses[item.key] == true
	setPreviewIcon(BoostsPreview, getItemIcon("boost", item))
	BoostsPreview.Title.Text = item.displayName
	BoostsPreview.Equipped.Text = item.description or "Premium boost"
	if isOwnedPass then
		BoostsPreview.TotalBonus.Text = "Owned"
	elseif item.configured then
		BoostsPreview.TotalBonus.Text = item.price and Util.GetRobuxText(item.price) or "Robux"
	else
		BoostsPreview.TotalBonus.Text = "Set ID"
	end
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
	setTopbarIconSelected(shopTopbarIcon, ShopFrame.Visible)
	setTopbarIconSelected(boostsTopbarIcon, BoostsFrame.Visible)
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
	ShopFrame:SetAttribute("GrowthCategory", selectedShopCategory)
	updateTabButton(ShopTabs.CoinTab, selectedShopCategory == "coin")
	updateTabButton(ShopTabs.DeskTab, selectedShopCategory == "desk")
	updateTabButton(ShopTabs.ChairTab, selectedShopCategory == "chair")

	local ownedItems = getOwnedItems(selectedShopCategory)
	local items = EcoPresets.GrowthShopItems[selectedShopCategory] or {}
	local selectedItem = getSelectedShopItem(items)
	clearGeneratedCards(ShopItems)
	generatedShopCards = {}

	for index, item in ipairs(items) do
		local card = createGeneratedCard(ShopItemTemplate, ShopItems, index)
		local itemKey = item.id
		generatedShopCards[getGeneratedCardKey(selectedShopCategory, itemKey)] = card
		updateCardSelection(card, selectedItem and itemKey == selectedItem.id)
		setCardIcon(card, getItemIcon(selectedShopCategory, item))
		setTextIfPresent(card, "Name", item.displayName)
		card.Price.Visible = false
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

		local selectButton = card:FindFirstChild("SelectButton")
		if selectButton and selectButton:IsA("GuiButton") then
			selectButton.Selectable = false
			uiController.SetButtonHoverAndClick(selectButton, function()
				selectedShopItemKeys[selectedShopCategory] = item.id
				updateShopPanel()
			end)
		end
		card.BuyButton.SelectionGained:Connect(function()
			selectedShopItemKeys[selectedShopCategory] = item.id
			for _, generatedCard in pairs(generatedShopCards) do
				updateCardSelection(generatedCard, generatedCard == card)
			end
			updateShopPreview(item, ownedItems)
		end)
		uiController.SetButtonHoverAndClick(card.BuyButton, function()
			selectedShopItemKeys[selectedShopCategory] = item.id
			if not ownedItems[item.id] then
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

local function updateBoostsPanel()
	local items = getOrderedBoostItems()
	local selectedItem = getSelectedBoostItem(items)
	clearGeneratedCards(BoostsItems)
	generatedBoostCards = {}

	for index, item in ipairs(items) do
		local card = createGeneratedCard(BoostsItemTemplate, BoostsItems, index)
		local itemKey = getShopSelectionKey("boost", item)
		generatedBoostCards[getGeneratedCardKey("boost", itemKey)] = card
		updateCardSelection(card, selectedItem and itemKey == getShopSelectionKey("boost", selectedItem))
		setCardIcon(card, getItemIcon("boost", item))
		setTextIfPresent(card, "Name", item.displayName)
		card.Price.Visible = false
		card.Bonus.Text = item.description or "Premium boost"
		card.Price.Text = item.price and Util.GetRobuxText(item.price) or "Robux"

		if item.itemType == "gamePass" and currentGamePasses[item.key] == true then
			setButtonText(card.BuyButton, "Owned", false, OWNED_BUTTON_COLOR)
		elseif item.configured then
			setButtonText(card.BuyButton, item.price and Util.GetRobuxText(item.price) or "Robux", true, BUY_BUTTON_COLOR)
		else
			setButtonText(card.BuyButton, "Set ID", false, DISABLED_BUTTON_COLOR)
		end

		local selectButton = card:FindFirstChild("SelectButton")
		if selectButton and selectButton:IsA("GuiButton") then
			selectButton.Selectable = false
			uiController.SetButtonHoverAndClick(selectButton, function()
				selectedBoostItemKey = getShopSelectionKey("boost", item)
				updateBoostsPanel()
			end)
		end
		card.BuyButton.SelectionGained:Connect(function()
			selectedBoostItemKey = getShopSelectionKey("boost", item)
			for _, generatedCard in pairs(generatedBoostCards) do
				updateCardSelection(generatedCard, generatedCard == card)
			end
			updateBoostsPreview(item)
		end)
		uiController.SetButtonHoverAndClick(card.BuyButton, function()
			selectedBoostItemKey = getShopSelectionKey("boost", item)
			if not item.configured then
				updateBoostsPanel()
				return
			end
			if item.itemType == "product" then
				reportPurchaseFunnel("entry", "product", item.storeId)
				MarketplaceService:PromptProductPurchase(LocalPlayer, item.storeId)
			elseif item.itemType == "gamePass" and not currentGamePasses[item.key] then
				reportPurchaseFunnel("entry", "gamePass", item.storeId)
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.storeId)
			end
			updateBoostsPanel()
		end)
	end

	updateBoostsPreview(selectedItem)
end

local function updateInventoryPanel()
	InventoryFrame:SetAttribute("GrowthCategory", selectedInventoryCategory)
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
			card.EquipButton.SelectionGained:Connect(function()
				for _, generatedCard in pairs(generatedInventoryCards) do
					updateCardSelection(generatedCard, generatedCard == card)
				end
				updateLoadoutSummary()
			end)
		end
	end

	updateLoadoutSummary()
end

local function updatePanels()
	updateShopPanel()
	updateBoostsPanel()
	updateInventoryPanel()
	refreshTopbarIconState()
	local openFrame = if ShopFrame.Visible
		then ShopFrame
		elseif BoostsFrame.Visible
		then BoostsFrame
		elseif InventoryFrame.Visible then InventoryFrame else nil
	if openFrame and UserInputService.GamepadEnabled then
		task.defer(function()
			if openFrame.Visible then
				uiController.ConfigureGrowthFrameGamepad(openFrame)
			end
		end)
	end
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
			openGrowthFrame(frame.Name, if name == "Boosts" then "topbarBoosts" else `topbar{name}`)
		else
			uiController.CloseFrame(frame.Name)
		end
	end)
	syncTopbarIcon(frame)
	return icon
end

local function bindTopbarIcons()
	shopTopbarIcon = createTopbarFrameIcon("Shop", "S", 20, ShopFrame, function()
		resetScrollPosition(ShopItems)
		updatePanels()
	end)
	boostsTopbarIcon = createTopbarFrameIcon("Boosts", "R$", 21, BoostsFrame, function()
		resetScrollPosition(BoostsItems)
		updatePanels()
	end)
	inventoryTopbarIcon = createTopbarFrameIcon("Inventory", "B", 22, InventoryFrame, function()
		resetScrollPosition(InventoryItems)
		updatePanels()
	end)
end

local function bindButtons()
	ShopTabs.CoinTab:SetAttribute("GrowthCategory", "coin")
	ShopTabs.DeskTab:SetAttribute("GrowthCategory", "desk")
	ShopTabs.ChairTab:SetAttribute("GrowthCategory", "chair")
	InventoryTabs.CoinTab:SetAttribute("GrowthCategory", "coin")
	InventoryTabs.DeskTab:SetAttribute("GrowthCategory", "desk")
	InventoryTabs.ChairTab:SetAttribute("GrowthCategory", "chair")
	InventoryTabs.OtherTab:SetAttribute("GrowthCategory", "other")
	uiController.SetButtonHoverAndClick(CoinFlipMenu.ShopButton, function()
		resetScrollPosition(ShopItems)
		updatePanels()
		openGrowthFrame("Shop", "legacyMenu")
	end)
	uiController.SetButtonHoverAndClick(CoinFlipMenu.InventoryButton, function()
		resetScrollPosition(InventoryItems)
		updatePanels()
		openGrowthFrame("Inventory", "legacyMenu")
	end)

	uiController.SetButtonHoverAndClick(ShopFrame.X, function()
		uiController.CloseFrame("Shop")
	end)
	uiController.SetButtonHoverAndClick(BoostsFrame.X, function()
		uiController.CloseFrame("Boosts")
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
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
		if userId == LocalPlayer.UserId then
			reportPurchaseFunnel("prompt_result", "product", productId, purchased)
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if player == LocalPlayer then
			reportPurchaseFunnel("prompt_result", "gamePass", gamePassId, purchased)
		end
	end)

	ShopFrame.Visible = false
	BoostsFrame.Visible = false
	InventoryFrame.Visible = false
	InventoryTabs.OtherTab.Text = "COMING SOON"
	ShopItemTemplate.Visible = false
	ShopItemTemplate.Parent = nil
	BoostsItemTemplate.Visible = false
	BoostsItemTemplate.Parent = nil
	InventoryItemTemplate.Visible = false
	InventoryItemTemplate.Parent = nil
	currentCash = ClientData:GetOneData(dataKey.wins) or 0
	currentLoadoutState = ClientData:GetOneData("loadoutState") or currentLoadoutState
	currentGamePasses = ClientData:GetOneData(dataKey.gamePasses) or currentGamePasses
	bindButtons()
	bindTopbarIcons()
	updatePanels()
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
	openGrowthFrame("Shop", "guide")

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
	openGrowthFrame("Inventory", "guide")

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
