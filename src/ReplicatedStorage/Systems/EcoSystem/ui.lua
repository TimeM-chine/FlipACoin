local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local EcoPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local Icon = require(Replicated.Packages.topbarplus)

local dataKey = Keys.DataKey
local PANEL_COLOR = Color3.fromRGB(5, 5, 6)
local CREAM_COLOR = Color3.fromRGB(255, 244, 220)

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
local ShopPageControls = ShopBody:WaitForChild("PageControls")
local ShopItemCards = {
	ShopItems:WaitForChild("Item1"),
	ShopItems:WaitForChild("Item2"),
	ShopItems:WaitForChild("Item3"),
	ShopItems:WaitForChild("Item4"),
}

local InventoryBody = InventoryFrame:WaitForChild("Body")
local InventoryTabs = InventoryBody:WaitForChild("Tabs")
local InventoryItems = InventoryBody:WaitForChild("Items")
local InventoryLoadout = InventoryBody:WaitForChild("Loadout")
local InventoryPageControls = InventoryBody:WaitForChild("PageControls")
local InventoryItemCards = {
	InventoryItems:WaitForChild("Item1"),
	InventoryItems:WaitForChild("Item2"),
	InventoryItems:WaitForChild("Item3"),
	InventoryItems:WaitForChild("Item4"),
	InventoryItems:WaitForChild("Item5"),
	InventoryItems:WaitForChild("Item6"),
}

local EcoUi = {}
local initialized = false
local currentCash = 0
local currentLoadoutState = {}
local currentGamePasses = {}
local selectedShopCategory = "coin"
local selectedInventoryCategory = "coin"
local selectedShopPageByCategory = {
	coin = 1,
	desk = 1,
	chair = 1,
	boost = 1,
}
local selectedInventoryPageByCategory = {
	coin = 1,
	desk = 1,
	chair = 1,
}
local selectedTabBackgroundColor = Color3.fromRGB(198, 158, 68)
local idleTabBackgroundColor = PANEL_COLOR
local selectedTabTextColor = Color3.fromRGB(36, 32, 26)
local idleTabTextColor = CREAM_COLOR
local suppressTopbarToggle = false
local shopTopbarIcon
local inventoryTopbarIcon
local boostsTopbarIcon
local shopRenderedItems = {}
local inventoryRenderedItems = {}

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

local function getBoostPageCount(pageSize)
	return math.max(1, math.ceil(#getOrderedBoostItems() / pageSize))
end

local function getPagedBoostItem(pageIndex, pageSize, slotIndex)
	local items = getOrderedBoostItems()
	local itemIndex = (pageIndex - 1) * pageSize + slotIndex
	return items[itemIndex]
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

local function setButtonText(button, text, isEnabled)
	button.Text = text
	button.AutoButtonColor = isEnabled
	button.Active = isEnabled
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

local function updateTabButton(button, isSelected)
	button.AutoButtonColor = not isSelected
	button.BackgroundTransparency = isSelected and 0.08 or 0.26
	button.BackgroundColor3 = isSelected and selectedTabBackgroundColor or idleTabBackgroundColor
	button.TextColor3 = isSelected and selectedTabTextColor or idleTabTextColor
end

local function getPageCount(category, pageSize)
	if category == "boost" then
		return getBoostPageCount(pageSize)
	end

	local items = EcoPresets.GrowthShopItems[category] or {}
	return math.max(1, math.ceil(#items / pageSize))
end

local function getOwnedPageCount(category, pageSize)
	local ownedItems = getOwnedItems(category)
	local ownedCount = 0
	for _, item in ipairs(EcoPresets.GrowthShopItems[category] or {}) do
		if ownedItems[item.id] then
			ownedCount += 1
		end
	end

	return math.max(1, math.ceil(ownedCount / pageSize))
end

local function clampPage(category, pageByCategory, pageSize)
	local pageCount = getPageCount(category, pageSize)
	pageByCategory[category] = math.clamp(pageByCategory[category] or 1, 1, pageCount)
	return pageByCategory[category], pageCount
end

local function clampOwnedPage(category, pageByCategory, pageSize)
	local pageCount = getOwnedPageCount(category, pageSize)
	pageByCategory[category] = math.clamp(pageByCategory[category] or 1, 1, pageCount)
	return pageByCategory[category], pageCount
end

local function getPagedItem(category, pageIndex, pageSize, slotIndex)
	if category == "boost" then
		return getPagedBoostItem(pageIndex, pageSize, slotIndex)
	end

	local items = EcoPresets.GrowthShopItems[category] or {}
	local itemIndex = (pageIndex - 1) * pageSize + slotIndex
	return items[itemIndex]
end

local function updatePageControls(pageControls, pageIndex, pageCount)
	pageControls.PageLabel.Text = `{pageIndex}/{pageCount}`
	setButtonText(pageControls.PrevButton, "<", pageIndex > 1)
	setButtonText(pageControls.NextButton, ">", pageIndex < pageCount)
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
	ShopPreview.Equipped.Text = `{equippedCoinName} / {equippedDeskName} / {equippedChairName}`
	ShopPreview.TotalBonus.Text = describeItemStats(bonuses)
end

local function updateShopPanel()
	updateTabButton(ShopTabs.CoinTab, selectedShopCategory == "coin")
	updateTabButton(ShopTabs.DeskTab, selectedShopCategory == "desk")
	updateTabButton(ShopTabs.ChairTab, selectedShopCategory == "chair")
	if ShopBoostTab and ShopBoostTab:IsA("TextButton") then
		updateTabButton(ShopBoostTab, selectedShopCategory == "boost")
	end
	if selectedShopCategory == "coin" then
		ShopPreview.Title.Text = "Coin Loadout"
	elseif selectedShopCategory == "desk" then
		ShopPreview.Title.Text = "Desk Setup"
	elseif selectedShopCategory == "boost" then
		ShopPreview.Title.Text = "Boosts"
	else
		ShopPreview.Title.Text = "Chair Setup"
	end

	local ownedItems = getOwnedItems(selectedShopCategory)
	local equippedItem = getEquippedItem(selectedShopCategory)
	local pageIndex, pageCount = clampPage(selectedShopCategory, selectedShopPageByCategory, #ShopItemCards)
	updatePageControls(ShopPageControls, pageIndex, pageCount)
	table.clear(shopRenderedItems)

	for index, card in ipairs(ShopItemCards) do
		local item = getPagedItem(selectedShopCategory, pageIndex, #ShopItemCards, index)
		shopRenderedItems[index] = item
		card.Visible = item ~= nil
		if item then
			if selectedShopCategory == "boost" then
				local isOwnedPass = item.itemType == "gamePass" and currentGamePasses[item.key] == true
				setTextIfPresent(card, "Name", item.displayName)
				card.Bonus.Text = item.description or "Premium boost"
				card.Price.Text = item.price and Util.GetRobuxText(item.price) or "Robux"
				if isOwnedPass then
					setButtonText(card.BuyButton, "Owned", false)
				elseif item.configured then
					setButtonText(card.BuyButton, "Buy", true)
				else
					setButtonText(card.BuyButton, "Set ID", false)
				end
			else
				local isOwned = ownedItems[item.id] == true
				local isEquipped = equippedItem == item.id
				setTextIfPresent(card, "Name", item.displayName)
				card.Bonus.Text = `{item.rarity} | {item.role} | {describeItemStats(item.stats)}`
				card.Price.Text = item.cost == 0 and "Starter" or `$ {Util.FormatNumber(item.cost, true)}`
				if isEquipped then
					setButtonText(card.BuyButton, "On", false)
				elseif isOwned then
					setButtonText(card.BuyButton, "Equip", true)
				else
					setButtonText(card.BuyButton, currentCash >= item.cost and "Buy" or "Need", currentCash >= item.cost)
				end
			end
		end
	end

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
	local pageIndex, pageCount = clampOwnedPage(selectedInventoryCategory, selectedInventoryPageByCategory, #InventoryItemCards)
	updatePageControls(InventoryPageControls, pageIndex, pageCount)
	table.clear(inventoryRenderedItems)

	for _, card in ipairs(InventoryItemCards) do
		card.Visible = false
	end

	if selectedInventoryCategory == "other" then
		updatePageControls(InventoryPageControls, 1, 1)
		local card = InventoryItemCards[1]
		card.Visible = true
		setTextIfPresent(card, "Name", "Coming Soon")
		card.Bonus.Text = "Future item types"
		setButtonText(card.EquipButton, "Locked", false)
		updateLoadoutSummary()
		return
	end

	for _, item in ipairs(EcoPresets.GrowthShopItems[selectedInventoryCategory] or {}) do
		if ownedItems[item.id] then
			visibleIndex += 1
			if visibleIndex <= (pageIndex - 1) * #InventoryItemCards then
				continue
			end

			local cardIndex = visibleIndex - (pageIndex - 1) * #InventoryItemCards
			local card = InventoryItemCards[cardIndex]
			if not card then
				break
			end
			inventoryRenderedItems[cardIndex] = item
			card.Visible = true
			setTextIfPresent(card, "Name", item.displayName)
			card.Bonus.Text = describeItemStats(item.stats)
			if equippedItem == item.id then
				setButtonText(card.EquipButton, "On", false)
			else
				setButtonText(card.EquipButton, "Equip", true)
			end
		end
	end

	updateLoadoutSummary()
end

local function updatePanels()
	updateShopPanel()
	updateInventoryPanel()
	refreshTopbarIconState()
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
		updatePanels()
	end)
	boostsTopbarIcon = createTopbarFrameIcon("Boosts", "R$", 21, ShopFrame, function()
		selectedShopCategory = "boost"
		updatePanels()
	end)
	inventoryTopbarIcon = createTopbarFrameIcon("Inventory", "B", 22, InventoryFrame, updatePanels)
end

local function bindButtons()
	uiController.SetButtonHoverAndClick(CoinFlipMenu.ShopButton, function()
		if selectedShopCategory == "boost" then
			selectedShopCategory = "coin"
		end
		updatePanels()
		uiController.OpenFrame("Shop")
	end)
	uiController.SetButtonHoverAndClick(CoinFlipMenu.InventoryButton, function()
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
		updatePanels()
	end)
	uiController.SetButtonHoverAndClick(ShopTabs.DeskTab, function()
		selectedShopCategory = "desk"
		updatePanels()
	end)
	uiController.SetButtonHoverAndClick(ShopTabs.ChairTab, function()
		selectedShopCategory = "chair"
		updatePanels()
	end)
	if ShopBoostTab and ShopBoostTab:IsA("TextButton") then
		uiController.SetButtonHoverAndClick(ShopBoostTab, function()
			selectedShopCategory = "boost"
			updatePanels()
		end)
	end
	uiController.SetButtonHoverAndClick(ShopPageControls.PrevButton, function()
		selectedShopPageByCategory[selectedShopCategory] = (selectedShopPageByCategory[selectedShopCategory] or 1) - 1
		updateShopPanel()
	end)
	uiController.SetButtonHoverAndClick(ShopPageControls.NextButton, function()
		selectedShopPageByCategory[selectedShopCategory] = (selectedShopPageByCategory[selectedShopCategory] or 1) + 1
		updateShopPanel()
	end)
	for index, card in ipairs(ShopItemCards) do
		local boundIndex = index
		uiController.SetButtonHoverAndClick(card.BuyButton, function()
			local item = shopRenderedItems[boundIndex]
			if not item then
				return
			end
			if selectedShopCategory == "boost" then
				if not item.configured then
					return
				end
				if item.itemType == "product" then
					MarketplaceService:PromptProductPurchase(LocalPlayer, item.storeId)
				elseif item.itemType == "gamePass" and not currentGamePasses[item.key] then
					MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.storeId)
				end
			elseif getOwnedItems(selectedShopCategory)[item.id] then
				SystemMgr.systems.EcoSystem.Server:RequestEquipItem({
					category = selectedShopCategory,
					itemId = item.id,
				})
			else
				SystemMgr.systems.EcoSystem.Server:RequestShopPurchase({
					category = selectedShopCategory,
					itemId = item.id,
				})
			end
		end)
	end

	uiController.SetButtonHoverAndClick(InventoryTabs.CoinTab, function()
		selectedInventoryCategory = "coin"
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.DeskTab, function()
		selectedInventoryCategory = "desk"
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.ChairTab, function()
		selectedInventoryCategory = "chair"
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryTabs.OtherTab, function()
		selectedInventoryCategory = "other"
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryPageControls.PrevButton, function()
		selectedInventoryPageByCategory[selectedInventoryCategory] =
			(selectedInventoryPageByCategory[selectedInventoryCategory] or 1) - 1
		updateInventoryPanel()
	end)
	uiController.SetButtonHoverAndClick(InventoryPageControls.NextButton, function()
		selectedInventoryPageByCategory[selectedInventoryCategory] =
			(selectedInventoryPageByCategory[selectedInventoryCategory] or 1) + 1
		updateInventoryPanel()
	end)
	for index, card in ipairs(InventoryItemCards) do
		local boundIndex = index
		uiController.SetButtonHoverAndClick(card.EquipButton, function()
			if selectedInventoryCategory == "other" then
				return
			end

			local item = inventoryRenderedItems[boundIndex]
			if not item then
				return
			end
			SystemMgr.systems.EcoSystem.Server:RequestEquipItem({
				category = selectedInventoryCategory,
				itemId = item.id,
			})
		end)
	end
end

function EcoUi.Init()
	if initialized then
		return
	end
	initialized = true

	ShopFrame.Visible = false
	InventoryFrame.Visible = false
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
