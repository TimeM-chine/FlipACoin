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
local Textures = require(Replicated.configs.Textures)
local WeaponAttributes = require(Replicated.configs.WeaponAttributes)
local WeaponPresets = require(script.Parent.Presets)
local WeaponAttributeEngine = require(Replicated.modules.WeaponAttributeEngine)
local Util = require(Replicated.modules.Util)
local Zone = require(Replicated.modules.Zone)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Gradients = PlayerGui:WaitForChild("Gradients")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local Elements = Main:WaitForChild("Elements")
local AutoButton = Elements:WaitForChild("auto")
local Buttons = Main:WaitForChild("Buttons")
local InventoryButton = Buttons:WaitForChild("InventoryButton")
local notificationText = InventoryButton:WaitForChild("Main"):WaitForChild("notification")
local InventoryFrame = Frames:WaitForChild("Inventory"):WaitForChild("weapons")
local buttons = InventoryFrame:WaitForChild("buttons")
local DeleteButton = buttons:WaitForChild("Delete")
local CancelButton = buttons:WaitForChild("Cancel")
-- local DeleteButton = InventoryFrame:WaitForChild("DeleteButton")
-- local CancelButton = DeleteButton:WaitForChild("DeleteCancel")
local InfoFrame = InventoryFrame:WaitForChild("ItemInfoFrame")
local WeaponInfoFrame = InventoryFrame:WaitForChild("WeaponInfo")
local AttrInfoFrame = InventoryFrame:WaitForChild("attrInfo")
local ItemScroll = InventoryFrame:WaitForChild("ScrollingFrame")
-- local FullText = InventoryFrame:WaitForChild("FullText")
local StockText = InventoryFrame:WaitForChild("Stock")
local itemTpl = ItemScroll:WaitForChild("Template")
local attrInfoTemplate = AttrInfoFrame:WaitForChild("Template")
local EnhanceFrame = Frames:WaitForChild("Enhance")
local EnchantFrame = Frames:WaitForChild("Enchant")

local uiController = require(Main:WaitForChild("uiController"))
local ContextActionMgr = require(Main:WaitForChild("ContextActionMgr"))

---- logic variables ----
local WeaponUi = {}
local unreadCount = 0
local selectedWeapon = {
	id = nil,
	size = nil,
}
local equippedIndex
local nowOperation
local deletingIndexes = {}
local weaponInfoFollowConn
local UpdateWeaponInfoFrame
local UpdateWeaponInfoPosition
local UpdateAttrInfoList
local updateAttrsFrame
local updateEnchantsFrame
local weaponSelectionMap = {}
local weaponSelectionConn

local function getWeaponSelectionInfo(selected)
	if not selected then
		return nil
	end
	local info = weaponSelectionMap[selected]
	if info then
		return info
	end
	local cursor = selected
	while cursor and cursor ~= InventoryFrame do
		local weaponIndex = cursor:GetAttribute("WeaponIndex")
		if weaponIndex then
			return { weaponIndex = weaponIndex, unit = cursor }
		end
		cursor = cursor.Parent
	end
	return nil
end

local function ensureWeaponSelectionListener()
	if weaponSelectionConn then
		return
	end
	weaponSelectionConn = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		if not UserInputService.GamepadEnabled then
			return
		end
		local info = getWeaponSelectionInfo(GuiService.SelectedObject)
		if info then
			local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
			local weaponData = weapons[info.weaponIndex]
			if weaponData then
				UpdateWeaponInfoFrame(weaponData)
				WeaponInfoFrame.Visible = true
				local gap = 12
				local parent = WeaponInfoFrame.Parent
				if parent then
					local x = info.unit.AbsolutePosition.X - parent.AbsolutePosition.X + info.unit.AbsoluteSize.X + gap
					local y = info.unit.AbsolutePosition.Y - parent.AbsolutePosition.Y
					WeaponInfoFrame.AnchorPoint = Vector2.new(0, 0)
					WeaponInfoFrame.Position = UDim2.fromOffset(x, y)
				end
				return
			end
		end
		WeaponInfoFrame.Visible = false
	end)
end

function WeaponUi.Init(pendingCalls)
	itemTpl.Visible = false
	attrInfoTemplate.Visible = false
	notificationText.Visible = false
	CancelButton.Visible = false
	WeaponInfoFrame.Visible = false
	-- CancelButton.Visible = false

	local enhanceContainer = workspace.Boxes:WaitForChild("Enhance")
	local enhanceZone = Zone.new(enhanceContainer)
	enhanceZone.localPlayerEntered:Connect(function()
		WeaponUi.OpenEnhanceFrame()
	end)

	enhanceZone.localPlayerExited:Connect(function()
		uiController.CloseFrame("Enhance")
	end)

	local enchantContainer = workspace.Boxes:WaitForChild("Enchant")
	local enchantZone = Zone.new(enchantContainer)
	enchantZone.localPlayerEntered:Connect(function()
		WeaponUi.OpenEnchantFrame()
	end)

	enchantZone.localPlayerExited:Connect(function()
		uiController.CloseFrame("Enchant")
	end)

	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	for index, weaponData in weapons do
		if not weaponData then
			continue
		end
		local itemCard = CreateCard(index, weaponData)
	end

	-- FullText.Visible = #weapons >= 100
	StockText.Text = `{#weapons}/100`

	SelectWeapon(equippedIndex)
	UpdateAttrInfoList()

	uiController.SetButtonHoverAndClick(DeleteButton, function()
		if nowOperation == "delete" then
			SystemMgr.systems.WeaponSystem.Server:DeleteWeaponList({
				deletingIndexes = deletingIndexes,
			})
			QuitOperation()
		else
			StartDeleteOperation()
		end
	end)
	uiController.SetButtonHoverAndClick(CancelButton, function()
		QuitOperation()
	end)

	if uiController.GetButtonRecall(InventoryButton) then
		ContextActionMgr.AddFrameBinding({
			btn = InventoryButton,
			frame = Main,
			keys = { Enum.KeyCode.ButtonX },
		})
	else
		local con
		con = InventoryButton.ChildAdded:Connect(function(child)
			if child.Name == "clickBtn" then
				ContextActionMgr.AddFrameBinding({
					btn = InventoryButton,
					frame = Main,
					keys = { Enum.KeyCode.ButtonX },
				})
				con:Disconnect()
			end
		end)
	end

	InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not InventoryFrame.Visible then
			if weaponInfoFollowConn then
				weaponInfoFollowConn:Disconnect()
				weaponInfoFollowConn = nil
			end
			WeaponInfoFrame.Visible = false
			GuiService.SelectedObject = nil
		end
	end)

	for _, call in ipairs(pendingCalls) do
		WeaponUi[call.functionName](table.unpack(call.args))
	end
end

function WeaponUi.AddWeapons(args)
	uiController.ClearScrollChildren(ItemScroll)
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	for index, weaponData in weapons do
		if not weaponData then
			continue
		end
		local itemCard = CreateCard(index, weaponData)
	end

	-- FullText.Visible = #weapons >= 100
	StockText.Text = `{#weapons}/100`

	SelectWeapon(equippedIndex)
	UpdateAttrInfoList()
end

function WeaponUi.DeleteWeapons(args)
	local weaponKey = args.weaponKey
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	weapons[weaponKey] = nil
end

function WeaponUi.EquipWeapon(args)
	for _, card in ItemScroll:GetChildren() do
		if card:IsA("Frame") then
			card.equipped.Visible = false
		end
	end
	local weaponIndex = args.weaponIndex
	local card = ItemScroll:FindFirstChild(weaponIndex)
	if not card then
		return
	end
	card.equipped.Visible = true
	equippedIndex = weaponIndex
end

function SelectWeapon(weaponIndex)
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponData = weapons[weaponIndex]
	if not weaponData then
		return
	end

	selectedWeapon = weaponIndex
	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	InfoFrame.item.icon.Image = Textures.Weapons[weaponProperty.weaponId].icon
	InfoFrame.item.ImageColor3 = Textures.RarityColor[weaponProperty.rarity]
	InfoFrame.item.name.Text = weaponProperty.name
	-- InfoFrame.power.TextLabel.Text = Util.FormatNumber(weaponProperty.power)
	InfoFrame.item.size.Text = `{math.floor((weaponProperty.size * 100) + 0.5)}%`

	local ti = TweenInfo.new(0.3)
	local areaBar = InfoFrame.area.bar
	local areaBarTween = TweenService:Create(areaBar, ti, {
		Size = UDim2.fromScale(weaponProperty.size / 5, 1),
	})
	areaBarTween:Play()
	local speedBar = InfoFrame.speed.bar
	local speedBarTween = TweenService:Create(speedBar, ti, {
		Size = UDim2.fromScale(0.5 / weaponProperty.size, 1),
	})
	speedBarTween:Play()
end

local tierColor = {
	normal = "Common",
	big = "Black",
	huge = "Red",
	gigantic = "RainbowB",
}
function CreateCard(index, weaponData)
	return Util.Clone(itemTpl, ItemScroll, function(card)
		local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
		card.Visible = true
		card.deleting.Visible = false
		card.Name = index
		-- card.icon.Image = Textures.Weapons[weaponProperty.weaponId].icon
		local viewport = card:FindFirstChild("ViewportFrame")

		local weaponModel = WeaponPresets.CreateWeaponModelForUi(weaponData)
		uiController.PetViewport(weaponModel, viewport)
		local mainOre = weaponData.mainOre or "Stone"
		local oreRarity = BlockPresets.Ores[mainOre].rarity
		local oreColor = Textures.RarityColor[oreRarity]
		card.name.Text = `{weaponProperty.name}[{mainOre}]`
		card.bg.ImageColor3 = oreColor
		card.size.Text = `{math.floor((weaponProperty.size * 100) + 0.5)}%`
		card.tier.Text = string.gsub(weaponProperty.tier, "^%l", string.upper)
		-- card.tier.UIGradient.Color = Gradients:FindFirstChild(tierColor[weaponProperty.tier]).Color
		card.LayoutOrder = -weaponProperty.sellPrice
		card.equipped.Visible = weaponData.equipped
		if weaponData.equipped then
			equippedIndex = index
		end

		local attrsFrame = card:FindFirstChild("Attrs")
		updateAttrsFrame(attrsFrame, weaponData)

		local enchantsFrame = card:FindFirstChild("Enchants")
		updateEnchantsFrame(enchantsFrame, weaponData)

		uiController.SetButtonHoverAndClick(card, function()
			if nowOperation == "delete" then
				if equippedIndex == index then
					uiController.SetNotification({
						text = "Cannot sell equipped weapon",
						textColor = Textures.ButtonColors.red,
					})
					return
				end
				local alreadyDeleting = false
				for i, deletingIndex in ipairs(deletingIndexes) do
					if deletingIndex == index then
						alreadyDeleting = i
					end
				end
				if alreadyDeleting then
					table.remove(deletingIndexes, alreadyDeleting)
					card.deleting.Visible = false
				else
					table.insert(deletingIndexes, index)
					card.deleting.Visible = true
				end
				DeleteButton.TextLabel.Text = `Sell({#deletingIndexes})`
				return
			end
			SelectWeapon(index)
			SystemMgr.systems.WeaponSystem.Server:EquipWeapon({
				weaponIndex = index,
			})

			local quests = ClientData:GetOneData(Keys.DataKey.quests)
			if not quests.completed and quests.index == 4 then
				SystemMgr.systems.QuestSystem.Server:AddProgress({
					questType = Keys.QuestType.equipWeapon,
					value = 1,
				})
			end
		end)

		card.MouseEnter:Connect(function()
			if weaponInfoFollowConn then
				weaponInfoFollowConn:Disconnect()
				weaponInfoFollowConn = nil
			end
			UpdateWeaponInfoFrame(weaponData)
			WeaponInfoFrame.Visible = true
			UpdateWeaponInfoPosition(UserInputService:GetMouseLocation())
			weaponInfoFollowConn = UserInputService.InputChanged:Connect(function(inputObj)
				if inputObj.UserInputType == Enum.UserInputType.MouseMovement then
					UpdateWeaponInfoPosition(inputObj.Position)
				end
			end)
		end)

		card.MouseLeave:Connect(function()
			if weaponInfoFollowConn then
				weaponInfoFollowConn:Disconnect()
				weaponInfoFollowConn = nil
			end
			WeaponInfoFrame.Visible = false
		end)

		if UserInputService.GamepadEnabled then
			local clickBtn = card:FindFirstChild("clickBtn", true) or card:FindFirstChildWhichIsA("GuiButton", true)
			if clickBtn then
				clickBtn.Selectable = true
				clickBtn.Active = true
				weaponSelectionMap[clickBtn] = { weaponIndex = index, unit = card }
				card:SetAttribute("WeaponIndex", index)
				clickBtn:SetAttribute("WeaponIndex", index)
				ensureWeaponSelectionListener()
			end
		end
	end)
end

function StartDeleteOperation()
	nowOperation = "delete"
	DeleteButton.TextLabel.Text = "Sell(0)"
	CancelButton.Visible = true
end

function QuitOperation()
	nowOperation = nil
	DeleteButton.TextLabel.Text = "Sell Items"
	CancelButton.Visible = false

	for _, card in ItemScroll:GetChildren() do
		if card:IsA("Frame") and card.Name ~= "Template" then
			card.deleting.Visible = false
		end
	end
	deletingIndexes = {}
end

-- Helper function to calculate weapon stats with enhance multiplier
local function CalculateWeaponStats(weaponData)
	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)

	return {
		damage = weaponProperty.damage or 0,
		speed = weaponProperty.coolDownFinal or weaponProperty.coolDown or 1,
		quality = weaponProperty.size or 1,
		multiplier = weaponProperty.enhanceMultiplier or 1,
	}
end

local AttrDisplayNames = {
	Attack = "Damage+",
	AttackSpeed = "Attack Speed+",
	DamageRange = "Range+",
	CritRate = "Crit Rate",
	Explosion = "Explosion",
	Burn = "Burn",
	CoinBoost = "Coin Boost",
	EnchantLuck = "Enchant Luck",
}

local EnchantDisplayNames = {
	[Keys.Enchants.Explosion] = "Explosion",
	[Keys.Enchants.CoinBoost] = "Coin Boost",
	[Keys.Enchants.CritRate] = "Crit Rate",
	[Keys.Enchants.AttackSpeed] = "Attack Speed",
	[Keys.Enchants.Attack] = "Attack",
	[Keys.Enchants.EnchantLuck] = "Enchant Luck",
	[Keys.Enchants.Burn] = "Burn",
}

local AttrTips = {
	Attack = "Increase weapon attack damage.",
	AttackSpeed = "Increase weapon attack speed.",
	DamageRange = "Increase attack range.",
	CritRate = "Increase critical hit chance.",
	Explosion = "Explode nearby blocks on hit.",
	Burn = "Burn block for 5 seconds.",
	CoinBoost = "Increase coin gain from mining.",
	EnchantLuck = "Increase forging luck.",
	[Keys.Enchants.Explosion] = "Explode nearby blocks on hit.",
	[Keys.Enchants.CoinBoost] = "Increase coin gain from mining.",
	[Keys.Enchants.CritRate] = "Increase critical hit chance.",
	[Keys.Enchants.AttackSpeed] = "Increase weapon attack speed.",
	[Keys.Enchants.Attack] = "Increase weapon attack damage.",
	[Keys.Enchants.EnchantLuck] = "Increase forging luck.",
	[Keys.Enchants.Burn] = "Burn block for 5 seconds.",
}

local function getAttrDisplayName(attrId)
	return AttrDisplayNames[attrId] or EnchantDisplayNames[attrId] or attrId
end

local function formatNumber(value, decimals)
	local scale = 10 ^ (decimals or 0)
	return math.floor(value * scale + 0.5) / scale
end

local function formatAttrValue(attrId, inst)
	local def = WeaponAttributes.Definitions[attrId]
	if attrId == Keys.ForgeAttrs.Explosion then
		local chance = inst.baseChance or (def and def.baseChance) or 0
		local radius = inst.radius or (def and def.radius) or 0
		local stacks = inst.stacks or 0
		local perStack = inst.perStack or (def and def.defaultPerStack) or 0
		local damageMult = 1 + stacks * perStack
		return `{math.floor(chance * 100)}% x{formatNumber(damageMult, 2)} R{radius}`
	end
	if attrId == Keys.ForgeAttrs.Burn then
		local chance = inst.baseChance or (def and def.baseChance) or 0
		local duration = inst.duration or (def and def.duration) or 0
		local stacks = inst.stacks or 0
		local perStack = inst.perStack or (def and def.defaultPerStack) or 0
		local dpsPct = stacks * perStack * 100
		return `{math.floor(chance * 100)}% {duration}s +{formatNumber(dpsPct, 0)}%/s`
	end

	local value = inst.legacyValue
	if value == nil then
		local stacks = inst.stacks or 0
		local perStack = inst.perStack or (def and def.defaultPerStack) or 0
		value = stacks * perStack
	end
	if value == nil then
		return nil
	end
	local percent = value * 100
	return `+{formatNumber(percent, 0)}%`
end

function updateAttrsFrame(attrsFrame, weaponData)
	if not attrsFrame then
		return
	end
	local template = attrsFrame:FindFirstChild("Template")
	template.Visible = false
	uiController.ClearScrollChildren(attrsFrame)

	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
	local hasAny = false
	for attrId, inst in pairs(attrs) do
		if typeof(inst) ~= "table" then
			continue
		end
		local stacks = inst.stacks or 0
		if stacks <= 0 and inst.legacyValue == nil then
			continue
		end
		hasAny = true
		Util.Clone(template, attrsFrame, function(clone)
			clone.Visible = true
			local iconData = Textures.Attrs[attrId]
			clone.Image = iconData and iconData.icon or Textures.Empty
			local nameText = AttrDisplayNames[attrId] or attrId
			local valueText = formatAttrValue(attrId, inst)
			local combined = valueText and `{nameText} {valueText}` or nameText
			local nameLabel = clone:FindFirstChild("name")
			local valueLabel = clone:FindFirstChild("value")
			if nameLabel then
				nameLabel.Text = nameText
			end
			if valueLabel then
				valueLabel.Text = valueText or ""
			elseif clone:IsA("TextLabel") or clone:IsA("TextButton") then
				clone.Text = combined
			else
				local textLabel = clone:FindFirstChild("Text") or clone:FindFirstChildWhichIsA("TextLabel")
				if textLabel then
					textLabel.Text = combined
				end
			end
		end)
	end
	attrsFrame.Visible = hasAny
end

function updateEnchantsFrame(enchantsFrame, weaponData)
	if not enchantsFrame then
		return
	end
	local enchantTemplate = enchantsFrame:FindFirstChild("Template")
	if enchantTemplate then
		enchantTemplate.Visible = false
	end
	uiController.ClearScrollChildren(enchantsFrame)

	local enchantSlots = weaponData.enchantSlots or {}
	local enchants = weaponData.enchants or {}
	if #enchantSlots == 0 then
		enchantsFrame.Visible = false
		return
	end

	enchantsFrame.Visible = true
	uiController.ClearScrollChildren(enchantsFrame)
	for slotIndex = 1, #enchantSlots do
		if enchantTemplate then
			Util.Clone(enchantTemplate, enchantsFrame, function(clone)
				clone.Visible = true
				local levelLabel = clone:FindFirstChild("level")
				local enchant = enchants[slotIndex]
				local attrName = enchant and (enchant.attrName or enchant.enchantType)

				if attrName then
					local iconData = Textures.Enchants[attrName]
					clone.icon.Image = iconData and iconData.icon or Textures.Empty
				else
					clone.icon.Image = Textures.Empty
				end

				if levelLabel then
					if enchant and typeof(enchant.roll) == "number" then
						levelLabel.Text = `x{formatNumber(enchant.roll, 2)}`
					else
						levelLabel.Text = ""
					end
				end
			end)
		end
	end
end

function UpdateAttrInfoList()
	if not AttrInfoFrame or not attrInfoTemplate then
		return
	end
	attrInfoTemplate.Visible = false
	uiController.ClearScrollChildren(AttrInfoFrame)

	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local attrSet = {}
	local attrList = {}
	for _, weaponData in weapons do
		if not weaponData then
			continue
		end

		local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
		for attrId, inst in pairs(attrs) do
			if typeof(inst) ~= "table" then
				continue
			end
			local stacks = inst.stacks or 0
			if stacks <= 0 and inst.legacyValue == nil then
				continue
			end
			if not attrSet[attrId] then
				attrSet[attrId] = true
				table.insert(attrList, attrId)
			end
		end

		local enchants = weaponData.enchants or {}
		for _, enchant in pairs(enchants) do
			if enchant then
				local attrName = enchant.attrName or enchant.enchantType
				if attrName and not attrSet[attrName] then
					attrSet[attrName] = true
					table.insert(attrList, attrName)
				end
			end
		end
	end

	table.sort(attrList, function(a, b)
		return getAttrDisplayName(a) < getAttrDisplayName(b)
	end)

	for _, attrId in ipairs(attrList) do
		Util.Clone(attrInfoTemplate, AttrInfoFrame, function(clone)
			clone.Visible = true
			local iconData = Textures.Attrs[attrId] or Textures.Enchants[attrId]
			clone.Image = iconData and iconData.icon or Textures.Empty
			local nameLabel = clone:FindFirstChild("name") or clone:FindFirstChildWhichIsA("TextLabel")
			if nameLabel then
				nameLabel.Text = getAttrDisplayName(attrId)
			end
			local tipText = AttrTips[attrId] or `{getAttrDisplayName(attrId)}: TODO`
			uiController.SetOneLineTip(clone, {
				text = tipText,
			})
		end)
	end
end

local function getWeaponPrice(weaponData, currentStats)
	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	-- local basePrice = weaponProperty.sellPrice
	-- local coinBoost = WeaponAttributeEngine.ComputeCoinBoostMult(weaponData)
	return weaponProperty.sellPrice
end

function UpdateWeaponInfoPosition(position)
	if typeof(position) == "Vector3" then
		position = Vector2.new(position.X, position.Y)
	end
	local parent = WeaponInfoFrame.Parent
	if parent then
		position = position - parent.AbsolutePosition
	end
	WeaponInfoFrame.AnchorPoint = Vector2.new(0, 0)
	WeaponInfoFrame.Position = UDim2.fromOffset(position.X, position.Y)
end

function UpdateWeaponInfoFrame(weaponData)
	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	local currentStats = CalculateWeaponStats(weaponData)

	local weaponNameLabel = WeaponInfoFrame:FindFirstChild("weaponName")
	if weaponNameLabel then
		weaponNameLabel.Text = weaponProperty.name
	end

	local viewportFrame = WeaponInfoFrame:FindFirstChild("ViewportFrame")
	if viewportFrame then
		local weaponModel = WeaponPresets.CreateWeaponModelForUi(weaponData)
		uiController.PetViewport(weaponModel, viewportFrame)
	end

	local statsFrame = WeaponInfoFrame:FindFirstChild("Stats")
	local damageLabel = statsFrame:FindFirstChild("damage")
	damageLabel.Text = `{Util.FormatNumber(currentStats.damage)} DMG`
	local speedLabel = statsFrame:FindFirstChild("speed")
	local speedValue = math.round(currentStats.speed * 10) / 10
	speedLabel.Text = `{speedValue} ATK SPD`
	local qualityLabel = statsFrame:FindFirstChild("quality")
	local qualityPercent = math.floor(currentStats.quality * 100)
	local qualityText = "Great Quality"
	if qualityPercent < 50 then
		qualityText = "Poor Quality"
	elseif qualityPercent < 75 then
		qualityText = "Good Quality"
	elseif qualityPercent < 90 then
		qualityText = "Great Quality"
	else
		qualityText = "Perfect Quality"
	end
	qualityLabel.Text = `[{qualityPercent}%] {qualityText}`
	local priceLabel = statsFrame:FindFirstChild("price")
	local price = getWeaponPrice(weaponData, currentStats)
	priceLabel.Text = `{Util.FormatNumber(price)} $`

	local attrsFrame = WeaponInfoFrame:FindFirstChild("Attrs")
	updateAttrsFrame(attrsFrame, weaponData)

	local enchantsFrame = WeaponInfoFrame:FindFirstChild("Enchants")
	updateEnchantsFrame(enchantsFrame, weaponData)
end

function WeaponUi.OpenEnhanceFrame()
	local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if not tool then
		uiController.SetNotification({
			text = "You are not holding a weapon",
			textColor = Textures.ButtonColors.red,
		})
		return
	end

	-- Find equipped weapon
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponIndex = nil
	for index, weaponData in weapons do
		if weaponData and weaponData.equipped then
			weaponIndex = index
			break
		end
	end

	if not weaponIndex then
		uiController.SetNotification({
			text = "No weapon equipped",
			textColor = Textures.ButtonColors.red,
		})
		return
	end

	uiController.OpenFrame("Enhance")
	WeaponUi.UpdateEnhanceUI(weaponIndex)
end

function WeaponUi.UpdateEnhanceUI(weaponIndex)
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponData = weapons[weaponIndex]
	if not weaponData then
		return
	end

	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	local currentStats = CalculateWeaponStats(weaponData)
	local enhanceLevel = weaponData.enhance or 0
	local nextLevel = enhanceLevel + 1

	-- Check if max enhance reached
	if enhanceLevel >= 10 then
		-- Disable enhance button or show message
		local enhanceBtn = EnhanceFrame:FindFirstChild("Enhance")
		if enhanceBtn then
			enhanceBtn.Visible = false
		end
		return
	end

	local enhanceConfig = WeaponPresets.EnhanceCost[nextLevel]
	if not enhanceConfig then
		return
	end

	-- Update WeaponInfo
	local weaponInfo = EnhanceFrame:FindFirstChild("WeaponInfo")
	if weaponInfo then
		local weaponNameLabel = weaponInfo:FindFirstChild("weaponName")
		if weaponNameLabel then
			weaponNameLabel.Text = weaponProperty.name
		end

		local weaponModel = WeaponPresets.CreateWeaponModelForUi(weaponData)
		uiController.PetViewport(weaponModel, weaponInfo.ViewportFrame)

		-- Update Stats
		local statsFrame = weaponInfo:FindFirstChild("Stats")
		if statsFrame then
			local damageLabel = statsFrame:FindFirstChild("damage")
			if damageLabel then
				damageLabel.Text = `{Util.FormatNumber(currentStats.damage)} DMG`
			end
			local speedLabel = statsFrame:FindFirstChild("speed")
			if speedLabel then
				local speedText = formatNumber(currentStats.speed, 1)
				speedLabel.Text = `{speedText} ATK SPD`
			end
			local qualityLabel = statsFrame:FindFirstChild("quality")
			if qualityLabel then
				local qualityPercent = math.floor(currentStats.quality * 100)
				local qualityText = "Great Quality"
				if qualityPercent < 50 then
					qualityText = "Poor Quality"
				elseif qualityPercent < 75 then
					qualityText = "Good Quality"
				elseif qualityPercent < 90 then
					qualityText = "Great Quality"
				else
					qualityText = "Perfect Quality"
				end
				qualityLabel.Text = `[{qualityPercent}%] {qualityText}`
			end
			local priceLabel = statsFrame:FindFirstChild("price")
			if priceLabel then
				local price = getWeaponPrice(weaponData, currentStats)
				priceLabel.Text = `{Util.FormatNumber(price)} $`
			end
		end

		local attrsFrame = weaponInfo:FindFirstChild("Attrs")
		updateAttrsFrame(attrsFrame, weaponData)

		local enchantsFrame = weaponInfo:FindFirstChild("Enchants")
		updateEnchantsFrame(enchantsFrame, weaponData)

		-- Update Buffs
		local buffsFrame = weaponInfo:FindFirstChild("Buffs")
		if buffsFrame then
			local buffTemplate = buffsFrame:FindFirstChild("Template")
			buffsFrame.Visible = false
			uiController.ClearScrollChildren(buffsFrame)

			if weaponData.buffs and #weaponData.buffs > 0 then
				for _, buff in ipairs(weaponData.buffs) do
					if buff and buffTemplate then
						Util.Clone(buffTemplate, buffsFrame, function(clone)
							clone.Visible = true
							if Textures.Buffs[buff.type] then
								clone.Image = Textures.Buffs[buff.type].icon
							end
						end)
					end
				end
			else
				buffsFrame.Visible = false
			end
		end
	end

	-- Update StatImprovement
	local statImprovement = EnhanceFrame:FindFirstChild("StatImprovement")
	if statImprovement then
		-- All Stats multiplier
		local allStatsFrame = statImprovement:FindFirstChild("AllStats")
		if allStatsFrame then
			local beforeLabel = allStatsFrame:FindFirstChild("Before")
			local afterLabel = allStatsFrame:FindFirstChild("After")
			if beforeLabel then
				local beforeMult = formatNumber(currentStats.multiplier, 1)
				beforeLabel.Text = `{beforeMult}x`
			end
			if afterLabel then
				local afterMult = formatNumber(enhanceConfig.statsMultiplier, 1)
				afterLabel.Text = `{afterMult}x`
			end
		end

		-- Slot Count
		local slotCountFrame = statImprovement:FindFirstChild("SlotCount")
		if slotCountFrame then
			local beforeLabel = slotCountFrame:FindFirstChild("Before")
			local afterLabel = slotCountFrame:FindFirstChild("After")
			local currentSlots = weaponData.enchantSlots and #weaponData.enchantSlots or 0
			if beforeLabel then
				beforeLabel.Text = tostring(currentSlots)
			end
			if afterLabel then
				afterLabel.Text = tostring(currentSlots + enhanceConfig.enchantSlot)
			end
		end

		-- Craft Chance
		local craftChanceFrame = statImprovement:FindFirstChild("CraftChance")
		if craftChanceFrame then
			local chanceLabel = craftChanceFrame:FindFirstChild("Chance")
			if chanceLabel then
				local successRate = enhanceConfig.successRate
				local chanceText = "OK"
				local textColor = Textures.ButtonColors.green
				if successRate < 70 then
					chanceText = "RISKY"
					textColor = Textures.ButtonColors.red
				elseif successRate < 85 then
					chanceText = "CAUTION"
					textColor = Textures.ButtonColors.golden
				end
				chanceLabel.Text = `{chanceText} ({successRate}%)`
				chanceLabel.TextColor3 = textColor
			end
		end
	end

	-- Update Requirements
	local requirementsFrame = EnhanceFrame:FindFirstChild("Requirements")
	if requirementsFrame then
		local template = requirementsFrame:FindFirstChild("Template")
		template.Visible = false
		uiController.ClearScrollChildren(requirementsFrame)

		local backpack = ClientData:GetOneData(Keys.DataKey.backpack)
		local wins = ClientData:GetOneData(Keys.DataKey.wins) or 0

		if template and enhanceConfig.cost then
			Util.Clone(template, requirementsFrame, function(clone)
				clone.Visible = true
				local icon = clone:FindFirstChild("icon")
				local countLabel = icon and icon:FindFirstChild("count")
				if icon then
					icon.Image = Textures.UnclassifiedIcons.wins
				end
				if countLabel then
					countLabel.Text = `x{Util.FormatNumber(enhanceConfig.cost)}`
					-- countLabel.TextColor3 = wins >= enhanceConfig.cost and Textures.ButtonColors.white
					-- 	or Textures.ButtonColors.red
				end
			end)
		end

		if enhanceConfig.requireItems then
			for _, item in ipairs(enhanceConfig.requireItems) do
				if template then
					Util.Clone(template, requirementsFrame, function(clone)
						clone.Visible = true

						local icon = clone:FindFirstChild("icon")
						local countLabel = icon and icon:FindFirstChild("count")

						if item.itemType == Keys.ItemType.wins then
							-- Use wins icon
							if icon then
								icon.Image = Textures.UnclassifiedIcons.wins
							end
							if countLabel then
								countLabel.Text = `x{item.count}`
							end
						elseif item.itemType == Keys.ItemType.ores then
							-- Use ore icon
							if icon then
								icon.Image = Textures.GetIcon({ itemType = Keys.ItemType.ores, name = item.itemName })
							end
							if countLabel then
								countLabel.Text = `x{item.count}`
							end
						end
					end)
				end
			end
		end
	end

	-- Bind Enhance button
	local enhanceBtn = EnhanceFrame:FindFirstChild("Enhance")
	if enhanceBtn then
		enhanceBtn.Visible = true
		uiController.SetButtonHoverAndClick(enhanceBtn, function()
			SystemMgr.systems.WeaponSystem.Server:EnhanceWeapon({
				weaponIndex = weaponIndex,
			})
		end)
	end

	-- Bind X button
	local xButton = EnhanceFrame:FindFirstChild("X")
	if xButton then
		uiController.SetButtonHoverAndClick(xButton, function()
			uiController.CloseFrame("Enhance")
		end)
	end
end

function WeaponUi.EnhanceResult(args)
	local success = args.success
	local weaponIndex = args.weaponIndex
	local backpack = args.backpack

	if backpack then
		ClientData:SetOneData(Keys.DataKey.backpack, backpack)
	end

	if success then
		uiController.SetNotification({
			text = "Enhancement successful!",
			textColor = Textures.ButtonColors.green,
		})
		-- Update UI with new weapon data
		if weaponIndex then
			WeaponUi.UpdateEnhanceUI(weaponIndex)
		end
	else
		uiController.SetNotification({
			text = "Enhancement failed!",
			textColor = Textures.ButtonColors.red,
		})
		-- Refresh requirements to show updated resource counts
		if weaponIndex then
			WeaponUi.UpdateEnhanceUI(weaponIndex)
		end
	end
	UpdateAttrInfoList()
end

-- Enchant functions
local selectedOreForEnchant = nil

function WeaponUi.OpenEnchantFrame()
	local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if not tool then
		uiController.SetNotification({
			text = "You are not holding a weapon",
			textColor = Textures.ButtonColors.red,
		})
		return
	end

	-- Find equipped weapon
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponIndex = nil
	for index, weaponData in weapons do
		if weaponData and weaponData.equipped then
			weaponIndex = index
			break
		end
	end

	if not weaponIndex then
		uiController.SetNotification({
			text = "No weapon equipped",
			textColor = Textures.ButtonColors.red,
		})
		return
	end

	selectedOreForEnchant = nil
	uiController.OpenFrame("Enchant")
	WeaponUi.UpdateEnchantUI(weaponIndex)
end

function WeaponUi.UpdateEnchantUI(weaponIndex)
	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponData = weapons[weaponIndex]
	if not weaponData then
		return
	end

	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	local currentStats = CalculateWeaponStats(weaponData)

	-- Update WeaponInfo
	local weaponInfo = EnchantFrame:FindFirstChild("WeaponInfo")
	if weaponInfo then
		local weaponNameLabel = weaponInfo:FindFirstChild("weaponName")
		if weaponNameLabel then
			weaponNameLabel.Text = weaponProperty.name
		end

		local viewportFrame = weaponInfo:FindFirstChild("ViewportFrame")
		if viewportFrame then
			local weaponModel = WeaponPresets.CreateWeaponModelForUi(weaponData)
			uiController.PetViewport(weaponModel, viewportFrame)
		end

		-- Update Stats
		local statsFrame = weaponInfo:FindFirstChild("Stats")
		if statsFrame then
			local damageLabel = statsFrame:FindFirstChild("damage")
			if damageLabel then
				damageLabel.Text = `{Util.FormatNumber(currentStats.damage)} DMG`
			end
			local speedLabel = statsFrame:FindFirstChild("speed")
			if speedLabel then
				local speedText = formatNumber(currentStats.speed, 1)
				speedLabel.Text = `{speedText} ATK SPD`
			end
			local qualityLabel = statsFrame:FindFirstChild("quality")
			if qualityLabel then
				local qualityPercent = math.floor(currentStats.quality * 100)
				local qualityText = "Great Quality"
				if qualityPercent < 50 then
					qualityText = "Poor Quality"
				elseif qualityPercent < 75 then
					qualityText = "Good Quality"
				elseif qualityPercent < 90 then
					qualityText = "Great Quality"
				else
					qualityText = "Perfect Quality"
				end
				qualityLabel.Text = `[{qualityPercent}%] {qualityText}`
			end
			local priceLabel = statsFrame:FindFirstChild("price")
			if priceLabel then
				local price = getWeaponPrice(weaponData, currentStats)
				priceLabel.Text = `{Util.FormatNumber(price)} $`
			end
		end

		local attrsFrame = weaponInfo:FindFirstChild("Attrs")
		updateAttrsFrame(attrsFrame, weaponData)

		local enchantsFrame = weaponInfo:FindFirstChild("Enchants")
		updateEnchantsFrame(enchantsFrame, weaponData)

		-- Update Buffs
		local buffsFrame = weaponInfo:FindFirstChild("Buffs")
		if buffsFrame then
			local buffTemplate = buffsFrame:FindFirstChild("Template")
			if buffTemplate then
				buffTemplate.Visible = false
			end
			uiController.ClearScrollChildren(buffsFrame)

			if weaponData.buffs and #weaponData.buffs > 0 then
				buffsFrame.Visible = true
				for _, buff in ipairs(weaponData.buffs) do
					if buff and buffTemplate then
						Util.Clone(buffTemplate, buffsFrame, function(clone)
							clone.Visible = true
							if Textures.Buffs[buff.type] then
								clone.Image = Textures.Buffs[buff.type].icon
							end
						end)
					end
				end
			else
				buffsFrame.Visible = false
			end
		end
	end

	-- Update ScrollingFrame with available ores
	local hasEnchantableOre = false
	local oreScroll = EnchantFrame:FindFirstChild("ScrollingFrame")
	if oreScroll then
		local oreTemplate = oreScroll:FindFirstChild("Template")
		if oreTemplate then
			oreTemplate.Visible = false
		end
		uiController.ClearScrollChildren(oreScroll)

		local backpack = ClientData:GetOneData(Keys.DataKey.backpack)
		local ores = backpack.ores or {}
		local oreEntries = {}
		for oreName, count in pairs(ores) do
			if count > 0 and WeaponPresets.Enchants[oreName] then
				table.insert(oreEntries, {
					oreName = oreName,
					count = count,
				})
			end
		end
		table.sort(oreEntries, function(a, b)
			return a.oreName < b.oreName
		end)

		for _, entry in ipairs(oreEntries) do
			local oreName = entry.oreName
			local count = entry.count
			hasEnchantableOre = true
			if oreTemplate then
				Util.Clone(oreTemplate, oreScroll, function(clone)
					clone.Visible = true
					clone.Name = oreName

					local countLabel = clone:FindFirstChild("count")
					if countLabel then
						countLabel.Text = `x{count}`
					end

					local itemNameLabel = clone:FindFirstChild("ItemName")
					if itemNameLabel then
						itemNameLabel.Text = oreName
					end

					local icon = clone:FindFirstChild("icon")
					if icon then
						icon.Image = Textures.GetIcon({ itemType = Keys.ItemType.ores, name = oreName })
					end

					uiController.SetButtonHoverAndClick(clone, function()
						WeaponUi.UpdateEnchantPreview(weaponIndex, oreName)
					end)
				end)
			end
		end
	end

	-- Initialize Preview as empty
	WeaponUi.UpdateEnchantPreview(weaponIndex, nil)
	if not hasEnchantableOre then
		local preview = EnchantFrame:FindFirstChild("Preview")
		if preview then
			local titleLabel = preview:FindFirstChild("title")
			if titleLabel then
				titleLabel.Text = "No Enchantable Ores"
			end
		end
	end

	-- Bind Enchant button
	local preview = EnchantFrame:FindFirstChild("Preview")
	if preview then
		local enchantBtn = preview:FindFirstChild("Enchant")
		if enchantBtn then
			-- Update cost display
			local costLabel = enchantBtn:FindFirstChild("cost")
			if costLabel then
				costLabel.Text = `{WeaponPresets.EnchantCost}`
			end

			uiController.SetButtonHoverAndClick(enchantBtn, function()
				if not selectedOreForEnchant then
					uiController.SetNotification({
						text = "Please select an ore to enchant",
						textColor = Textures.ButtonColors.red,
					})
					return
				end
				SystemMgr.systems.WeaponSystem.Server:EnchantWeapon({
					weaponIndex = weaponIndex,
					oreName = selectedOreForEnchant,
				})
			end)
		end
	end

	-- Bind X button
	local xButton = EnchantFrame:FindFirstChild("X")
	if xButton then
		uiController.SetButtonHoverAndClick(xButton, function()
			uiController.CloseFrame("Enchant")
		end)
	end
end

function WeaponUi.UpdateEnchantPreview(weaponIndex, oreName)
	selectedOreForEnchant = oreName

	local weapons = ClientData:GetOneData(Keys.DataKey.backpack).weapons
	local weaponData = weapons[weaponIndex]
	if not weaponData then
		return
	end

	local preview = EnchantFrame:FindFirstChild("Preview")
	if not preview then
		return
	end
	local rarityNameLabel = preview:FindFirstChild("RarityName")
	local titleLabel = preview:FindFirstChild("title")
	local previewViewport = preview:FindFirstChild("ViewportFrame")

	if not oreName then
		-- Show empty state
		local itemNameLabel = preview:FindFirstChild("ItemName")
		if itemNameLabel then
			itemNameLabel.Text = "Select an Ore"
		end

		if titleLabel then
			titleLabel.Text = "Enchants:"
		end
		if rarityNameLabel then
			rarityNameLabel.Text = ""
			rarityNameLabel.Visible = false
		end
		if previewViewport then
			for _, child in ipairs(previewViewport:GetChildren()) do
				if child:IsA("Camera") or child:IsA("WorldModel") or child:IsA("Model") or child:IsA("BasePart") then
					child:Destroy()
				end
			end
		end

		local enchantsScroll = preview:FindFirstChild("Enchants")
		if enchantsScroll then
			uiController.ClearScrollChildren(enchantsScroll)
		end

		return
	end

	-- Get enchant info
	local enchantPreset = WeaponPresets.Enchants[oreName]
	if not enchantPreset then
		return
	end

	-- Create preview weapon data with new enchant
	local previewWeaponData = {}
	for k, v in pairs(weaponData) do
		previewWeaponData[k] = v
	end

	if not previewWeaponData.enchants then
		previewWeaponData.enchants = {}
	end

	-- Create a list of current enchants for preview (slot-based)
	local previewEnchants = {}
	local slots = previewWeaponData.enchantSlots or {}
	local enchants = previewWeaponData.enchants or {}
	for i = 1, #slots do
		if enchants[i] then
			table.insert(previewEnchants, enchants[i])
		end
	end

	-- Add the new enchant to preview
	table.insert(previewEnchants, {
		attrName = enchantPreset.attrName,
		oreName = oreName,
		rollMin = enchantPreset.rollMin,
		rollMax = enchantPreset.rollMax,
	})

	-- Update Preview.ItemName
	local itemNameLabel = preview:FindFirstChild("ItemName")
	if itemNameLabel then
		local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
		itemNameLabel.Text = weaponProperty.name
	end

	if rarityNameLabel then
		rarityNameLabel.Text = oreName
		rarityNameLabel.Visible = true
	end
	if titleLabel then
		titleLabel.Text = "Enchants:"
	end
	if previewViewport then
		local previewWeaponModel = WeaponPresets.CreateWeaponModelForUi(weaponData)
		uiController.PetViewport(previewWeaponModel, previewViewport)
	end

	-- Update Preview.Enchants
	local enchantsScroll = preview:FindFirstChild("Enchants")
	if enchantsScroll then
		local enchantTemplate = enchantsScroll:FindFirstChild("Template")
		if enchantTemplate then
			enchantTemplate.Visible = false
		end
		uiController.ClearScrollChildren(enchantsScroll)

		for _, enchant in ipairs(previewEnchants) do
			if enchant and enchantTemplate then
				Util.Clone(enchantTemplate, enchantsScroll, function(clone)
					clone.Visible = true
					clone.Name = enchant.attrName or enchant.enchantType
					local attrName = enchant.attrName or enchant.enchantType
					local nameLabel = clone:FindFirstChild("name")
					if nameLabel then
						local displayName = EnchantDisplayNames[attrName] or attrName or "Enchant"
						local rollText = ""
						if typeof(enchant.roll) == "number" then
							rollText = ` x{formatNumber(enchant.roll, 2)}`
						elseif enchant.rollMin and enchant.rollMax then
							rollText = ` x{formatNumber(enchant.rollMin, 2)}-{formatNumber(enchant.rollMax, 2)}`
						end
						nameLabel.Text = `{displayName}{rollText}`
						nameLabel.TextWrapped = false
						nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
					end

					local iconData = attrName and Textures.Enchants[attrName]
					local iconImage = iconData and iconData.icon or Textures.Empty
					local icon = clone:FindFirstChild("icon")
					if icon and icon:IsA("ImageLabel") then
						icon.Image = iconImage
					elseif clone:IsA("ImageLabel") then
						clone.Image = iconImage
					end
				end)
			end
		end
	end
end

function WeaponUi.EnchantResult(args)
	local success = args.success
	local weaponIndex = args.weaponIndex
	local backpack = args.backpack

	if backpack then
		ClientData:SetOneData(Keys.DataKey.backpack, backpack)
	end

	if success then
		uiController.SetNotification({
			text = "Enchantment successful!",
			textColor = Textures.ButtonColors.green,
		})
		-- Update UI with new weapon data
		if weaponIndex then
			selectedOreForEnchant = nil
			WeaponUi.UpdateEnchantUI(weaponIndex)
		end
	else
		uiController.SetNotification({
			text = args.error or "Enchantment failed!",
			textColor = Textures.ButtonColors.red,
		})
		-- Refresh UI to show updated ore counts
		if weaponIndex then
			WeaponUi.UpdateEnchantUI(weaponIndex)
		end
	end
	UpdateAttrInfoList()
end

return WeaponUi
