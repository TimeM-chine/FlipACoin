local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Background = script.Parent:WaitForChild("Background")
Background.Visible = true
-- local title = Background:WaitForChild("title")

-- local alphabet = "abcdefghijklmnopqrstuvwxyz"
-- local letters = {}
-- local finalLetters = { "R", "O", "B", "S", "T", "A", "R" }
-- for i = 3, 7 do
-- 	title:WaitForChild("t" .. i).Visible = false
-- 	table.insert(letters, title:WaitForChild("t" .. i):WaitForChild("t" .. i))
-- end

-- local robloxIcon = title:WaitForChild("t2"):WaitForChild("t2")

-- -- jump the roblox icon
-- local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0)

-- local tween = TweenService:Create(robloxIcon, tweenInfo, { Position = UDim2.fromScale(0.5, 0) })
-- tween:Play()
-- tween.Completed:Connect(function()
-- 	tween:Play()
-- end)

-- RunService.Heartbeat:Connect(function()
-- 	robloxIcon.Rotation = (robloxIcon.Rotation + 3) % 360
-- 	for i = 1, #letters do
-- 		if letters[i]:GetAttribute("StopRandom") then
-- 			continue
-- 		end
-- 		local num = math.random(1, #alphabet)
-- 		letters[i].Text = alphabet:sub(num, num)
-- 		letters[i].Position = UDim2.fromScale(0.5, math.random(3, 4) / 10)
-- 	end
-- end)

-- for i = 3, 7 do
-- 	local card = title:WaitForChild("t" .. i)
-- 	card.Visible = true
-- 	local letter = card:WaitForChild("t" .. i)
-- 	task.wait(0.7)
-- 	letter:SetAttribute("StopRandom", true)
-- 	letter.Text = finalLetters[i]
-- 	letter.Position = UDim2.fromScale(0.5, 0.5)
-- end

-- local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
-- local CanClose = PlayerGui:GetAttribute("CanClose")
-- if not CanClose then
-- 	task.wait(3)
-- end

local t1 = Background:WaitForChild("t1")
local ti = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true)
local tween = TweenService:Create(t1, ti, { Position = UDim2.fromScale(0.5, 0.4) })
tween:Play()

local bg = Background:WaitForChild("bg")
local ti2 = TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true)
local tween2 = TweenService:Create(bg, ti2, { Position = UDim2.fromScale(0.1, 0.1) })
tween2:Play()

task.wait(6)

local tweenInfo2 = TweenInfo.new(1.5)
for _, des in script.Parent:GetDescendants() do
	local tween2
	if des:IsA("Frame") or des:IsA("UIStroke") then
		tween2 = TweenService:Create(des, tweenInfo2, { Transparency = 1 })
	elseif des:IsA("TextLabel") or des:IsA("TextButton") then
		tween2 = TweenService:Create(des, tweenInfo2, { TextTransparency = 1 })
	elseif des:IsA("ImageLabel") or des:IsA("ImageButton") then
		tween2 = TweenService:Create(des, tweenInfo2, { ImageTransparency = 1 })
	end
	if tween2 then
		tween2:Play()
	end
end
-- local LoadingScreen = script.Parent.Parent:WaitForChild("LoadingScreen")
-- local Loader = require(LoadingScreen:WaitForChild("Loader"))
-- LoadingScreen:WaitForChild("Background").Visible = true

-- Loader.PreStart()
-- task.wait(1.5)

-- if LoadingScreen.Parent then
-- 	Loader.Start()
-- end
-- script.Parent:Destroy()
