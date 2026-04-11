--[[
--Author: TimeM_chine
--Created Date: Fri Feb 23 2024
--Description: init.lua
--Version: 1.0
--Last Modified: 2024-05-25 6:59:23
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

---- requires ----
local PetPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local TableModule = require(Replicated.modules.TableModule)
-- local GAModule = require(Replicated.modules.GAModule)
local ModelModule = require(Replicated.modules.ModelModule)
local PetMgr = require(script.PetMgr)
local Textures = require(Replicated.configs.Textures)
local Util = require(Replicated.modules.Util)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local Connections = {}
local HUGE_NUMBER = 999999999
local dataKey = Keys.DataKey
local petOperations = Keys.PetOperations

---- server variables ----
local PlayerServerClass, AnalyticsService
local craftingPlayer = {}

---- client variables ----
local LocalPlayer, nowOperation, ClientData
local lastMoveDirM = 0
local clientPets = {}
local preDeletePets = {}
local clientChosenPet = {}
local playerTarget = {}

---- [[ UI ]] ----
local PetUi = { pendingCalls = {} }
setmetatable(PetUi, Types.mt)

local PetSystem: Types.System = {
	whiteList = {
		"GetPlayerPetIns",
		"GetPetBoost",
		"ChangeVisibleSetting",
	},
	players = {},
	IsLoaded = false,
}
PetSystem.__index = PetSystem

if IsServer then
	PetSystem.Client = setmetatable({}, PetSystem)
	PetSystem.AllClients = setmetatable({}, PetSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	ClientData = require(Replicated.Systems.ClientData)
	PetSystem.Server = setmetatable({}, PetSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function PetSystem:Init()
	GetSystemMgr()
end

function PetSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		self.players[player.UserId] = {
			equippedPets = {},
			skipCraftIndex = nil,
		}

		-- check equipped
		local pets = playerIns:GetOneData(dataKey.pets)
		for index, pet in pets do
			if not pet then
				continue
			end
			if pet.equipped then
				-- table.insert(self.players[player.UserId].equippedPets, pet)
				local petIndexName = index .. "_" .. pet.name
				local petF = Instance.new("IntValue")
				petF.Name = petIndexName
				petF:SetAttribute("UserId", player.UserId)
				petF.Parent = GetPetsFolderOfPlayer(player)
				PetMgr.CreateIns({
					serverInt = petF,
					level = pet.level,
				})

				CollectionService:AddTag(petF, Keys.Tags.Pet)
			end
		end

		self.Client:PlayerAdded(player, args)
	else
		Connections["PetAdded"] = CollectionService:GetInstanceAddedSignal(Keys.Tags.Pet):Connect(function(fakePet)
			-- print("PetAdded", fakePet)
			local settingsData = ClientData:GetOneData(dataKey.settingsData)
			local UserId = fakePet:GetAttribute("UserId")

			if UserId == LocalPlayer.UserId and not settingsData.showMyPets then
				return
			end

			if UserId ~= LocalPlayer.UserId and not settingsData.showOtherPets then
				return
			end

			PetMgr.CreateIns({
				serverInt = fakePet,
			})
		end)

		Connections["PetRemoved"] = CollectionService:GetInstanceRemovedSignal(Keys.Tags.Pet):Connect(function(fakePet)
			-- print("PetRemoved", fakePet)
			if PetMgr.GetIns(fakePet) then
				PetMgr.GetIns(fakePet):Destroy()
			end
		end)

		for _, fakePet in pairs(CollectionService:GetTagged(Keys.Tags.Pet)) do
			-- CreatePetModel(fakePet)
			PetMgr.CreateIns({
				serverInt = fakePet,
			})
		end

		LocalPlayer:GetAttributeChangedSignal("isBattle"):Connect(function()
			if not ClientData:GetOneData(dataKey.settingsData).showMyPets then
				return
			end
			if LocalPlayer:GetAttribute("isBattle") then
				self:ChangeVisibleSetting("showMyPets", false)
			else
				self:ChangeVisibleSetting("showMyPets", true)
			end
		end)

		local pendingCalls = PetUi.pendingCalls

		PetUi = require(script.ui)
		PetUi.Init()

		for _, call in ipairs(pendingCalls) do
			PetUi[call.functionName](table.unpack(call.args))
		end
	end
end

function PetSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		local playerFolder = workspace.PetsFolder:FindFirstChild(player.UserId)
		if playerFolder then
			playerFolder:Destroy()
		end
	end
end

----------------[[ Pet Operations ]]----------------
function PetSystem:TryHatchEgg(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)

		local eggName = args.eggName
		local count = args.count
		if PetPresets.EggsList[eggName].itemType == Keys.ItemType.robux then
			MarketplaceService:PromptProductPurchase(player, EcoPresets.Products.egg[eggName .. count].productId)
			return
		end

		local checkCost = args.checkCost == nil and true or args.checkCost

		local eggPreset = PetPresets.EggsList[eggName]
		---- check game pass ----
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		if count == 3 then
			if not gamePasses.egg3 then
				MarketplaceService:PromptGamePassPurchase(player, EcoPresets.GamePasses.egg3.gamePassId)
				return
			end
		elseif count == 8 then
			if not gamePasses.egg8 then
				MarketplaceService:PromptGamePassPurchase(player, EcoPresets.GamePasses.egg8.gamePassId)
				return
			end
		end

		---- check inventory ----
		local pets = playerIns:GetOneData(dataKey.pets)
		local petInventorySize = playerIns:GetOneData(dataKey.petInventorySize)
		if TableModule.TrueLength(pets) + count > petInventorySize then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Your inventory is full!",
			})
			return
		end
		---- check cost ----
		if checkCost then
			local costType = eggPreset.costType
			if costType == Keys.ItemType.wins then
				local wins = playerIns:GetOneData(dataKey.wins)
				local cost = eggPreset.cost * count
				if wins < cost then
					local need = cost - wins
					SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
						text = `You need {need} more wins !`,
					})
					return
				else
					SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
						resourceType = Keys.ItemType.wins,
						count = -cost,
						reason = "HatchEgg",
					})
					self:HatchEgg(SENDER, player, args)
				end
			elseif costType == Keys.ItemType.eventEgg then
				local res = SystemMgr.systems.EventSystem:TryClaim(SENDER, player, {
					count = count,
				})
				if res then
					self:HatchEgg(SENDER, player, args)
				end
			end
		else
			self:HatchEgg(SENDER, player, args)
		end
	end
end

function PetSystem:HatchEgg(sender, player, args: { eggName: string, count: number })
	if IsServer then
		if sender ~= SENDER then
			return
		end
		-- print("HatchEgg", player, args)
		local eggName = args.eggName
		local count = args.count or 1

		local playerIns = PlayerServerClass.GetIns(player)
		local autoDelete = playerIns:GetOneData(dataKey.autoDelete)[eggName] or {}
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		local eggPreset = PetPresets.EggsList[eggName]
		local hatchResult = {}
		local lucky1 = gamePasses.lucky1
		local lucky2 = gamePasses.lucky2
		local lucky3 = gamePasses.lucky3
		local startPoint = 0
		if lucky1 then
			if lucky2 then
				if lucky3 then
					startPoint = 0.3
				else
					startPoint = 0.2
				end
			else
				startPoint = 0.1
			end
		end

		local equippedBuff = playerIns:GetOneData(dataKey.equippedBuff)
		if equippedBuff and equippedBuff["lucky"] then
			startPoint = startPoint + 0.05
		end

		local totalWeight = 0
		for _, pet in ipairs(eggPreset.pets) do
			totalWeight += pet.weight
		end
		totalWeight = totalWeight * 10000 -- Preventing fractions from appearing, unable to randomize.
		playerIns:AddOneData(dataKey.eggHatched, count)
		for i = 1, count do
			local rand = math.random(math.floor(startPoint * totalWeight), totalWeight) / 10000
			local nowWeight = 0
			for _, pet in ipairs(eggPreset.pets) do
				nowWeight += pet.weight
				if rand <= nowWeight then
					table.insert(hatchResult, pet.name)
					break
				end
			end
		end

		SystemMgr.systems.QuestSystem:DoQuest(player, {
			questType = Keys.QuestType.hatchEgg,
			value = count,
		})

		SystemMgr.systems.QuestSystem:DoQuest(player, {
			questType = Keys.QuestType.getAnyCard,
			value = count,
		})

		for i = 1, #hatchResult do
			-- print("hatchResult", hatchResult[i], table.find(autoDelete, hatchResult[i]))
			if table.find(autoDelete, hatchResult[i]) then
				continue
			end

			SystemMgr.systems.QuestSystem:DoQuest(player, {
				questType = Keys.QuestType.hatchNamedPet,
				name = hatchResult[i],
				value = 1,
			})

			SystemMgr.systems.QuestSystem:DoQuest(player, {
				questType = Keys.QuestType.hatchRarityPet,
				name = hatchResult[i],
				rarity = PetPresets.PetsList[hatchResult[i]].rarity,
				value = 1,
			})

			self:AddNewPet(SENDER, player, { petName = hatchResult[i] })
		end

		args = {
			eggName = eggName,
			hatchResult = hatchResult,
			autoDelete = autoDelete,
		}
		-- AnalyticsService:LogOnboardingFunnelStepEvent(player, 4, "HatchEgg")
		AnalyticsService:LogCustomEvent(player, "hatchEgg" .. eggName)
		self.Client:HatchEgg(player, args)
	else
		PetUi.HatchEgg(args)
	end
end

function PetSystem:AutoHatchEgg(sender, player, args)
	if IsServer then
		player = player or sender :: Player
		local playerIns = PlayerServerClass.GetIns(player)
		-- check game pass
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		if not gamePasses.autoHatch then
			if player:IsInGroup(GameConfig.GroupId) then
				gamePasses.autoHatch = true
			else
				SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
					text = "Join Group to unlock Auto Hatch!",
				})
				return
			end
		end

		args.count = playerIns:GetOneData(dataKey.settingsData).autoHatchNum

		self:TryHatchEgg(SENDER, player, args)
		self.Client:AutoHatchEgg(player, args)
	else
		PetUi.AutoHatchEgg(args)
	end
end

function PetSystem:AddNewPet(sender, player, args: { petName: string, star: number, rank: string })
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local petName = args.petName
		local petIndex = TableModule.SetFirstNil(pets, GetPetDict(args))

		-- GAModule:addDesignEvent(player.UserId, {
		-- 	eventId = `pet:addPet:{petName}`,
		-- 	value = 1,
		-- })

		args = {
			pet = pets[petIndex],
			pets = pets,
		}
		self:UpdatePetIndex(SENDER, player, { petName = petName })
		self.Client:AddNewPet(player, args)
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		PetUi.AddNewPet(args.pet)
	end
end

function PetSystem:UpdatePetIndex(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local petName = args.petName
		local playerIns = PlayerServerClass.GetIns(player)
		local petIndex = playerIns:GetOneData(dataKey.petIndex)
		if petIndex[args.petName] then
			return
		end
		petIndex[args.petName] = true
		self.Client:UpdatePetIndex(player, {
			petIndex = petIndex,
			petName = petName,
		})
	else
		ClientData:SetOneData(dataKey.petIndex, args.petIndex)
		PetUi.UpdatePetIndex(args)
	end
end

function PetSystem:DeletePet(sender, player, args: { petsList: { number } })
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local petsList = args.petsList
		for _, index in petsList do
			local pet = pets[index]
			if not pet then
				warn("PetSystem:DeletePet: pet is nil" .. index)
				continue
			end
			if pet.locked then
				warn("PetSystem:DeletePet: pet is locked" .. index)
				continue
			elseif pet.equipped then
				self:UnEquipPet(SENDER, player, { index = index })
			end
			pets[index] = false

			-- GAModule:addDesignEvent(player.UserId, {
			-- 	eventId = `pet:deletePet:{pet.name}`,
			-- 	value = 1,
			-- })
		end
		self.Client:DeletePet(player, {
			petsList = petsList,
			pets = pets,
		})
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		PetUi.DeletePet(args)
	end
end

function PetSystem:LockPet(sender, player, args)
	if IsServer then
		local petsDict = args.petsDict
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		for strKey, shouldLock in pairs(petsDict) do
			local index = tonumber(strKey)
			local pet = pets[index]
			if not pet then
				warn("PetSystem:LockPet: pet is nil")
				return
			end
			pet.locked = shouldLock
		end

		self.Client:LockPet(player, {
			petsDict = petsDict,
			pets = pets,
		})
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		PetUi.LockPet(args)
	end
end

function PetSystem:UnlockPet(sender, player, args)
	if IsServer then
		-- TODO
	else
		-- TODO
	end
end

function PetSystem:EquipPet(sender, player, args: { index: number })
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local index = args.index
		local pet = pets[index]
		if pet then
			if pet.equipped then
				self:UnEquipPet(SENDER, player, { index = index })
				return
			end
			-- check carry size
			local petCarrySize = playerIns:GetOneData(dataKey.petCarrySize)
			local folder = GetPetsFolderOfPlayer(player)
			if #folder:GetChildren() >= petCarrySize then
				SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
					text = "Your carry size is full!",
					textColor = Color3.fromRGB(255, 0, 0),
				})
				return
			end

			pet.equipped = true
			local petIndexName = index .. "_" .. pet.name
			local petF = Instance.new("IntValue")
			petF.Name = petIndexName
			petF:SetAttribute("UserId", player.UserId)
			petF.Parent = folder

			CollectionService:AddTag(petF, Keys.Tags.Pet)

			PetMgr.CreateIns({
				serverInt = petF,
				level = pet.level,
			})
		else
			warn("PetSystem:EquipPet: pet is nil")
			return
		end
		self.Client:EquipPet(player, { index = index, pets = pets })
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		PetUi.EquipPet({
			index = args.index,
		})
	end
end

function PetSystem:EquipBest(sender, player, args)
	if IsServer then
		player = player or sender
		self:UnEquipAllPet(SENDER, player)
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local copyPets = {}
		for i, pet in pets do
			if pets[i] then
				table.insert(copyPets, pet)
			end
		end
		table.sort(copyPets, function(a, b)
			return a.power > b.power
		end)

		local bestIndexList = {}
		local petCarrySize = playerIns:GetOneData(dataKey.petCarrySize)
		for i = 1, petCarrySize do
			local pet = copyPets[i]
			if not pet then
				continue
			end
			pets[pet.index].equipped = true

			local petIndexName = pet.index .. "_" .. pet.name
			local petF = Instance.new("IntValue")
			petF.Name = petIndexName
			petF:SetAttribute("UserId", player.UserId)
			petF.Parent = GetPetsFolderOfPlayer(player)
			CollectionService:AddTag(petF, Keys.Tags.Pet)
			table.insert(bestIndexList, pet.index)

			PetMgr.CreateIns({
				serverInt = petF,
				level = pet.level,
			})
		end

		self.Client:EquipBest(player, {
			pets = pets,
			bestIndexList = bestIndexList,
		})
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		for _, index in args.bestIndexList do
			PetUi.EquipPet({
				index = index,
			})
		end
		-- clientPets = args.pets
		-- local bestIndexList = args.bestIndexList
		-- for _, petUnit in pairs(petScroll:GetChildren()) do
		--     if not tonumber(petUnit.Name) then
		--         continue
		--     end
		--     if table.find(bestIndexList, tonumber(petUnit.Name)) then
		--         petUnit.equipped.Visible = true
		--         petUnit.LayoutOrder = -1
		--     else
		--         petUnit.equipped.Visible = false
		--         petUnit.LayoutOrder = HUGE_NUMBER - clientPets[tonumber(petUnit.Name)].power * 100
		--     end
		-- end

		-- SetPetsSubmenuVisible(false)

		-- SoundService.equipPet:Play()
	end
end

function PetSystem:UnEquipPet(sender, player, args)
	if IsServer then
		player = player or sender
		local index = args.index
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local pet = pets[index]

		if pet then
			pet.equipped = false
		else
			warn("PetSystem:UnEquipPet: pet is nil")
			return
		end

		local folder = GetPetsFolderOfPlayer(player)
		local petName = pet.index .. "_" .. pet.name
		local petF = folder:FindFirstChild(petName)
		if petF then
			local petIns = PetMgr.GetIns(petF)
			petIns:Destroy()
		end

		-- TableModule.RemoveByValue(self.players[player.UserId].equippedPets, pet)

		self.Client:UnEquipPet(player, {
			pet = pet,
			pets = pets,
			-- serverInt = petF
		})
	else
		ClientData:SetOneData(dataKey.pets, args.pets)
		PetUi.UnEquipPet(args)
	end
end

function PetSystem:UnEquipAllPet(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		for _, pet in pets do
			if not pet then
				continue
			end
			if pet.equipped then
				self:UnEquipPet(SENDER, player, { index = pet.index })
			end
		end

		local folder = GetPetsFolderOfPlayer(player)
		for _, petF in folder:GetChildren() do
			local petIns = PetMgr.GetIns(petF)
			petIns:Destroy()
		end
	end
end

function PetSystem:CraftPet(sender, player, args: { petIndex: number })
	if IsServer then
		player = player or sender
		local petIndex = args.petIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local pet = pets[petIndex]
		local deleted = {}
		if not pet then
			return
		end
		if pet.locked then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Pet is locked!",
			})
			return
		end
		local name = pet.name
		local star = pet.star
		local rank = pet.rank
		if star >= 2 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Pet is Huge already!",
			})
			return
		end
		for i, otherPet in pets do
			if not otherPet then
				continue
			end
			if i == petIndex then
				continue
			end
			if otherPet.locked then
				continue
			end
			if otherPet.name == name and otherPet.star == star and otherPet.rank == rank then
				table.insert(deleted, i)
				if #deleted == 2 then
					break
				end
			end
		end
		if #deleted < 2 then -- cause index will change to new pet
			if sender == SENDER then
				return -- called by Craft All, should not notify
			end
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough pets to craft!",
			})
			return
		end
		local newPet = GetPetDict({
			index = petIndex,
			petName = name,
			star = star + 1,
			rank = rank,
		})
		pets[petIndex] = newPet
		self.Client:CraftPet(player, {
			newPet = newPet,
		})
		self:DeletePet(SENDER, player, {
			petsList = deleted,
		})
	else
		PetUi.CraftPet(args)
	end
end

function PetSystem:CraftAll(sender, player, args)
	if IsServer then
		player = player or sender
		if craftingPlayer[player.UserId] then
			return
		end
		craftingPlayer[player.UserId] = true
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		for _, pet in pets do
			if not pet then
				continue
			end
			self:CraftPet(SENDER, player, { petIndex = pet.index })
		end
		craftingPlayer[player.UserId] = false
	end
end

function PetSystem:GoldenPet(sender, player, args)
	if IsServer then
		player = player or sender
		local petsList = args.petsList
		local playerIns = PlayerServerClass.GetIns(player)
		local pets = playerIns:GetOneData(dataKey.pets)
		local newPet
		if math.random() <= (#petsList * 0.2) then
			local pet = pets[petsList[1]]
			newPet = {
				petName = pet.name,
				star = pet.star,
				rank = "Golden",
			}
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Success! o(*￣▽￣*)ブ",
				textColor = Color3.fromRGB(0, 255, 0),
			})
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Fail! /(ㄒoㄒ)/~~",
			})
		end
		self.Client:GoldenPet(player)
		self:DeletePet(SENDER, player, { petsList = petsList })
		if newPet then
			self:AddNewPet(SENDER, player, newPet)
		end
	else
		PetUi.GoldenPet()
	end
end

function PetSystem:AddShinyCraft(sender, player, args)
	if IsServer then
		player = player or sender

		local petIndex = args.petIndex
		local playerIns = PlayerServerClass.GetIns(player)

		local shinyMachine = playerIns:GetOneData(dataKey.shinyMachine)
		if TableModule.TrueLength(shinyMachine) >= PetPresets.Shiny.maxSlots then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Shiny machine is full!",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local pets = playerIns:GetOneData(dataKey.pets)
		local petInfo = pets[petIndex]
		if petInfo then
			self:DeletePet(SENDER, player, {
				petsList = { petIndex },
			})
		end
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		local craftTime = PetPresets.Shiny.craftTime
		if gamePasses.instantShinyMachine then
			craftTime = 0
		elseif gamePasses.halfShinyMachine then
			craftTime = math.floor(craftTime / 2)
		end

		local shinyInfo = {
			petIndex = petIndex,
			petInfo = petInfo,
			startTime = os.time(),
			craftTime = craftTime,
		}

		TableModule.SetFirstNil(shinyMachine, shinyInfo)
		self.Client:AddShinyCraft(player, {
			shinyInfo = shinyInfo,
			shinyMachine = shinyMachine,
		})
	else
		ClientData:SetOneData(dataKey.shinyMachine, args.shinyMachine)
		PetUi.UpdateShinyCraft()
	end
end

function PetSystem:TrySkipCraftTime(sender, player, args)
	if IsServer then
		player = player or sender
		local shinyIndex = args.shinyIndex

		local playerCache = self.players[player.UserId]
		playerCache.skipCraftIndex = shinyIndex

		MarketplaceService:PromptProductPurchase(player, EcoPresets.Products.skipCraftTime.productId)
	end
end

function PetSystem:SkipCraftTime(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerCache = self.players[player.UserId]
		local shinyIndex = playerCache.skipCraftIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local shinyMachine = playerIns:GetOneData(dataKey.shinyMachine)
		local shinyInfo = shinyMachine[shinyIndex]
		if not shinyInfo then
			return
		end
		shinyInfo.craftTime = 0
		self.Client:SkipCraftTime(player, {
			shinyIndex = shinyIndex,
			shinyMachine = shinyMachine,
		})
	else
		ClientData:SetOneData(dataKey.shinyMachine, args.shinyMachine)
		PetUi.SkipCraftTime(args)
	end
end

function PetSystem:ClaimShinyCraft(sender, player, args)
	if IsServer then
		player = player or sender
		local shinyIndex = args.shinyIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local shinyMachine = playerIns:GetOneData(dataKey.shinyMachine)
		local shinyInfo = shinyMachine[shinyIndex]

		if os.time() - shinyInfo.startTime > shinyInfo.craftTime then
			-- finished
			local petInfo = shinyInfo.petInfo
			self:AddNewPet(SENDER, player, {
				petName = petInfo.name,
				star = petInfo.star,
				rank = "Shiny",
			})

			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "🎉You have crafted a shiny pet!",
				textColor = Color3.fromRGB(0, 255, 0),
			})
			shinyMachine[shinyIndex] = false
			self.Client:ClaimShinyCraft(player, {
				shinyMachine = shinyMachine,
				shinyIndex = shinyIndex,
			})
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "This pet is already crafting.",
			})
			return
		end
	else
		ClientData:SetOneData(dataKey.shinyMachine, args.shinyMachine)
		PetUi.ClaimShinyCraft(args)
	end
end

function PetSystem:AddPlayerPetData(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local addType = args.addType
		local count = args.count
		local playerIns = PlayerServerClass.GetIns(player)
		playerIns:AddOneData(addType, count)
		self.Client:AddPlayerPetData(player, {
			petCarrySize = playerIns:GetOneData(dataKey.petCarrySize),
			petInventorySize = playerIns:GetOneData(dataKey.petInventorySize),
		})
	else
		ClientData:SetDataTable(args)
		PetUi.UpdateStatsBar()
	end
end

function PetSystem:SetEggAutoDelete(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local autoDelete = playerIns:GetOneData(dataKey.autoDelete)
		local eggName = args.eggName
		local petName = args.petName
		local delete = args.delete
		if not autoDelete[eggName] then
			autoDelete[eggName] = {}
		end
		if delete then
			for i, v in ipairs(autoDelete[eggName]) do
				if v == petName then
					return
				end
			end
			table.insert(autoDelete[eggName], petName)
		else
			for i, v in ipairs(autoDelete[eggName]) do
				if v == petName then
					table.remove(autoDelete[eggName], i)
					break
				end
			end
		end
	end
end

----------------[[ Pet Behaviors ]]----------------

function PetSystem:SetTarget(sender, player, args: { dmIns: Instance })
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local dmIns = args.dmIns
		if dmIns.state == Keys.DemonStates.Dead then
			return
		end

		local pets = SystemMgr.systems.PetSystem:GetPlayerPetIns(player)
		for _, pet in pets do
			pet:AddTarget(dmIns)
		end

		args.player = player
		args.model = dmIns.model
		self.AllClients:SetTarget(args)
	else
		player = args.player
		local demon = args.model
		local folder = GetPetsFolderOfPlayer(player, true)
		for _, serverInt in folder:GetChildren() do
			if not demon then
				PetMgr.GetIns(serverInt):ClearTarget()
			else
				PetMgr.GetIns(serverInt):AddTarget(demon)
			end
		end
		-- playerTarget[tostring(player.UserId)] = monster
		-- print("set target", player, monster, playerTarget)
	end
end

function PetSystem:RemoveAllTarget(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local mstIns = args.mstIns
		PetMgr.RemoveAllTarget(mstIns)
		args = {
			model = mstIns.model,
		}
		self.AllClients:RemoveAllTarget(args)
	else
		local model = args.model
		PetMgr.RemoveAllTarget(model)
	end
end

function PetSystem:ClearTarget(sender, player, args)
	if IsServer then
		print("ClearTarget", sender, player, args)
		if sender ~= SENDER then
			return
		end
		local folder = GetPetsFolderOfPlayer(player, true)
		for _, serverInt in folder:GetChildren() do
			PetMgr.GetIns(serverInt):ClearTarget()
		end
		args = {
			player = player,
		}
		self.AllClients:ClearTarget(args)
	else
		player = args.player
		local folder = GetPetsFolderOfPlayer(player, true)
		for _, serverInt in folder:GetChildren() do
			PetMgr.GetIns(serverInt):ClearTarget()
		end
		-- playerTarget[tostring(player.UserId)] = nil
	end
end

function PetSystem:Attack(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local serverInt = args.serverInt
		local petIns = PetMgr.GetIns(serverInt)
		local mstIns = petIns.targetList[1]
		SystemMgr.systems.DungeonSystem:DemonGetHurt(SENDER, player, {
			damage = petIns.atkDamage,
			spawner = mstIns.spawner,
			source = "pet",
		})
		self.AllClients:Attack(args)
	else
		local serverInt = args.serverInt
		local atkIndex = args.atkIndex

		local petIns = PetMgr.GetIns(serverInt)
		petIns.state = Keys.DemonStates.Attacking
		task.delay(2, function()
			petIns.state = Keys.DemonStates.Idle
		end)
		SystemMgr.systems.AnimateSystem:PlayAnimation(nil, nil, {
			actor = petIns.model,
			animKey = "malePet",
			animName = "attack" .. atkIndex,
		})
	end
end

---- [[ Server ]] ----

---- [[ Client ]] ----
function PetSystem:ChangeVisibleSetting(name, visible)
	-- print("ChangeVisibleSetting", name, visible)
	if name == "showMyPets" then
		local folder = GetPetsFolderOfPlayer(LocalPlayer, true)
		if not folder then
			return
		end
		if visible then
			for _, serverInt in folder:GetChildren() do
				PetMgr.CreateIns({
					serverInt = serverInt,
				})
			end
		else
			for _, serverInt in folder:GetChildren() do
				PetMgr.GetIns(serverInt):Destroy()
			end
		end
	elseif name == "showOtherPets" then
		if visible then
			for _, folder in workspace.PetsFolder:GetChildren() do
				if tonumber(folder.Name) == LocalPlayer.UserId then
					continue
				end
				if not folder:FindFirstChild("Pets_Server") then
					continue
				end
				for _, serverInt in folder.Pets_Server:GetChildren() do
					PetMgr.CreateIns({
						serverInt = serverInt,
					})
				end
			end
		else
			for _, folder in workspace.PetsFolder:GetChildren() do
				if tonumber(folder.Name) == LocalPlayer.UserId then
					continue
				end
				if not folder:FindFirstChild("Pets_Server") then
					continue
				end
				for _, serverInt in folder.Pets_Server:GetChildren() do
					PetMgr.GetIns(serverInt):Destroy()
				end
			end
		end
	end
end

---- [[ Common ]] ----
function GetPetsFolderOfPlayer(player, findServer)
	local playerFolder = workspace.PetsFolder:FindFirstChild(player.UserId)
	if not playerFolder then
		if IsServer then
			playerFolder = Instance.new("Folder")
			playerFolder.Name = player.UserId
			playerFolder.Parent = workspace.PetsFolder
		else
			return
		end
	end

	local folderName

	if IsServer or findServer then
		folderName = "Pets_Server"
	else
		folderName = "Pets_Client"
	end

	local folder = playerFolder:FindFirstChild(folderName)
	if not folder then
		if IsServer then
			folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = playerFolder
		else
			return
		end
	end

	return folder
end

function GetPetDict(args)
	local petName = args.petName
	local star = args.star or 0
	local boost = math.pow(1.5, star)

	local rank = args.rank or "Normal"
	if rank == "Golden" then
		boost = boost * 1.5
	elseif rank == "Shiny" then
		boost = boost * 1.5 * 1.5
	end

	local power = PetPresets.PetsList[petName].power
	return {
		index = args.index, -- can be nil
		name = petName,
		rarity = PetPresets.PetsList[petName].rarity,
		power = math.ceil(power * boost),
		equipped = false,
		locked = false,
		star = star,
		rank = rank,
	}
end

function PetSystem:GetPlayerPetIns(player)
	return PetMgr.GetPlayerPetIns(player)
end

function PetSystem:GetPetBoost(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local pets = playerIns:GetOneData(dataKey.pets)
	local boost = 0
	for _, pet in pets do
		if not pet then
			continue
		end
		if pet.equipped then
			boost += pet.power
		end
	end
	return 1 + boost
end

return PetSystem
