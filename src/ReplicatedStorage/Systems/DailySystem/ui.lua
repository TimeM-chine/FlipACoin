---- services ----
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local GameConfig = require(Replicated.configs.GameConfig)
local DailyPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local Icon = require(Replicated.Packages.topbarplus)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Gradients = PlayerGui:WaitForChild("Gradients")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local DailyFrame = Frames:WaitForChild("Daily")
local giftScroll = DailyFrame:WaitForChild("ScrollingFrame")

---- logic variables ----
local DAILY_STATE = {
	claimed = 2,
	active = 1,
	notReady = 0,
}

local DailyUi = {}

function DailyUi.Init()
	local stringValue = script.Parent.Presets:WaitForChild("Day2Reward")
	DailyPresets.GiftList[2].name = stringValue.Value

	local settingsIcon: any = Icon.new()
		:align("Left")
		:setName("Daily")
		:setImage("http://www.roblox.com/asset/?id=82869678350407", "Selected")
		:setImage("http://www.roblox.com/asset/?id=82869678350407", "Deselected")
		:autoDeselect(false)
	settingsIcon.toggled:Connect(function(): ()
		if not GuiService.MenuIsOpen then
			if DailyFrame.Visible then
				uiController.CloseFrame("Daily")
			else
				uiController.OpenFrame("Daily")
			end
		end
	end)

	local dailyClaim = ClientData:GetOneData(Keys.DataKey.dailyClaim)
	local template = giftScroll:WaitForChild("Template")
	template.Visible = false
	local canClaim = false
	for i = 1, #DailyPresets.GiftList do
		local config = DailyPresets.GiftList[i]
		local function setBtn(btn)
			btn.Visible = true
			btn.Name = i
			---- set icon ----
			btn:WaitForChild("icon").Image = Textures.GetIcon(config)
			btn.day.Text = "DAY " .. i

			if dailyClaim[i] == DAILY_STATE.active then
				btn.claim.TextLabel.Text = "CLAIM"
				btn.claim.UIGradient.Color = Gradients.Green.Color
				canClaim = true
			elseif dailyClaim[i] == DAILY_STATE.claimed then
				btn.claim.TextLabel.Text = "CLAIMED"
				btn.claim.UIGradient.Color = Gradients.DarkGray.Color
			else
				btn.claim.TextLabel.Text = "NOT READY"
				btn.claim.UIGradient.Color = Gradients.Gray.Color
			end

			---- set count ----
			local rebirth = ClientData:GetOneData(Keys.DataKey.rebirth)
			rebirth = rebirth == 0 and 1 or rebirth
			local count = btn.count
			if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, config.itemType) then
				count.Text = "x" .. Util.FormatNumber(config.count * rebirth * rebirth)
			else
				count.Text = "x" .. Util.FormatNumber(config.count)
			end

			uiController.SetButtonHoverAndClick(btn.claim, function()
				local text = btn.claim.TextLabel.Text
				if text == "CLAIM" then
					SystemMgr.systems.DailySystem.Server:TryClaimGift({
						dayIndex = i,
					})
				elseif text == "CLAIMED" then
					uiController.SetNotification({
						text = "You have claimed this gift.",
						textColor = Color3.fromRGB(255, 0, 0),
					})
				else
					uiController.SetNotification({
						text = "Claim it another day.",
					})
				end
			end)

			---- set gradient ----
			local gradient = config.gradient
			if Gradients:FindFirstChild(gradient) then
				btn.UIGradient.Color = Gradients[gradient].Color
			end
		end
		Util.Clone(template, giftScroll, setBtn)
	end

	local quests = ClientData:GetOneData(Keys.DataKey.quests)
	local index = quests.index
	if canClaim and index > 3 then
		uiController.OpenFrame("Daily")
	end
end

function DailyUi.ReceivedGift(args)
	local dayIndex = args.dayIndex
	local btn = giftScroll:FindFirstChild(dayIndex)
	if btn then
		btn.claim.TextLabel.Text = "CLAIMED"
		btn.claim.UIGradient.Color = Gradients.DarkGray.Color
	end
end

function DailyUi.UpdateRewards()
	for i = 1, #DailyPresets.GiftList do
		local config = DailyPresets.GiftList[i]
		local btn = giftScroll:FindFirstChild(i)
		---- set count ----
		local rebirth = ClientData:GetOneData(Keys.DataKey.rebirth)
		rebirth = rebirth == 0 and 1 or rebirth
		local count = btn.count
		local itemType = config.itemType
		if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, itemType) then
			count.Text = "x" .. Util.FormatNumber(config.count * rebirth * rebirth)
		else
			count.Text = "x" .. Util.FormatNumber(config.count)
		end
	end
end

return DailyUi
