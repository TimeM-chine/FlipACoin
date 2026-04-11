---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local TrailPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local TrailFrame = Frames:WaitForChild("Trail")
local TrailScroll = TrailFrame:WaitForChild("ScrollingFrame")
local boostInfo = TrailFrame:WaitForChild("TrailBoostInfo")

---- logic variables ----
local curTrail = nil

local TrailUi = {}

function TrailUi.Init()
	local TrailBoostInfo = TrailFrame:FindFirstChild("TrailBoostInfo")
	TrailBoostInfo.Visible = false
	local trails = ClientData:GetOneData(Keys.DataKey.trails)
	local trailEquipped = ClientData:GetOneData(Keys.DataKey.trailEquipped)
	TrailScroll.Template.Visible = false
	for name, config in pairs(TrailPresets.Trails) do
		Util.Clone(TrailScroll.Template, TrailScroll, function(card)
			card.Visible = true
			card.Name = name
			card:WaitForChild("Name").Text = config.name
			card.LayoutOrder = config.speedBoost
			-- cost
			local Button = card:FindFirstChild("Button")
			if trails[name] then
				if trailEquipped == name then
					Button:FindFirstChild("Cost").Text = "Equipped"
					curTrail = name
				else
					Button:FindFirstChild("Cost").Text = "Owned"
				end

				Button:FindFirstChild("Cost").Position = UDim2.new(0.5, 0, 0.5, 0)

				-- del cost icon
				if Button:FindFirstChild("Cost"):FindFirstChild("ImageLabel") then
					Button:FindFirstChild("Cost"):FindFirstChild("ImageLabel"):Destroy()
				end

				local UIPadding = Button:FindFirstChild("Cost"):FindFirstChild("UIPadding")
				UIPadding.PaddingRight = UDim.new(0.1, 0)
			else
				Button:FindFirstChild("Cost").Text = Util.FormatNumber(config.cost, true)
			end

			-- button
			uiController.SetButtonHoverAndClick(Button, function()
				if Button:FindFirstChild("Cost").Text == "Owned" then
					SystemMgr.systems.TrailSystem.Server:EquipTrail({ name = name })
				elseif Button:FindFirstChild("Cost").Text == "Equipped" then
					-- nothing
				else
					SystemMgr.systems.TrailSystem.Server:BuyTrail({ name = name })
				end
			end)

			-- preview
			local trailInstance = script.Parent.Assets.Trails:FindFirstChild(name)
			if trailInstance.Texture ~= "" then
				card:FindFirstChild("Preview"):FindFirstChild("ImageLabel").Image = trailInstance.Texture
				card:FindFirstChild("Preview"):FindFirstChild("ImageLabel").Visible = true
			else
				card:FindFirstChild("Preview"):FindFirstChild("UIGradient").Color = trailInstance.Color
				card:FindFirstChild("Preview"):FindFirstChild("ImageLabel").Visible = false
			end
			uiController.SetHoverFrame(card, {
				title = config.name,
				infoList = config.info,
			})
		end)
	end
end

function TrailUi.BuyTrail(args)
	local name = args.name
	local card = TrailScroll:FindFirstChild(name)
	if not card then
		return
	end
	local Button = card:FindFirstChild("Button")
	Button:FindFirstChild("Cost").Text = "Owned"
	Button:FindFirstChild("Cost").Position = UDim2.new(0.5, 0, 0.5, 0)
	Button:FindFirstChild("Cost"):FindFirstChild("UIPadding").PaddingRight = UDim.new(0.1, 0)

	if Button:FindFirstChild("Cost"):FindFirstChild("ImageLabel") then
		Button:FindFirstChild("Cost"):FindFirstChild("ImageLabel"):Destroy()
	end
end

function TrailUi.EquipTrail(args)
	local name = args.name
	local card = TrailScroll:FindFirstChild(name)
	if not card then
		return
	end

	if curTrail then
		local oldCard = TrailScroll:FindFirstChild(curTrail)
		if oldCard then
			local oldButton = oldCard:FindFirstChild("Button")
			oldButton:FindFirstChild("Cost").Text = "Owned"
			oldButton:FindFirstChild("Cost").Position = UDim2.new(0.5, 0, 0.5, 0)
			oldButton:FindFirstChild("Cost"):FindFirstChild("UIPadding").PaddingRight = UDim.new(0.1, 0)
			oldButton.BackgroundColor3 = Textures.ButtonColors.green
		end
	end
	curTrail = name

	local Button = card:FindFirstChild("Button")
	Button:FindFirstChild("Cost").Text = "Equipped"
	Button:FindFirstChild("Cost").Position = UDim2.new(0.5, 0, 0.5, 0)
	Button:FindFirstChild("Cost"):FindFirstChild("UIPadding").PaddingRight = UDim.new(0.1, 0)
	Button.BackgroundColor3 = Textures.ButtonColors.blue

	local config = TrailPresets.Trails[name]
	local TrailBoostInfo = TrailFrame:FindFirstChild("TrailBoostInfo")
	TrailBoostInfo.Visible = true
	TrailBoostInfo.Text = string.format("%s Trail Boost WalkSpeed by %d%%", config.name, config.speedBoost)
end

return TrailUi
