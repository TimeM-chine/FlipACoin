---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local QuestPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local BackpackUi = require(Replicated.Systems.BackpackSystem.ui)
local CardPresets = require(Replicated.Systems.CardSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local Buttons = Main:WaitForChild("Buttons")
local Elements = Main:WaitForChild("Elements")
local QuestsFrame = Elements:WaitForChild("Quests")
local RewardsFrame = QuestsFrame:WaitForChild("Rewards")
local rewardTpl = RewardsFrame:WaitForChild("Template")
local uiController = require(Main:WaitForChild("uiController"))
local ContextActionMgr = require(Main:WaitForChild("ContextActionMgr"))
local TutorFrame = Frames:WaitForChild("Tutor")

---- logic variables ----
local guideIns = {}
local nowGuide = {
	index = nil,
	questIndex = nil,
}

---- UI guide state ----
local activeUIGuideType = nil
local uiGuideConns = {}
local ClearUIGuide, StartUIGuide
local ForgeGuideWait, ForgeGuideOre, ForgeGuideForgeBtn, ForgeGuideClose
local EquipGuideInventory, EquipGuideWeaponsTab, EquipGuideSelectWeapon

local QuestUi = {}

function QuestUi.Init()
	rewardTpl.Visible = false
	QuestUi.SetQuest()
	uiController.SetButtonHoverAndClick(QuestsFrame.Quests.other.TextButton, function()
		SystemMgr.systems.QuestSystem.Server:ClaimRewards()
	end)

	ContextActionMgr.AddFrameBinding({
		btn = QuestsFrame.Quests.other.TextButton,
		frame = QuestsFrame.Quests,
		keys = { Enum.KeyCode.ButtonY },
	})

	LocalPlayer:GetAttributeChangedSignal("isBattle"):Connect(function()
		if LocalPlayer:GetAttribute("isBattle") then
			ClearGuideIns()
			ClearUIGuide()
		else
			CheckNeedGuide()
		end
	end)

	TutorFrame.ZIndex += 100
	for _, des in TutorFrame:GetDescendants() do
		if des:IsA("GuiObject") then
			des.ZIndex += 100
		end
	end
end

function QuestUi.SetQuest()
	local quests = ClientData:GetOneData(Keys.DataKey.quests)
	local index = quests.index
	if not index then
		return
	end

	uiController.SetGuideButton(nil)
	local questConfig = QuestPresets.Quests[index]
	QuestsFrame.Top.Title.Text = questConfig.title
	for i = 1, 3 do
		local questData = quests.quests[i]
		local card = QuestsFrame.Quests:FindFirstChild(i)
		if not questData then
			card.Visible = false
			continue
		else
			card.Visible = true
		end
		card.Title.Text = questConfig.quests[i].title
		if questData.isCompleted then
			card.ProgressBar.Progress.Text = `Completed!`
			card.ProgressBar.Bar.Size = UDim2.fromScale(1, 1)
			card.redDot.Visible = true
			SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, {
				musicName = "questCompleted",
				musicGroup = "SFX",
			})
		else
			uiController.SetGuideButton(nil)
			card.redDot.Visible = false
			card.ProgressBar.Progress.Text = `{questData.current}/{questData.target}`
			card.ProgressBar.Bar.Size = UDim2.fromScale(questData.current / questData.target, 1)
			card.ProgressBar.tips.Visible = false
		end
	end

	CheckNeedGuide()

	uiController.ClearScrollChildren(RewardsFrame)
	if not questConfig.rewards or #questConfig.rewards == 0 then
		RewardsFrame.Visible = false
		local bottomRewards = QuestsFrame.Bottom and QuestsFrame.Bottom:FindFirstChild("Rewards")
		if bottomRewards then
			bottomRewards.Visible = false
		end
		return
	end

	RewardsFrame.Visible = true
	local bottomRewards = QuestsFrame.Bottom and QuestsFrame.Bottom:FindFirstChild("Rewards")
	if bottomRewards then
		bottomRewards.Visible = true
	end
	-- RewardsFrame.title.Text = questConfig.rewards[1].title
	if questConfig.rewards[1].itemType == Keys.ItemType.pet then
		-- RewardsFrame.icon.Image = Textures.UnclassifiedIcons.wins
	else
		QuestsFrame.Bottom.Rewards.icon.Image = Textures.GetIcon(questConfig.rewards[1])
		-- RewardsFrame.icon.Image = Textures.GetIcon(questConfig.rewards[1])
	end

	-- for _, child in ipairs(littleRewards:GetChildren()) do
	--     if child:IsA("ImageLabel") and child.Name ~= "Template" then
	--         child:Destroy()
	--     end
	-- end

	for i, reward in ipairs(questConfig.rewards) do
		Util.Clone(rewardTpl, RewardsFrame, function(card)
			card.Name = i
			card.Visible = true
			card.icon.Image = Textures.GetIcon(reward)
			card.count.Text = "x" .. reward.count
		end)
	end
end

function QuestUi.AddProgress(args)
	local quests = ClientData:GetOneData(Keys.DataKey.quests)
	uiController.SetGuideButton(nil)

	-- Process all updated quests
	for _, updatedQuest in ipairs(args.questsUpdated or {}) do
		local questIndex = updatedQuest.index
		local questData = quests.quests[questIndex]

		local questCard = QuestsFrame.Quests:FindFirstChild(questIndex)
		if questData.isCompleted then
			SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, {
				musicName = "questCompleted",
				musicGroup = "SFX",
			})
			questCard.redDot.Visible = true
			questCard.ProgressBar.Progress.Text = `Completed!`
			questCard.ProgressBar.Bar.Size = UDim2.fromScale(1, 1)
			if nowGuide.index == quests.index and nowGuide.questIndex == questIndex then
				ClearGuideIns()
			end
		else
			uiController.SetGuideButton(nil)
			questCard.redDot.Visible = false
			questCard.ProgressBar.Progress.Text = `{questData.current}/{questData.target}`
			questCard.ProgressBar.Bar.Size = UDim2.fromScale(questData.current / questData.target, 1)
		end
	end

	CheckNeedGuide()
end

---- UI Guide Utilities ----

local function DisconnectUIGuideConns()
	for _, conn in uiGuideConns do
		conn:Disconnect()
	end
	uiGuideConns = {}
end

local function AddUIGuideConn(conn)
	table.insert(uiGuideConns, conn)
end

ClearUIGuide = function()
	DisconnectUIGuideConns()
	activeUIGuideType = nil
	uiController.SetGuideButton(nil)
end

---- Forge UI Guide ----

local function FindFirstOreCard(oreScroll)
	for _, child in oreScroll:GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= "Template" and child.Visible then
			return child
		end
	end
	return nil
end

ForgeGuideWait = function()
	DisconnectUIGuideConns()
	uiController.SetGuideButton(nil)

	local ForgeFrame = Frames:FindFirstChild("Forge")
	if not ForgeFrame then
		return
	end

	if ForgeFrame.Visible then
		ForgeGuideOre()
		return
	end

	AddUIGuideConn(ForgeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if ForgeFrame.Visible and activeUIGuideType == "forge" then
			ForgeGuideOre()
		end
	end))
end

ForgeGuideOre = function()
	DisconnectUIGuideConns()
	uiController.SetGuideButton(nil)

	local ForgeFrame = Frames:FindFirstChild("Forge")
	if not ForgeFrame or not ForgeFrame.Visible then
		ForgeGuideWait()
		return
	end

	local currentScore = ForgeFrame:GetAttribute("TotalOreScore") or 0
	if currentScore >= 30 then
		ForgeGuideForgeBtn()
		return
	end

	local OreScroll = ForgeFrame.Ores.Frame.ScrollingFrame
	local firstOre = FindFirstOreCard(OreScroll)
	if firstOre then
		uiController.SetGuideButton(firstOre, OreScroll)
	end

	AddUIGuideConn(ForgeFrame:GetAttributeChangedSignal("TotalOreScore"):Connect(function()
		if activeUIGuideType ~= "forge" then
			return
		end
		local score = ForgeFrame:GetAttribute("TotalOreScore") or 0
		if score >= 30 then
			ForgeGuideForgeBtn()
		else
			uiController.SetGuideButton(nil)
			local ore = FindFirstOreCard(OreScroll)
			if ore then
				uiController.SetGuideButton(ore, OreScroll)
			end
		end
	end))

	AddUIGuideConn(ForgeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not ForgeFrame.Visible and activeUIGuideType == "forge" then
			ForgeGuideWait()
		end
	end))
end

ForgeGuideForgeBtn = function()
	DisconnectUIGuideConns()

	local ForgeFrame = Frames:FindFirstChild("Forge")
	if not ForgeFrame or not ForgeFrame.Visible then
		ForgeGuideWait()
		return
	end

	local ForgeBtnInner = ForgeFrame:FindFirstChild("Forge")
	if ForgeBtnInner then
		uiController.SetGuideButton(ForgeBtnInner)
	end

	local ResultFrame = ForgeFrame:FindFirstChild("Result")
	if ResultFrame then
		AddUIGuideConn(ResultFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if ResultFrame.Visible and activeUIGuideType == "forge" then
				ForgeGuideClose()
			end
		end))
	end

	AddUIGuideConn(ForgeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not ForgeFrame.Visible and activeUIGuideType == "forge" then
			ForgeGuideWait()
		end
	end))
end

ForgeGuideClose = function()
	DisconnectUIGuideConns()

	local ForgeFrame = Frames:FindFirstChild("Forge")
	if not ForgeFrame or not ForgeFrame.Visible then
		activeUIGuideType = nil
		uiController.SetGuideButton(nil)
		task.defer(CheckNeedGuide)
		return
	end

	local XButton = ForgeFrame:FindFirstChild("X")
	if XButton then
		uiController.SetGuideButton(XButton)
	end

	AddUIGuideConn(ForgeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not ForgeFrame.Visible then
			activeUIGuideType = nil
			uiController.SetGuideButton(nil)
			DisconnectUIGuideConns()
			task.defer(CheckNeedGuide)
		end
	end))
end

---- Equip Weapon UI Guide ----

EquipGuideInventory = function()
	DisconnectUIGuideConns()
	uiController.SetGuideButton(nil)

	local InventoryButton = Buttons:FindFirstChild("InventoryButton")
	local InventoryFrame = Frames:FindFirstChild("Inventory")
	if not InventoryButton or not InventoryFrame then
		return
	end

	if InventoryFrame.Visible then
		EquipGuideWeaponsTab()
		return
	end

	uiController.SetGuideButton(InventoryButton)

	AddUIGuideConn(InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if InventoryFrame.Visible and activeUIGuideType == "equipWeapon" then
			EquipGuideWeaponsTab()
		end
	end))
end

EquipGuideWeaponsTab = function()
	DisconnectUIGuideConns()
	uiController.SetGuideButton(nil)

	local InventoryFrame = Frames:FindFirstChild("Inventory")
	if not InventoryFrame or not InventoryFrame.Visible then
		EquipGuideInventory()
		return
	end

	local weaponsFrame = InventoryFrame:FindFirstChild("weapons")
	if not weaponsFrame then
		return
	end

	if weaponsFrame.Visible then
		EquipGuideSelectWeapon()
		return
	end

	local invButtons = InventoryFrame:FindFirstChild("Buttons")
	local weaponsTabBtn = invButtons and invButtons:FindFirstChild("weapons")
	if weaponsTabBtn then
		uiController.SetGuideButton(weaponsTabBtn)
	end

	AddUIGuideConn(weaponsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if weaponsFrame.Visible and activeUIGuideType == "equipWeapon" then
			EquipGuideSelectWeapon()
		end
	end))

	AddUIGuideConn(InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not InventoryFrame.Visible and activeUIGuideType == "equipWeapon" then
			EquipGuideInventory()
		end
	end))
end

EquipGuideSelectWeapon = function()
	DisconnectUIGuideConns()
	uiController.SetGuideButton(nil)

	local InventoryFrame = Frames:FindFirstChild("Inventory")
	if not InventoryFrame or not InventoryFrame.Visible then
		EquipGuideInventory()
		return
	end

	local weaponsFrame = InventoryFrame:FindFirstChild("weapons")
	if not weaponsFrame or not weaponsFrame.Visible then
		EquipGuideWeaponsTab()
		return
	end

	local ItemScroll = weaponsFrame:FindFirstChild("ScrollingFrame")
	if not ItemScroll then
		return
	end

	local targetCard = nil
	for _, card in ItemScroll:GetChildren() do
		if card:IsA("GuiObject") and card.Name ~= "Template" and card.Visible then
			local equipped = card:FindFirstChild("equipped")
			if equipped and not equipped.Visible then
				targetCard = card
				break
			end
		end
	end

	if targetCard then
		uiController.SetGuideButton(targetCard)
	end

	AddUIGuideConn(InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not InventoryFrame.Visible then
			activeUIGuideType = nil
			uiController.SetGuideButton(nil)
			DisconnectUIGuideConns()
			task.defer(CheckNeedGuide)
		end
	end))
end

---- UI Guide Dispatcher ----

StartUIGuide = function(guideType)
	ClearUIGuide()
	activeUIGuideType = guideType
	if guideType == "forge" then
		ForgeGuideWait()
	elseif guideType == "equipWeapon" then
		EquipGuideInventory()
	end
end

---- Guide Check ----

function CheckNeedGuide()
	if LocalPlayer:GetAttribute("isBattle") then
		return
	end

	local quests = ClientData:GetOneData(Keys.DataKey.quests)
	local index = quests.index
	if not index then
		return
	end
	local questConfig = QuestPresets.Quests[index]
	if not questConfig then
		return
	end

	local neededUIGuide = nil

	for i = 1, 3 do
		if not questConfig.quests[i] then
			continue
		end
		local questData = quests.quests[i]
		if not questData.isCompleted then
			if #guideIns == 0 then
				if questConfig.quests[i].guideTo then
					local guideToPart = questConfig.quests[i].guideTo(LocalPlayer)
					GuideTo(guideToPart)
					nowGuide = { index = index, questIndex = i }
				end
				if questConfig.quests[i].guideText then
					ShowGuideText(questConfig.quests[i].guideText)
					nowGuide = { index = index, questIndex = i }
				end
			end

			if questConfig.quests[i].guideUI then
				neededUIGuide = questConfig.quests[i].guideUI
			end

			break
		end
	end

	if neededUIGuide and not activeUIGuideType then
		StartUIGuide(neededUIGuide)
	end
end

function GuideTo(part)
	if part.Name == "Forge" then
		local Camera = workspace.CurrentCamera
		Camera.CameraType = Enum.CameraType.Scriptable
		local nowCFrame = Camera.CFrame

		local cf = CFrame.new(part.CFrame * CFrame.new(0, 0, -20).Position, part.Position)
		local ti = TweenInfo.new(3)
		local tween = TweenService:Create(Camera, ti, {
			CFrame = cf,
		})
		tween:Play()
		task.delay(5, function()
			local tween2 = TweenService:Create(Camera, ti, {
				CFrame = nowCFrame,
			})
			tween2:Play()
			tween2.Completed:Wait()
			Camera.CameraType = Enum.CameraType.Custom
		end)
	end

	local beam = workspace.CurrentCamera:FindFirstChild("tutorialBeam")
	if not beam then
		beam = script.Parent.Assets.Beam:Clone()
		beam.Name = "tutorialBeam"
		beam.Parent = workspace.CurrentCamera
		table.insert(guideIns, beam)
	end

	local Attachment0 = LocalPlayer.Character:WaitForChild("HumanoidRootPart"):WaitForChild("RootAttachment")
	beam.Attachment0 = Attachment0

	local attachment = part:FindFirstChild("Attachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Parent = part
		table.insert(guideIns, attachment)
	end
	beam.Attachment1 = attachment
end

function ClearGuideIns()
	for _, ins in ipairs(guideIns) do
		ins:Destroy()
	end
	guideIns = {}
	TutorFrame.Visible = false
	nowGuide = {}
end

function ShowGuideText(guideText)
	TutorFrame.Visible = true
	uiController.SetUnitJump(TutorFrame)
	TutorFrame.Label.Text = guideText
end

return QuestUi
