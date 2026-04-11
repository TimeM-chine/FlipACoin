---- services ----
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local CardPresets = require(Replicated.Systems.CardSystem.Presets)
local ItemTypeKey = Keys.ItemType

---- module ----
local ServerToolHandler = {}
local activeTools = {} -- {[player] = {model = model, weld = weld, itemType = itemType, itemName = itemName}}

-- Helper function to set physics properties for tool models
local function SetModelPhysicsForServer(model)
	local PrimaryPart = model.PrimaryPart
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") then
			des.CanCollide = false
			des.CanTouch = false
			des.CanQuery = false
			des.Anchored = false
			des.Massless = true

			if des ~= PrimaryPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = PrimaryPart
				weld.Part1 = des
				weld.Parent = des
			end
		end
	end
end

-- Helper function to create weld between hand and model
local function WeldModelToHand(character, model, gripCFrame)
	local rightHand = character:FindFirstChild("RightHand")
	if not rightHand then
		warn("Right hand not found for character:", character.Name)
		return nil
	end

	model:PivotTo(rightHand.CFrame * gripCFrame)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightHand
	weld.Part1 = model.PrimaryPart
	weld.Parent = model

	return weld
end

-- Get card model name based on type
local function GetCardModelName(cardType)
	if cardType == "normal" then
		return "normalCard"
	elseif cardType == "full" then
		return "fullCard"
	elseif cardType == "shiny" then
		return "shinyCard"
	else
		return "normalCard"
	end
end

-- Format card display name
local function FormatCardDisplayName(cardName, cardType)
	if cardType == "normal" then
		return cardName
	elseif cardType == "full" then
		return `[Full]{cardName}`
	elseif cardType == "shiny" then
		return `[Shiny]{cardName}`
	else
		return cardName
	end
end

-- Create and equip tool model on server
function ServerToolHandler.EquipTool(player, itemType, itemName)
	-- Clean up any existing tool
	ServerToolHandler.UnequipTool(player)

	local character = player.Character
	if not character then
		warn("Character not found for player:", player.Name)
		return false
	end

	local Assets = script.Parent.Assets
	local model = nil
	local gripCFrame = CFrame.new(0, 0, 0)

	if itemType == ItemTypeKey.furniture then
		gripCFrame = CFrame.Angles(math.rad(-90), 0, 0)
		local furnitureModel = Assets:WaitForChild("furniture"):FindFirstChild(itemName)
		if not furnitureModel then
			warn("Furniture model not found:", itemName)
			return false
		end
		model = furnitureModel:Clone()

		local originalScale = model:GetScale()
		model:ScaleTo(originalScale * 0.2)

		SetModelPhysicsForServer(model)
		model.Parent = character
	elseif itemType == ItemTypeKey.tools then
		local toolIns = Assets:WaitForChild("tools"):FindFirstChild(itemName)
		gripCFrame = toolIns.Grip * CFrame.Angles(math.rad(90), 0, 0)
		model = Instance.new("Model")
		for _, des in toolIns:GetDescendants() do
			des:Clone().Parent = model
		end
		model.PrimaryPart = model:FindFirstChild("Handle")

		SetModelPhysicsForServer(model)
		model.Parent = character
	elseif itemType == ItemTypeKey.cardPacks then
		gripCFrame = CFrame.Angles(math.rad(90), 0, 0)

		local packModel = Assets:WaitForChild("cardPacks"):FindFirstChild(itemName)
		if not packModel then
			warn("Card pack model not found:", itemName)
			return false
		end
		model = packModel:Clone()

		SetModelPhysicsForServer(model)
		model.Parent = character
	elseif itemType == ItemTypeKey.cards then
		gripCFrame = CFrame.new(0, -0.5, -1) * CFrame.Angles(math.rad(-90), 0, 0)

		local cardName, cardType = CardPresets.ParseCardName(itemName)
		local cardModelName = GetCardModelName(cardType)
		local cardTemplate = Assets:FindFirstChild(cardModelName)

		if not cardTemplate then
			warn("Card model not found:", cardModelName)
			return false
		end

		model = cardTemplate:Clone()

		-- Set up card visuals
		local surfaceGui = model:FindFirstChild("Main") and model.Main:FindFirstChild("SurfaceGui")
		if surfaceGui then
			local displayName = FormatCardDisplayName(cardName, cardType)
			surfaceGui.name.Text = displayName

			if CardPresets.CardsList[cardName] then
				surfaceGui.power.TextLabel.Text = `{CardPresets.GetCardCashPerSec(itemName)}/s`
				surfaceGui.rarity.Text = CardPresets.CardsList[cardName].rarity
				surfaceGui.rarity.TextColor3 = Textures.RarityColor[CardPresets.CardsList[cardName].rarity]
				surfaceGui.bg.Image = Textures.Environments[CardPresets.CardsList[cardName].envId].icon
				surfaceGui.bg.petIcon.Image = Textures.Cards[cardName].icon
			end
		end

		SetModelPhysicsForServer(model)
		model.Parent = character
	else
		warn("Unknown item type:", itemType)
		return false
	end

	WeldModelToHand(character, model, gripCFrame)

	activeTools[player] = {
		model = model,
		itemType = itemType,
		itemName = itemName,
	}

	return true
end

-- Unequip and destroy tool model
function ServerToolHandler.UnequipTool(player)
	local toolData = activeTools[player]
	if not toolData then
		return
	end

	if toolData.model then
		toolData.model:Destroy()
	end

	activeTools[player] = nil
end

-- Clean up when player leaves
function ServerToolHandler.PlayerRemoving(player)
	ServerToolHandler.UnequipTool(player)
end

return ServerToolHandler
