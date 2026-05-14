local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local EcoPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)

local dataKey = Keys.DataKey

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
local ShopItems = ShopBody:WaitForChild("Items")
local ShopPreview = ShopBody:WaitForChild("Preview")
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
local selectedShopCategory = "coin"
local selectedInventoryCategory = "coin"
local selectedTabBackgroundColor = Color3.fromRGB(198, 158, 68)
local idleTabBackgroundColor = Color3.fromRGB(34, 39, 48)
local selectedTabTextColor = Color3.fromRGB(36, 32, 26)
local idleTabTextColor = Color3.fromRGB(246, 240, 226)

local function getOwnedItems(category)
	if category == "coin" then
		return currentLoadoutState.ownedCoins or {}
	end
	if category == "desk" then
		return currentLoadoutState.ownedDeskSetups or {}
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

	return ""
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

local function styleSmallButtonText(button, textSize)
	button.TextScaled = false
	button.TextSize = textSize
	button.TextWrapped = false
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	button.TextStrokeTransparency = 1
	button.LineHeight = 1

	local constraint = button:FindFirstChild("GrowthTextSizeConstraint")
		or button:FindFirstChild("CodexTextSizeConstraint")
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Parent = button
	end
	constraint.Name = "GrowthTextSizeConstraint"
	constraint.MinTextSize = math.max(11, textSize - 5)
	constraint.MaxTextSize = textSize
end

local function styleCategoryTab(button)
	button.Size = UDim2.fromScale(0.92, 0.2)
	styleSmallButtonText(button, 16)
end

local function applyTextPolish()
	styleSmallButtonText(ShopFrame.X, 22)
	styleSmallButtonText(InventoryFrame.X, 22)
	styleCategoryTab(ShopTabs.CoinTab)
	styleCategoryTab(ShopTabs.DeskTab)
	styleCategoryTab(InventoryTabs.CoinTab)
	styleCategoryTab(InventoryTabs.DeskTab)
	styleCategoryTab(InventoryTabs.OtherTab)

	InventoryLoadout.ApplyButton.Visible = false
	InventoryLoadout.ApplyButton.Active = false
	InventoryLoadout.ApplyButton.Selectable = false

	for _, card in ipairs(ShopItemCards) do
		styleSmallButtonText(card.BuyButton, 14)
	end

	for _, card in ipairs(InventoryItemCards) do
		styleSmallButtonText(card.EquipButton, 13)
	end
end

local function updateTabButton(button, isSelected)
	button.AutoButtonColor = not isSelected
	button.BackgroundTransparency = isSelected and 0.08 or 0.26
	button.BackgroundColor3 = isSelected and selectedTabBackgroundColor or idleTabBackgroundColor
	button.TextColor3 = isSelected and selectedTabTextColor or idleTabTextColor
end

local function updateLoadoutSummary()
	local equippedCoin = getEquippedItem("coin")
	local equippedDesk = getEquippedItem("desk")
	local equippedCoinName = EcoPresets.GetShopItemDisplayName("coin", equippedCoin)
	local equippedDeskName = EcoPresets.GetShopItemDisplayName("desk", equippedDesk)
	local bonuses = EcoPresets.BuildLoadoutBonuses(equippedCoin, equippedDesk)
	InventoryLoadout.CoinSlot.Value.Text = equippedCoinName
	InventoryLoadout.DeskSlot.Value.Text = equippedDeskName
	InventoryLoadout.TotalBonus.Text = describeItemStats(bonuses)
	ShopPreview.Equipped.Text = `{equippedCoinName} / {equippedDeskName}`
	ShopPreview.TotalBonus.Text = describeItemStats(bonuses)
end

local function updateShopPanel()
	updateTabButton(ShopTabs.CoinTab, selectedShopCategory == "coin")
	updateTabButton(ShopTabs.DeskTab, selectedShopCategory == "desk")
	ShopPreview.Title.Text = selectedShopCategory == "coin" and "Coin Loadout" or "Desk Setup"

	local ownedItems = getOwnedItems(selectedShopCategory)
	local equippedItem = getEquippedItem(selectedShopCategory)
	local items = EcoPresets.GrowthShopItems[selectedShopCategory] or {}

	for index, card in ipairs(ShopItemCards) do
		local item = items[index]
		card.Visible = item ~= nil
		if item then
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

	updateLoadoutSummary()
end

local function updateInventoryPanel()
	updateTabButton(InventoryTabs.CoinTab, selectedInventoryCategory == "coin")
	updateTabButton(InventoryTabs.DeskTab, selectedInventoryCategory == "desk")
	updateTabButton(InventoryTabs.OtherTab, selectedInventoryCategory == "other")

	local ownedItems = getOwnedItems(selectedInventoryCategory)
	local equippedItem = getEquippedItem(selectedInventoryCategory)
	local visibleIndex = 0

	for _, card in ipairs(InventoryItemCards) do
		card.Visible = false
	end

	if selectedInventoryCategory == "other" then
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
			local card = InventoryItemCards[visibleIndex]
			if not card then
				break
			end
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
end

local function bindButtons()
	uiController.SetButtonHoverAndClick(CoinFlipMenu.ShopButton, function()
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
		updateShopPanel()
	end)
	uiController.SetButtonHoverAndClick(ShopTabs.DeskTab, function()
		selectedShopCategory = "desk"
		updateShopPanel()
	end)
	for index, card in ipairs(ShopItemCards) do
		local boundIndex = index
		uiController.SetButtonHoverAndClick(card.BuyButton, function()
			local item = (EcoPresets.GrowthShopItems[selectedShopCategory] or {})[boundIndex]
			if not item then
				return
			end
			if getOwnedItems(selectedShopCategory)[item.id] then
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
	uiController.SetButtonHoverAndClick(InventoryTabs.OtherTab, function()
		selectedInventoryCategory = "other"
		updateInventoryPanel()
	end)
	for index, card in ipairs(InventoryItemCards) do
		local boundIndex = index
		uiController.SetButtonHoverAndClick(card.EquipButton, function()
			if selectedInventoryCategory == "other" then
				return
			end

			local visibleIndex = 0
			for _, item in ipairs(EcoPresets.GrowthShopItems[selectedInventoryCategory] or {}) do
				if getOwnedItems(selectedInventoryCategory)[item.id] then
					visibleIndex += 1
					if visibleIndex == boundIndex then
						SystemMgr.systems.EcoSystem.Server:RequestEquipItem({
							category = selectedInventoryCategory,
							itemId = item.id,
						})
						return
					end
				end
			end
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
	applyTextPolish()
	bindButtons()
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

	if initialized then
		updatePanels()
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

function EcoUi.BuyGamePass() end

function EcoUi.BuyStarterPack() end

function EcoUi.UpdatePotion() end

function EcoUi.UpdateGamePassesBar() end

function EcoUi.UpdateStrengthBoost() end

return EcoUi
