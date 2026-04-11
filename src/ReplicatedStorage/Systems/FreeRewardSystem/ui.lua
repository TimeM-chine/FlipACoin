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
local Presets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local GameConfig = require(Replicated.configs.GameConfig)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Gradients = PlayerGui:WaitForChild("Gradients")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local FreeRewardFrame = Frames:WaitForChild("FreeOPReward")
local Buttons = Main:WaitForChild("Buttons")
local FreeRewardButton = Buttons:WaitForChild("RightMenu"):WaitForChild("Special"):WaitForChild("FreeOPRewardButton")

---- logic variables ----
local rotateTask

function RotatePlate(plate)
	local ti = TweenInfo.new(3, Enum.EasingStyle.Linear)
	rotateTask = task.spawn(function()
		while true do
			local tween = TweenService:Create(plate, ti, { Rotation = plate.Rotation + 180 })
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

local FreeRewardUi = {}

function FreeRewardUi.Init()
	InitFrame()
	RotatePlate(FreeRewardButton:WaitForChild("Rotate"))
end

function FreeRewardUi.ClaimReward()
	local claimFree = FreeRewardFrame:WaitForChild("ClaimFree")
	claimFree:FindFirstChild("Text").Text = "Claimed"
	claimFree.Green.Color = Gradients.Gray.Color

	if rotateTask then
		task.cancel(rotateTask)
	end
end

function FreeRewardUi.UnlockZone()
	local Quest2 = FreeRewardFrame:WaitForChild("Quests"):WaitForChild("Quest2")
	Quest2.Task.Text = Presets.Reward.quests[2].description
	Quest2.Progress.Text.Text = "1/1"
	Quest2.Progress.ProgressBar.Size = UDim2.fromScale(1, 1)
end

function InitFrame()
	local claimFree = FreeRewardFrame:WaitForChild("ClaimFree")
	uiController.SetButtonHoverAndClick(claimFree, function()
		SystemMgr.systems.FreeRewardSystem.Server:TryClaim()
	end)

	local claimPay = FreeRewardFrame:WaitForChild("ClaimRobux")
	claimPay:FindFirstChild("Text").Text = EcoPresets.Products.pet["Watermelon Winner"].price .. " R$"
	uiController.SetButtonHoverAndClick(claimPay, function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.pet["Watermelon Winner"].productId)
	end)

	local Quest1 = FreeRewardFrame:WaitForChild("Quests"):WaitForChild("Quest1")
	Quest1.Task.Text = Presets.Reward.quests[1].description
	Quest1.Progress.Text.Text = "0/" .. Presets.Reward.quests[1].target .. "M"
	Quest1.Progress.ProgressBar.Size = UDim2.fromScale(0, 1)
	task.spawn(function()
		local minutes = 0
		while task.wait(GameConfig.OneMinute) do
			if minutes >= Presets.Reward.quests[1].target then
				break
			end
			minutes += 1
			Quest1.Progress.Text.Text = minutes .. "/" .. Presets.Reward.quests[1].target .. "M"
			Quest1.Progress.ProgressBar.Size = UDim2.fromScale(minutes / Presets.Reward.quests[1].target, 1)
		end
	end)

	local Quest2 = FreeRewardFrame:WaitForChild("Quests"):WaitForChild("Quest2")
	Quest2.Task.Text = Presets.Reward.quests[2].description

	local startTime = ClientData:GetOneData(Keys.DataKey.startTimes)["FreeOPReward"]
	local totalHour = Presets.Reward.quests[2].target / GameConfig.OneHour
	local nowHour = (os.time() - startTime) / GameConfig.OneHour
	if startTime and os.time() - startTime >= Presets.Reward.quests[2].target then
		Quest2.Progress.Text.Text = "24/24H"
		Quest2.Progress.ProgressBar.Size = UDim2.fromScale(1, 1)
	else
		Quest2.Progress.Text.Text = `{math.floor(nowHour)}/{totalHour}H`
		Quest2.Progress.ProgressBar.Size = UDim2.fromScale(0, 1)
	end
end

return FreeRewardUi
