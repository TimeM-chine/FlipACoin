local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))

local AnnouncementUi = {}

local initialized = false

function AnnouncementUi.Init()
	if initialized then
		return
	end

	initialized = true
end

function AnnouncementUi.PlayAnnouncement(args)
	AnnouncementUi.Init()

	local duration = args.duration or 2.4

	uiController.SetNotification({
		text = args.text,
		lastTime = math.min(duration, 2.8),
		textColor = args.textColor,
	})
end

return AnnouncementUi
