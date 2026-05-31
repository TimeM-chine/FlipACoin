---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

---- requires ----
local CoinFlipPresets = require(Replicated.Systems.CoinFlipSystem.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Keys = require(Replicated.configs.Keys)
local ModelModule = require(Replicated.modules.ModelModule)
local PlayerPresets = require(Replicated.Systems.PlayerSystem.Presets)
local Presets = require(script.Presets)
local ScheduleModule = require(Replicated.modules.ScheduleModule)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

local FakePlayerSystem: Types.System = {
	whiteList = {
		"ApplyLookBehavior",
		"CreateFakeActor",
		"GetActiveFakeCount",
		"GetFakeActor",
		"RemoveFakeActor",
		"ReleaseOneFakeActor",
		"RunDirector",
		"StepFakeActor",
		"UpdateFakeActorHead",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
FakePlayerSystem.__index = FakePlayerSystem

if IsServer then
	FakePlayerSystem.Client = setmetatable({}, FakePlayerSystem)
else
	FakePlayerSystem.Server = setmetatable({}, FakePlayerSystem)
end

local function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function FakePlayerSystem:Init()
	GetSystemMgr()
	if not IsServer then
		return
	end

	self.fakeActors = {}
	self._nextFakeIndex = 0
	self._desiredFakeCount = 0
	self._nextDesiredRefreshAt = 0
	self._directorRunning = false
	self._pendingFakeCreates = 0
	self._directorScheduleId = ScheduleModule.AddSchedule(Presets.DirectorInterval, function()
		self:RunDirector(SENDER)
	end)
	task.defer(function()
		self:RunDirector(SENDER)
	end)
end

function FakePlayerSystem:PlayerAdded(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	task.delay(1.5, function()
		if player:IsDescendantOf(Players) then
			self:RunDirector(SENDER)
		end
	end)
end

function FakePlayerSystem:PlayerRemoving(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	task.defer(function()
		if player and player:IsDescendantOf(Players) then
			return
		end
		self:RunDirector(SENDER)
	end)
end

function FakePlayerSystem:GetFakeActor(sender, fakeId)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end

	return self.fakeActors and self.fakeActors[fakeId] or nil
end

function FakePlayerSystem:RunDirector(sender)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if self._directorRunning then
		return
	end

	self._directorRunning = true
	local success, result = pcall(function()
		self.fakeActors = self.fakeActors or {}
		local realPlayerCount = #Players:GetPlayers()
		local now = os.clock()
		local desiredCount = 0
		if realPlayerCount > 0 and realPlayerCount <= Presets.LowPopulationMaxRealPlayers then
			if now >= (self._nextDesiredRefreshAt or 0) then
				self._desiredFakeCount = math.random(Presets.MinFakePlayers, Presets.MaxFakePlayers)
				self._nextDesiredRefreshAt = now
					+ math.random(Presets.DesiredCountRefreshMin, Presets.DesiredCountRefreshMax)
			end
			desiredCount = self._desiredFakeCount or Presets.MinFakePlayers
		end

		local didMutateSeats = false
		while self:GetActiveFakeCount() > desiredCount do
			if not self:ReleaseOneFakeActor(SENDER, { reason = "populationChanged", suppressBroadcast = true }) then
				break
			end
			didMutateSeats = true
		end
		while self:GetActiveFakeCount() + (self._pendingFakeCreates or 0) < desiredCount do
			if not self:CreateFakeActor({ suppressBroadcast = true }) then
				break
			end
			didMutateSeats = true
		end

		if didMutateSeats then
			GetSystemMgr().systems.TableSeatSystem:RefreshAudienceState(SENDER)
		end

		for _, fakeActor in pairs(self.fakeActors) do
			if fakeActor.isActive then
				self:StepFakeActor(fakeActor, now)
			end
		end
	end)
	self._directorRunning = false
	if not success then
		error(result)
	end
end

function FakePlayerSystem:ReleaseOneFakeActor(sender, args)
	if not IsServer then
		return false
	end
	if sender ~= SENDER then
		return false
	end

	local candidates = {}
	for _, fakeActor in pairs(self.fakeActors or {}) do
		if fakeActor.isActive then
			table.insert(candidates, fakeActor)
		end
	end
	if #candidates == 0 then
		return false
	end

	local fakeActor = candidates[math.random(1, #candidates)]
	self:RemoveFakeActor(fakeActor, args)
	return true
end

function FakePlayerSystem:CreateFakeActor(args)
	local rigTemplate = Replicated.Systems.PlayerSystem.Assets:FindFirstChild("Rig")
	if not rigTemplate or not rigTemplate:IsA("Model") then
		warn("[FakePlayerSystem] Missing PlayerSystem.Assets.Rig")
		return nil
	end

	self._pendingFakeCreates = (self._pendingFakeCreates or 0) + 1
	local success, result = pcall(function()
		self._nextFakeIndex += 1
		local fakeId = `FakePlayer{self._nextFakeIndex}`
		local userId = Presets.FakeUserIdBase - self._nextFakeIndex
		local model = rigTemplate:Clone()
		local displayName = getRandomFakeName()
		local sourceUserId = getRandomFakeUserId()
		local equippedCoin = getRandomShopItemId("coin")
		local equippedDeskSetup = getRandomShopItemId("desk")
		local equippedChair = getRandomShopItemId("chair")
		local runData = table.clone(CoinFlipPresets.RunDataDefaults)
		runData.biasLevel = math.random(Presets.FakeBiasLevelMin, Presets.FakeBiasLevelMax)
		local now = os.clock()
		local fakeActor = {
			isFake = true,
			isActive = false,
			fakeId = fakeId,
			userId = userId,
			UserId = userId,
			displayName = displayName,
			DisplayName = displayName,
			sourceUserId = sourceUserId,
			model = model,
			equippedCoin = equippedCoin,
			equippedDeskSetup = equippedDeskSetup,
			equippedChair = equippedChair,
			runData = runData,
			bestStreak = 0,
			cash = math.random(Presets.StartingCashMin, Presets.StartingCashMax),
			nextActionAt = now + randomFloat(Presets.FirstActionMinDelay, Presets.FirstActionMaxDelay),
			nextFlipAt = now + randomFloat(Presets.FirstActionMinDelay, Presets.FirstActionMaxDelay),
		}

		model.Name = fakeId
		model:SetAttribute("IsFakePlayer", true)
		model:SetAttribute("FakeId", fakeId)
		model:SetAttribute("DisplayName", displayName)
		model:PivotTo(CFrame.new(0, 10000, 0))
		model.Parent = getRuntimeFolder()
		applyFakeAppearance(fakeActor)
		prepareFakeRig(fakeActor)
		attachHeadGui(fakeActor)

		local assignment = GetSystemMgr().systems.TableSeatSystem:AssignFakeActor(SENDER, fakeActor, {
			suppressBroadcast = args and args.suppressBroadcast == true,
		})
		if not assignment then
			if model.Parent then
				model:Destroy()
			end
			return nil
		end

		self.fakeActors[fakeId] = fakeActor
		return fakeActor
	end)
	self._pendingFakeCreates -= 1
	if not success then
		error(result)
	end
	return result
end

function FakePlayerSystem:RemoveFakeActor(fakeActor, args)
	if not fakeActor or not fakeActor.isActive then
		return
	end

	fakeActor.isActive = false
	GetSystemMgr().systems.TableSeatSystem:ClearFakeActor(SENDER, fakeActor, {
		suppressBroadcast = args and args.suppressBroadcast == true,
	})
	if fakeActor.model and fakeActor.model.Parent then
		fakeActor.model:Destroy()
	end
	self.fakeActors[fakeActor.fakeId] = nil
end

function FakePlayerSystem:StepFakeActor(fakeActor, now)
	if updateLookGesture(fakeActor, now) then
		return
	end
	if fakeActor.nextActionAt > now then
		return
	end

	if now >= (fakeActor.nextFlipAt or 0) and math.random() < Presets.FlipActionChance then
		local resolvedFlip = GetSystemMgr().systems.CoinFlipSystem:RequestFakeFlip(SENDER, fakeActor)
		if resolvedFlip then
			fakeActor.nextActionAt = now + getNextFakeActionDelay()
			return
		end
	end

	self:ApplyLookBehavior(fakeActor, now)
	fakeActor.nextActionAt = now + randomFloat(Presets.ActionMinDelay, Presets.ActionMaxDelay)
end

function FakePlayerSystem:ApplyLookBehavior(fakeActor, now)
	local gestureKind = math.random() < 0.58 and "shake" or "nod"
	local duration = randomFloat(Presets.GestureDurationMin, Presets.GestureDurationMax)
	local cycles = randomFloat(Presets.GestureCyclesMin, Presets.GestureCyclesMax)
	local pitchAmplitude = if gestureKind == "nod" then randomFloat(Presets.NodPitchMin, Presets.NodPitchMax) else 0
	local yawAmplitude = if gestureKind == "shake" then randomFloat(Presets.ShakeYawMin, Presets.ShakeYawMax) else 0

	fakeActor.lookGesture = {
		startedAt = now or os.clock(),
		duration = duration,
		cycles = cycles,
		pitchAmplitude = pitchAmplitude,
		yawAmplitude = yawAmplitude,
	}
	updateLookGesture(fakeActor, now or os.clock())
end

function FakePlayerSystem:UpdateFakeActorHead(sender, fakeActor)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if typeof(fakeActor) ~= "table" or fakeActor.isFake ~= true then
		return
	end

	local head = fakeActor.model and fakeActor.model:FindFirstChild("Head")
	local onPlayerHead = head and (head:FindFirstChild("onPlayerHead") or head:FindFirstChild("OnPlayerHead"))
	if not onPlayerHead then
		return
	end

	local runData = fakeActor.runData or {}
	local streak = runData.currentStreak or 0
	local equippedCoinName = EcoPresets.GetShopItemDisplayName("coin", fakeActor.equippedCoin)
	onPlayerHead.name.Text = fakeActor.displayName
	onPlayerHead.vip.Visible = true
	onPlayerHead.vip.Text = `Streak {streak}`
	onPlayerHead.cardPackOpened.Visible = true
	onPlayerHead.cardPackOpened.Text = equippedCoinName
	onPlayerHead.cash.Visible = false
	if onPlayerHead:FindFirstChild("power") then
		onPlayerHead.power.Visible = false
	end
end

function FakePlayerSystem:GetActiveFakeCount()
	local count = 0
	for _, fakeActor in pairs(self.fakeActors or {}) do
		if fakeActor.isActive then
			count += 1
		end
	end
	return count
end

---- [[ Server Only ]] ----
function getRuntimeFolder()
	local tableModel = Workspace:FindFirstChild("CoinFlipTable")
	local assetsFolder = tableModel and tableModel:FindFirstChild("Assets")
	if tableModel and not assetsFolder then
		assetsFolder = Instance.new("Folder")
		assetsFolder.Name = "Assets"
		assetsFolder.Parent = tableModel
	end

	local runtimeFolder = assetsFolder and assetsFolder:FindFirstChild(Presets.RuntimeFolderName)
	if assetsFolder and not runtimeFolder then
		runtimeFolder = Instance.new("Folder")
		runtimeFolder.Name = Presets.RuntimeFolderName
		runtimeFolder.Parent = assetsFolder
	end

	return runtimeFolder or Workspace
end

function prepareFakeRig(fakeActor)
	local model = fakeActor.model
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.AutoJumpEnabled = false
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end

	ModelModule.SetModelCollisionGroup(model, Keys.CollisionGroup.Player)
	local neck = getHeadPoseMotor(model, "Neck")
	local waist = getHeadPoseMotor(model, "Waist")
	fakeActor.neck = neck
	fakeActor.waist = waist
	fakeActor.neckC0 = neck and getHeadPoseJointBase(neck) or nil
	fakeActor.waistC0 = waist and getHeadPoseJointBase(waist) or nil
end

function applyFakeAppearance(fakeActor)
	local humanoid = fakeActor.model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local success, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(fakeActor.sourceUserId)
	end)
	if not success or not description then
		warn(`[FakePlayerSystem] Failed to load fake avatar for userId {fakeActor.sourceUserId}`)
		return
	end

	local applySuccess, applyResult = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applySuccess then
		warn(`[FakePlayerSystem] Failed to apply fake avatar: {applyResult}`)
	end
end

function attachHeadGui(fakeActor)
	local head = fakeActor.model:FindFirstChild("Head")
	if not head then
		return
	end
	if head:FindFirstChild("onPlayerHead") or head:FindFirstChild("OnPlayerHead") then
		FakePlayerSystem:UpdateFakeActorHead(SENDER, fakeActor)
		return
	end

	local template = StarterGui:FindFirstChild("Templates")
		and StarterGui.Templates:FindFirstChild("onPlayerHead")
	if not template then
		return
	end

	local onPlayerHead = template:Clone()
	onPlayerHead.Enabled = true
	onPlayerHead.Parent = head
	FakePlayerSystem:UpdateFakeActorHead(SENDER, fakeActor)
end

function applyHeadPose(fakeActor, pitch, yaw)
	if fakeActor.neck and fakeActor.neckC0 then
		setHeadPoseJoint(
			fakeActor.neck,
			fakeActor.neckC0,
			CFrame.Angles(pitch * Presets.NeckPitchWeight, yaw * Presets.NeckYawWeight, 0)
		)
	end
	if fakeActor.waist and fakeActor.waistC0 then
		setHeadPoseJoint(fakeActor.waist, fakeActor.waistC0, CFrame.Angles(0, yaw * Presets.WaistYawWeight, 0))
	end
end

function getHeadPoseJointBase(joint)
	if joint.ClassName == "AnimationConstraint" then
		return joint.Transform
	end

	return joint.C0
end

function setHeadPoseJoint(joint, baseCFrame, offsetCFrame)
	if joint.ClassName == "AnimationConstraint" then
		joint.Transform = baseCFrame * offsetCFrame
	else
		joint.C0 = baseCFrame * offsetCFrame
	end
end

function getHeadPoseMotor(model, motorName)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == motorName and (descendant:IsA("Motor6D") or descendant.ClassName == "AnimationConstraint") then
			return descendant
		end
	end

	return nil
end

function getRandomFakeName()
	local names = PlayerPresets.FakeNames
	if typeof(names) ~= "table" or #names == 0 then
		return "Guest"
	end

	return names[math.random(1, #names)]
end

function getRandomFakeUserId()
	local userIds = PlayerPresets.FakeUserIds
	if typeof(userIds) ~= "table" or #userIds == 0 then
		return 1
	end

	return userIds[math.random(1, #userIds)]
end

function getRandomShopItemId(category)
	local items = EcoPresets.GrowthShopItems[category]
	if typeof(items) ~= "table" or #items == 0 then
		if category == "coin" then
			return EcoPresets.LoadoutDefaults.equippedCoin
		end
		if category == "desk" then
			return EcoPresets.LoadoutDefaults.equippedDeskSetup
		end
		if category == "chair" then
			return EcoPresets.LoadoutDefaults.equippedChair
		end
		return nil
	end

	return items[math.random(1, #items)].id
end

function updateLookGesture(fakeActor, now)
	local gesture = fakeActor.lookGesture
	if not gesture then
		return false
	end

	local alpha = math.clamp((now - gesture.startedAt) / gesture.duration, 0, 1)
	if alpha >= 1 then
		fakeActor.lookGesture = nil
		applyHeadPose(fakeActor, 0, 0)
		return false
	end

	local fade = math.sin(alpha * math.pi)
	local wave = math.sin(alpha * math.pi * 2 * gesture.cycles)
	applyHeadPose(fakeActor, gesture.pitchAmplitude * wave * fade, gesture.yawAmplitude * wave * fade)

	return true
end

function getNextFakeActionDelay()
	if math.random() < Presets.PostFlipPauseChance then
		return randomFloat(Presets.PostFlipPauseMin, Presets.PostFlipPauseMax)
	end

	return randomFloat(Presets.ActionMinDelay, Presets.ActionMaxDelay)
end

function randomFloat(minValue, maxValue)
	return minValue + math.random() * (maxValue - minValue)
end

return FakePlayerSystem
