local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local RebirthPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local Icon = require(Replicated.Packages.topbarplus)

local dataKey = Keys.DataKey

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Buttons = Main:WaitForChild("Buttons")
local Frames = Main:WaitForChild("Frames")
local uiController = require(Main:WaitForChild("uiController"))

local CoinFlipMenu = Buttons:WaitForChild("CoinFlipMenu")
local RebirthFrame = Frames:WaitForChild("Rebirth")
local RebirthSummary = RebirthFrame:WaitForChild("Body"):WaitForChild("Summary")
local RebirthPerks = RebirthFrame.Body:WaitForChild("Perks")
local RebirthPointGain = RebirthSummary:WaitForChild("PointGain")
local RebirthResetPreview = RebirthSummary:WaitForChild("ResetPreview")
local RebirthConfirmButton = RebirthSummary:WaitForChild("ConfirmButton")
local RebirthKeepRunButton = RebirthSummary:WaitForChild("KeepRunButton")
local RebirthPerkCards = {
	RebirthPerks:WaitForChild("Perk1"),
	RebirthPerks:WaitForChild("Perk2"),
	RebirthPerks:WaitForChild("Perk3"),
	RebirthPerks:WaitForChild("Perk4"),
}

local RebirthUi = {}
local initialized = false
local currentCash = 0
local currentRebirthState = {}
local suppressTopbarToggle = false
local rebirthTopbarIcon

local function setButtonText(button, text, isEnabled)
	button.Text = text
	button.AutoButtonColor = isEnabled
	button.Active = isEnabled
end

local function playSfx(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return
	end

	SystemMgr.systems.MusicSystem:PlayLocalSfx({
		musicName = soundName,
	})
end

local function updateRebirthPanel()
	local pointGain = currentRebirthState.pointGain or 0
	local rebirthPoints = currentRebirthState.rebirthPoints or currentRebirthState.fateShards or 0
	local minCash = currentRebirthState.rebirthMinCash or RebirthPresets.FlipACoin.Rebirth.MinCash
	local cashAfterReset = currentRebirthState.rebirthCashAfterReset or RebirthPresets.FlipACoin.Rebirth.CashAfterReset
	local canRebirth = currentRebirthState.canRebirth == true

	RebirthPointGain.Label.Text = "Rebirth Points"
	RebirthPointGain.Value.Text = `+{pointGain} now | {rebirthPoints} banked`
	RebirthResetPreview.Title.Text = "Reset preview"
	RebirthResetPreview.Desc.Text =
		`Cash resets to $ {Util.FormatNumber(cashAfterReset, true)} and run upgrades restart from permanent perks. Need $ {Util.FormatNumber(
			minCash,
			true
		)} minimum.`
	setButtonText(
		RebirthConfirmButton,
		canRebirth and "Rebirth" or `Need $ {Util.FormatNumber(minCash, true)}`,
		canRebirth
	)
	RebirthKeepRunButton.Text = "Keep Run"

	local upgradesByKey = {}
	for _, entry in ipairs(currentRebirthState.rebirthUpgrades or {}) do
		upgradesByKey[entry.key] = entry
	end

	for index, upgradeKey in ipairs(RebirthPresets.FlipACoin.UpgradeOrder) do
		local card = RebirthPerkCards[index]
		local config = RebirthPresets.GetFlipACoinUpgradeConfig(upgradeKey)
		local entry = upgradesByKey[upgradeKey]
			or {
				level = 0,
				maxLevel = config.maxLevel,
				cost = RebirthPresets.GetFlipACoinUpgradeCost(upgradeKey, 0),
			}
		card.Title.Text = config.displayName
		card.Desc.Text = config.description
		card.Chip.Text = `Lv.{entry.level}/{entry.maxLevel}`
		if entry.cost then
			setButtonText(card.UpgradeButton, `{entry.cost} RP`, rebirthPoints >= entry.cost)
		else
			setButtonText(card.UpgradeButton, "MAX", false)
		end
	end
end

local function syncTopbarIcon(icon, frame)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		suppressTopbarToggle = true
		if frame.Visible then
			icon:select()
		else
			icon:deselect()
		end
		suppressTopbarToggle = false
	end)
end

local function bindTopbarIcon()
	rebirthTopbarIcon = Icon.new()
		:align("Left")
		:setName("Rebirth")
		:setLabel("R")
		:setOrder(19)
		:setCaption("Rebirth")
		:autoDeselect(false)

	rebirthTopbarIcon.toggled:Connect(function(isSelected): ()
		if suppressTopbarToggle or GuiService.MenuIsOpen then
			return
		end
		if isSelected then
			updateRebirthPanel()
			uiController.OpenFrame("Rebirth")
		else
			uiController.CloseFrame("Rebirth")
		end
	end)
	syncTopbarIcon(rebirthTopbarIcon, RebirthFrame)
end

local function bindButtons()
	uiController.SetButtonHoverAndClick(CoinFlipMenu.RebirthButton, function()
		updateRebirthPanel()
		uiController.OpenFrame("Rebirth")
	end)

	uiController.SetButtonHoverAndClick(RebirthFrame.X, function()
		uiController.CloseFrame("Rebirth")
	end)
	uiController.SetButtonHoverAndClick(RebirthConfirmButton, function()
		SystemMgr.systems.RebirthSystem.Server:RequestRebirth()
	end)
	uiController.SetButtonHoverAndClick(RebirthKeepRunButton, function()
		uiController.CloseFrame("Rebirth")
	end)

	for index, upgradeKey in ipairs(RebirthPresets.FlipACoin.UpgradeOrder) do
		local boundUpgradeKey = upgradeKey
		uiController.SetButtonHoverAndClick(RebirthPerkCards[index].UpgradeButton, function()
			SystemMgr.systems.RebirthSystem.Server:RequestRebirthUpgrade({
				upgradeKey = boundUpgradeKey,
			})
		end)
	end
end

function RebirthUi.Init()
	if initialized then
		return
	end
	initialized = true

	RebirthFrame.Visible = false
	currentCash = ClientData:GetOneData(dataKey.wins) or 0
	currentRebirthState = ClientData:GetOneData("rebirthState") or currentRebirthState
	bindButtons()
	bindTopbarIcon()
	updateRebirthPanel()
end

function RebirthUi.SyncRebirthState(args)
	if args and args.cash then
		currentCash = args.cash
	else
		currentCash = ClientData:GetOneData(dataKey.wins) or currentCash
	end

	if args and args.rebirthState then
		currentRebirthState = args.rebirthState
		currentCash = args.rebirthState.cash or currentCash
	end

	if initialized then
		updateRebirthPanel()
	end

	if args and args.rebirthed then
		playSfx("rebirth")
	elseif args and args.rebirthUpgradePurchased then
		playSfx("shopPurchase")
	end
end

function RebirthUi.UpdateUi(args)
	RebirthUi.SyncRebirthState({
		cash = args and args.wins,
		rebirthState = args,
	})
end

return RebirthUi
