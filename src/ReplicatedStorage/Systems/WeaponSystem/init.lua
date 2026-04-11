--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.2 Analysis
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local WeaponPresets = require(script.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Types = require(Replicated.configs.Types)
local Libraries = script.Libraries
local ShoulderCamera = require(Libraries:WaitForChild("ShoulderCamera"))
local WeaponsGui = require(Libraries:WaitForChild("WeaponsGui"))
local SpringService = require(Libraries:WaitForChild("SpringService"))
ShoulderCamera.SpringService = SpringService
local ancestorHasTag = require(Libraries:WaitForChild("ancestorHasTag"))
local Util = require(Replicated.modules.Util)
local TableModule = require(Replicated.modules.TableModule)
local WeaponAttributeEngine = require(Replicated.modules.WeaponAttributeEngine)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local WeaponTypes = script.WeaponTypes
local WEAPON_TYPES_LOOKUP = {}
local WeaponData = script.WeaponData

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local SprintEnabled = false
local SlowZoomWalkEnabled = false
local WeaponUi = { pendingCalls = {} }
setmetatable(WeaponUi, Types.mt)

local WeaponSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
	knownWeapons = {},
	CurrentWeaponChanged = Instance.new("BindableEvent"),
}
WeaponSystem.__index = WeaponSystem

if IsServer then
	WeaponSystem.Client = setmetatable({}, WeaponSystem)
	WeaponSystem.AllClients = setmetatable({}, WeaponSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	-- AnalyticsService = game:GetService("AnalyticsService")
else
	WeaponSystem.Server = setmetatable({}, WeaponSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

local _damageCallback = nil
local _getTeamCallback = nil

local function getBlockIdFromPart(part)
	while part and part ~= workspace do
		local blockId = part:GetAttribute("BlockId")
		if blockId then
			return blockId
		end
		part = part.Parent
	end
end

function WeaponSystem.setDamageCallback(cb)
	_damageCallback = cb
end

function WeaponSystem.setGetTeamCallback(cb)
	_getTeamCallback = cb
end

function WeaponSystem:Init()
	GetSystemMgr()

	local function onNewWeaponType(weaponTypeModule)
		if not weaponTypeModule:IsA("ModuleScript") then
			return
		end
		local weaponTypeName = weaponTypeModule.Name
		xpcall(function()
			coroutine.wrap(function()
				local weaponType = require(weaponTypeModule)
				assert(
					typeof(weaponType) == "table",
					string.format('WeaponType "%s" did not return a valid table', weaponTypeModule:GetFullName())
				)
				WEAPON_TYPES_LOOKUP[weaponTypeName] = weaponType
			end)()
		end, function(errMsg)
			warn(string.format("Error while loading %s: %s", weaponTypeModule:GetFullName(), errMsg))
			warn(debug.traceback())
		end)
	end
	for _, child in pairs(WeaponTypes:GetChildren()) do
		onNewWeaponType(child)
	end
	WeaponTypes.ChildAdded:Connect(onNewWeaponType)

	CollectionService:GetInstanceAddedSignal(Keys.Tags.Weapon):Connect(WeaponSystem.onWeaponAdded)
	CollectionService:GetInstanceRemovedSignal(Keys.Tags.Weapon):Connect(WeaponSystem.onWeaponRemoved)

	for _, instance in pairs(CollectionService:GetTagged(Keys.Tags.Weapon)) do
		WeaponSystem.onWeaponAdded(instance)
	end

	if IsServer then
		local effectsFolder = script.Assets.Effects
		local partNonZeroTransparencyValues = {
			["BulletHole"] = 1,
			["Explosion"] = 1,
			["Pellet"] = 1,
			["Scorch"] = 1,
			["Bullet"] = 1,
			["Plasma"] = 1,
			["Railgun"] = 1,
		}
		local decalNonZeroTransparencyValues = { ["ScorchMark"] = 0.25 }
		local particleEmittersToDisable = { ["Smoke"] = true }
		local imageLabelNonZeroTransparencyValues = { ["Impact"] = 0.25 }
		-- for _, descendant in pairs(effectsFolder:GetDescendants()) do
		-- 	if descendant:IsA("BasePart") then
		-- 		if partNonZeroTransparencyValues[descendant.Name] ~= nil then
		-- 			descendant.Transparency = partNonZeroTransparencyValues[descendant.Name]
		-- 		else
		-- 			descendant.Transparency = 0
		-- 		end
		-- 	elseif descendant:IsA("Decal") then
		-- 		descendant.Transparency = 0
		-- 		if decalNonZeroTransparencyValues[descendant.Name] ~= nil then
		-- 			descendant.Transparency = decalNonZeroTransparencyValues[descendant.Name]
		-- 		else
		-- 			descendant.Transparency = 0
		-- 		end
		-- 	elseif descendant:IsA("ParticleEmitter") then
		-- 		descendant.Enabled = true
		-- 		if particleEmittersToDisable[descendant.Name] ~= nil then
		-- 			descendant.Enabled = false
		-- 		else
		-- 			descendant.Enabled = true
		-- 		end
		-- 	elseif descendant:IsA("ImageLabel") then
		-- 		if imageLabelNonZeroTransparencyValues[descendant.Name] ~= nil then
		-- 			descendant.ImageTransparency = imageLabelNonZeroTransparencyValues[descendant.Name]
		-- 		else
		-- 			descendant.ImageTransparency = 0
		-- 		end
		-- 	end
		-- end
	else
		-- self.camera = ShoulderCamera.new(self)
		-- self.gui = WeaponsGui.new(self)
		-- if SprintEnabled then
		-- 	self.camera:setSprintEnabled(true)
		-- end
		-- if SlowZoomWalkEnabled then
		-- 	self.camera:setSlowZoomWalkEnabled(true)
		-- end

		-- self.camera:setEnabled(true) -- shoulder camera

		-- LocalPlayer.CharacterAdded:Connect(function(character)
		-- 	local humanoid = character:WaitForChild("Humanoid")
		-- 	humanoid.Seated:Connect(function(isSeated)
		-- 		if isSeated then
		-- 			WeaponSystem.seatedWeapon = character:FindFirstChildOfClass("Tool")
		-- 			humanoid:UnequipTools()
		-- 		else
		-- 			humanoid:EquipTool(WeaponSystem.seatedWeapon)
		-- 		end
		-- 	end)

		-- 	character.ChildAdded:Connect(function(child)
		-- 		if child:IsA("Tool") then
		-- 			child.Equipped:Connect(function()
		-- 				self.camera:setEnabled(true)
		-- 				self.gui:setEnabled(true)
		-- 			end)
		-- 		end
		-- 	end)

		-- 	character.ChildRemoved:Connect(function(child)
		-- 		if child:IsA("Tool") then
		-- 			self.camera:setEnabled(false)
		-- 			self.gui:setEnabled(false)
		-- 		end
		-- 	end)
		-- end)
	end
end

function WeaponSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.players[player.UserId] = {
			equippedWeapon = {},
		}
		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons
		if #weapons == 0 then
			weapons[1] = table.clone(WeaponPresets.DefaultWeaponData)
			weapons[1].weaponId = "Pickaxe1"
			weapons[1].equipped = true
		end
		local weaponIndex
		for index, weaponData in weapons do
			if weaponData.equipped then
				weaponIndex = index
				break
			end
		end
		if not weaponIndex then
			for index, weaponData in weapons do
				weaponData.equipped = true
				weaponIndex = index
				break
			end
		end
		if player.Character then
			self:EquipWeapon(SENDER, player, {
				weaponIndex = weaponIndex,
			})
		else
			player.CharacterAdded:Once(function(character)
				self:EquipWeapon(SENDER, player, {
					weaponIndex = weaponIndex,
				})
			end)
		end

		self.Client:PlayerAdded(player, {
			backpack = playerIns:GetOneData(Keys.DataKey.backpack),
		})
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)

		local pendingCalls = WeaponUi.pendingCalls
		WeaponUi = require(script.ui)
		WeaponUi.Init(pendingCalls)
	end
end

function WeaponSystem:EquipWeapon(sender, player, args)
	if IsServer then
		player = player or sender
		local weaponIndex = args.weaponIndex
		local Character = player.Character
		if not Character then
			return
		end
		local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
		if not Humanoid then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons
		for index, weaponData in weapons do
			if weaponData and weaponData.equipped then
				weaponData.equipped = false
			end
		end

		local weaponData = weapons[weaponIndex]
		if not weaponData then
			return
		end
		weaponData.equipped = true

		local deleteNames = {}
		for _, weaponType in Keys.WeaponTypes do
			table.insert(deleteNames, weaponType)
			table.insert(deleteNames, weaponType .. "Model")
		end
		for _, deleteName in deleteNames do
			local child = Character:FindFirstChild(deleteName)
			if child then
				child:Destroy()
			end
		end
		-- Keep only one runtime weapon tool instance across Character + Backpack.
		-- Without this cleanup, switching weapons after unequip can leave stale tools in Backpack.
		for _, container in ipairs({ Character, player:FindFirstChildOfClass("Backpack") }) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") and CollectionService:HasTag(child, Keys.Tags.Weapon) then
						child:Destroy()
					end
				end
			end
		end

		local playerCache = self.players[player.UserId]
		playerCache.equippedWeapon = weaponData

		-- Apply equip-time attributes (replicates to client).
		-- AttackSpeed affects both animation speed (already read in WeaponTypes) and firing cooldown (we scale cooldown in WeaponTypes).
		local attackSpeedMult = WeaponAttributeEngine.ComputeAttackSpeedMult(weaponData)
		local gamePasses = playerIns:GetOneData(Keys.DataKey.gamePasses) or {}
		local attackSpeedPassMult = 1
		if gamePasses.attackSpeedX2 then
			local effectCfg = EcoPresets.GamePassEffects and EcoPresets.GamePassEffects.attackSpeedX2
			attackSpeedPassMult = (effectCfg and effectCfg.mult) or 2
		end
		player:SetAttribute("AttackSpeed", attackSpeedMult * attackSpeedPassMult)

		local weaponId = weaponData.weaponId
		local weaponPreset = WeaponPresets.Weapons[weaponId]
		local animationType = weaponPreset.weaponType
		local toolName = animationType
		local tool = script.Assets.Tools:FindFirstChild(toolName)
		if not tool then
			warn("Tool not found", toolName)
			return
		end

		-- Equip tool
		tool = tool:Clone() :: Tool
		local Configuration = tool:WaitForChild("Configuration")
		for k, v in weaponPreset do
			if k == "name" then
				v = weaponId
			end
			if not Configuration:FindFirstChild(k) then
				local value
				if typeof(v) == "number" then
					value = Instance.new("NumberValue")
				elseif typeof(v) == "string" then
					value = Instance.new("StringValue")
					value.Value = tostring(v)
				elseif typeof(v) == "boolean" then
					value = Instance.new("BoolValue")
					value.Value = v
				else
					warn("Invalid value type", typeof(v))
					return
				end
				value.Name = k
				value.Parent = Configuration
			end
			Configuration:FindFirstChild(k).Value = v
		end
		tool.Parent = player.Backpack
		CollectionService:AddTag(tool, Keys.Tags.Weapon)
		tool.Equipped:Connect(function()
			local model = self:EquipWeaponModel(player, weaponData)
			tool.Unequipped:Once(function()
				model:Destroy()
			end)
		end)
		Humanoid:EquipTool(tool)

		SystemMgr.systems.QuestSystem:DoQuest(player, {
			questType = Keys.QuestType.equipWeapon,
			value = 1,
		})

		self.Client:EquipWeapon(player, {
			weaponIndex = weaponIndex,
			backpack = playerIns:GetOneData(Keys.DataKey.backpack),
		})

		if #weapons > 1 then
			playerIns:LogOnboarding(5, "equipWeapon")
		end
	else
		self.equippedWeaponId = args.backpack.weapons[args.weaponIndex].weaponId
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		WeaponUi.EquipWeapon(args)
	end
end

function WeaponSystem:GetEquippedWeaponData(player)
	if not IsServer then
		return nil
	end
	if not player then
		return nil
	end

	-- Prefer server cache (kept updated by EquipWeapon).
	local cache = self.players[player.UserId]
	if cache and cache.equippedWeapon then
		return cache.equippedWeapon
	end

	-- Fallback: scan backpack data (more robust for edge-cases).
	local playerIns = PlayerServerClass.GetIns(player)
	if not playerIns then
		return nil
	end
	local backpack = playerIns:GetOneData(Keys.DataKey.backpack)
	local weapons = backpack and backpack.weapons
	if typeof(weapons) ~= "table" then
		return nil
	end
	for _, weaponData in ipairs(weapons) do
		if weaponData and weaponData.equipped then
			if cache then
				cache.equippedWeapon = weaponData
			end
			return weaponData
		end
	end
	return nil
end

function WeaponSystem:AddWeaponList(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local weaponList = args.weaponList
		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons

		for _, weaponData in weaponList do
			table.insert(weapons, weaponData)
		end
		table.sort(weapons, function(a, b)
			local aProperty = WeaponPresets.GetWeaponProperty(a)
			local bProperty = WeaponPresets.GetWeaponProperty(b)
			local aValue = aProperty.sellPrice or 0
			local bValue = bProperty.sellPrice or 0
			if aValue ~= bValue then
				return aValue > bValue
			end

			local aDamage = aProperty.baseDamage or 0
			local bDamage = bProperty.baseDamage or 0
			if aDamage ~= bDamage then
				return aDamage > bDamage
			end

			return tostring(aProperty.weaponId or "") < tostring(bProperty.weaponId or "")
		end)

		self.Client:AddWeaponList(player, {
			backpack = playerIns:GetOneData(Keys.DataKey.backpack),
		})
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		WeaponUi.AddWeapons(args)
	end
end

function WeaponSystem:DeleteWeaponList(sender, player, args)
	if IsServer then
		player = player or sender
		local deletingIndexes = args.deletingIndexes
		table.sort(deletingIndexes)
		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons

		local sellCash = 0
		for i = #deletingIndexes, 1, -1 do
			local index = deletingIndexes[i]
			local weaponData = weapons[index]
			local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
			sellCash += weaponProperty.sellPrice
			table.remove(weapons, index)
		end

		if sellCash > 0 then
			SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
				resourceType = Keys.ItemType.wins,
				count = sellCash,
				reason = "sellWeapon",
			})
		end

		table.sort(weapons, function(a, b)
			local aProperty = WeaponPresets.GetWeaponProperty(a)
			local bProperty = WeaponPresets.GetWeaponProperty(b)
			local aValue = aProperty.sellPrice or 0
			local bValue = bProperty.sellPrice or 0
			if aValue ~= bValue then
				return aValue > bValue
			end

			local aDamage = aProperty.baseDamage or 0
			local bDamage = bProperty.baseDamage or 0
			if aDamage ~= bDamage then
				return aDamage > bDamage
			end

			return tostring(aProperty.weaponId or "") < tostring(bProperty.weaponId or "")
		end)

		self.Client:AddWeaponList(player, {
			backpack = playerIns:GetOneData(Keys.DataKey.backpack),
		})
	end
end

function WeaponSystem:WeaponActivated(sender, player, args)
	local instance = args.instance
	local activated = args.activated
	local weapon = self.getWeaponForInstance(instance)
	local weaponType = getmetatable(weapon)

	if weapon and weaponType then
		if weapon.instance == instance and weapon.player == player then
			weapon:setActivated(activated, true)
		end
	end
end

function WeaponSystem:WeaponFired(sender, player, args)
	player = player or sender
	local instance = args.instance
	local weapon = self.getWeaponForInstance(instance)
	local weaponType = getmetatable(weapon)

	if weapon and weaponType then
		if weapon.instance == args.instance and weaponType.CanBeFired and weapon.player == player then
			weapon:onFired(player, args.fireInfo, true)
		end
	end
end

function WeaponSystem:WeaponReloadRequest(sender, player, args)
	player = player or sender
	local instance = args.instance
	local weapon = self.getWeaponForInstance(instance)
	local weaponType = getmetatable(weapon)

	if weapon then
		if weapon.instance == args.instance and weaponType.CanBeReloaded then
			weapon:reload(player, true)
		end
	end
end

function WeaponSystem:WeaponReloaded(sender, player, args)
	player = args.player
	local instance = args.instance
	local weapon = self.getWeaponForInstance(instance)
	local weaponType = getmetatable(weapon)
	if weapon then
		if weapon.instance == instance and weaponType.CanBeReloaded and player ~= nil and player ~= LocalPlayer then
			weapon:onReloaded(player, true)
		end
	end
end

function WeaponSystem:WeaponReloadCanceled(sender, player, args)
	player = args.player
	local instance = args.instance
	local weapon = self.getWeaponForInstance(instance)
	local weaponType = getmetatable(weapon)
	if weapon then
		if weapon.instance == args.instance and weaponType.CanBeReloaded and args.player ~= LocalPlayer then
			weapon:cancelReload(args.player, true)
		end
	end
end

function WeaponSystem:WeaponHit(sender, player, args)
	if IsServer then
		player = player or sender
		local instance = args.instance
		local hitInfo = args.hitInfo
		local weapon = self.getWeaponForInstance(instance)
		local weaponType = getmetatable(weapon)
		if weapon then
			if weapon.instance == instance and weaponType.CanHit then
				local blockIds = hitInfo.blockIds
				local unique = {}
				local finalIds = {}

				local function addBlockId(blockId)
					if not blockId or unique[blockId] then
						return
					end
					unique[blockId] = true
					table.insert(finalIds, blockId)
				end

				if typeof(blockIds) == "table" then
					for _, blockId in ipairs(blockIds) do
						addBlockId(blockId)
					end
				else
					local blockId = getBlockIdFromPart(hitInfo.part or hitInfo.instance)
					addBlockId(blockId)
				end

				if #finalIds > 0 then
					SystemMgr.systems.BlockSystem:HurtBlocksWithWeapon(SENDER, player, {
						blockIds = finalIds,
					})
				end
			end
		end
	end
end

function WeaponSystem:TeleportHandle(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		-- self.Client:TeleportHandle(player, args)
	else
		-- WeaponUi.TeleportHandle()
	end
end

---- [[ Enhance and Enchant ]] ----
function WeaponSystem:EnhanceWeapon(sender, player, args)
	if IsServer then
		player = player or sender

		-- Validate player has character
		if not player.Character then
			return
		end

		local weaponIndex = args.weaponIndex
		if not weaponIndex then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons
		local weaponData = weapons[weaponIndex]

		if not weaponData then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon not found",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check if weapon is equipped
		if not weaponData.equipped then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon must be equipped to enhance",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local enhanceLevel = weaponData.enhance or 0

		-- Check max enhance level
		if enhanceLevel >= 10 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon is already at maximum enhance level",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local nextLevel = enhanceLevel + 1
		local enhanceConfig = WeaponPresets.EnhanceCost[nextLevel]

		if not enhanceConfig then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Invalid enhance level",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check resources
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)
		local wins = playerIns:GetOneData(Keys.DataKey.wins)
		local cost = enhanceConfig.cost
		if wins < cost then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `Not enough wins! Need {cost}, have {wins}`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		if enhanceConfig.requireItems then
			for _, item in ipairs(enhanceConfig.requireItems) do
				if item.itemType == Keys.ItemType.ores then
					local oreCount = backpack.ores and backpack.ores[item.itemName] or 0
					if oreCount < item.count then
						SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
							text = `Not enough {item.itemName}! Need {item.count}, have {oreCount}`,
							textColor = Color3.fromRGB(255, 0, 0),
						})
						return
					end
				end
			end
		end

		-- Deduct resources
		SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
			resourceType = Keys.ItemType.wins,
			count = -enhanceConfig.cost,
			reason = "enhanceWeapon",
		})
		if enhanceConfig.requireItems then
			for _, item in ipairs(enhanceConfig.requireItems) do
				if item.itemType == Keys.ItemType.ores then
					SystemMgr.systems.BackpackSystem:DeleteItems(SENDER, player, {
						items = {
							{
								itemType = Keys.ItemType.ores,
								itemName = item.itemName,
								count = item.count,
							},
						},
					})
				end
			end
		end

		-- Roll success chance
		local success = math.random(1, 100) <= enhanceConfig.successRate

		if success then
			-- Increment enhance level
			weaponData.enhance = nextLevel

			-- Add enchant slots
			if enhanceConfig.enchantSlot > 0 then
				if not weaponData.enchantSlots then
					weaponData.enchantSlots = {}
				end
				for i = 1, enhanceConfig.enchantSlot do
					if not weaponData.enchantSlots[i] then
						weaponData.enchantSlots[i] = {}
					end
				end
			end

			-- Update backpack data
			local updatedBackpack = playerIns:GetOneData(Keys.DataKey.backpack)

			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `Enhancement successful! Weapon is now level {nextLevel}`,
				textColor = Color3.fromRGB(0, 255, 0),
			})

			self.Client:EnhanceResult(player, {
				success = true,
				weaponIndex = weaponIndex,
				backpack = updatedBackpack,
			})
		else
			-- Enhancement failed, resources already deducted
			local updatedBackpack = playerIns:GetOneData(Keys.DataKey.backpack)

			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Enhancement failed! Resources were consumed.",
				textColor = Color3.fromRGB(255, 0, 0),
			})

			self.Client:EnhanceResult(player, {
				success = false,
				weaponIndex = weaponIndex,
				backpack = updatedBackpack,
			})
		end
	end
end

function WeaponSystem:EnhanceResult(sender, player, args)
	if IsServer then
		-- This is a client method, should not be called on server
		return
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		WeaponUi.EnhanceResult(args)
	end
end

function WeaponSystem:EnchantResult(sender, player, args)
	if IsServer then
		-- This is a client method, should not be called on server
		return
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		WeaponUi.EnchantResult(args)
	end
end

function WeaponSystem:EnchantWeapon(sender, player, args)
	if IsServer then
		player = player or sender

		-- Validate player has character
		if not player.Character then
			return
		end

		local weaponIndex = args.weaponIndex
		local oreName = args.oreName

		if not weaponIndex then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon index not provided",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		if not oreName then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Ore not selected",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local weapons = playerIns:GetOneData(Keys.DataKey.backpack).weapons
		local weaponData = weapons[weaponIndex]

		if not weaponData then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon not found",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check if weapon is equipped
		if not weaponData.equipped then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Weapon must be equipped to enchant",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check if ore exists in enchant presets
		local enchantPreset = WeaponPresets.Enchants[oreName]
		if not enchantPreset then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `{oreName} cannot be used for enchanting`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check enchant slot availability
		if not weaponData.enchantSlots then
			weaponData.enchantSlots = {}
		end

		if not weaponData.enchants then
			weaponData.enchants = {}
		end

		-- Normalize legacy enchants array into slot-based storage
		if #weaponData.enchants > 0 and weaponData.enchants[1] and weaponData.enchants[1].enchantType then
			local normalized = {}
			for i, enchant in ipairs(weaponData.enchants) do
				normalized[i] = {
					attrName = enchant.attrName or enchant.enchantType,
					roll = enchant.roll,
					oreName = enchant.oreName,
				}
			end
			weaponData.enchants = normalized
		end

		while #weaponData.enchantSlots < #weaponData.enchants do
			table.insert(weaponData.enchantSlots, {})
		end

		local availableSlots = #weaponData.enchantSlots
		local slotIndex
		for i = 1, availableSlots do
			if weaponData.enchants[i] == nil then
				slotIndex = i
				break
			end
		end

		if not slotIndex then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "No available enchant slots! Enhance your weapon to get more slots.",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Check if player has the ore
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)
		local oreCount = backpack.ores and backpack.ores[oreName] or 0

		if oreCount < 1 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `Not enough {oreName}! Need 1, have {oreCount}`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		-- Deduct ore from backpack
		SystemMgr.systems.BackpackSystem:DeleteItems(SENDER, player, {
			items = {
				{
					itemType = Keys.ItemType.ores,
					itemName = oreName,
					count = 1,
				},
			},
		})

		-- Add enchant to weapon
		local gamePasses = playerIns:GetOneData(Keys.DataKey.gamePasses) or {}
		local effectCfg = EcoPresets.GamePassEffects and EcoPresets.GamePassEffects.enchantLucky or {}
		local baseMin = effectCfg.baseRollMin or 0.05
		local baseMax = effectCfg.baseRollMax or 0.2
		local minRoll = baseMin
		if gamePasses.enchantLucky then
			minRoll = math.clamp(minRoll + (effectCfg.rollMinBonus or 0), 0, baseMax)
		end
		local rollMin = enchantPreset.rollMin or minRoll
		local rollMax = enchantPreset.rollMax or baseMax
		local roll = rollMin + math.random() * math.max(0, rollMax - rollMin)
		local newEnchant = {
			attrName = enchantPreset.attrName,
			oreName = oreName,
			roll = roll,
		}
		weaponData.enchants[slotIndex] = newEnchant

		-- Apply enchant luck immediately (improves weapon quality)
		if newEnchant.attrName == Keys.Enchants.EnchantLuck then
			local size = weaponData.size or 1
			weaponData.size = math.clamp(size * roll, 0, 1)
		end

		-- Update backpack data
		local updatedBackpack = playerIns:GetOneData(Keys.DataKey.backpack)

		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = `Enchantment successful! Added {enchantPreset.attrName} enchant.`,
			textColor = Color3.fromRGB(0, 255, 0),
		})

		self.Client:EnchantResult(player, {
			success = true,
			weaponIndex = weaponIndex,
			backpack = updatedBackpack,
		})
	else
		-- Client-side: send to server
		self.Server:EnchantWeapon(args)
	end
end

---- [[ Common ]] ----

function WeaponSystem.onWeaponAdded(weaponInstance)
	local weapon = WeaponSystem.getWeaponForInstance(weaponInstance)
	if not weapon then
		WeaponSystem.createWeaponForInstance(weaponInstance)
	end
end

function WeaponSystem.onWeaponRemoved(weaponInstance)
	local weapon = WeaponSystem.getWeaponForInstance(weaponInstance)
	if weapon then
		weapon:onDestroyed()
	end
	WeaponSystem.knownWeapons[weaponInstance] = nil
end

function WeaponSystem.setWeaponEquipped(weapon, equipped)
	assert(not IsServer, "WeaponsSystem.setWeaponEquipped should only be called on the client.")
	if not weapon then
		return
	end

	local lastWeapon = WeaponSystem.currentWeapon
	local hasWeapon = false
	local weaponChanged = false

	if lastWeapon == weapon then
		if not equipped then
			WeaponSystem.currentWeapon = nil
			hasWeapon = false
			weaponChanged = true
		else
			weaponChanged = false
		end
	else
		if equipped then
			WeaponSystem.currentWeapon = weapon
			hasWeapon = true
			weaponChanged = true
		end
	end

	if WeaponSystem.camera then
		WeaponSystem.camera:resetZoomFactor()
		WeaponSystem.camera:setHasScope(false)

		if WeaponSystem.currentWeapon then
			WeaponSystem.camera:setZoomFactor(WeaponSystem.currentWeapon:getConfigValue("ZoomFactor", 1.1))
			WeaponSystem.camera:setHasScope(WeaponSystem.currentWeapon:getConfigValue("HasScope", false))
		end
	end

	if WeaponSystem.gui then
		WeaponSystem.gui:setEnabled(hasWeapon)

		if WeaponSystem.currentWeapon then
			WeaponSystem.gui:setCrosshairWeaponScale(WeaponSystem.currentWeapon:getConfigValue("CrosshairScale", 1))
		else
			WeaponSystem.gui:setCrosshairWeaponScale(1)
		end
	end

	if weaponChanged then
		WeaponSystem.CurrentWeaponChanged:Fire(weapon.instance, lastWeapon and lastWeapon.instance)
	end
end

function WeaponSystem.getHumanoid(part)
	while part and part ~= workspace do
		if part:IsA("Model") and part.PrimaryPart and part.PrimaryPart.Name == "HumanoidRootPart" then
			-- return part:FindFirstChild("Humanoid")
			return part.PrimaryPart
		end
		part = part.Parent
	end
end

function WeaponSystem.getPlayerFromHumanoid(humanoid)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and humanoid:IsDescendantOf(player.Character) then
			return player
		end
	end
end

local function _defaultDamageCallback(system, target, amount, damageType, dealer, hitInfo, damageData)
	if target:IsA("Humanoid") then
		target:TakeDamage(amount)
	end
end

function WeaponSystem.doDamage(target, amount, damageType, dealer, hitInfo, damageData)
	if not target or ancestorHasTag(target, "WeaponsSystemIgnore") then
		return
	end
	if IsServer then
		if target:IsA("Humanoid") and dealer:IsA("Player") and dealer.Character then
			local dealerHumanoid = dealer.Character:FindFirstChildOfClass("Humanoid")
			local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
			if dealerHumanoid and target ~= dealerHumanoid and targetPlayer then
				-- Trigger the damage indicator
				WeaponData:FireClient(
					targetPlayer,
					"HitByOtherPlayer",
					dealer.Character.HumanoidRootPart.CFrame.Position
				)
			end
		end

		-- NOTE:  damageData is a more or less free-form parameter that can be used for passing information from the code that is dealing damage about the cause.
		-- .The most obvious usage is extracting icons from the various weapon types (in which case a weapon instance would likely be passed in)
		-- ..The default weapons pass in that data
		local handler = _damageCallback or _defaultDamageCallback
		handler(WeaponSystem, target, amount, damageType, dealer, hitInfo, damageData)
	end
end

local function _defaultGetTeamCallback(player)
	return 0
end

function WeaponSystem.getTeam(player)
	local handler = _getTeamCallback or _defaultGetTeamCallback
	return handler(player)
end

function WeaponSystem.playersOnDifferentTeams(player1, player2)
	if player1 == player2 or player1 == nil or player2 == nil then
		-- This allows players to damage themselves and NPC's
		return true
	end

	local player1Team = WeaponSystem.getTeam(player1)
	local player2Team = WeaponSystem.getTeam(player2)
	return player1Team == 0 or player1Team ~= player2Team
end

function WeaponSystem.getWeaponTypeFromTags(instance)
	for _, tag in pairs(CollectionService:GetTags(instance)) do
		local weaponTypeFound = WEAPON_TYPES_LOOKUP[tag]
		if weaponTypeFound then
			return weaponTypeFound
		end
	end

	return nil
end

function WeaponSystem.createWeaponForInstance(weaponInstance)
	-- coroutine.wrap(function()
	local weaponType = WeaponSystem.getWeaponTypeFromTags(weaponInstance)
	if not weaponType then
		local weaponTypeObj = weaponInstance:WaitForChild("WeaponType")

		if weaponTypeObj and weaponTypeObj:IsA("StringValue") then
			local weaponTypeName = weaponTypeObj.Value
			local weaponTypeFound = WEAPON_TYPES_LOOKUP[weaponTypeName]
			if not weaponTypeFound then
				warn(
					string.format(
						'Cannot find the weapon type "%s" for the instance %s!',
						weaponTypeName,
						weaponInstance:GetFullName()
					)
				)
				return
			end

			weaponType = weaponTypeFound
		else
			warn("Could not find a WeaponType tag or StringValue for the instance ", weaponInstance:GetFullName())
			return
		end
	end

	-- Since we might have yielded while trying to get the WeaponType, we need to make sure not to continue
	-- making a new weapon if something else beat this iteration.
	if WeaponSystem.getWeaponForInstance(weaponInstance) then
		warn("Already got ", weaponInstance:GetFullName())
		warn(debug.traceback())
		return
	end

	-- We should be pretty sure we got a valid weaponType by now
	assert(weaponType, "Got invalid weaponType")

	local weapon = weaponType.new(WeaponSystem, weaponInstance)
	WeaponSystem.knownWeapons[weaponInstance] = weapon
	-- end)()
end

function WeaponSystem.getWeaponForInstance(weaponInstance)
	if not typeof(weaponInstance) == "Instance" then
		warn("WeaponsSystem.getWeaponForInstance(weaponInstance): 'weaponInstance' was not an instance.")
		return nil
	end

	return WeaponSystem.knownWeapons[weaponInstance]
end

---- [[ Server ]] ----
table.insert(WeaponSystem.whiteList, "EquipWeaponModel")
function WeaponSystem:EquipWeaponModel(player, weaponData)
	if IsServer then
		local weaponId = weaponData.weaponId
		local size = weaponData.size
		local weaponPreset = WeaponPresets.Weapons[weaponId]
		local animationType = weaponPreset.weaponType
		local weaponModel: Model = script.Assets.ToolModels:FindFirstChild(weaponId)
		if not weaponModel then
			warn("Weapon model not found", weaponId)
			return
		end

		local bindHandle = weaponModel:FindFirstChild("Handle")
		local bindRootPart = weaponModel:FindFirstChild("RootPart")

		if bindHandle then
			local rightHand = player.Character:WaitForChild("RightHand", 10)
			if not rightHand then
				return
			end
			weaponModel = weaponModel:Clone()
			-- weaponModel:ScaleTo(size)
			weaponModel:PivotTo(rightHand.CFrame)

			local m6d = weaponModel:WaitForChild("Handle"):FindFirstChild("Motor6D")
			if not m6d then
				m6d = Instance.new("Motor6D")
				m6d.Name = "Motor6D"
				m6d.Parent = weaponModel:WaitForChild("Handle")
			end
			m6d.Part0 = rightHand
			m6d.Part1 = weaponModel.Handle
		end

		if bindRootPart then
			local rootPart = player.Character:WaitForChild("HumanoidRootPart", 10)
			if not rootPart then
				return
			end
			weaponModel = weaponModel:Clone()
			-- weaponModel:ScaleTo(size)
			weaponModel:PivotTo(rootPart.CFrame)

			local m6d = weaponModel:WaitForChild("RootPart"):FindFirstChild("Motor6D")
			if not m6d then
				m6d = Instance.new("Motor6D")
				m6d.Name = "Motor6D"
				m6d.Parent = weaponModel:WaitForChild("RootPart")
			end
			m6d.Part0 = rootPart
			m6d.Part1 = weaponModel.RootPart
		end

		-- Apply color and material from weapon data
		local weaponColor = weaponData.color
		local weaponMaterial = weaponData.materials

		if weaponColor or weaponMaterial then
			for _, part in ipairs(weaponModel:GetDescendants()) do
				if part:IsA("BasePart") then
					-- Apply color
					if weaponColor and Keys.ForgeColors[weaponColor] then
						part.Color = Keys.ForgeColors[weaponColor]
					end

					-- Apply material
					if weaponMaterial and Keys.ForgeMaterials[weaponMaterial] then
						part.Material = Keys.ForgeMaterials[weaponMaterial]
					end
				end
			end
		end

		local function cloneEffectsToPart(effectFolder: Instance, targetPart: BasePart)
			if not effectFolder or not targetPart then
				return
			end

			for _, desc in ipairs(effectFolder:GetDescendants()) do
				if desc:IsA("Attachment") then
					local cloned = desc:Clone()
					cloned.Parent = targetPart
				elseif desc:IsA("ParticleEmitter") then
					if not desc.Parent or not desc.Parent:IsA("Attachment") then
						local cloned = desc:Clone()
						cloned.Parent = targetPart
					end
				end
			end
		end

		local function weaponHasAttr(attrId: string): boolean
			if not weaponData then
				return false
			end
			local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
			return attrs[attrId] ~= nil
		end

		local targetPart = weaponModel:FindFirstChild("Handle") or weaponModel:FindFirstChild("RootPart")
		if targetPart and targetPart:IsA("BasePart") then
			local effectsRoot = script.Assets:FindFirstChild("WeaponEffects")
			if effectsRoot then
				local effectChecks = {
					attackSpeed = weaponHasAttr("AttackSpeed"),
					burn = weaponHasAttr("Burn"),
					coinBoost = weaponHasAttr("CoinBoost"),
					damageBoost = weaponHasAttr("Attack"),
					lucky = weaponHasAttr("EnchantLuck") or weaponHasAttr("Lucky"),
				}

				for effectName, enabled in pairs(effectChecks) do
					if enabled then
						local effectFolder = effectsRoot:FindFirstChild(effectName)
						if effectFolder then
							cloneEffectsToPart(effectFolder, targetPart)
						else
							warn(`Weapon effect not found: {effectName}`)
						end
					end
				end
			else
				warn("WeaponEffects folder not found in WeaponSystem.Assets")
			end
		end

		for _, des in weaponModel:GetDescendants() do
			if des:IsA("ParticleEmitter") or des:IsA("Beam") or des:IsA("Trail") then
				CollectionService:AddTag(des, Keys.Tags.VFX)
			end
		end

		weaponModel.Name = animationType .. "Model"
		weaponModel.Parent = player.Character
		return weaponModel
	end
end

return WeaponSystem
