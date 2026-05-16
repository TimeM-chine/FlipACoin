local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))

local AnnouncementUi = {}

local initialized = false

local function playAnnouncementSound(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	local sound = sfxGroup and sfxGroup:FindFirstChild(soundName)
	if not sound or not sound:IsA("Sound") or sound.SoundId == "" then
		return
	end

	sound:Play()
end

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
	playAnnouncementSound(args.soundName)
end

return AnnouncementUi
