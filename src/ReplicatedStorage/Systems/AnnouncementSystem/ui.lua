local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))

local AnnouncementUi = {}

local initialized = false
local announcementQueue = {}
local activeAnnouncement
local announcementToken = 0

function AnnouncementUi.Init()
	if initialized then
		return
	end

	initialized = true
end

function AnnouncementUi.PlayAnnouncement(args)
	AnnouncementUi.Init()
	local priority = AnnouncementUi.GetAnnouncementPriority(args)
	if uiController.IsGrowthFrameOpen() and priority < 3 then
		return
	end

	local entry = {
		args = args,
		priority = priority,
	}
	if activeAnnouncement and priority > activeAnnouncement.priority then
		announcementToken += 1
		activeAnnouncement = nil
		table.insert(announcementQueue, 1, entry)
	else
		table.insert(announcementQueue, entry)
		table.sort(announcementQueue, function(a, b)
			return a.priority > b.priority
		end)
	end
	AnnouncementUi.PlayNextAnnouncement()
end

function AnnouncementUi.PlayNextAnnouncement()
	if activeAnnouncement or #announcementQueue <= 0 then
		return
	end

	local entry = table.remove(announcementQueue, 1)
	activeAnnouncement = entry
	announcementToken += 1
	local token = announcementToken
	local args = entry.args
	local duration = math.min(args.duration or 2.4, 2.4)

	uiController.SetNotification({
		text = args.text,
		lastTime = duration,
		textColor = args.textColor,
		channel = "tableAnnouncement",
		priority = entry.priority,
	})

	task.delay(duration + 0.08, function()
		if token ~= announcementToken then
			AnnouncementUi.PlayNextAnnouncement()
			return
		end
		activeAnnouncement = nil
		AnnouncementUi.PlayNextAnnouncement()
	end)
end

function AnnouncementUi.GetAnnouncementPriority(args)
	if args.kind == "comboMilestone" and (args.comboTier or 0) >= 5 then
		return 4
	end
	if args.kind == "bestStreak" or (args.comboTier or 0) >= 4 then
		return 3
	end
	if args.kind == "streakMilestone" and (args.streak or 0) >= 10 then
		return 2
	end
	return 1
end

return AnnouncementUi
