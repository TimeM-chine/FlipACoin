local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

local Camera = workspace.CurrentCamera
local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
Main.Enabled = false

local config = require(script.Parent.Config)
local GameConfig = require(Replicated.configs.GameConfig)
local BackGround = script.Parent.Background
local PlayBtn: TextButton = BackGround:WaitForChild("Menu"):WaitForChild("Play")

local Loader = {}

function Loader.PreStart()
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = workspace:WaitForChild("CameraPart").CFrame
	HumanoidRootPart.Anchored = true
	PlayBtn.MouseButton1Click:Connect(function()
		Loader.Complete()
	end)

	local updateLog = BackGround:WaitForChild("Menu"):WaitForChild("UpdateLog")
	local template = updateLog:WaitForChild("Template")
	template.Visible = false
	for i, log in GameConfig.UpdateLog do
		local logText = template:Clone()
		logText.Visible = true
		logText.Text = log
		logText.Parent = updateLog
	end
end

function Loader.Start()
	Loader.PreloadSource()
end

--function Loader.Skip()
--	BackGround:WaitForChild("Skip").Visible = false
--	BackGround:TweenPosition(UDim2.fromScale(0.5, 2), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 2)
--	task.delay(2, function()
--		script.Parent:Destroy()
--	end)
--end

function Loader.Complete()
	local ti = TweenInfo.new(2)
	local tween = TweenService:Create(Camera, ti, {
		CFrame = Character:WaitForChild("Head").CFrame,
	})
	tween:Play()
	script.Parent:Destroy()
	tween.Completed:Wait()
	Camera.CameraType = Enum.CameraType.Custom
	HumanoidRootPart.Anchored = false
	Main.Enabled = true

	-- BackGround:WaitForChild("Skip").Visible = false
	-- BackGround:TweenPosition(UDim2.fromScale(0.5, 2), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 2)
	--task.delay(2, function()
	--	script.Parent:Destroy()
	--end)
end

function Loader.TweenIconHolder()
	local iconHolder = BackGround:WaitForChild("IconHolder")
	local ti = TweenInfo.new(2)
	local nowPosition = iconHolder.Position

	task.spawn(function()
		while true do
			local tween = TweenService:Create(BackGround.IconHolder, ti, {
				Position = UDim2.new(
					nowPosition.X.Scale,
					nowPosition.X.Offset,
					nowPosition.Y.Scale,
					nowPosition.Y.Offset - math.random(50, 100)
				),
			})
			tween:Play()

			tween.Completed:Wait()

			local tween2 = TweenService:Create(BackGround.IconHolder, ti, {
				Position = UDim2.new(
					nowPosition.X.Scale,
					nowPosition.X.Offset,
					nowPosition.Y.Scale,
					nowPosition.Y.Offset + math.random(50, 100)
				),
			})
			tween2:Play()
			tween2.Completed:Wait()
		end
	end)
end

function Loader.SetIcon()
	if config.gameIcon and config.gameIcon ~= "" then
		BackGround:WaitForChild("IconHolder"):WaitForChild("Icon").Image = config.gameIcon
	end
end

function Loader.PreloadSource()
	local assets = {}
	local total = 0
	local loaded = 0

	for instanceType, idList in config.ResourceList do
		for _, id in idList do
			local ins = Instance.new(instanceType)
			if instanceType == "Sound" then
				ins.SoundId = id
			elseif instanceType == "Animation" then
				ins.AnimationId = id
			elseif instanceType == "Decal" then
				ins.Texture = id
			end

			table.insert(assets, ins)
			total += 1
		end
	end

	-- if total == 0 then
	-- 	Loader.Complete()
	-- 	return
	-- end

	local progressBar = BackGround:WaitForChild("Progress"):WaitForChild("ProgressBar")
	-- local percent = BackGround:WaitForChild("Progress"):WaitForChild("Percentage")
	-- This will be hit as each asset resolves
	local callback = function(assetId, assetFetchStatus)
		--print("PreloadAsync() resolved asset ID:", assetId)
		--print("PreloadAsync() final AssetFetchStatus:", assetFetchStatus)
		loaded += 1

		-- if loaded >= total * 0.5 then
		-- 	BackGround:WaitForChild("Skip").Visible = true
		-- end

		-- if loaded == total then
		-- 	Loader.Complete()
		-- 	BackGround:WaitForChild("Skip").Visible = false
		-- end

		progressBar.Size = UDim2.new(1, 0, loaded / total, 0)
		-- percent.Text = ("%.0f"):format(loaded / total * 100) .. "%"
	end

	-- Preload the content and time it
	-- local startTime = os.clock()
	ContentProvider:PreloadAsync(assets, callback)
	-- local deltaTime = os.clock() - startTime
	-- print(("Preloading complete, took %.2f seconds"):format(deltaTime))
end

return Loader
