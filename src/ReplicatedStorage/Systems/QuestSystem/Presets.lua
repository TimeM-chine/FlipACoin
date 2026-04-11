local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Keys = require(Replicated.configs.Keys)
local ItemType = Keys.ItemType
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)

local ClientData
if RunService:IsClient() then
	ClientData = require(Replicated.Systems.ClientData)
end

local QuestPresets = {}

QuestPresets.QuestType = Keys.QuestType

local function GetBackpackOreScore()
	if not ClientData then
		return 0
	end
	local backpack = ClientData:GetOneData(Keys.DataKey.backpack)
	local ores = backpack and backpack.ores
	if not ores then
		return 0
	end
	local totalScore = 0
	for oreName, count in ores do
		local preset = BlockPresets.Ores[oreName]
		if preset then
			totalScore += preset.score * count
		end
	end
	return totalScore
end

QuestPresets.Quests = {
	-- Tutorial Quests (1-5) - Keep Similar Structure
	[1] = {
		title = "Tutorial",
		quests = {
			[1] = {
				title = "Collect Ores",
				guideText = "Go to the Block area and mine 3 ores!",
				target = 30,
				questType = QuestPresets.QuestType.collectAnyOre,
				guideTo = function()
					return workspace.Boxes:WaitForChild("BlockArea")
				end,
			},
		},
		rewards = {
			-- [1] = {
			-- 	itemType = ItemType.potion,
			-- 	name = "wins1Potion30",
			-- 	count = 1,
			-- },
			-- [2] = {
			-- 	itemType = ItemType.wins,
			-- 	count = 150,
			-- },
		},
	},
	[2] = {
		title = "Tutorial",
		quests = {
			[1] = {
				title = "Forge a Weapon",
				guideText = "You have enough ores, head to the Forge to craft a weapon!",
				guideUI = "forge",
				target = 1,
				questType = QuestPresets.QuestType.forge,
				guideTo = function()
					local totalScore = GetBackpackOreScore()
					if totalScore >= 30 then
						return workspace.Boxes:WaitForChild("Forge")
					end
					return workspace.Boxes:WaitForChild("BlockArea")
				end,
			},
		},
		rewards = {},
	},
	[3] = {
		title = "Tutorial",
		quests = {
			[1] = {
				title = "Equip New Weapon",
				guideText = "Open your weapon bag and equip the new weapon!",
				guideUI = "equipWeapon",
				target = 1,
				questType = QuestPresets.QuestType.equipWeapon,
			},
		},
		rewards = {},
	},
}

return QuestPresets
