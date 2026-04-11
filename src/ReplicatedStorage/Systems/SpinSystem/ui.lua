---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local SpinPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local SpinFrame = Frames:WaitForChild("Spin")
local itemsFrame = SpinFrame:WaitForChild("plate"):WaitForChild("items")
local spinBtn = SpinFrame:WaitForChild("Buttons"):WaitForChild("spin")
local SpinButton =
	Main:WaitForChild("Buttons"):WaitForChild("TopBar"):WaitForChild("SpinButton")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local dataKey = Keys.DataKey
local spinTi = TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local isSpinning = false

local SpinUi = {}

function RotatePlate(plate)
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear)
	task.spawn(function()
		while true do
			local tween = TweenService:Create(plate, ti, { Rotation = plate.Rotation + 180 })
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

function SpinUi.Init()
	RotatePlate(SpinButton.ImageLabel)
	local buttons = SpinFrame:WaitForChild("Buttons")
	uiController.SetButtonHoverAndClick(buttons.spin, function()
		if isSpinning then
			uiController.SetNotification({
				text = "Too fast!",
			})
			return
		end
		local spin = ClientData:GetOneData(dataKey.spin)
		if spin > 0 then
			SystemMgr.systems.SpinSystem.Server:TrySpin()
		else
			MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.spin.spin1.productId)
		end
	end)

	uiController.SetButtonHoverAndClick(buttons.add3, function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.spin.spin3.productId)
	end)

	uiController.SetButtonHoverAndClick(buttons.add10, function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.spin.spin10.productId)
	end)

	local rebirth = ClientData:GetOneData(dataKey.rebirth)
	rebirth = rebirth == 0 and 1 or rebirth
	for i = 1, 5 do
		local rewardConfig = SpinPresets.Rewards[i]
		local card = itemsFrame:FindFirstChild(i)
		card.icon.Image = rewardConfig.icon or Textures.GetIcon(rewardConfig.items[1])
		local itemType = rewardConfig.items[1].itemType
		if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, itemType) then
			card.icon.count.Text = "x" .. Util.FormatNumber(SpinPresets.Rewards[i].items[1].count * rebirth * rebirth)
		else
			card.icon.count.Text = "x" .. Util.FormatNumber(SpinPresets.Rewards[i].items[1].count)
		end

		local formattedNum = string.format("%.2f", SpinPresets.Rewards[i].weight * 100)
		-- card.probability.Text = formattedNum.."%"
	end

	local spin = ClientData:GetOneData(dataKey.spin)
	spinBtn.count.Text = "x" .. spin

	local waitingSpinTime = ClientData:GetOneData(dataKey.waitingSpinTime)
	if waitingSpinTime ~= -1 then
		uiController.AddTimerLabel({
			textLabel = spinBtn.timer,
			duration = SpinPresets.FreeSpinInterval - (os.time() - waitingSpinTime) + 3,
			callback = function()
				spinBtn.timer.Text = ""
				SystemMgr.systems.SpinSystem.Server:TryAddFreeSpin()
			end,
		})
	else
		spinBtn.timer.Text = ""
	end
end

function SpinUi.Spin(args)
	isSpinning = true
	local rewardIndex = args.rewardIndex
	local spin = args.spin
	spinBtn.count.Text = "x" .. spin

	local reward = SpinPresets.Rewards[rewardIndex]

	itemsFrame.Rotation = 90
	local finalRotation = 90 - math.random(72 * (rewardIndex - 1) + 10, 72 * rewardIndex - 10) + 360 * math.random(7, 9)
	local tween = TweenService:Create(itemsFrame, spinTi, {
		Rotation = finalRotation,
	})

	tween:Play()
	tween.Completed:Wait()
	isSpinning = false
end

function SpinUi.AddSpin()
	local spin = ClientData:GetOneData(dataKey.spin)
	spinBtn.count.Text = "x" .. spin

	local waitingSpinTime = ClientData:GetOneData(dataKey.waitingSpinTime)
	if waitingSpinTime ~= -1 then
		uiController.AddTimerLabel({
			textLabel = spinBtn.timer,
			duration = SpinPresets.FreeSpinInterval - (os.time() - waitingSpinTime) + 3,
			callback = function()
				spinBtn.timer.Text = ""
				SystemMgr.systems.SpinSystem.Server:TryAddFreeSpin()
			end,
		})
	else
		spinBtn.timer.Text = ""
	end
end

function SpinUi.UpdateRewards()
	local rebirth = ClientData:GetOneData(dataKey.rebirth)
	rebirth = rebirth == 0 and 1 or rebirth
	for i = 1, 5 do
		local rewardConfig = SpinPresets.Rewards[i]
		local card = itemsFrame:FindFirstChild(i)
		local itemType = rewardConfig.items[1].itemType
		if not table.find({ Keys.ItemType.wins, Keys.ItemType.power }, itemType) then
			continue
		end
		card.icon.count.Text = "x" .. Util.FormatNumber(SpinPresets.Rewards[i].items[1].count * rebirth * rebirth)
	end
end

return SpinUi
