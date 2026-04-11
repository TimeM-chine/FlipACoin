--[[
--Author: TimeM_chine
--Created Date: Mon Feb 26 2024
--Description: PetClass.lua
--Last Modified: 2024-05-24 6:44:45
--]]

---- services ----
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

---- requires ----
local PetPresets = require(Replicated.Systems.PetSystem.Presets)
local Keys = require(Replicated.configs.Keys)
local TableModule = require(Replicated.modules.TableModule)
local ModelModule = require(Replicated.modules.ModelModule)
local GameConfig = require(Replicated.configs.GameConfig)

---- common variables ----
local petId = 0
local SystemMgr, SENDER
task.delay(1, function()
	SystemMgr = require(Replicated.Systems.SystemMgr)
	SENDER = SystemMgr.SENDER
end)
local petStates = Keys.PetStates
local Connections = {}
local pets = {}

---- server variables ----
local heartbeatGap = 60 --- 60 heartbeat 为 1 秒
local heartbeatTick = 0

---- client variables ----
local lastMoveDirM = 0
local renderTick = 0

---@class PetClass
local PetClass = {
	name = nil,
	ownerId = nil,
	serverInt = nil, -- server folder 中的 IntValue => Identifier
	model = nil, -- client folder 中的 Model
	targetList = {},
	atkCd = 3,
	atkDamage = 1,
	atkIndex = 1, -- 攻击段数，一共3段普攻
	level = 1, -- 宠物等级， 宠物的基础伤害只和等级有关
	maxDistance = 20, -- 索敌最大距离（怪物与主人之间的）
	-- status
	state = petStates.Idle,
}
PetClass.__index = PetClass

function PetClass.new(args)
	local self = setmetatable({}, PetClass)
	self.serverInt = args.serverInt
	self.name = args.name or self.serverInt.Name:split("_")[2]
	self.ownerId = args.ownerId or args.serverInt:GetAttribute("UserId")
	self.targetList = {} -- monsterIns 的表

	-- print("PetClass.new", args)
	if IsServer then
		-- nothing todo
	else
		self.model = CreatePetModel(self.serverInt)
	end
	return self
end

function PetClass:AddTarget(target)
	print("PetClass:AddTarget", target, self.targetList)
	if not table.find(self.targetList, target) then
		table.insert(self.targetList, target)
	end
end

function PetClass:RemoveTarget(target)
	local index = table.find(self.targetList, target)
	if index then
		table.remove(self.targetList, index)
	end
end

function PetClass:ClearTarget()
	self.targetList = {}
end

function PetClass:Destroy()
	if IsServer then
		self.state = petStates.Dead
		self.serverInt:Destroy()
		TableModule.RemoveByValue(pets, self)
	else
		if self.model then
			self.model:Destroy()
		end
		for i, petIns in pets do
			if petIns.serverInt == self.serverInt then
				table.remove(pets, i)
				break
			end
		end
	end
end

function PetClass:Attack(args)
	if self.state ~= petStates.Idle then
		return
	end
	self.state = petStates.Attacking
	task.delay(2, function()
		self.state = petStates.Idle
	end)
	self.atkCd = PetPresets.PetsList[self.name].atkCd
	self.atkIndex = (self.atkIndex + 1) % 3 + 1
	local player = Players:GetPlayerByUserId(self.ownerId)
	SystemMgr.systems.PetSystem:Attack(SENDER, player, {
		serverInt = self.serverInt,
		atkIndex = self.atkIndex,
	})
end

function PetClass:Move(Humanoid)
	if self.state ~= petStates.Idle then
		return
	end
	SystemMgr.systems.AnimateSystem:PlayAnimation(SENDER, nil, {
		actor = self.model,
		animName = "move",
		animKey = "malePet",
		speed = Humanoid.WalkSpeed / 16,
	})
end

function PetClass:StopMove()
	if self.state ~= petStates.Idle then
		return
	end
	SystemMgr.systems.AnimateSystem:StopAnimation(SENDER, nil, {
		actor = self.model,
		animName = "move",
	})
end

local PetMgr = {}

function PetMgr.CreateIns(args)
	for _, pet in pets do
		if pet.serverInt == args.serverInt then
			print("exist", pet.serverInt)
			return pet
		end
	end
	local petIns = PetClass.new(args)
	table.insert(pets, petIns)
	return petIns
end

---comment 获取宠物实例
---@param serverInt IntValue 服务端实例
---@return PetClass
function PetMgr.GetIns(serverInt)
	for _, petIns in pets do
		if petIns.serverInt == serverInt then
			return petIns
		end
	end
end

function PetMgr.GetAllIns()
	return pets
end

function PetMgr.GetPlayerPetIns(player)
	local petIns = {}
	for _, pet in pets do
		if pet.ownerId == player.UserId then
			table.insert(petIns, pet)
		end
	end

	return petIns
end

function PetMgr.RemoveAllTarget(target)
	for _, petIns in pets do
		petIns:RemoveTarget(target)
	end
end

if IsServer then
else
	---comment 根据行列、序号和给定基础间隔，得到位置
	local function getPosition(col, row, mod, padding)
		local x, z
		if row == 1 and mod ~= 0 then
			if mod == 1 then
				x = 0
			elseif mod == 2 then
				x = (2 * col - 3) * padding / 2
			end
		else
			x = ((col - 1) % 3 - 1) * padding
		end
		z = row * padding
		return x, z
	end

	local function positionPets(character, folder, dt)
		-- group by rarity
		local rarityPets = {}
		for i, pet in pairs(folder:GetChildren()) do
			local petName = pet.Name:split("_")[2]
			-- remove "Shiny" string in petName like "abcShiny"
			petName = string.match(petName, "(.-)Shiny") or petName
			local petInfo = PetPresets.PetsList[petName]
			local rarity = petInfo.Rarity

			if rarity == "Mythic" or rarity == "Secret" then
				if not rarityPets[rarity] then
					rarityPets[rarity] = {}
				end

				table.insert(rarityPets[rarity], pet)
			else
				if not rarityPets["Normal"] then
					rarityPets["Normal"] = {}
				end
				table.insert(rarityPets["Normal"], pet)
			end
		end

		local function positionPetInGroup(_pets, height, padding)
			-- local mod = #folder:GetChildren()%3
			local mod = #_pets % 3
			for i, pet in pairs(_pets) do
				-- colunm, row in 3
				local row, col
				if mod > 0 then
					if i <= mod then
						row = math.ceil(i / 3)
						col = i % 3
					else
						row = math.ceil((i - mod) / 3) + 1
						col = (i - mod) % 3
					end
				else
					row = math.ceil(i / 3)
					col = i % 3
				end

				local x, z = getPosition(col, row, mod, padding)
				if not character.PrimaryPart then
					return
				end
				local characterSize = character.PrimaryPart.Size --:GetBoundingBox()
				--  local _, petSize = pet:GetBoundingBox()

				local petSize
				if pet:IsA("Model") then
					petSize = pet.PrimaryPart.Size
				else
					petSize = pet.Size
				end

				local offsetY = -characterSize.Y / 2 + petSize.Y / 2
				local timeOffset = 0
				if character.Humanoid.MoveDirection.Magnitude > 0 then
					timeOffset = 1
				end

				local targetCFrame = character.PrimaryPart.CFrame
					* CFrame.new(x, offsetY / 2 + math.sin(time() * 3 - timeOffset + height), z)
					* CFrame.Angles(0, math.rad(180), 0)
				if pet:IsA("Model") then
					pet:PivotTo(pet.PrimaryPart.CFrame:Lerp(targetCFrame, 0.1))
				else
					pet.CFrame = pet.CFrame:Lerp(targetCFrame, 0.1)
				end
			end
		end

		for rarity, _pets in pairs(rarityPets) do
			local height = 0
			local padding = 4
			if rarity == "Mythic" then
				height = 4
				padding = 6
			elseif rarity == "Omega" then
				height = 8
				padding = 8
			end
			positionPetInGroup(_pets, height, padding)
		end
	end

	local PetsFolder = workspace.PetsFolder
	RunService.RenderStepped:Connect(function(dt)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then
				continue
			end

			local playerFolder = PetsFolder:FindFirstChild(player.UserId)
			if not playerFolder then
				continue
			end

			if not playerFolder:FindFirstChild("Pets_Client") then
				continue
			end

			positionPets(character, playerFolder.Pets_Client, dt)
		end
	end)
end

function GetPetsFolderOfPlayer(player, findServer)
	if not player.Character then
		return
	end

	local playerFolder = workspace.PetsFolder:FindFirstChild(player.UserId)
	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = player.UserId
		playerFolder.Parent = workspace.PetsFolder
	end

	local folderName

	if IsServer or findServer then
		folderName = "Pets_Server"
	else
		folderName = "Pets_Client"
	end

	local folder = playerFolder:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = playerFolder
	end

	return folder
end

---- [[ Client ]] ----
function CreatePetModel(fakePet)
	if (not fakePet) or not fakePet.Parent then
		return
	end
	-- clone pet on client
	local playerFolder = fakePet.Parent.Parent

	local petIndexName = fakePet.Name
	local player = Players:GetPlayerByUserId(playerFolder.Name)
	if not player then
		return
	end

	if GetPetsFolderOfPlayer(player):FindFirstChild(petIndexName) then
		print("pet exist")
		return
	else
		print("clone pet")
		local petName = petIndexName:split("_")[2]
		local index = petIndexName:split("_")[1]
		local petConfig = PetPresets.PetsList[petName]

		local pet = petConfig.mesh:Clone()
		ModelModule.SetModelCollisionGroup(pet, Keys.CollisionGroup.Pet)
		pet.Name = index .. "_" .. petName
		pet.Parent = GetPetsFolderOfPlayer(player)

		return pet
	end
end

return PetMgr
