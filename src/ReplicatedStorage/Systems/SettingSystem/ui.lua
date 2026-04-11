---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local Presets = require(script.Parent.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local Icon = require(Replicated.Packages.topbarplus)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local SettingFrame = Frames:WaitForChild("Settings")
local settingScroll = SettingFrame:WaitForChild("ScrollingFrame")

---- logic variables ----
local menu = { "sfx", "bgm" }

local SettingUi = {}

function SettingUi.Init()
	local settingsIcon: any = Icon.new()
		:align("Right")
		:setName("Settings")
		:setImage("http://www.roblox.com/asset/?id=85613740372383", "Selected")
		:setImage(15084827111, "Deselected")
		:autoDeselect(false)
	settingsIcon.toggled:Connect(function(): ()
		if not GuiService.MenuIsOpen then
			if SettingFrame.Visible then
				uiController.CloseFrame("Settings")
			else
				uiController.OpenFrame("Settings")
			end
		end
	end)

	for _, name in menu do
		local frame = settingScroll:FindFirstChild(name)
		if not frame then
			continue
		end
		local switch = frame:FindFirstChild("switch")
		local value = ClientData:GetOneData(Keys.DataKey.settingsData)[name]
		if value == 1 or value == true then
			frame.Green.Visible = true
			frame.Red.Visible = false
		else
			frame.Green.Visible = false
			frame.Red.Visible = true
		end

		SettingUi.ChangeSetting({
			settingName = name,
			value = value,
		})

		uiController.SetButtonHoverAndClick(switch, function()
			local oldValue = ClientData:GetOneData(Keys.DataKey.settingsData)[name]
			local newValue
			if oldValue == 0 then
				newValue = 1
			elseif oldValue == 1 then
				newValue = 0
			elseif oldValue == false then
				newValue = true
			elseif oldValue == true then
				newValue = false
			end
			SystemMgr.systems.SettingSystem.Server:ChangeSetting({
				settingName = name,
				value = newValue,
			})

			if newValue == 1 or newValue == true then
				frame.Green.Visible = true
				frame.Red.Visible = false
			else
				frame.Green.Visible = false
				frame.Red.Visible = true
			end
		end)
	end

	-- local autoHatchFrame = settingScroll:FindFirstChild("autoHatchNum")
	-- local autoHatchValue = ClientData:GetOneData(Keys.DataKey.settingsData)["autoHatchNum"]
	-- for _, i in ipairs({ 1, 3, 8 }) do
	-- 	local button = autoHatchFrame.num:FindFirstChild("x" .. i)
	-- 	if i == autoHatchValue then
	-- 		button.BackgroundColor3 = Textures.ButtonColors.green
	-- 		clientAutoHatchNum = i
	-- 	else
	-- 		button.BackgroundColor3 = Textures.ButtonColors.red
	-- 	end

	-- 	uiController.SetButtonHoverAndClick(button, function()
	-- 		if i > 1 then
	-- 			local gamePasses = ClientData:GetOneData(Keys.DataKey.gamePasses)
	-- 			if not gamePasses["egg" .. i] then
	-- 				MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses["egg" .. i].gamePassId)
	-- 				return
	-- 			end
	-- 		end
	-- 		SystemMgr.systems.SettingSystem.Server:ChangeSetting({
	-- 			settingName = "autoHatchNum",
	-- 			value = i,
	-- 		})

	-- 		if clientAutoHatchNum then
	-- 			autoHatchFrame.num:FindFirstChild("x" .. clientAutoHatchNum).BackgroundColor3 =
	-- 				Textures.ButtonColors.red
	-- 		end

	-- 		button.BackgroundColor3 = Textures.ButtonColors.green
	-- 		clientAutoHatchNum = i
	-- 	end)
	-- end

	-- uiController.SetButtonHoverAndClick(SettingFrame:WaitForChild("Update"), function()
	-- 	uiController.OpenFrame("UpdateLog")
	-- end)

	-- InitUpdateLog()

	if SoundService:FindFirstChild("bgm") then
		SoundService.bgm:Play()
	end
end

function SettingUi.ChangeSetting(args)
	local settingName = args.settingName
	local value = args.value

	if settingName == "sfx" then
		SystemMgr.systems.MusicSystem:SetSfxVolume(value)
	elseif settingName == "bgm" then
		SystemMgr.systems.MusicSystem:SetBgmVolume(value)
	elseif settingName == "showMyPets" or settingName == "showOtherPets" then
		SystemMgr.systems.PetSystem:ChangeVisibleSetting(settingName, value)
	elseif settingName == "weatherSfx" then
		SystemMgr.systems.MusicSystem:SetWeatherSfxVolume(value)
	end
end

function InitUpdateLog()
	-- update log
	local UpdateLog = Frames:WaitForChild("UpdateLog")
	local UpdateLogFrame = UpdateLog:WaitForChild("UpdateLogFrame")
	local Content = UpdateLogFrame:WaitForChild("Frame"):WaitForChild("Content")
	local Template = Content:WaitForChild("Template")

	-- delete all log
	for _, log in ipairs(Content:GetChildren()) do
		if log.Name == "Log" then
			log:Destroy()
		end
	end
	for i, update in ipairs(GameConfig.UpdateLog) do
		local log = Template:Clone()
		log.Name = "Log"
		log:WaitForChild("Text").Text = update
		log.LayoutOrder = i
		log.Visible = true
		log.Parent = Content
	end

	Content:WaitForChild("Version").Text = "v" .. GameConfig.Version
end

return SettingUi
