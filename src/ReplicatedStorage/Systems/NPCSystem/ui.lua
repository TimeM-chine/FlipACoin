---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local Zone = require(Replicated.modules.Zone)
local SimpleDialogue = require(Replicated.Packages.SimpleDialogue)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local NPCFolder = workspace:WaitForChild("NPCs")

local NPCUi = {}

function NPCUi.Init()
	local npcFrame = {
		displays = "FurnitureStore",
		packs = "PackStore",
	}

	for name, frameName in npcFrame do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hi~"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 20
		prompt.Triggered:Connect(function()
			uiController.OpenFrame(frameName)
		end)
		prompt.Parent = NPCFolder:WaitForChild(name)
	end

	local sellMan = NPCFolder:WaitForChild("sell")
	local dialogue = SimpleDialogue.new(sellMan)
	dialogue:SetConfiguration({
		proximityDistance = 10,
	})

	local dialogueTree = SimpleDialogue.CreateTree({
		SimpleDialogue.CreateNode("Hi, what would you like to sell?", {
			SimpleDialogue.CreateOption("Sell all cards", function()
				SystemMgr.systems.BackpackSystem.Server:SellAllCards()
			end),
			SimpleDialogue.CreateOption("Sell specific cards", function()
				local Character = LocalPlayer.Character
				local tool = Character:FindFirstChildOfClass("Tool")
				if tool and tool:GetAttribute("itemType") == Keys.ItemType.cards then
					SystemMgr.systems.BackpackSystem.Server:SellItems({
						items = {
							{
								itemType = Keys.ItemType.cards,
								itemName = `{tool:GetAttribute("cardName")}_{tool:GetAttribute("cardType")}`,
								count = tool:GetAttribute("itemCount"),
							},
						},
					})
				else
					dialogue:DisplayNode(2)
				end
			end),
		}),
		SimpleDialogue.CreateAutoNode("You are not holding any cards.", function()
			task.wait(2)
			dialogue:EndDialogue()
		end),
	})

	dialogue:SetDialogueTree(dialogueTree)
end

return NPCUi
