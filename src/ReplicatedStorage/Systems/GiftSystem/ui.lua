---- services ----
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local GameConfig = require(Replicated.configs.GameConfig)
local Zone = require(Replicated.modules.Zone)
local Util = require(Replicated.modules.Util)
local GiftPresets = require(script.Parent.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Gradients = PlayerGui:WaitForChild("Gradients")
local Frames = Main:WaitForChild("Frames")
local Buttons = Main:WaitForChild("Buttons")
local GiftsFrame = Frames:WaitForChild("OnlineGifts")
local giftScroll = GiftsFrame:WaitForChild("ScrollingFrame")
local OnlineGiftsBtn = Buttons:WaitForChild("TopBar"):WaitForChild("OnlineGiftsButton")
local giftIcon = OnlineGiftsBtn:WaitForChild("ImageLabel")
local unclaimedFrame = giftIcon:WaitForChild("unclaimed")

---- logic variables ----
local unClaimedGiftCount = 0
local unclaimedGifts = {}

function ShakeGiftIcon()
	local tick = 1
	RunService.Heartbeat:Connect(function()
		tick += 1
		if tick > 120 then
			if unClaimedGiftCount <= 0 then
				for i, v in ipairs(unclaimedGifts) do
					if v then
						OnlineGiftsBtn.Gifts.Text = giftScroll:FindFirstChild(i).timer.TextLabel.Text
						break
					end
				end
				return
			end
			OnlineGiftsBtn.Gifts.Text = "CLAIM GIFT!"
			local rad = math.sin(tick * 20) * 5
			giftIcon.Rotation = rad
			if tick > 240 then
				tick = 1
				giftIcon.Rotation = 0
			end
		end
	end)
end

local GiftUi = {}

function GiftUi.Init()
	local template = giftScroll:WaitForChild("Template")
	template.Visible = false
	ShakeGiftIcon()
	unclaimedFrame.Visible = false

	for i, gift in ipairs(GiftPresets.Gifts) do
		unclaimedGifts[i] = true
		Util.Clone(template, giftScroll, function(unit)
			unit.Visible = true
			unit.Name = i
			local gradient = gift.gradient
			if Gradients:FindFirstChild(gradient) then
				unit.UIGradient.Color = Gradients[gradient].Color
			end
			local item = gift.items[1]
			if item.itemType == "pet" then
				-- unit.icon.Visible = false
				-- unit.view.Visible = true
				-- local petMesh = PetPresets.PetsList[item.name].mesh:Clone()
				-- uiController.PetViewport(petMesh, unit.view)
			elseif item.itemType == Keys.ItemType.potion then
				unit:WaitForChild("icon").Image = Textures.Potions[item.name].icon
			elseif item.itemType == Keys.ItemType.egg then
				unit.icon.Visible = false
				unit.view.Visible = true
				local eggMesh = workspace.Eggs:FindFirstChild(item.name):FindFirstChild("EggModel"):Clone()
				uiController.PetViewport(eggMesh, unit.view)
			else
				unit:WaitForChild("icon").Image = Textures.GetIcon({ itemType = item.itemType, name = item.name })
			end

			uiController.SetButtonHoverAndClick(unit, function()
				SystemMgr.systems.GiftSystem.Server:TryClaimGift({ giftIndex = i })
			end)
			unit.count.Text = "x" .. item.count

			uiController.AddTimerLabel({
				textLabel = unit.timer.TextLabel,
				duration = gift.timer,
				callback = function()
					unClaimedGiftCount += 1

					if unclaimedGifts[i] then
						unit.timer.TextLabel.Text = "CLAIM!"
						unit.timer.TextLabel.TextColor3 = Textures.ButtonColors.green
						unclaimedFrame.Visible = true
						unclaimedFrame.TextLabel.Text = unClaimedGiftCount
					end
				end,
			})
		end)
	end
	GiftUi.UpdateGiftRewards()
end

function GiftUi.ReceivedGift(args)
	local giftIndex = args.giftIndex
	local unit = giftScroll:FindFirstChild(giftIndex)
	-- local gift = GiftPresets.Gifts[giftIndex]
	-- unit:WaitForChild("icon").Image = gift.icons.claimed
	unit.timer.TextLabel.Text = "CLAIMED!"
	unit.timer.TextLabel.TextColor3 = Textures.ButtonColors.gray
	unClaimedGiftCount -= 1
	unclaimedGifts[giftIndex] = false

	if unClaimedGiftCount <= 0 then
		unclaimedFrame.Visible = false
	else
		unclaimedFrame.TextLabel.Text = unClaimedGiftCount
	end
end

function GiftUi.UpdateGiftRewards()
	local rebirth = ClientData:GetOneData(Keys.DataKey.rebirth)
	rebirth = rebirth == 0 and 1 or rebirth
	for i, gift in ipairs(GiftPresets.Gifts) do
		local unit = giftScroll:FindFirstChild(i)
		local item = gift.items[1]
		local count = item.count
		if table.find({ Keys.ItemType.wins, Keys.ItemType.power }, item.itemType) then
			count = count * rebirth * rebirth
		end
		unit.count.Text = "x" .. Util.FormatNumber(count)
	end
end

return GiftUi
