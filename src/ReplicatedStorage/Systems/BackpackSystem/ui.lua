---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ItemTypeKey = Keys.ItemType
local Textures = require(Replicated.configs.Textures)
local BackpackPresets = require(script.Parent.Presets)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local Util = require(Replicated.modules.Util)
local Zone = require(Replicated.modules.Zone)
local ModelModule = require(Replicated.modules.ModelModule)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local InventoryFrame = Frames:WaitForChild("Inventory")
local miningToolsFrame = InventoryFrame:WaitForChild("miningTools")
local oresFrame = InventoryFrame:WaitForChild("ores")
local weaponsFrame = InventoryFrame:WaitForChild("weapons")
local WeaponInfoFrame = weaponsFrame:WaitForChild("WeaponInfo")
local OreInfoFrame = oresFrame:WaitForChild("OreInfo")

---- logic variables ----
local tabs = { "miningTools", "ores", "weapons" }

local BackpackUi = {
	initialized = false,
}
local selectedItem = nil
local currentCategory = nil
local nowOperation = nil
local sellingItems = {}
local Assets = script.Parent.Assets
local Satchel = require(script.Parent.Satchel)
local oreInfoFollowConn
local oreSelectionMap = {}
local oreSelectionConn

local function CompareOreByScoreAndName(a, b)
	local aPreset = BlockPresets.Ores[a]
	local bPreset = BlockPresets.Ores[b]
	local aScore = (aPreset and aPreset.score) or 0
	local bScore = (bPreset and bPreset.score) or 0

	if aScore ~= bScore then
		return aScore > bScore
	end

	return a < b
end

local function GetSortedOreNames(oreMap)
	local oreNames = {}
	for oreName in oreMap do
		table.insert(oreNames, oreName)
	end
	table.sort(oreNames, CompareOreByScoreAndName)
	return oreNames
end

local function ApplyOreLayoutOrder(scroll)
	local oreCards = {}
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= "Template" then
			table.insert(oreCards, child)
		end
	end

	table.sort(oreCards, function(a, b)
		return CompareOreByScoreAndName(a.Name, b.Name)
	end)

	for order, card in ipairs(oreCards) do
		card.LayoutOrder = order
	end
end

local function disconnectOreInfoFollow()
	if oreInfoFollowConn then
		oreInfoFollowConn:Disconnect()
		oreInfoFollowConn = nil
	end
end

local function UpdateOreInfoPosition(position)
	if typeof(position) == "Vector3" then
		position = Vector2.new(position.X, position.Y)
	end
	local parent = OreInfoFrame.Parent
	if parent then
		position = position - parent.AbsolutePosition
	end
	OreInfoFrame.AnchorPoint = Vector2.new(0, 0)
	OreInfoFrame.Position = UDim2.fromOffset(position.X, position.Y)
end

local function UpdateOreInfoPositionNearCard(card)
	local parent = OreInfoFrame.Parent
	if not parent then
		return
	end
	local gap = 12
	local x = card.AbsolutePosition.X - parent.AbsolutePosition.X + card.AbsoluteSize.X + gap
	local y = card.AbsolutePosition.Y - parent.AbsolutePosition.Y
	OreInfoFrame.AnchorPoint = Vector2.new(0, 0)
	OreInfoFrame.Position = UDim2.fromOffset(x, y)
end

local function UpdateOreInfoFrame(oreName)
	local oreData = BlockPresets.Ores[oreName]
	if not oreData then
		return
	end
	local statsFrame = OreInfoFrame:FindFirstChild("Stats")
	if not statsFrame then
		return
	end
	local nameLabel = statsFrame:FindFirstChild("name")
	if nameLabel then
		nameLabel.Text = oreData.name or oreName
	end
	local rarityLabel = statsFrame:FindFirstChild("rarity")
	if rarityLabel then
		rarityLabel.Text = oreData.rarity or ""
	end
	local damageBoostLabel = statsFrame:FindFirstChild("damageBoost")
	if damageBoostLabel then
		damageBoostLabel.Text = "Damage Boost: " .. Util.FormatNumber(oreData.damageBoost or 0)
	end
	local descriptionLabel = statsFrame:FindFirstChild("description")
	if descriptionLabel then
		descriptionLabel.Text = oreData.description or ""
	end
	local priceLabel = statsFrame:FindFirstChild("price")
	if priceLabel then
		priceLabel.Text = `{Util.FormatNumber(oreData.sellPrice or 0)} $`
	end
	OreInfoFrame.name.Text = oreData.name
end

local function ensureOreSelectionListener()
	if oreSelectionConn then
		return
	end
	oreSelectionConn = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		if not UserInputService.GamepadEnabled then
			return
		end
		local selected = GuiService.SelectedObject
		if not selected then
			OreInfoFrame.Visible = false
			return
		end

		local info = oreSelectionMap[selected]
		if not info then
			local cursor = selected
			while cursor and cursor ~= oresFrame do
				local oreName = cursor:GetAttribute("OreName")
				if oreName then
					info = { unit = cursor, oreName = oreName }
					break
				end
				cursor = cursor.Parent
			end
			warn(cursor)
		end

		if info then
			UpdateOreInfoFrame(info.oreName)
			OreInfoFrame.Visible = true
			UpdateOreInfoPositionNearCard(info.unit)
		else
			OreInfoFrame.Visible = false
		end
	end)
end

local function BindOreCardHoverAndSelection(unit, oreName)
	unit.MouseEnter:Connect(function()
		UpdateOreInfoFrame(oreName)
		OreInfoFrame.Visible = true
		UpdateOreInfoPosition(UserInputService:GetMouseLocation())
		disconnectOreInfoFollow()
		oreInfoFollowConn = UserInputService.InputChanged:Connect(function(inputObj)
			if
				inputObj.UserInputType == Enum.UserInputType.MouseMovement
				or inputObj.UserInputType == Enum.UserInputType.Touch
			then
				UpdateOreInfoPosition(inputObj.Position)
			end
		end)
	end)

	unit.MouseLeave:Connect(function()
		disconnectOreInfoFollow()
		OreInfoFrame.Visible = false
	end)

	if UserInputService.GamepadEnabled then
		local clickBtn = unit:FindFirstChild("clickBtn", true) or unit:FindFirstChildWhichIsA("GuiButton", true)
		if clickBtn then
			clickBtn.Selectable = true
			clickBtn.Active = true
			oreSelectionMap[clickBtn] = { unit = unit, oreName = oreName }
			unit:SetAttribute("OreName", oreName)
			clickBtn:SetAttribute("OreName", oreName)
			ensureOreSelectionListener()
		end
	end
end

function BackpackUi.Init()
	local backpack = ClientData:GetOneData(dataKey.backpack)
	BackpackUi.initialized = true

	WeaponInfoFrame.Visible = false
	OreInfoFrame.Visible = false

	local sideButtons = InventoryFrame:WaitForChild("Buttons")
	for _, button in sideButtons:GetChildren() do
		uiController.SetButtonHoverAndClick(button, function()
			for _, name in tabs do
				local page = InventoryFrame:WaitForChild(name)
				if page then
					page.Visible = name == button.Name
				end
			end
		end)
	end

	miningToolsFrame.Visible = false
	oresFrame.Visible = false
	weaponsFrame.Visible = true

	miningToolsFrame.ScrollingFrame.Template.Visible = false

	-- Initialize sell buttons for ores (only if buttons exist in UI)
	local oresButtons = oresFrame:FindFirstChild("buttons")
	if oresButtons then
		local SellButton = oresButtons:WaitForChild("Sell")
		local CancelSellButton = oresButtons:WaitForChild("Cancel")

		CancelSellButton.Visible = false

		uiController.SetButtonHoverAndClick(SellButton, function()
			if nowOperation == "sell" then
				local itemsToSell = {}
				for itemName, count in pairs(sellingItems) do
					table.insert(itemsToSell, {
						itemType = Keys.ItemType.ores,
						itemName = itemName,
						count = count,
					})
				end

				if #itemsToSell > 0 then
					SystemMgr.systems.BackpackSystem.Server:SellItems({
						items = itemsToSell,
					})
				end
				QuitSellOperation()
			else
				StartSellOperation()
			end
		end)

		uiController.SetButtonHoverAndClick(CancelSellButton, function()
			QuitSellOperation()
		end)
	end

	for _, name in { "ores" } do
		local invData = backpack[name]
		local scroll = InventoryFrame:WaitForChild(name):WaitForChild("ScrollingFrame")
		local template = scroll:WaitForChild("Template")
		template.Visible = false
		local sortedOreNames = GetSortedOreNames(invData)
		for order, itemName in ipairs(sortedOreNames) do
			local count = invData[itemName]
			Util.Clone(template, scroll, function(unit)
				unit.Visible = true
				unit.deleting.Visible = false
				local orePreset = BlockPresets.Ores[itemName]
				local oreRarity = orePreset and orePreset.rarity
				local oreColor = Textures.RarityColor[oreRarity] or Textures.RarityColor.Default
				unit.bg.ImageColor3 = oreColor
				unit.icon.Image = Textures.GetIcon({ itemType = name, itemName = itemName })
				unit.Name = itemName
				unit.LayoutOrder = order
				unit.name.Text = itemName
				unit.size.Text = "x" .. count

				uiController.SetButtonHoverAndClick(unit, function()
					if nowOperation == "sell" then
						if sellingItems[itemName] then
							sellingItems[itemName] = nil
							unit.deleting.Visible = false
						else
							local _backpack = ClientData:GetOneData(dataKey.backpack)
							sellingItems[itemName] = _backpack[Keys.ItemType.ores][itemName]
							unit.deleting.Visible = true
						end
						UpdateSellButtonText()
					end
				end)
				BindOreCardHoverAndSelection(unit, itemName)
			end)
		end
	end

	oresFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not oresFrame.Visible then
			disconnectOreInfoFollow()
			OreInfoFrame.Visible = false
			GuiService.SelectedObject = nil
		end
	end)
end

function BackpackUi.AddItems(args)
	local items = args.items
	local backpack = args.backpack
	local touchedOres = false
	for _, item in ipairs(items) do
		local itemType = item.itemType
		local itemName = item.itemName
		local count = backpack[itemType][itemName]

		-- if table.find({ "miningTools", "weapons" }, itemType) then

		-- elseif table.find({ "ores" }, itemType) then
		-- 	local scroll = InventoryFrame:WaitForChild(itemType):WaitForChild("ScrollingFrame")
		-- 	local itemCard = scroll:FindFirstChild(itemName)
		-- 	if itemCard then
		-- 		itemCard.size.Text = "x" .. (count + 1)
		-- 	end
		-- end

		local scroll = InventoryFrame:WaitForChild(itemType):WaitForChild("ScrollingFrame")
		local itemCard = scroll:FindFirstChild(itemName)
		if itemCard then
			itemCard.size.Text = "x" .. count
		else
			local template = scroll:WaitForChild("Template")
			itemCard = Util.Clone(template, scroll, function(unit)
				unit.Visible = true
				unit.icon.Image = Textures.GetIcon({ itemType = itemType, itemName = itemName })
				unit.Name = itemName
				unit.deleting.Visible = false
				local oreRarity = BlockPresets.Ores[itemName].rarity
				local oreColor = Textures.RarityColor[oreRarity]
				unit.bg.ImageColor3 = oreColor
				unit.name.Text = itemName
				unit.size.Text = "x" .. count

				if itemType == Keys.ItemType.ores then
					uiController.SetButtonHoverAndClick(unit, function()
						if nowOperation == "sell" then
							if sellingItems[itemName] then
								sellingItems[itemName] = nil
								unit.deleting.Visible = false
							else
								local _backpack = ClientData:GetOneData(dataKey.backpack)
								sellingItems[itemName] = _backpack[Keys.ItemType.ores][itemName]
								unit.deleting.Visible = true
							end
							UpdateSellButtonText()
						end
					end)
					BindOreCardHoverAndSelection(unit, itemName)
				end
			end)
		end

		if itemType == Keys.ItemType.ores then
			touchedOres = true
		end
	end

	if touchedOres then
		local oreScroll = InventoryFrame:WaitForChild(Keys.ItemType.ores):WaitForChild("ScrollingFrame")
		ApplyOreLayoutOrder(oreScroll)
	end
end

function BackpackUi.SellItems(args)
	-- Client-side sell confirmation, the actual selling is handled server-side
	-- This function is called after successful server-side sell operation
	ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
	BackpackUi.UpdateItem(args)
end

-- add function to update item quantities
function BackpackUi.UpdateItem(args)
	local deleted = args.deleted
	local backpack = args.backpack
	if Satchel.UpdateBackpackData then
		Satchel.UpdateBackpackData(args.backpack)
	end

	for _, item in ipairs(deleted) do
		local itemType = item.itemType
		local itemName = item.itemName
		local count = backpack[itemType][itemName]

		local scroll = InventoryFrame:WaitForChild(itemType):WaitForChild("ScrollingFrame")
		local itemCard = scroll:FindFirstChild(itemName)
		if itemCard then
			if not backpack[itemType][itemName] then
				itemCard:Destroy()
			else
				itemCard.size.Text = "x" .. count
			end
		end
	end
end

function BackpackUi.GetSlots()
	while not BackpackUi.initialized do
		task.wait(0.1)
	end
	return Satchel.GetSlots()
end

function StartSellOperation()
	nowOperation = "sell"
	UpdateSellButtonText()

	local oresButtons = oresFrame:FindFirstChild("buttons")
	if oresButtons then
		local CancelSellButton = oresButtons:WaitForChild("Cancel")
		CancelSellButton.Visible = true
	end
end

function QuitSellOperation()
	nowOperation = nil

	local oresButtons = oresFrame:FindFirstChild("buttons")
	if oresButtons then
		local SellButton = oresButtons:WaitForChild("Sell")
		local CancelSellButton = oresButtons:WaitForChild("Cancel")

		SellButton.TextLabel.Text = "Sell Items"
		CancelSellButton.Visible = false
	end

	-- Clear all selling selections
	for _, card in oresFrame.ScrollingFrame:GetChildren() do
		if card:IsA("Frame") and card.Name ~= "Template" then
			card.deleting.Visible = false
		end
	end
	sellingItems = {}
end

function UpdateSellButtonText()
	local oresButtons = oresFrame:FindFirstChild("buttons")
	if oresButtons then
		local SellButton = oresButtons:WaitForChild("Sell")
		local itemCount = 0
		for _, count in pairs(sellingItems) do
			itemCount = itemCount + count
		end
		SellButton.TextLabel.Text = `Sell ({itemCount})`
	end
end

return BackpackUi
