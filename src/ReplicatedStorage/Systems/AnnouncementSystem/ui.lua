local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local uiController = require(Main:WaitForChild("uiController"))

local AnnouncementUi = {}

local initialized = false
local bannerFrame
local bannerToken = 0

local function ensureBanner()
	if bannerFrame then
		return bannerFrame
	end

	bannerFrame = Instance.new("Frame")
	bannerFrame.Name = "StreakAnnouncementBanner"
	bannerFrame.AnchorPoint = Vector2.new(0.5, 0)
	bannerFrame.BackgroundColor3 = Color3.fromRGB(19, 24, 31)
	bannerFrame.BackgroundTransparency = 0.08
	bannerFrame.BorderSizePixel = 0
	bannerFrame.Position = UDim2.new(0.5, 0, 0, 26)
	bannerFrame.Size = UDim2.fromOffset(560, 88)
	bannerFrame.Visible = false
	bannerFrame.Parent = Elements

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = bannerFrame

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.fromRGB(255, 220, 120)
	stroke.Thickness = 1.6
	stroke.Transparency = 0.22
	stroke.Parent = bannerFrame

	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = Color3.fromRGB(255, 220, 120)
	glow.BackgroundTransparency = 0.82
	glow.BorderSizePixel = 0
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.new(1, 24, 1, 24)
	glow.ZIndex = bannerFrame.ZIndex - 1
	glow.Parent = bannerFrame

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 22)
	glowCorner.Parent = glow

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Name = "TierLabel"
	tierLabel.BackgroundTransparency = 1
	tierLabel.Font = Enum.Font.GothamBlack
	tierLabel.Text = "STREAK"
	tierLabel.TextColor3 = Color3.fromRGB(255, 230, 180)
	tierLabel.TextSize = 16
	tierLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierLabel.Position = UDim2.fromOffset(22, 14)
	tierLabel.Size = UDim2.new(1, -44, 0, 18)
	tierLabel.Parent = bannerFrame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = ""
	textLabel.TextColor3 = Color3.fromRGB(244, 247, 250)
	textLabel.TextSize = 26
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Position = UDim2.fromOffset(22, 32)
	textLabel.Size = UDim2.new(1, -44, 0, 28)
	textLabel.Parent = bannerFrame

	local seatLabel = Instance.new("TextLabel")
	seatLabel.Name = "SeatLabel"
	seatLabel.BackgroundTransparency = 1
	seatLabel.Font = Enum.Font.GothamSemibold
	seatLabel.Text = ""
	seatLabel.TextColor3 = Color3.fromRGB(194, 204, 219)
	seatLabel.TextSize = 14
	seatLabel.TextXAlignment = Enum.TextXAlignment.Left
	seatLabel.Position = UDim2.fromOffset(22, 62)
	seatLabel.Size = UDim2.new(1, -44, 0, 16)
	seatLabel.Parent = bannerFrame

	return bannerFrame
end

local function playAnnouncementSound(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	local sound = sfxGroup and sfxGroup:FindFirstChild(soundName)
	if not sound or not sound:IsA("Sound") then
		return
	end

	sound:Play()
end

function AnnouncementUi.Init()
	if initialized then
		return
	end

	initialized = true
	ensureBanner()
end

function AnnouncementUi.PlayAnnouncement(args)
	AnnouncementUi.Init()

	local banner = ensureBanner()
	local stroke = banner:FindFirstChild("Stroke")
	local glow = banner:FindFirstChild("Glow")
	local tierLabel = banner:FindFirstChild("TierLabel")
	local textLabel = banner:FindFirstChild("TextLabel")
	local seatLabel = banner:FindFirstChild("SeatLabel")
	if not stroke or not glow or not tierLabel or not textLabel or not seatLabel then
		return
	end

	bannerToken += 1
	local token = bannerToken
	local accent = args.strokeColor or args.textColor or Color3.fromRGB(255, 220, 120)
	local duration = args.duration or 2.4
	local tierText = args.bannerText or `Streak {args.streak or "?"}`

	stroke.Color = accent
	glow.BackgroundColor3 = accent
	tierLabel.Text = `${tierText}  x{args.streak or "?"}`
	tierLabel.TextColor3 = accent
	textLabel.Text = args.text or "Heads streak!"
	textLabel.TextColor3 = args.textColor or Color3.fromRGB(244, 247, 250)

	if args.isJackpot then
		seatLabel.Text = `Seat {args.seatId or "--"} is popping off. Entire table spotlight.`
	else
		seatLabel.Text = `Seat {args.seatId or "--"} is building heat.`
	end

	banner.Visible = true
	banner.BackgroundTransparency = 0.08
	textLabel.TextTransparency = 0
	seatLabel.TextTransparency = 0
	tierLabel.TextTransparency = 0
	glow.BackgroundTransparency = args.isJackpot and 0.68 or 0.82
	banner.Position = UDim2.new(0.5, 0, 0, 18)

	TweenService:Create(
		banner,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 26) }
	):Play()

	uiController.SetNotification({
		text = args.text,
		lastTime = math.min(duration, 2.8),
		textColor = args.textColor,
	})
	playAnnouncementSound(args.soundName)

	task.delay(duration, function()
		if bannerToken ~= token then
			return
		end

		local tween = TweenService:Create(
			banner,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 10),
			}
		)
		local textTween = TweenService:Create(
			textLabel,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)
		local seatTween = TweenService:Create(
			seatLabel,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)
		local tierTween = TweenService:Create(
			tierLabel,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)

		tween:Play()
		textTween:Play()
		seatTween:Play()
		tierTween:Play()
		tween.Completed:Once(function()
			if bannerToken ~= token then
				return
			end
			banner.Visible = false
		end)
	end)
end

return AnnouncementUi
