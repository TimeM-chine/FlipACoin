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
local notifications = PlayerGui:FindFirstChild("Notifications")
if notifications then
	local tipFrame = notifications:FindFirstChild("TipFrame")
	if tipFrame and tipFrame:IsA("GuiObject") then
		tipFrame.Visible = false
	end
end

local noUseFrames = PlayerGui.Main.Frames:FindFirstChild("noUse")
if noUseFrames then
	for _, des in ipairs(noUseFrames:GetDescendants()) do
		if des:IsA("GuiObject") then
			des.Interactable = false
		end
	end

	for _, frame in ipairs(noUseFrames:GetChildren()) do
		if frame:IsA("GuiObject") then
			frame.Visible = false
		end
	end
end

local legacyUiNames = {
	Buttons = { "TopBar", "RightBottom", "InventoryButton" },
	Elements = { "cash", "candy" },
}
for containerName, childNames in pairs(legacyUiNames) do
	local container = PlayerGui.Main:FindFirstChild(containerName)
	if container then
		for _, childName in ipairs(childNames) do
			local child = container:FindFirstChild(childName)
			if child and child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
end

-- local vsLabel = PlayerGui.Main:FindFirstChild("vsLabel")
-- if vsLabel then
--     vsLabel.Text = "ver "..GameConfig.version
-- else
--     warn("vsLabel not found")
-- end

-- if UserInputService.TouchEnabled then
-- 	for _, des in PlayerGui.Main:GetDescendants() do
-- 		if des:IsA("UIStroke") then
-- 			des.Thickness = 1
-- 		end
-- 	end

-- 	PlayerGui.Main.DescendantAdded:Connect(function(descendant)
-- 		if descendant:IsA("UIStroke") then
-- 			descendant.Thickness = 1
-- 		end
-- 	end)
-- end

if UserInputService.GamepadEnabled and not UserInputService.TouchEnabled then
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

if UserInputService.TouchEnabled then
	local touchGui = PlayerGui:FindFirstChild("TouchGui")
	if touchGui and touchGui:IsA("ScreenGui") then
		touchGui.Enabled = false
	end

	PlayerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" and child:IsA("ScreenGui") then
			child.Enabled = false
		end
	end)
end
