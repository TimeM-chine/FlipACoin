---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Replicated = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local GroupService = game:GetService("GroupService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local BuffPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local Buffs = Elements:WaitForChild("Buffs")
local friendCard = Buffs:WaitForChild("friend")
local groupCard = Buffs:WaitForChild("group")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----

local BuffUi = {}

function BuffUi.Init()
	InitFriendBuff()
	InitPremiumBuff()
	InitPlayTimeBuff()
	InitWeekendBuff()
	InitGroupBuff()
end

function BuffUi.AddBuff(args)
	local buffName = args.buffName
	local startTime = args.startTime
	local duration = args.duration

	local buffCard = Buffs:FindFirstChild(buffName)
	if not buffCard then
		buffCard = Util.Clone(Buffs.Template, Buffs, function(unit)
			unit.Visible = true
			unit.ImageLabel.Image = Textures.Buffs[buffName].icon
			unit.Name = buffName
		end)
	end

	uiController.AddTimerLabel({
		textLabel = buffCard.Timer,
		startTime = startTime,
		duration = duration,
		callback = function()
			buffCard:Destroy()
		end,
	})

	uiController.SetOneLineTip(buffCard, {
		text = BuffPresets.Buffs[buffName].tip,
	})
end

function BuffUi.UpdateFriendBuff(args)
	local friendCount = args.friendCount
	friendCard.Boost.Text = `+{BuffPresets.Buffs.friend.boost * 100 * friendCount}%`
end

function InitFriendBuff()
	uiController.SetButtonHoverAndClick(friendCard, function()
		SocialService:PromptGameInvite(LocalPlayer)
	end)

	uiController.SetOneLineTip(friendCard, {
		text = "Cash boost + 10% for each friend",
	})
end

function InitPremiumBuff()
	local premiumCard = Buffs:WaitForChild("premium")
	uiController.SetButtonHoverAndClick(premiumCard, function()
		if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
			premiumCard.Boost.Text = "+10%"
		else
			MarketplaceService:PromptPremiumPurchase(LocalPlayer)
		end
	end)

	uiController.SetOneLineTip(premiumCard, {
		text = "Cash boost +20%, Walking Speed +10%",
	})
end

function InitPlayTimeBuff()
	local playTimeCard = Buffs:WaitForChild("playTime")

	local playTimer = 0
	local tipFrame = uiController.SetOneLineTip(playTimeCard, {
		text = `+1% luck boost after {GameConfig.OneMinute - playTimer % GameConfig.OneMinute}s`,
	})

	ScheduleModule.AddSchedule(1, function()
		playTimer += 1
		tipFrame.TextLabel.Text = `+1% luck boost after {GameConfig.OneMinute - playTimer % GameConfig.OneMinute}s`
		playTimeCard.Boost.Text = `+{math.floor(playTimer / GameConfig.OneMinute)}%`
	end)
end

function InitWeekendBuff()
	local weekendCard = Buffs:WaitForChild("weekend")
	local remainTime = Util.WeekendToMondayTime()

	if remainTime > 0 then
		weekendCard.Visible = true
		uiController.AddTimerLabel({
			textLabel = weekendCard.CountDown,
			startTime = os.time(),
			duration = remainTime,
			callback = function()
				weekendCard.Visible = false
			end,
		})
		uiController.SetOneLineTip(weekendCard, {
			text = "Double lucky during the weekend",
		})
	else
		weekendCard.Visible = false
	end
end

function InitGroupBuff()
	if LocalPlayer:IsInGroupAsync(GameConfig.GroupId) then
		groupCard.Boost.Text = "+10%"
	else
		groupCard.Boost.Text = "+0%"
		uiController.SetButtonHoverAndClick(groupCard, function()
			local success, result = pcall(function()
				return GroupService:PromptJoinAsync(GameConfig.GroupId)
			end)

			if success then
				if result == Enum.GroupMembershipStatus.Joined then
					groupCard.Boost.Text = "+10%"
					uiController.SetButtonHoverAndClick(groupCard, function() end)
				elseif result == Enum.GroupMembershipStatus.JoinRequestPending then
					print("Join request sent")
				elseif result == Enum.GroupMembershipStatus.AlreadyMember then
					groupCard.Boost.Text = "+10%"
					uiController.SetButtonHoverAndClick(groupCard, function() end)
				else
					print("Did not join or not eligible")
				end
			else
				warn("Prompt failed:", result)
			end
		end)
	end
	uiController.SetOneLineTip(groupCard, {
		text = BuffPresets.Buffs.group.tip,
	})
end

return BuffUi
