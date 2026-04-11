---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local DoorPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local Zone = require(Replicated.modules.Zone)
local BattlePresets = require(Replicated.Systems.BattleSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local Elements = Main:WaitForChild("Elements")
local TravelFrame = Frames:WaitForChild("Travel")
local scroll = TravelFrame:WaitForChild("ScrollingFrame")
local TeleportUi = PlayerGui:WaitForChild("Teleport")
local TeleportFrame = TeleportUi:WaitForChild("Frame")
local BackToCampBtn = Elements:WaitForChild("BackToCamp")

---- logic variables ----
-- local DoorsFolder = workspace:WaitForChild("Doors")
-- local BackPartsFolder = workspace:WaitForChild("BackParts")
local SpawnLocations = workspace:WaitForChild("SpawnLocations")
local debounce = false

local DoorUi = {}

function DoorUi.Init()
	scroll.Template.Visible = false

	local maxZone = ClientData:GetOneData(Keys.DataKey.maxZone)
	-- for i = 1, GameConfig.ZoneCount do
	-- local doorModel = DoorsFolder:FindFirstChild(`door{i}to{i + 1}`)
	-- if not doorModel then
	-- 	continue
	-- end

	-- local frame = doorModel:WaitForChild("BillboardGui"):WaitForChild("Frame")
	-- if maxZone >= i + 1 then
	-- 	frame.defeat.Visible = false
	-- 	frame.cost.Visible = false
	-- 	frame.destination.Text = `{GameConfig.Zones[i + 1].name}`
	-- end

	-- if DoorPresets.UnlockCondition[i + 1] then
	-- 	-- frame.defeat.Text = "Defeat"..BattlePresets.BossConfig[i+1][5].name
	-- 	frame.cost.Text = Util.FormatNumber(DoorPresets.UnlockCondition[i + 1].cost)
	-- 		.. " "
	-- 		.. DoorPresets.UnlockCondition[i + 1].itemType
	-- 	frame.destination.Text = `{GameConfig.Zones[i + 1].name}`

	-- 	local container = doorModel:WaitForChild("Container")
	-- 	local zone = Zone.new(container)
	-- 	zone.localPlayerEntered:Connect(function()
	-- 		SystemMgr.systems.DoorSystem.Server:TouchDoor({ zoneIndex = i + 1 })
	-- 	end)
	-- else
	-- 	frame.defeat.Visible = false
	-- 	frame.cost.Visible = false
	-- 	frame.machine.Visible = false
	-- 	frame.destination.Text = "Coming Soon!"
	-- end
	-- end

	for i = 1, GameConfig.ZoneCount do
		Util.Clone(scroll.Template, scroll, function(unit)
			unit.Visible = true
			unit.Name = i
			unit.LayoutOrder = i * 10
			unit.icon.Image = Textures.Zones[i].icon
			if maxZone < i then
				unit.mask.Visible = true
			end
			unit.destination.Text = GameConfig.Zones[i].name
			uiController.SetButtonHoverAndClick(unit, function()
				SystemMgr.systems.DoorSystem.Server:TouchDoor({ zoneIndex = i })
			end)
		end)

		if not GameConfig.Zones[i].boxes then
			continue
		end
		for j, boxName in pairs(GameConfig.Zones[i].boxes) do
			Util.Clone(scroll.desTpl, scroll, function(unit)
				unit.Visible = true
				unit.LayoutOrder = i * 10 + j
				unit.Text = boxName
			end)
		end
	end

	uiController.SetButtonHoverAndClick(BackToCampBtn, function()
		SystemMgr.systems.DoorSystem.Server:TryTeleportToZone({ zoneIndex = 0 })
	end)
end

function DoorUi.UnlockZone(zoneIndex)
	local card = scroll:FindFirstChild(zoneIndex)
	card.mask.Visible = false
	uiController.SetButtonHoverAndClick(card, function()
		SystemMgr.systems.DoorSystem.Server:TryTeleportToZone({ zoneIndex = zoneIndex })
	end)

	-- local doorModel = DoorsFolder:FindFirstChild(`door{zoneIndex - 1}to{zoneIndex}`)
	-- local frame = doorModel:WaitForChild("BillboardGui"):WaitForChild("Frame")
	-- frame.defeat.Visible = false
	-- frame.cost.Visible = false
	-- frame.destination.Text = `Teleport to {GameConfig.Zones[zoneIndex].name}`
end

function DoorUi.TeleportDone()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	TeleportFrame.Visible = true
	TeleportFrame.Size = UDim2.fromScale(0, 0)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(TeleportFrame, tweenInfo, { Size = UDim2.fromScale(1.5, 1.5) })
	tween:Play()
	task.delay(2, function()
		tween = TweenService:Create(TeleportFrame, tweenInfo, { Size = UDim2.fromScale(0, 0) })
		tween:Play()
		tween.Completed:Wait()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		local nowZone = ClientData:GetOneData(Keys.DataKey.nowZone)
		if nowZone == 0 then
			BackToCampBtn.Visible = false
		else
			BackToCampBtn.Visible = true
		end
	end)
	if TravelFrame.Visible then
		uiController.CloseFrame("Travel")
	end
end

-- local function SetBackPart(part)
-- 	part.Touched:Connect(function(hit)
-- 		if debounce then
-- 			return
-- 		end
-- 		if hit:IsDescendantOf(LocalPlayer.Character) then
-- 			debounce = true
-- 			task.delay(1, function()
-- 				debounce = false
-- 			end)
-- 			LocalPlayer.Character:PivotTo(SpawnLocations:WaitForChild(part.Name).CFrame + Vector3.new(0, 3, 0))
-- 		end
-- 	end)
-- end
-- for _, part in BackPartsFolder:GetChildren() do
-- 	SetBackPart(part)
-- end
-- BackPartsFolder.ChildAdded:Connect(SetBackPart)

return DoorUi
