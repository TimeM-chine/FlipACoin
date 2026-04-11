---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local GameConfig = require(Replicated.configs.GameConfig)
local PetPresets = require(script.Parent.Presets)
local Zone = require(Replicated.modules.Zone)
local Util = require(Replicated.modules.Util)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local TableModule = require(Replicated.modules.TableModule)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local dataKey = Keys.DataKey
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Gradients = PlayerGui:WaitForChild("Gradients")
local Templates = PlayerGui:WaitForChild("Templates")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local PetsFrame = Frames:WaitForChild("Pets")
local GoldenFrame = Frames:WaitForChild("Golden")
local ShinyFrame = Frames:WaitForChild("Shiny"):WaitForChild("Frame")
local PetIndexFrame = Frames:WaitForChild("PetIndex")
local PetsHelpFrame = Frames:WaitForChild("PetsHelp")
local pixScroll = PetIndexFrame.Container.ScrollingFrame
local goldenScroll = GoldenFrame.Container.ScrollingFrame
local petsScroll = PetsFrame.Container.ScrollingFrame
local petsInfoFrame = PetsFrame.Container.PetInfo
local petsToolBar = PetsFrame.ToolBar
local petsStatsBar = PetsFrame.StatsBar
local OpeningUI = PlayerGui:WaitForChild("OpeningUI")

local uiController = require(Main:WaitForChild("uiController"))
local Elements = Main:WaitForChild("Elements")

---- logic variables ----
local HUGE_NUMBER = 999999999
local isAuto = false
local ZonesFolder = workspace:WaitForChild("Zones")
local EggsFolder = workspace:WaitForChild("Eggs")
local zoneCount = GameConfig.ZoneCount
local nowOperation
local operatePetsList = {}
local operatePetsDict = {}
local oldLockDict = {}
local chosenPet = {}
local PetOperations = Keys.PetOperations
local petInfoTween
local ti = TweenInfo.new(0.5)
local Connections = {}
local clientIsHatching = false
local clientAutoHatch = {
	eggName = nil,
	isAuto = false,
	count = 1,
	startAuto = false,
}

local PetUi = {}

function PetUi.Init(args)
	InitPetsFrame()
	InitEggs()
	InitGoldenFrame()
	InitPetIndexFrame()
	InitShinyFrame()
end

function PetUi.AddNewPet(petData)
	local petTemplate = petsScroll:FindFirstChild("Template")
	local petUnit = Util.Clone(petTemplate, petsScroll, function(unit)
		unit.Name = petData.index
		unit.name.Text = petData.name
		unit.Visible = true
		unit.power.Text = "x" .. Util.FormatNumber(petData.power)
		local petClone = PetPresets.PetsList[petData.name].mesh:Clone()
		uiController.PetViewport(petClone, unit:WaitForChild("ViewportFrame"))
		local rarityColor = GameConfig.RarityColor[PetPresets.PetsList[petData.name].rarity]
		unit.BackgroundColor3 = rarityColor

		if petData.equipped then
			unit.equipped.Visible = true
			unit.LayoutOrder = -1
		else
			unit.LayoutOrder = HUGE_NUMBER - petData.power * 100
		end

		if petData.locked then
			unit.locked.Visible = true
		end

		if petData.rank == "Golden" then
			unit.name.TextColor3 = Textures.ButtonColors.golden
		elseif petData.rank == "Shiny" then
			unit.name.ShinyGradient.Enabled = true
		end

		for i = 1, petData.star do
			unit.stars[i].Visible = true
		end

		uiController.SetButtonHoverAndClick(unit, function()
			if not nowOperation then
				if chosenPet.petUnit and chosenPet.petUnit.Parent then
					chosenPet.petUnit.selected.Visible = false
				end
				chosenPet = {
					index = petData.index,
					name = petData.name,
					power = petData.power,
					petUnit = unit,
				}
				unit.selected.Visible = true
				SetPetFrameInfo(petData)
			elseif nowOperation == PetOperations.SellPet then
				local clientPets = ClientData:GetOneData(dataKey.pets)
				if clientPets[tonumber(unit.Name)].locked then
					uiController.SetNotification({
						text = "Pet is locked!",
						textColor = Textures.ButtonColors.red,
					})
					return
				end
				unit.selected.Visible = not unit.selected.Visible
				if unit.selected.Visible then
					table.insert(operatePetsList, tonumber(unit.Name))
				else
					for i, petIndex in ipairs(operatePetsList) do
						if petIndex == tonumber(unit.Name) then
							table.remove(operatePetsList, i)
							break
						end
					end
				end
				petsToolBar.DeleteDone.TextHolder.TextLabel.Text = `Delete!({#operatePetsList})`
			elseif nowOperation == PetOperations.LockPet then
				if oldLockDict[unit.Name] == nil then
					oldLockDict[unit.Name] = unit.locked.Visible
				end

				unit.locked.Visible = not unit.locked.Visible
				operatePetsDict[unit.Name] = unit.locked.Visible
			end
		end)
	end)

	PetUi.UpdateStatsBar()
	AddGoldenCard(petUnit, petData)
	return petUnit
end

function PetUi.EquipPet(args)
	local petUnit = petsScroll:FindFirstChild(args.index)

	SetPetFrameInfo()
	PetUi.UpdateStatsBar()
	if petUnit then
		petUnit.equipped.Visible = true
		petUnit.LayoutOrder = -1
	end
end

function PetUi.UnEquipPet(args)
	local petInfo = args.pet
	local petUnit = petsScroll:FindFirstChild(tostring(petInfo.index))

	SetPetFrameInfo()

	if petUnit then
		petUnit.equipped.Visible = false
		petUnit.LayoutOrder = HUGE_NUMBER - petInfo.power * 100
	end
end

function PetUi.HatchEgg(args)
	local hatchResult = args.hatchResult
	local eggName = args.eggName
	clientIsHatching = true
	clientAutoHatch.startAuto = false
	local EggOpeningFrame = OpeningUI.EggOpeningFrame
	local eggsFrame = EggOpeningFrame.Eggs
	if #hatchResult == 10 then
		eggsFrame = EggOpeningFrame.Egg10
	elseif #hatchResult == 8 then
		eggsFrame = EggOpeningFrame.Egg8
	end

	local speedHatch = args.speedHatch
	for i = 1, #hatchResult do
		local petName = hatchResult[i]
		if speedHatch then
			task.spawn(function()
				ShowPet(petName, eggsFrame[tostring(i)].Pet)
			end)
		else
			EggViewPort(eggName, petName, eggsFrame[tostring(i)])
		end
	end
end

function PetUi.AutoHatchEgg(args)
	if clientAutoHatch.isAuto then
		return
	end
	local eggName = args.eggName
	local count = args.count
	clientAutoHatch.eggName = eggName
	clientAutoHatch.count = count
	clientAutoHatch.isAuto = true
end

function PetUi.CraftPet(args)
	local newPet = args.newPet
	local petUnit = petsScroll:FindFirstChild(newPet.index)
	if petUnit then
		petUnit:Destroy()
	else
		warn("didn't find pet:", newPet, newPet.index)
	end

	local goldenUnit = goldenScroll:FindFirstChild(newPet.index)
	if goldenUnit then
		goldenUnit:Destroy()
	else
		warn("didn't find golden pet:", newPet, newPet.index)
	end
	PetUi.AddNewPet(newPet)
	SetPetFrameInfo()
end

function PetUi.LockPet(args)
	local petsDict = args.petsDict
	for index, shouldLock in pairs(petsDict) do
		local petUnit = petsScroll:FindFirstChild(index)
		if petUnit then
			petUnit.locked.Visible = shouldLock
		else
			warn("PetSystem:LockPet: petUnit is nil", index)
		end
	end
end

function PetUi.DeletePet(args)
	local petsList = args.petsList
	for _, index in petsList do
		local petUnit = petsScroll:FindFirstChild(tostring(index))
		if petUnit then
			petUnit:Destroy()
		else
			warn("PetSystem:DeletePet: petUnit is nil", index)
		end

		local goldenUnit = goldenScroll:FindFirstChild(index)
		if goldenUnit then
			goldenUnit:Destroy()
		else
			warn("PetSystem:DeletePet: goldenUnit is nil", index)
		end
	end
	PetUi.UpdateStatsBar()
	SetPetFrameInfo(false)
end

function PetUi.GoldenPet()
	operatePetsList = {}
	for _, petCard in ipairs(goldenScroll:GetChildren()) do
		if not petCard:IsA("Frame") then
			continue
		end
		petCard.Visible = true
	end
	for i = 1, 5 do
		local petFrame = GoldenFrame.Container.CraftInfo.PetFrame["Pet" .. i]
		if petFrame:FindFirstChild("ViewportFrame") then
			petFrame.ViewportFrame:Destroy()
		end
	end

	local CraftInfo = GoldenFrame.Container.CraftInfo
	CraftInfo.ChanceHolder.Percent.Text = "0%"
end

function PetUi.UpdatePetIndex(args)
	local petName = args.petName
	local petIndex = ClientData:GetOneData(dataKey.petIndex)

	local petCard = pixScroll:FindFirstChild(petName)
	petCard.ViewportFrame:ClearAllChildren()
	local petClone = PetPresets.PetsList[petName].mesh:Clone()
	uiController.PetViewport(petClone, petCard.ViewportFrame)

	local Name = petCard:FindFirstChild("Name")
	Name.Text = petName

	PetIndexFrame.PetsDiscovered.Amount.Text =
		`{Util.DictionaryLength(petIndex)}/{Util.DictionaryLength(PetPresets.PetsList)} Pets Discoverd`
end

function PetUi.UpdateStatsBar()
	local pets = ClientData:GetOneData(dataKey.pets)
	local count = 0
	local equippedCount = 0
	for _, petData in pairs(pets) do
		if not petData then
			continue
		end
		count += 1
		if petData.equipped then
			equippedCount += 1
		end
	end

	local invStatsFrame = PetsFrame.StatsBar.InvStats
	local eqpStatsFrame = PetsFrame.StatsBar.EqpStats
	local petInventorySize = ClientData:GetOneData(dataKey.petInventorySize)
	local petCarrySize = ClientData:GetOneData(dataKey.petCarrySize)
	invStatsFrame.count.Text = `{count}/{petInventorySize} Storage`
	eqpStatsFrame.count.Text = `{equippedCount}/{petCarrySize} Equipped`
end

function PetUi.IsHatching()
	return clientIsHatching
end

local function AddShinyCraft(args: { shinyInfo: table, shinyIndex: number })
	local Container = ShinyFrame:WaitForChild("Container")
	local CraftContainer = Container:WaitForChild("CraftContainer")
	local GiantSlot = CraftContainer:FindFirstChild("GiantSlot")

	local shinyInfo = args.shinyInfo
	local petInfo = shinyInfo.petInfo
	local shinyIndex = args.shinyIndex

	local slot = GiantSlot:Clone()
	slot.Name = shinyIndex

	-- pet view
	local petConfig = PetPresets.PetsList[petInfo.name]
	local petClone = petConfig.mesh:Clone()
	local petView = slot:FindFirstChild("PetView")
	uiController.PetViewport(petClone, petView)

	if os.time() - shinyInfo.startTime >= shinyInfo.craftTime then
		-- finished
		slot.Frames.Claim.Visible = true
		slot.Frames.Make.Visible = false
		slot.Frames.Purchase.Visible = false
		-- claim button
		uiController.SetButtonHoverAndClick(slot.Frames.Claim.TextButton, function()
			SystemMgr.systems.PetSystem.Server:ClaimShinyCraft({ shinyIndex = shinyIndex })
		end)
	else
		-- Crafting
		slot.Frames.Claim.Visible = false
		slot.Frames.Make.Visible = false
		slot.Frames.Purchase.Visible = true

		uiController.AddTimerLabel({
			textLabel = slot.Frames.Purchase.Time,
			startTime = shinyInfo.startTime,
			duration = shinyInfo.craftTime,
			callback = function()
				if not slot or not slot.Parent then
					return
				end
				slot.Frames.Claim.Visible = true
				slot.Frames.Make.Visible = false
				slot.Frames.Purchase.Visible = false
				-- claim button
				uiController.SetButtonHoverAndClick(slot.Frames.Claim.TextButton, function()
					SystemMgr.systems.PetSystem.Server:ClaimShinyCraft({ shinyIndex = shinyIndex })
				end)
			end,
		})

		uiController.SetButtonHoverAndClick(slot.Frames.Purchase.TextButton, function()
			SystemMgr.systems.PetSystem.Server:TrySkipCraftTime({ shinyIndex = shinyIndex })
		end)
	end

	slot.Parent = CraftContainer
end

function PetUi.UpdateShinyCraft()
	local Container = ShinyFrame:WaitForChild("Container")
	local CraftContainer = Container:WaitForChild("CraftContainer")
	local canShinyScroll = Container:WaitForChild("ScrollingFrame")
	CraftContainer.Visible = true
	canShinyScroll.Visible = false
	local shinyMachine = ClientData:GetOneData(dataKey.shinyMachine)

	for shinyIndex, shinyInfo in ipairs(shinyMachine) do
		if not shinyInfo then
			continue
		end
		if CraftContainer:FindFirstChild(shinyIndex) then
			continue
		end
		AddShinyCraft({
			shinyIndex = shinyIndex,
			shinyInfo = shinyInfo,
		})
	end
end

function PetUi.ClaimShinyCraft(args)
	local shinyIndex = args.shinyIndex
	local Container = ShinyFrame:WaitForChild("Container")
	local CraftContainer = Container:WaitForChild("CraftContainer")
	local slot = CraftContainer:FindFirstChild(shinyIndex)
	slot:Destroy()
end

function PetUi.SkipCraftTime(args)
	local shinyIndex = args.shinyIndex
	local Container = ShinyFrame:WaitForChild("Container")
	local CraftContainer = Container:WaitForChild("CraftContainer")
	local slot = CraftContainer:FindFirstChild(shinyIndex)
	slot.Frames.Claim.Visible = true
	slot.Frames.Make.Visible = false
	slot.Frames.Purchase.Visible = false
	-- claim button
	uiController.SetButtonHoverAndClick(slot.Frames.Claim.TextButton, function()
		SystemMgr.systems.PetSystem.Server:ClaimShinyCraft({ shinyIndex = shinyIndex })
	end)
end

---- [[ Private Functions ]] ----

function SetPetFrameInfo(pet)
	if petInfoTween then
		petInfoTween:Cancel()
	end
	if pet then
		pet = ClientData:GetOneData(dataKey.pets)[pet.index]
		petsInfoFrame.Visible = true
		petsInfoFrame.Size = UDim2.fromOffset(0, 0.95)
		local petClone = PetPresets.PetsList[pet.name].mesh:Clone()
		uiController.PetViewport(petClone, petsInfoFrame:WaitForChild("ViewportFrame"))
		petsInfoFrame.name.Text = chosenPet.name
		petsInfoFrame.power.Text = "x" .. Util.FormatNumber(chosenPet.power)
		petsInfoFrame.rarity.Text = PetPresets.PetsList[chosenPet.name].rarity
		petsInfoFrame.rank.Text = pet.rank
		if pet.rank == "Golden" then
			petsInfoFrame.rank.TextColor3 = Textures.ButtonColors.golden
		else
			petsInfoFrame.rank.TextColor3 = Textures.ButtonColors.white
		end
		petsInfoFrame.req.Visible = true
		petsInfoFrame.req.Text = "Craft Req: " .. GetPetCount(pet) .. "/3"
		if pet.star < 2 then
			petsInfoFrame.Craft.TextLabel.Text = `Craft Into {pet.star + 1}⭐`
		else
			petsInfoFrame.Craft.TextLabel.Text = "Can't Craft"
			petsInfoFrame.req.Visible = false
		end

		if pet.equipped then
			petsInfoFrame.Equip.TextLabel.Text = "Unequip"
			petsInfoFrame.Equip.UIGradient.Color = Gradients.Red.Color
		else
			petsInfoFrame.Equip.TextLabel.Text = "Equip"
			petsInfoFrame.Equip.UIGradient.Color = Gradients.Green.Color
		end

		petInfoTween = TweenService:Create(petsInfoFrame, ti, { Size = UDim2.fromOffset(0.35, 0.95) })
		petInfoTween:Play()
		TweenService:Create(petsScroll, ti, { Size = UDim2.fromOffset(0.6, 1) }):Play()
	else
		petInfoTween = TweenService:Create(petsInfoFrame, ti, { Size = UDim2.fromOffset(0, 0.95) })
		petInfoTween:Play()
		petInfoTween.Completed:Once(function()
			petsInfoFrame.Visible = false
		end)
		TweenService:Create(petsScroll, ti, { Size = UDim2.fromScale(1, 1) }):Play()
	end
end

function ToggleOperateMode(operation) -- start delete or lock
	nowOperation = operation
	if operation then
		SetPetFrameInfo(false)
		ToggleAllSelected(false)

		if operation == PetOperations.LockPet then
			petsToolBar.LockDone.Visible = true
		elseif operation == PetOperations.SellPet then
			petsToolBar.DeleteDone.Visible = true
		end

		petsToolBar.Cancel.Visible = true

		petsToolBar.Delete.Visible = false
		petsToolBar.CraftAll.Visible = false
		petsToolBar.EquipBest.Visible = false
		petsToolBar.Lock.Visible = false
	else
		petsToolBar.Cancel.Visible = false
		petsToolBar.LockDone.Visible = false
		petsToolBar.DeleteDone.Visible = false

		petsToolBar.Delete.Visible = true
		petsToolBar.CraftAll.Visible = true
		petsToolBar.EquipBest.Visible = true
		petsToolBar.Lock.Visible = true

		for strKey, lock in pairs(oldLockDict) do
			local petUnit = petsScroll:FindFirstChild(strKey)
			if petUnit then
				petUnit.locked.Visible = lock
			end
		end

		oldLockDict = {}
		operatePetsList = {}
		operatePetsDict = {}
	end
end

function ToggleAllSelected(flag)
	for _, petUnit in pairs(petsScroll:GetChildren()) do
		if petUnit:IsA("Frame") then
			if petUnit.Name == "Template" then
				continue
			end
			petUnit.selected.Visible = flag
		end
	end
end

function InitPetsFrame()
	local Template = petsScroll.Template
	Template.Visible = false

	local pets = ClientData:GetOneData(dataKey.pets)

	for _, petData in pairs(pets) do
		if not petData then
			continue
		end
		PetUi.AddNewPet(petData)
	end

	---- tool bar ----
	uiController.SetButtonHoverAndClick(petsToolBar.EquipBest, function()
		SystemMgr.systems.PetSystem.Server:EquipBest()
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.CraftAll, function()
		SystemMgr.systems.PetSystem.Server:CraftAll()
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.Lock, function()
		ToggleOperateMode(PetOperations.LockPet)
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.Delete, function()
		ToggleOperateMode(PetOperations.SellPet)
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.Cancel, function()
		ToggleOperateMode()
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.LockDone, function()
		SystemMgr.systems.PetSystem.Server:LockPet({ petsDict = operatePetsDict })
		ToggleOperateMode()
	end)

	uiController.SetButtonHoverAndClick(petsToolBar.DeleteDone, function()
		SystemMgr.systems.PetSystem.Server:DeletePet({ petsList = operatePetsList })
		ToggleOperateMode()
	end)

	---- stats bar ----
	PetUi.UpdateStatsBar()
	-- local gamePasses = ClientData:GetOneData(dataKey.gamePasses)
	local eqpStatsFrame = PetsFrame.StatsBar.EqpStats
	eqpStatsFrame.Add.Visible = true
	uiController.SetButtonHoverAndClick(eqpStatsFrame.Add, function()
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses.petCarry2.gamePassId)
	end)

	local invStatsFrame = PetsFrame.StatsBar.InvStats
	invStatsFrame.Add.Visible = true
	uiController.SetButtonHoverAndClick(invStatsFrame.Add, function()
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses.petStorage100.gamePassId)
	end)

	uiController.SetButtonHoverAndClick(PetsFrame.Help, function()
		PetsHelpFrame.Visible = true
		uiController.SetUnitJump(PetsHelpFrame)
	end)

	---- pets info frame ----
	uiController.SetButtonHoverAndClick(petsInfoFrame.Equip, function()
		if not chosenPet.index then
			return
		end
		SystemMgr.systems.PetSystem.Server:EquipPet({ index = chosenPet.index })
	end)

	uiController.SetButtonHoverAndClick(petsInfoFrame.Delete, function()
		SystemMgr.systems.PetSystem.Server:DeletePet({ petsList = { chosenPet.index } })
	end)

	uiController.SetButtonHoverAndClick(petsInfoFrame.Craft, function()
		SystemMgr.systems.PetSystem.Server:CraftPet({ petIndex = chosenPet.index })
	end)
end

function InitGoldenFrame()
	uiController.SetButtonHoverAndClick(GoldenFrame.Container.CraftInfo.CraftButton, function()
		if #operatePetsList > 0 then
			SystemMgr.systems.PetSystem.Server:GoldenPet({ petsList = operatePetsList })
		else
			uiController.SetNotification({
				text = "You should at least select one pet!",
				textColor = Textures.ButtonColors.red,
			})
		end
	end)

	GoldenFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not GoldenFrame.Visible then
			PetUi.GoldenPet()
		end
	end)
end

function InitPetIndexFrame()
	pixScroll.Template.Visible = false
	local petIndex = ClientData:GetOneData(dataKey.petIndex)
	for petName, petInfo in pairs(PetPresets.PetsList) do
		Util.Clone(pixScroll.Template, pixScroll, function(petCell)
			petCell.Visible = true
			petCell.Name = petName
			petCell.LayoutOrder = -PetPresets.Order[petInfo.rarity]

			local petClone = petInfo.mesh:Clone()
			uiController.PetViewport(petClone, petCell:WaitForChild("ViewportFrame"))

			local Background = petCell:FindFirstChild("Background")
			local Name = petCell:FindFirstChild("Name")
			-- Background for rarity
			Background.Image = Textures.RarityColor[petInfo.rarity .. "BG"] or Textures.RarityColor.DefaultBG
			-- hide deleting
			petCell:FindFirstChild("Deleting"):FindFirstChild("UIScale").Scale = 0
			---- check if have this pet before -----
			if not petIndex[petInfo.name] then
				if petClone:IsA("BasePart") then
					petClone.Color = Color3.new(0, 0, 0)
				end
				for _, dec in petClone:GetDescendants() do
					if dec:IsA("BasePart") then
						dec.Color = Color3.new(0, 0, 0)
						if dec:IsA("MeshPart") then
							dec.TextureID = ""
						end
					end
					if dec:IsA("Decal") then
						dec:Destroy()
					end
				end
				Name.Text = "???"
			else
				Name.Text = petInfo.name
			end
		end)

		PetIndexFrame.PetsDiscovered.Amount.Text =
			`{Util.DictionaryLength(petIndex)}/{Util.DictionaryLength(PetPresets.PetsList)} Pets Discoverd`
	end
end

function UpdateCanShinyScroll()
	local Container = ShinyFrame:WaitForChild("Container")
	local canShinyScroll = Container:WaitForChild("ScrollingFrame")
	local pets = ClientData:GetOneData(dataKey.pets)
	local canShinyTotal = 0
	----- can shiny pet -----
	for _, petCell in ipairs(canShinyScroll:GetChildren()) do
		if not petCell:IsA("Frame") then
			continue
		end
		petCell:Destroy()
	end

	for petIndex, petInfo in ipairs(pets) do
		if not petInfo then
			continue
		end

		if petInfo.rank ~= "Golden" then
			continue
		end
		canShinyTotal += 1
		local petCell = petsScroll:FindFirstChild(petIndex)
		if petCell then
			local petCellClone = petCell:Clone()
			petCellClone.selected.Visible = false
			petCellClone.locked.Visible = false
			petCellClone.equipped.Visible = false
			petCellClone.Parent = canShinyScroll

			uiController.SetButtonHoverAndClick(petCellClone, function()
				SystemMgr.systems.PetSystem.Server:AddShinyCraft({ petIndex = petIndex })
			end)
		end
	end
	return canShinyTotal
end

function InitShinyFrame()
	local Container = ShinyFrame:WaitForChild("Container")
	local CraftContainer = Container:WaitForChild("CraftContainer")
	local canShinyScroll = Container:WaitForChild("ScrollingFrame")
	local GiantSlot = CraftContainer:FindFirstChild("GiantSlot")
	CraftContainer.Visible = true
	canShinyScroll.Visible = false

	local shinyMachine = ClientData:GetOneData(dataKey.shinyMachine)
	local inCrafting = TableModule.TrueLength(shinyMachine)
	local canShinyTotal = UpdateCanShinyScroll()

	---- in shiny scroll ----
	for shinyIndex, shinyInfo in ipairs(shinyMachine) do
		-- crafting
		if not shinyInfo then
			continue
		end
		print("shinyIndex", shinyIndex, shinyInfo)
		AddShinyCraft({ shinyInfo = shinyInfo, shinyIndex = shinyIndex })
	end

	-- add new craft
	uiController.SetButtonHoverAndClick(GiantSlot.Frames.Make.TextButton, function()
		canShinyTotal = UpdateCanShinyScroll()
		inCrafting = TableModule.TrueLength(ClientData:GetOneData(dataKey.shinyMachine))
		if canShinyTotal == 0 then
			uiController.SetNotification({
				text = "❌You don't have any golden pet to craft.",
				textColor = Textures.ButtonColors.red,
			})
		elseif inCrafting < PetPresets.Shiny.maxSlots then
			-- select pet
			CraftContainer.Visible = false
			canShinyScroll.Visible = true
		else
			uiController.SetNotification({
				text = "You can only craft " .. PetPresets.Shiny.maxSlots .. " giant pet at once.",
				textColor = Textures.ButtonColors.red,
			})
		end
	end)
end

function AddGoldenCard(petUnit, petData)
	local CraftInfo = GoldenFrame.Container.CraftInfo
	Util.Clone(petUnit, goldenScroll, function(unit)
		unit.equipped.Visible = false
		if operatePetsList[1] then
			local pet = ClientData:GetOneData(dataKey.pets)[operatePetsList[1]]
			local name = pet.name
			local nowStar = pet.star
			local nowRank = pet.rank
			if petData.name ~= name or petData.star ~= nowStar or petData.rank ~= nowRank then
				unit.Visible = false
			end
		end
		uiController.SetButtonHoverAndClick(unit, function()
			local clientPets = ClientData:GetOneData(dataKey.pets)
			if clientPets[tonumber(petUnit.Name)].locked then
				uiController.SetNotification({
					text = "Pet is locked!",
				})
				return
			end

			local rank = clientPets[tonumber(petUnit.Name)].rank
			if rank == "Golden" or rank == "Shiny" then
				uiController.SetNotification({
					text = "Pet is golden already!",
				})
				return
			end

			local index = table.find(operatePetsList, tonumber(unit.Name))
			if index then
				local card = CraftInfo.PetFrame["Pet" .. #operatePetsList]
				if card:FindFirstChild("ViewportFrame") then
					card.ViewportFrame:Destroy()
				end
				table.remove(operatePetsList, index)
				unit.selected.Visible = false

				if #operatePetsList == 0 then
					for _, petCard in ipairs(goldenScroll:GetChildren()) do
						if not petCard:IsA("Frame") then
							continue
						end
						petCard.Visible = true
					end
				end
			else
				if #operatePetsList >= 5 then
					uiController.SetNotification({
						text = "You can only choose less then 5 pets!",
					})
					return
				end
				table.insert(operatePetsList, petData.index)
				unit.selected.Visible = true
				local card = CraftInfo.PetFrame["Pet" .. #operatePetsList]
				if card:FindFirstChild("ViewportFrame") then
					card.ViewportFrame:Destroy()
				end
				unit.ViewportFrame:Clone().Parent = card

				if #operatePetsList == 1 then
					local name = clientPets[petData.index].name
					local nowStar = clientPets[petData.index].star
					local nowRank = clientPets[petData.index].rank
					for i, pet in clientPets do
						if not pet then
							continue
						end
						if pet.name ~= name or pet.star ~= nowStar or pet.rank ~= nowRank then
							goldenScroll:FindFirstChild(i).Visible = false
						end
					end
				end
			end
			CraftInfo.ChanceHolder.Percent.Text = `{#operatePetsList * 20}%`
		end)
	end)
end

function InitEggs()
	local templateEgg = Templates:WaitForChild("Template_Egg")
	local autoDelete = ClientData:GetOneData(dataKey.autoDelete)
	for _, eggModel in EggsFolder:GetChildren() do
		local eggAutoDelete = autoDelete[eggModel.Name] or {}
		local eggConfig = PetPresets.EggsList[eggModel.Name]
		if not eggConfig then
			-- warn("No egg config in presets", eggModel.Name)
			continue
		end

		local cost = eggConfig.cost
		if not cost then
			continue
		end
		if eggConfig.display == false then
			continue
		end
		local eggName = eggModel.Name
		local displayName = eggConfig.displayName
		local ProximityPrompt = Instance.new("ProximityPrompt")
		ProximityPrompt.Name = eggName
		ProximityPrompt.HoldDuration = 0
		ProximityPrompt.GamepadKeyCode = Enum.KeyCode.BackSlash
		ProximityPrompt.KeyboardKeyCode = Enum.KeyCode.ButtonL3
		ProximityPrompt.MaxActivationDistance = 8
		ProximityPrompt.Style = Enum.ProximityPromptStyle.Custom
		ProximityPrompt.RequiresLineOfSight = false
		ProximityPrompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		ProximityPrompt.ActionText = ""
		ProximityPrompt.Parent = eggModel

		local eggMenu = templateEgg:Clone()
		eggMenu.Name = eggName
		local PetSlotTpl = eggMenu:WaitForChild("Frame"):WaitForChild("Templates"):WaitForChild("PetSlot")
		local pets = eggConfig.pets

		for i, pet in pets do
			local PetSlot = PetSlotTpl:Clone()
			PetSlot.LayoutOrder = i
			-- print("====>", pet.name)
			PetSlot:FindFirstChild("PetName").Text = pet.name
			PetSlot:FindFirstChild("Chance").Text = string.format("%.2f%%", pet.weight)
			local rarity = PetPresets.PetsList[pet.name].rarity
			PetSlot.BackgroundColor3 = GameConfig.RarityColor[rarity]

			local petClone = PetPresets.PetsList[pet.name].mesh:Clone()
			uiController.PetViewport(petClone, PetSlot:WaitForChild("ViewportFrame"))

			PetSlot.Visible = true
			local Button = PetSlot:FindFirstChild("Button")
			local Deleting = PetSlot:FindFirstChild("Deleting")

			if table.find(eggAutoDelete, pet.name) then
				Deleting.Visible = true
			else
				Deleting.Visible = false
			end

			Button.MouseButton1Click:Connect(function()
				Deleting.Visible = not Deleting.Visible
				SystemMgr.systems.PetSystem.Server:SetEggAutoDelete({
					eggName = eggName,
					petName = pet.name,
					delete = Deleting.Visible,
				})
			end)

			PetSlot.Parent = eggMenu:WaitForChild("Frame"):WaitForChild("Slots")
		end

		-- Buttons
		local Buttons = eggMenu:WaitForChild("Frame"):WaitForChild("Buttons")

		local hatch1 = Buttons:WaitForChild("x1")
		local hatchAuto = Buttons:WaitForChild("Auto")
		local hatch3 = Buttons:WaitForChild("x3")
		local hatch8 = Buttons:WaitForChild("x8")

		eggMenu.Frame.Title.Text = displayName
		if eggConfig.itemType == Keys.ItemType.robux then
			eggMenu.Frame.Price.ImageLabel.Visible = false
			eggMenu.Frame.Buttons.Auto.Visible = false
			eggMenu.Frame.Buttons["x8"].Subheader.Text = "x10"
			eggMenu.Frame.Price.Text = Util.GetRobuxText(cost)
		else
			eggMenu.Frame.Price.Text = Util.FormatNumber(cost)
		end

		uiController.SetButtonHoverAndClick(hatch1, function()
			if clientIsHatching then
				return
			end
			SystemMgr.systems.PetSystem.Server:TryHatchEgg({
				eggName = eggName,
				count = 1,
			})
		end)

		uiController.SetButtonHoverAndClick(hatchAuto, function()
			if clientIsHatching then
				return
			end
			SystemMgr.systems.PetSystem.Server:AutoHatchEgg({
				eggName = eggName,
				count = 1,
			})
		end)

		uiController.SetButtonHoverAndClick(hatch3, function()
			if clientIsHatching then
				return
			end
			SystemMgr.systems.PetSystem.Server:TryHatchEgg({
				eggName = eggName,
				count = 3,
			})
		end)

		uiController.SetButtonHoverAndClick(hatch8, function()
			if clientIsHatching then
				return
			end
			local count = 8
			if PetPresets.EggsList[eggName].itemType == Keys.ItemType.robux then
				count = 10
			end
			SystemMgr.systems.PetSystem.Server:TryHatchEgg({
				eggName = eggName,
				count = count,
			})
		end)

		-- left side
		local leftSide = eggMenu:WaitForChild("Frame"):WaitForChild("LeftSide")
		uiController.SetButtonHoverAndClick(leftSide.lucky1, function()
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses.lucky1.gamePassId)
		end)

		uiController.SetButtonHoverAndClick(leftSide.lucky2, function()
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses.lucky2.gamePassId)
		end)

		uiController.SetButtonHoverAndClick(leftSide.lucky3, function()
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses.lucky3.gamePassId)
		end)

		eggMenu.Parent = PlayerGui.Main

		local function addShortcut(EggMenu)
			if UserInputService.GamepadEnabled then
				local buttons = EggMenu:WaitForChild("Frame"):WaitForChild("Buttons")
				local LuckyOnce = buttons:WaitForChild("x1")
				local LuckyAuto = buttons:WaitForChild("Auto")
				local LuckyTriple = buttons:WaitForChild("x3")
				local LuckyOctuple = buttons:WaitForChild("x8")

				LuckyOnce:FindFirstChild("TextLabel").Text = "X"
				LuckyAuto:FindFirstChild("TextLabel").Text = "Y"
				LuckyTriple:FindFirstChild("TextLabel").Text = "A"
				LuckyOctuple:FindFirstChild("TextLabel").Text = "R2"
			end

			local eggMenuName = EggMenu.Name
			--bind
			ContextActionService:BindAction(
				"ACTION_HATCH_BUTTONS",
				function(actionName, inputState, inputObj)
					if inputState == Enum.UserInputState.Begin then
						if inputObj.KeyCode == Enum.KeyCode.E or inputObj.KeyCode == Enum.KeyCode.ButtonX then
							SystemMgr.systems.PetSystem.Server:TryHatchEgg({
								eggName = eggMenuName,
								count = 1,
							})
						elseif inputObj.KeyCode == Enum.KeyCode.T or inputObj.KeyCode == Enum.KeyCode.ButtonY then
							if PetPresets.EggsList[eggMenuName].itemType == Keys.ItemType.robux then
								return
							end
							SystemMgr.systems.PetSystem.Server:AutoHatchEgg({
								eggName = eggMenuName,
							})
						elseif inputObj.KeyCode == Enum.KeyCode.R or inputObj.KeyCode == Enum.KeyCode.ButtonA then
							SystemMgr.systems.PetSystem.Server:TryHatchEgg({
								eggName = eggMenuName,
								count = 3,
							})
						elseif inputObj.KeyCode == Enum.KeyCode.Y or inputObj.KeyCode == Enum.KeyCode.ButtonR2 then
							local count = 8
							if PetPresets.EggsList[eggMenuName].itemType == Keys.ItemType.robux then
								count = 10
							end
							SystemMgr.systems.PetSystem.Server:TryHatchEgg({
								eggName = eggMenuName,
								count = count,
							})
						end
					end
				end,
				false,
				Enum.KeyCode.T,
				Enum.KeyCode.E,
				Enum.KeyCode.R,
				Enum.KeyCode.Y,
				Enum.KeyCode.ButtonX,
				Enum.KeyCode.ButtonY,
				Enum.KeyCode.ButtonA,
				Enum.KeyCode.ButtonR2
			)
		end

		if not Connections["PromptShown"] then
			Connections["PromptShown"] = ProximityPromptService.PromptShown:Connect(function(promptObj, inputObj)
				-- egg menu
				local EggMenu = PlayerGui.Main:FindFirstChild(promptObj.Name)
				if not EggMenu then
					return
				end
				EggMenu.Adornee = promptObj.Parent
				EggMenu.Enabled = true
				EggMenu:WaitForChild("Frame").Visible = true
				addShortcut(EggMenu)
			end)
		end

		if not Connections["PromptHidden"] then
			Connections["PromptHidden"] = ProximityPromptService.PromptHidden:Connect(function(promptObj, player)
				local EggMenu = PlayerGui.Main:FindFirstChild(promptObj.Name)
				if not EggMenu then
					return
				end
				EggMenu.Adornee = nil
				EggMenu.Enabled = false
				EggMenu:WaitForChild("Frame").Visible = false
				-- EggMenu.Parent = self.Folder:WaitForChild("Assets"):WaitForChild("EggsMenu")
				ContextActionService:UnbindAction("ACTION_HATCH_BUTTONS")
			end)
		end

		if eggConfig.itemType == Keys.ItemType.wins then
			-- set price
			local priceText = eggModel:WaitForChild("Stand"):FindFirstChild("PriceLabel", true)
			priceText.Text = Util.FormatNumber(cost)
			-- set name
			local nameGui = eggModel:WaitForChild("Sign"):WaitForChild("SurfaceGui")
			nameGui.TextLabel.Text = displayName
			nameGui.TextLabel.TextInner.Text = displayName
		end
	end
end

function ShowPet(petName, frame)
	local petInfo = PetPresets.PetsList[petName]
	local EggOpeningFrame = OpeningUI.EggOpeningFrame
	Scale(EggOpeningFrame.ClickToContinue, 1, 0.3)
	toggleOverlay(true)
	EggOpeningFrame.ClickToContinue.Text = "(Click anywhere to continue)"

	local viewport = frame:WaitForChild("Viewport")
	uiController.PetViewport(petInfo.mesh:Clone(), viewport)
	frame.NameLabel.Text = petInfo.name
	frame.Rarity.Text = petInfo.rarity
	frame.Rarity.UIStroke.Color = GameConfig.RarityColor[petInfo.rarity]
	Scale(viewport, 1, 0.5)
	Scale(frame.NameLabel, 1, 0.5)
	Scale(frame.Rarity, 1, 0.5)

	task.wait(0.5)
	local function showEnding()
		toggleOverlay(false)
		Scale(viewport, 0, 0.3)
		Scale(EggOpeningFrame.ClickToContinue, 0, 0.3)
		Scale(frame.NameLabel, 0, 0.3)
		Scale(frame.Rarity, 0, 0.3)
		task.wait(0.3)
		clientIsHatching = false

		if clientAutoHatch.isAuto and not clientAutoHatch.startAuto then
			clientAutoHatch.startAuto = true
			SystemMgr.systems.PetSystem.Server:TryHatchEgg(clientAutoHatch)
		end
	end

	local taskId = task.delay(2.5, showEnding)
	local conn = nil
	conn = UserInputService.InputBegan:Connect(function(input)
		clientAutoHatch.isAuto = false
		conn:Disconnect()
		task.cancel(taskId)
		showEnding()
	end)
end

function toggleOverlay(ifShow)
	local EggOpeningFrame = OpeningUI.EggOpeningFrame
	if not ifShow then
		ifShow = not EggOpeningFrame.Overlay.Visible
	end
	local params = {}
	local trans = 1
	if ifShow then
		trans = 0.4
	end
	params.BackgroundTransparency = trans
	TweenService:Create(EggOpeningFrame.Overlay, TweenInfo.new(0.2), params):Play()
end

function Scale(unit, endScale, aniTime, visible)
	if visible == nil then
		visible = true
	end
	if visible then
		unit.Visible = true
	end
	local uiScale = unit:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = unit
	end
	local tween =
		TweenService:Create(uiScale, TweenInfo.new(aniTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Scale = endScale,
		})
	tween:Play()
	if endScale == 0 then
		tween.Completed:Connect(function()
			unit.Visible = false
			return unit.Visible
		end)
	end
	return tween
end

function EggViewPort(eggName, petName, frame)
	toggleOverlay(true)

	local eggViewPort = frame.Egg

	local eggClone = workspace.Eggs:FindFirstChild(eggName, true):WaitForChild("EggModel"):Clone()
	eggClone.Parent = eggViewPort
	local eggPrimaryPart = eggClone.PrimaryPart
	-- set no rotation
	eggPrimaryPart.CFrame = CFrame.new(eggPrimaryPart.Position)

	local camera = Instance.new("Camera")
	camera.Parent = eggViewPort

	camera.CFrame = CFrame.new(eggPrimaryPart.Position + Vector3.new(0, 0, eggPrimaryPart.Size.Z / 2 + 10))
	camera.Focus = CFrame.new(eggPrimaryPart.Position)

	eggViewPort.CurrentCamera = camera

	local startAngle = 0.4
	local conn
	conn = RunService.Heartbeat:Connect(function()
		startAngle += 0.025
		local rad = math.sin(tick() * 20) * startAngle
		eggClone:PivotTo(eggClone:GetPivot() * CFrame.Angles(0, math.rad(rad) / 5, math.rad(rad) * 1.5))
		if startAngle > 3 then
			conn:Disconnect()
			eggClone:Destroy()
			camera:Destroy()
			playFlash(OpeningUI.EggOpeningFrame)
			ShowPet(petName, frame.Pet)
		end
	end)
end

function playFlash(EggOpeningFrame)
	TweenService:Create(EggOpeningFrame.WhiteFlash, TweenInfo.new(0.1), {
		BackgroundTransparency = 0,
	}):Play()
	task.wait(0.15)
	TweenService:Create(EggOpeningFrame.WhiteFlash, TweenInfo.new(0.2), {
		BackgroundTransparency = 1,
	}):Play()
end

function GetPetCount(petDict)
	local count = 0
	for _, pet in ClientData:GetOneData(dataKey.pets) do
		if not pet then
			continue
		end
		if
			pet.name == petDict.name
			and pet.rarity == petDict.rarity
			and pet.star == petDict.star
			and pet.rank == petDict.rank
		then
			count += 1
		end
	end
	return count
end

return PetUi
