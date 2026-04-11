--[[
--Author: TimeM_chine
--Created Date: Tue Aug 15 2023
--Last Modified: 2024-05-25 2:18:46
--]]
---- services ----
local Players = game.Players
local Replicated = game.ReplicatedStorage
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- hide earlier

---- requires ----
local GameConfig = require(Replicated.configs.GameConfig)
local uiController = require(script.Parent.uiController)

---- variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

---- main ----
-- local vsLabel = PlayerGui.Main:FindFirstChild("vsLabel")
-- if vsLabel then
--     vsLabel.Text = "ver "..GameConfig.version
-- else
--     warn("vsLabel not found")
-- end

if UserInputService.TouchEnabled then
	for _, des in PlayerGui.Main:GetDescendants() do
		if des:IsA("UIStroke") then
			des.Thickness = 1
		end
	end

	PlayerGui.Main.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("UIStroke") then
			descendant.Thickness = 1
		end
	end)
end

if UserInputService.GamepadEnabled then
	for _, des in PlayerGui.Main:GetDescendants() do
		if des.Name == "gamepadKeyImg" then
			des.Visible = true
		end
	end

	PlayerGui.Main.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "gamepadKeyImg" then
			descendant.Visible = true
		end
	end)
end

local Buttons = PlayerGui.Main:FindFirstChild("Buttons")
local Frames = PlayerGui.Main:FindFirstChild("Frames")
for _, btn in ipairs(Buttons:GetDescendants()) do
	local frameName = string.match(btn.Name, "(%a+)Button")
	if frameName then
		uiController.SetButtonHoverAndClick(btn, function()
			uiController.OpenFrame(frameName)
		end)
	end
end

for _, frame in ipairs(Frames:GetChildren()) do
	local closeBtn = frame:FindFirstChild("X", true)
	if closeBtn then
		uiController.SetButtonHoverAndClick(closeBtn, function()
			uiController.CloseFrame(frame.Name)
		end)
	end
end

-- local Icon = require(Replicated.modules.Icon)
-- Icon.new()
-- 	:align("Right")
-- 	:setImage(15084827111)
-- 	:bindEvent("selected", function()
-- 		uiController.OpenFrame("Settings")
-- 	end)
-- 	:bindEvent("deselected", function()
-- 		uiController.CloseFrame("Settings")
-- 	end)

local s: boolean = false
repeat
	task.wait(1) -- we may never register if Roblox entirely disables the ability to remove the reset button, we don't want to lag out if this happens
	s = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
until s

local fakeGui = PlayerGui:WaitForChild("TouchGuiFake", 10)
if UserInputService.TouchEnabled and fakeGui then
	local touchGui = PlayerGui:FindFirstChild("TouchGui")
	touchGui.TouchControlFrame.JumpButton.Position = fakeGui.TouchControlFrame.JumpButton.Position
	touchGui.TouchControlFrame.JumpButton.Size = fakeGui.TouchControlFrame.JumpButton.Size
end
