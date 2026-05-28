local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Background = script.Parent:WaitForChild("Background")
local CoinStage = Background:WaitForChild("CoinStage")
local Coin = CoinStage:WaitForChild("Coin")
local CoinShadow = CoinStage:WaitForChild("CoinShadow")
local Progress = Background:WaitForChild("Progress")
local ProgressBar = Progress:WaitForChild("ProgressBar")
local ProgressLabel = Background:WaitForChild("ProgressLabel")
local SkipButton = Background:WaitForChild("Skip")

local Loader = {}

local isFinishing = false
local skipUnlocked = false
local animationConnection
local skipConnection
local progressConnection

function Loader.Start()
	Loader.ResetUi()
	local config = require(script.Parent.Config)
	local startTime = os.clock()
	local preloadComplete = false
	local displayedProgress = 0

	Loader.StartAnimation(config, startTime, function()
		local elapsed = os.clock() - startTime
		displayedProgress = Loader.GetDisplayProgress(elapsed, preloadComplete, config)
		Loader.SetProgress(displayedProgress)

		if displayedProgress >= config.SkipUnlockProgress then
			Loader.UnlockSkip()
		end

		if preloadComplete and elapsed >= config.MinimumDuration then
			Loader.Finish()
		elseif elapsed >= config.MaximumDuration then
			Loader.Finish()
		end
	end)

	skipConnection = SkipButton.MouseButton1Click:Connect(function()
		if not skipUnlocked or isFinishing then
			return
		end

		ProgressLabel.Text = "Entering..."
		Loader.Finish()
	end)

	local assets = {}
	local preloadBucket = Instance.new("Frame")
	preloadBucket.Name = "PreloadBucket"
	preloadBucket.Size = UDim2.fromScale(0, 0)
	preloadBucket.BackgroundTransparency = 1
	preloadBucket.Parent = Background

	for _, assetId in config.ImageAssets do
		local image = Instance.new("ImageLabel")
		image.Name = "Asset"
		image.Image = assetId
		image.Size = UDim2.fromScale(0, 0)
		image.BackgroundTransparency = 1
		image.Parent = preloadBucket
		table.insert(assets, image)
	end

	local total = #assets
	if total == 0 then
		preloadComplete = true
	end

	local function preloadCallback()
		if isFinishing then
			return
		end
	end

	local success = true
	local err = nil
	if total > 0 then
		success, err = pcall(function()
			ContentProvider:PreloadAsync(assets, preloadCallback)
		end)
	end

	preloadBucket:Destroy()

	if not success then
		warn(`LoadingScreen preload failed: {err}`)
	end

	preloadComplete = true
	if not isFinishing and os.clock() - startTime >= config.MinimumDuration then
		Loader.SetProgress(1)
		Loader.Finish()
	end
end

function Loader.ResetUi()
	isFinishing = false
	skipUnlocked = false

	Background.Visible = true
	Coin.Visible = true
	CoinShadow.Visible = true
	SkipButton.Visible = false
	SkipButton.Active = false
	SkipButton.Selectable = false
	SkipButton.AutoButtonColor = false
	ProgressBar.Size = UDim2.fromScale(0, 1)
	ProgressLabel.Text = "Loading 0%"

	for _, descendant in Background:GetDescendants() do
		if descendant:IsA("Frame") then
			descendant.BackgroundTransparency = descendant:GetAttribute("DefaultBackgroundTransparency") or descendant.BackgroundTransparency
		elseif descendant:IsA("UIStroke") then
			descendant.Transparency = descendant:GetAttribute("DefaultTransparency") or descendant.Transparency
		elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			descendant.TextTransparency = descendant:GetAttribute("DefaultTextTransparency") or descendant.TextTransparency
			descendant.BackgroundTransparency = descendant:GetAttribute("DefaultBackgroundTransparency") or descendant.BackgroundTransparency
		elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			descendant.ImageTransparency = descendant:GetAttribute("DefaultImageTransparency") or descendant.ImageTransparency
			descendant.BackgroundTransparency = descendant:GetAttribute("DefaultBackgroundTransparency") or descendant.BackgroundTransparency
		end
	end
end

function Loader.StartAnimation(config, startTime, updateProgress)
	local startPosition = Coin.Position
	local shadowStartSize = CoinShadow.Size

	animationConnection = RunService.RenderStepped:Connect(function()
		if isFinishing then
			return
		end

		local elapsed = os.clock()
		local phase = (elapsed % 1.45) / 1.45
		local lift = math.sin(phase * math.pi)
		local flip = math.sin(phase * math.pi * 8)
		local squash = 0.34 + math.abs(flip) * 0.66
		local shadowScale = 1 - lift * 0.38

		Coin.Position = UDim2.fromScale(startPosition.X.Scale, startPosition.Y.Scale - lift * 0.24)
		Coin.Size = UDim2.fromScale(0.16 * squash, 0.16)
		Coin.Rotation = (phase * 720) % 360
		CoinShadow.Size = UDim2.fromScale(shadowStartSize.X.Scale * shadowScale, shadowStartSize.Y.Scale * shadowScale)
		CoinShadow.ImageTransparency = 0.48 + lift * 0.34
	end)

	progressConnection = RunService.RenderStepped:Connect(function()
		if isFinishing then
			return
		end

		updateProgress(os.clock() - startTime, config)
	end)
end

function Loader.SetProgress(progress)
	local clampedProgress = math.clamp(progress, 0, 1)
	ProgressBar.Size = UDim2.fromScale(clampedProgress, 1)
	ProgressLabel.Text = `Loading {math.floor(clampedProgress * 100 + 0.5)}%`
end

function Loader.UnlockSkip()
	if skipUnlocked then
		return
	end

	skipUnlocked = true
	SkipButton.Visible = true
	SkipButton.Active = true
	SkipButton.Selectable = true
	SkipButton.AutoButtonColor = true
	SkipButton.BackgroundTransparency = 1
	SkipButton.TextTransparency = 1

	local tween = TweenService:Create(SkipButton, TweenInfo.new(0.25), {
		BackgroundTransparency = 0.1,
		TextTransparency = 0,
	})
	tween:Play()
end

function Loader.Finish()
	if isFinishing then
		return
	end

	isFinishing = true
	SkipButton.Active = false
	SkipButton.Selectable = false
	SkipButton.AutoButtonColor = false

	if skipConnection then
		skipConnection:Disconnect()
		skipConnection = nil
	end

	if animationConnection then
		animationConnection:Disconnect()
		animationConnection = nil
	end

	if progressConnection then
		progressConnection:Disconnect()
		progressConnection = nil
	end

	Loader.SetProgress(1)

	local fadeTweens = {}
	for _, descendant in Background:GetDescendants() do
		local tween = Loader.CreateFadeTween(descendant)
		if tween then
			table.insert(fadeTweens, tween)
			tween:Play()
		end
	end

	local backgroundTween = TweenService:Create(Background, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	backgroundTween:Play()
	table.insert(fadeTweens, backgroundTween)

	local lastTween = fadeTweens[#fadeTweens]
	if lastTween then
		lastTween.Completed:Wait()
	end

	script.Parent:Destroy()
end

function Loader.CreateFadeTween(instance)
	local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if instance:IsA("TextButton") then
		return TweenService:Create(instance, tweenInfo, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
	elseif instance:IsA("ImageButton") then
		return TweenService:Create(instance, tweenInfo, {
			BackgroundTransparency = 1,
			ImageTransparency = 1,
		})
	elseif instance:IsA("Frame") then
		return TweenService:Create(instance, tweenInfo, {
			BackgroundTransparency = 1,
		})
	elseif instance:IsA("UIStroke") then
		return TweenService:Create(instance, tweenInfo, {
			Transparency = 1,
		})
	elseif instance:IsA("TextLabel") then
		return TweenService:Create(instance, tweenInfo, {
			TextTransparency = 1,
		})
	elseif instance:IsA("ImageLabel") then
		return TweenService:Create(instance, tweenInfo, {
			ImageTransparency = 1,
			BackgroundTransparency = 1,
		})
	end

	return nil
end

function Loader.GetDisplayProgress(elapsed, preloadComplete, config)
	if preloadComplete and elapsed >= config.MinimumDuration then
		return 1
	end

	if elapsed >= config.MaximumDuration then
		return 1
	end

	local durationProgress = math.clamp(elapsed / config.MaximumDuration, 0, 1)
	local easedProgress = 1 - (1 - durationProgress) ^ 2
	local cappedProgress = math.min(easedProgress, 0.95)

	if preloadComplete then
		local minDurationProgress = math.clamp(elapsed / config.MinimumDuration, 0, 1)
		return math.max(cappedProgress, math.min(0.98, minDurationProgress * 0.98))
	end

	return cappedProgress
end

return Loader
