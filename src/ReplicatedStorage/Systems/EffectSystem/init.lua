--[[
--Author: TimeM_chine
--Created Date: Sat Mar 16 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-05-25 10:18:29
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

---- requires ----
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer
local FirstPersonCamera
local activeCoinFlipVisuals = {}
local VisualConfig = Presets.CoinFlipVisuals
local CoinAssetFolderName = "Coins"
local missingCoinAssetWarnings = {}
local cameraShakeToken = 0
local CameraShakeRenderStepName = "StreakMilestoneCameraShake"

-- 硬币相对世界的“立起”基准；空中翻转绕世界水平轴 `outward×tableNormal`（见 getFlipPositions），再乘基准
local CoinVisualBaseRot = CFrame.Angles(0, 0, math.rad(90))

---- [[ UI ]] ----
local PlayerGui, Main, uiController

local EffectSystem: Types.System = {
	whiteList = {
		"PlayInsideEffects",
		"ToggleInsideEffects",
		"PlayCoinFlipVisual",
		"PlayStreakMilestone",
		"RefreshPersistentSeatCoins",
	},
	players = {},
	IsLoaded = false,
}
EffectSystem.__index = EffectSystem

if IsServer then
	EffectSystem.Client = setmetatable({}, EffectSystem)
	EffectSystem.AllClients = setmetatable({}, EffectSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	EffectSystem.Server = setmetatable({}, EffectSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function EffectSystem:Init()
	GetSystemMgr()
	if not IsServer then
		FirstPersonCamera =
			require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"):WaitForChild("FirstPersonCamera"))
	end
end

function EffectSystem:PlayEffects(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		args.unreliable = true
		self.AllClients:PlayEffects(args)
	else
		local effectName = args.effectName
		local folderName = args.folderName
		local targetPart = args.targetPart
		local targetCFrame = args.targetCFrame
		local lifeTime = args.lifeTime or 5
		if not targetCFrame then
			targetCFrame = targetPart.CFrame
		end
		local bind = args.bind

		local folder
		if folderName then
			folder = script.Assets.Effects:FindFirstChild(folderName)
			if not folder then
				warn("Folder not found: ", folderName)
				return
			end
		else
			folder = script.Assets.Effects
		end
		local effectPart = folder:FindFirstChild(effectName)
		if not effectPart then
			warn("Effect not found: ", effectName)
			return
		end
		local effectP = effectPart:Clone()
		if effectPart:IsA("BasePart") then
			effectP.Massless = true
			effectP.CFrame = targetCFrame
		elseif effectP:IsA("Model") then
			for _, part in effectP:GetDescendants() do
				if part:IsA("BasePart") then
					part.Massless = true
				end
			end
			effectP:PivotTo(targetCFrame)
		else
			warn("Effect not supported: ", effectName)
			return
		end
		if bind then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = effectP:IsA("Model") and effectP.PrimaryPart or effectP
			weld.Part1 = targetPart
			weld.Parent = effectP
			effectP.Parent = workspace
		else
			effectP.Parent = workspace
		end
		self:PlayInsideEffects(effectP)
		Debris:AddItem(effectP, lifeTime)
		return effectP
	end
end

---- [[ Client ]] ----
function EffectSystem:PlayInsideEffects(container)
	local particleRateFactor = SystemMgr.systems.SettingSystem:GetParticleRateFactor()
	if particleRateFactor == 0 then
		return
	end
	local nValue = container:FindFirstChild("totalDelay")
	local totalDelay = nValue and nValue.Value or 0

	task.delay(totalDelay, function()
		for _, particle in container:GetDescendants() do
			if particle:IsA("ParticleEmitter") then
				particle.Rate = math.max(math.floor(particle.Rate * particleRateFactor + 1e-5), 1)
				if particle:GetAttribute("EmitDelay") then
					task.delay(particle:GetAttribute("EmitDelay"), function()
						if particle:GetAttribute("EmitDuration") then
							particle.Enabled = true
							task.delay(particle:GetAttribute("EmitDuration"), function()
								particle.Enabled = false
							end)
						else
							-- particle:Emit(math.ceil(particle.Rate * 0.1))
							particle:Emit(particle.Rate)
						end
					end)
				else
					-- particle:Emit(math.ceil(particle.Rate * 0.1))
					particle:Emit(particle.Rate)
				end
			end

			if particle:IsA("Beam") then
				if particle:GetAttribute("EmitDelay") then
					task.delay(particle:GetAttribute("EmitDelay"), function()
						particle.Enabled = true
					end)
				else
					particle.Enabled = true
				end

				if particle:GetAttribute("EmitDuration") then
					task.delay(particle:GetAttribute("EmitDuration"), function()
						particle.Enabled = false
					end)
				else
					task.delay(5, function()
						particle.Enabled = false
					end)
				end
			end
		end
	end)
end

function EffectSystem:ToggleInsideEffects(container, toggle)
	for _, particle in container:GetDescendants() do
		if
			particle:IsA("ParticleEmitter")
			or particle:IsA("Beam")
			or particle:IsA("Trail")
			or particle:IsA("PointLight")
		then
			particle.Enabled = toggle
		end
	end
end

function EffectSystem:PlayCoinFlipVisual(sender, player, args)
	if IsServer then
		return
	end

	local seatId = args and args.seatId
	local landedCallback = args and args.landedCallback
	if typeof(seatId) ~= "string" then
		if landedCallback then
			landedCallback()
		end
		return
	end

	local visual = getOrCreatePersistentCoinVisual(seatId, args and args.coinId)
	if not visual then
		if landedCallback then
			landedCallback()
		end
		return
	end
	if visual.isFlipping then
		visual.pendingCoinId = args and args.coinId or visual.pendingCoinId
		if landedCallback then
			landedCallback()
		end
		return
	end

	local coinObject = visual.coin
	local shadow = visual.shadow
	local landingPulse = visual.landingPulse
	local streakPulse = visual.streakPulse
	local baseCoinSize = getCoinObjectSize(coinObject)
	local baseShadowSize = shadow.Size
	local result = args.result == "Tails" and "Tails" or "Heads"
	local restSpinRadians = getRandomRestSpinRadians()
	local airborneYawRadians = getRandomAirborneYawRadians(restSpinRadians)
	local finalRotation = math.rad(VisualConfig.SpinTurns * 360) + (result == "Tails" and math.pi or 0)
	local airborneRotation = finalRotation
	local startPos, endPos, tableNormal, surfaceEndPos, flipAxisWorld =
		getFlipPositions(seatId, coinObject, finalRotation)
	if not startPos or not endPos or not tableNormal or not surfaceEndPos then
		hidePersistentCoinVisual(visual)
		if landedCallback then
			landedCallback()
		end
		return
	end
	local flatWorldRot = buildFlatCoinWorldRotation(tableNormal, flipAxisWorld, result, restSpinRadians)
	local endPosFlat = resolveFlatLandWorldPosition(surfaceEndPos, tableNormal, flatWorldRot, visual.coin)
	endPos = endPosFlat

	shadow.Size = baseShadowSize
	shadow.Transparency = VisualConfig.ShadowBaseTransparency

	visual.baseShadowSize = baseShadowSize
	visual.shouldFollowCamera = args.shouldFollowCamera == true
	visual.isFlipping = true

	local startTime = os.clock()
	local arcHeight =
		math.max(VisualConfig.ArcHeight, (startPos - endPos).Magnitude * VisualConfig.ArcHeightTravelFactor)
	local travel = endPos - startPos
	local travelFlat = travel - tableNormal * travel:Dot(tableNormal)
	local bankReference = travelFlat.Magnitude > 1e-4 and travelFlat.Unit or flipAxisWorld:Cross(tableNormal).Unit
	local airborneDuration = VisualConfig.TravelDuration
	local shadowPos = surfaceEndPos + (tableNormal * ((baseShadowSize.X * 0.5) + VisualConfig.ShadowSurfaceGap))
	local visualOptions = args.visualOptions
	local observedStreak = visualOptions and (visualOptions.streak or 0) or 0
	local shouldShowObservedStreakPulse = visualOptions
		and visualOptions.isObserved == true
		and result == "Heads"
		and observedStreak >= VisualConfig.StreakPulseMinimum

	pivotCoinVisual(visual, CFrame.new(startPos) * CoinVisualBaseRot)
	shadow.CFrame = CFrame.new(startPos.X, shadowPos.Y, startPos.Z) * CoinVisualBaseRot
	playSfx("coinToss")
	playTimedSfx("coinSpin", airborneDuration + VisualConfig.LandingDuration)
	if visual.shouldFollowCamera then
		FirstPersonCamera.FollowCoin(visual.focusPart, {
			duration = airborneDuration + VisualConfig.LandingDuration + (VisualConfig.ResultRevealDelay or 0) + 0.08,
		})
	end

	visual.connection = RunService.RenderStepped:Connect(function()
		local currentVisual = activeCoinFlipVisuals[seatId]
		if currentVisual ~= visual then
			if visual.connection then
				visual.connection:Disconnect()
			end
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / airborneDuration, 0, 1)
		local height = math.sin(alpha * math.pi) * arcHeight
		local position = startPos + (travel * alpha) + tableNormal * height
		local flipAngle = airborneRotation * alpha
		local bankAngle = math.sin(alpha * math.pi) * VisualConfig.BankAngle
		local yawAngle = airborneYawRadians * easeOutCubic(alpha)
		local shadowAlpha = math.clamp(height / arcHeight, 0, 1)
		local shadowScale = VisualConfig.ShadowMaxScale
			- ((VisualConfig.ShadowMaxScale - VisualConfig.ShadowMinScale) * shadowAlpha)
		local shadowTransparency = VisualConfig.ShadowBaseTransparency
			+ ((VisualConfig.ShadowMaxTransparency - VisualConfig.ShadowBaseTransparency) * shadowAlpha)

		local coinWorldRot = buildAirborneCoinWorldRotation(
			tableNormal,
			flipAxisWorld,
			bankReference,
			flipAngle,
			bankAngle,
			yawAngle,
			flatWorldRot,
			alpha
		)
		local coinCFrame = CFrame.new(position) * coinWorldRot
		pivotCoinVisual(visual, coinCFrame)
		shadow.CFrame = CFrame.new(position.X, shadowPos.Y, position.Z) * CoinVisualBaseRot
		shadow.Size = Vector3.new(baseShadowSize.X, baseCoinSize.Y * shadowScale, baseCoinSize.Z * shadowScale)
		shadow.Transparency = shadowTransparency

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil

		local pulseColor = result == "Heads" and VisualConfig.HeadsPulseColor or VisualConfig.TailsPulseColor
		playSfx("coinLand")
		playLandingPulse(landingPulse, shadowPos, pulseColor)
		if shouldShowObservedStreakPulse then
			local streakPulseBonus = math.clamp(observedStreak - VisualConfig.StreakPulseMinimum, 0, 6) * 0.16
			playLandingPulse(streakPulse, shadowPos, VisualConfig.StreakPulseColor, {
				startSize = VisualConfig.StreakPulseStartSize,
				endSize = VisualConfig.StreakPulseEndSize + streakPulseBonus,
				duration = VisualConfig.StreakPulseDuration,
				transparency = 0.22,
			})
		end

		local settleCFrame = Instance.new("CFrameValue")
		settleCFrame.Value = getCoinObjectPivot(visual.coin)
		visual.settleCFrame = settleCFrame
		visual.settleConnection = settleCFrame:GetPropertyChangedSignal("Value"):Connect(function()
			pivotCoinVisual(visual, settleCFrame.Value)
		end)

		local settleTween = TweenService:Create(
			settleCFrame,
			TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Value = CFrame.new(endPosFlat) * flatWorldRot,
			}
		)
		visual.settleTween = settleTween
		settleTween:Play()

		local shadowEndFlat = Vector3.new(endPosFlat.X, shadowPos.Y, endPosFlat.Z)
		local shadowTween = TweenService:Create(
			shadow,
			TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(shadowEndFlat) * CoinVisualBaseRot,
				Size = baseShadowSize,
				Transparency = VisualConfig.ShadowBaseTransparency,
			}
		)
		shadowTween:Play()

		settleTween.Completed:Once(function(playbackState)
			if playbackState ~= Enum.PlaybackState.Completed then
				return
			end
			if visual.settleConnection then
				visual.settleConnection:Disconnect()
				visual.settleConnection = nil
			end
			if visual.settleCFrame then
				visual.settleCFrame:Destroy()
				visual.settleCFrame = nil
			end
			visual.settleTween = nil
			visual.isFlipping = false
			visual.lastResult = result
			visual.lastRestSpinRadians = restSpinRadians
			if visual.shouldFollowCamera then
				FirstPersonCamera.ReturnToFirstPerson(visual.focusPart)
			end
			visual.shouldFollowCamera = false
			playSfx(result == "Heads" and "headsWin" or "tailsLose")
			refreshPendingCoinVisual(visual, seatId)
			if landedCallback then
				task.delay(VisualConfig.ResultRevealDelay or 0, landedCallback)
			end
		end)
	end)
end

function EffectSystem:RefreshPersistentSeatCoins(sender, player, args)
	if IsServer then
		return
	end
	if typeof(args) ~= "table" or typeof(args.seatDisplayEntries) ~= "table" then
		return
	end

	local occupiedSeats = {}
	for _, entry in ipairs(args.seatDisplayEntries) do
		if entry.isOccupied and typeof(entry.seatId) == "string" then
			occupiedSeats[entry.seatId] = true
			local visual = getOrCreatePersistentCoinVisual(entry.seatId, entry.equippedCoin)
			if visual and not visual.isFlipping then
				placePersistentCoinAtRest(visual, entry.seatId, visual.lastResult)
			elseif visual then
				visual.pendingCoinId = entry.equippedCoin or visual.pendingCoinId
			end
		end
	end

	for seatId, visual in pairs(activeCoinFlipVisuals) do
		if not occupiedSeats[seatId] and not visual.isFlipping then
			hidePersistentCoinVisual(visual)
		end
	end
end

function EffectSystem:PlayStreakMilestone(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		if typeof(args) ~= "table" then
			return
		end

		args.unreliable = true
		self.AllClients:PlayStreakMilestone(args)
		return
	end
	if typeof(args) ~= "table" then
		return
	end
	if typeof(args.seatId) ~= "string" then
		return
	end

	playSfx(args.sfx)
	playStreakMilestoneVfx(args.seatId, args.vfx, args.lifeTime)
	playConfiguredCameraShake(args.cameraShake)
end

function getTableModel()
	return Workspace:FindFirstChild("CoinFlipTable")
end

function getSeatRecord(seatId)
	if typeof(seatId) ~= "string" then
		return nil
	end

	return SystemMgr.systems.TableSeatSystem:GetSeatRecordByDisplayId(seatId)
end

function getCoinVisualsFolder(seatId)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	if not tableModel then
		return nil
	end

	local assets = tableModel:FindFirstChild("Assets")
	local underAssets = assets and assets:FindFirstChild("CoinVisuals")
	if underAssets then
		return underAssets
	end

	return tableModel:FindFirstChild("CoinVisuals")
end

function getSeatAttachment(seatId)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local attachmentsFolder = tableModel and tableModel:FindFirstChild("Attachments")
	local marker = attachmentsFolder and attachmentsFolder:FindFirstChild(`{rawSeatId}Marker`)
	return marker and marker:FindFirstChildWhichIsA("Attachment") or nil
end

function getSeatPart(seatId)
	local seatRecord = getSeatRecord(seatId)
	if seatRecord and seatRecord.seat then
		return seatRecord.seat
	end

	local tableModel = getTableModel()
	local seatsFolder = tableModel and tableModel:FindFirstChild("Seats")
	return seatsFolder and seatsFolder:FindFirstChild(seatId)
end

function getCoinLandingAnchor(tableModel, rawSeatId)
	local attachmentsFolder = tableModel and tableModel:FindFirstChild("Attachments")
	if not attachmentsFolder then
		return nil
	end

	local candidateNames = {
		`{rawSeatId}CoinLandingAnchor`,
		`{rawSeatId}CoinLanding`,
		`{rawSeatId}LandingAnchor`,
	}

	for _, candidateName in ipairs(candidateNames) do
		local candidate = attachmentsFolder:FindFirstChild(candidateName)
		if candidate then
			local attachment = candidate:IsA("Attachment") and candidate
				or candidate:FindFirstChildWhichIsA("Attachment")
			return attachment or candidate
		end
	end

	return nil
end

function getDynamicSeatCFrame(seatId)
	return SystemMgr.systems.TableSeatSystem:GetSeatTargetCFrame(seatId)
end

function getAnchorPosition(anchor)
	if anchor:IsA("Attachment") then
		return anchor.WorldPosition
	end
	if anchor:IsA("BasePart") then
		return anchor.Position
	end
	if anchor:IsA("Model") then
		return anchor:GetPivot().Position
	end

	return nil
end

function getTableSurfaceData(tableTop)
	local axisRecords = {
		{
			size = tableTop.Size.X,
			normal = tableTop.CFrame.RightVector,
		},
		{
			size = tableTop.Size.Y,
			normal = tableTop.CFrame.UpVector,
		},
		{
			size = tableTop.Size.Z,
			normal = -tableTop.CFrame.LookVector,
		},
	}

	table.sort(axisRecords, function(a, b)
		return a.size < b.size
	end)

	local normal = axisRecords[1].normal
	if normal:Dot(Vector3.yAxis) < 0 then
		normal = -normal
	end

	return normal, axisRecords[1].size * 0.5
end

-- 用射线命中 TableTop 得到真实落点，再按硬币当前姿态做一次 bounds lift，避免重复抬高导致浮空
function resolveFlatLandWorldPosition(surfaceEndPos, tableNormal, flatWorldRot, coinObject)
	local n = tableNormal.Unit
	local tableModel = getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	if not tableTop or not tableTop:IsA("BasePart") then
		local lift0 = math.max(getObjectSurfaceLift(coinObject, CFrame.new(surfaceEndPos) * flatWorldRot, n), 0.05)
		return surfaceEndPos + n * (lift0 + VisualConfig.CoinSurfaceGap)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { tableTop }

	local origin = surfaceEndPos + n * 35
	local hit = Workspace:Raycast(origin, -n * 120, rayParams)
	if not hit and tableModel then
		rayParams.FilterDescendantsInstances = { tableModel }
		hit = Workspace:Raycast(origin, -n * 120, rayParams)
	end
	local surfacePosition
	if hit then
		surfacePosition = hit.Position
	else
		surfacePosition = surfaceEndPos
	end

	local lift = math.max(getObjectSurfaceLift(coinObject, CFrame.new(surfacePosition) * flatWorldRot, n), 0)
	return surfacePosition + n * (lift + VisualConfig.CoinSurfaceGap)
end

function getFlipPositions(seatId, coinObject, landingSpinRadians)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return nil, nil, nil, nil, nil
	end

	local centerAttachment = tableTop.TableCenterAttachment
	local seatAttachment = getSeatAttachment(seatId)
	local seatPart = getSeatPart(seatId)
	local startPos
	if seatAttachment then
		startPos = seatAttachment.WorldPosition + Vector3.new(0, VisualConfig.CoinStartHeight, 0)
	elseif seatPart then
		startPos = seatPart.Position + Vector3.new(0, 1.25 + VisualConfig.CoinStartHeight, 0)
	else
		return nil, nil, nil, nil, nil
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + (tableNormal * halfThickness)
	local centerPos = centerAttachment and centerAttachment.WorldPosition or surfaceCenter
	local dynamicSeatCFrame = getDynamicSeatCFrame(seatId)
	if dynamicSeatCFrame then
		startPos = dynamicSeatCFrame.Position + tableNormal * (1.25 + VisualConfig.CoinStartHeight)
	end
	local outward = startPos - surfaceCenter
	outward = outward - (tableNormal * outward:Dot(tableNormal))
	if outward.Magnitude < 0.001 then
		outward = Vector3.new(1, 0, 0)
	else
		outward = outward.Unit
	end

	local flipAxisWorld = outward:Cross(tableNormal)
	if flipAxisWorld.Magnitude < 1e-4 then
		flipAxisWorld = Vector3.new(0, 0, 1)
	else
		flipAxisWorld = flipAxisWorld.Unit
	end

	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local landingAnchor = getCoinLandingAnchor(tableModel, rawSeatId)
	local landingAnchorPosition = landingAnchor and getAnchorPosition(landingAnchor)
	local surfaceEndPos = centerPos + (outward * VisualConfig.LandingRadius)
	if landingAnchorPosition and not dynamicSeatCFrame then
		surfaceEndPos = landingAnchorPosition - tableNormal * (landingAnchorPosition - surfaceCenter):Dot(tableNormal)
	end
	local landedRotation = CFrame.fromAxisAngle(flipAxisWorld, landingSpinRadians) * CoinVisualBaseRot
	local surfaceLift = getObjectSurfaceLift(coinObject, CFrame.new() * landedRotation, tableNormal)
	local endPos = surfaceEndPos + (tableNormal * (surfaceLift + VisualConfig.CoinSurfaceGap))
	startPos = endPos

	return startPos, endPos, tableNormal, surfaceEndPos, flipAxisWorld
end

function getCoinVisual(seatId)
	local seatRecord = getSeatRecord(seatId)
	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local coinVisualsFolder = getCoinVisualsFolder(seatId)
	local visualModel = coinVisualsFolder and coinVisualsFolder:FindFirstChild(`{rawSeatId}CoinVisual`)
	if not visualModel then
		return nil
	end

	return visualModel,
		visualModel:WaitForChild("Coin"),
		visualModel:WaitForChild("Shadow"),
		visualModel:WaitForChild("LandingPulse"),
		visualModel:WaitForChild("StreakPulse")
end

function getOrCreatePersistentCoinVisual(seatId, coinId)
	local visual = activeCoinFlipVisuals[seatId]
	if visual then
		visual.lastResult = visual.lastResult or "Heads"
		visual.lastRestSpinRadians = visual.lastRestSpinRadians or getRandomRestSpinRadians()
		if coinId and visual.coinId ~= coinId and not visual.isFlipping then
			replacePersistentCoinObject(visual, coinId)
		elseif coinId and visual.coinId ~= coinId then
			visual.pendingCoinId = coinId
		end
		setCoinObjectEnabled(visual.coin, visual.shadow, true)
		return visual
	end

	local visualModel, fallbackCoin, shadow, landingPulse, streakPulse = getCoinVisual(seatId)
	if not visualModel or not fallbackCoin or not shadow or not landingPulse or not streakPulse then
		return nil
	end

	local coinObject, clonedCoinObject = createCoinObject(visualModel, fallbackCoin, coinId)
	visual = {
		model = visualModel,
		coin = coinObject,
		coinId = coinId,
		focusPart = getCoinFocusPart(coinObject, fallbackCoin),
		fallbackCoin = fallbackCoin,
		clonedCoinObject = clonedCoinObject,
		shadow = shadow,
		landingPulse = landingPulse,
		streakPulse = streakPulse,
		baseShadowSize = shadow.Size,
		lastResult = "Heads",
		lastRestSpinRadians = getRandomRestSpinRadians(),
		shouldFollowCamera = false,
		isFlipping = false,
	}
	activeCoinFlipVisuals[seatId] = visual
	setCoinObjectEnabled(visual.coin, visual.shadow, true)
	hidePulseVisual(landingPulse)
	hidePulseVisual(streakPulse)
	placePersistentCoinAtRest(visual, seatId, visual.lastResult)

	return visual
end

function replacePersistentCoinObject(visual, coinId)
	if visual.clonedCoinObject and visual.coin and visual.coin.Parent then
		visual.coin:Destroy()
	elseif visual.fallbackCoin then
		setCoinObjectEnabled(visual.fallbackCoin, nil, false)
	end

	local coinObject, clonedCoinObject = createCoinObject(visual.model, visual.fallbackCoin, coinId)
	visual.coin = coinObject
	visual.coinId = coinId
	visual.focusPart = getCoinFocusPart(coinObject, visual.fallbackCoin)
	visual.clonedCoinObject = clonedCoinObject
	setCoinObjectEnabled(visual.coin, visual.shadow, true)
end

function refreshPendingCoinVisual(visual, seatId)
	if not visual.pendingCoinId or visual.pendingCoinId == visual.coinId then
		visual.pendingCoinId = nil
		return
	end

	local pendingCoinId = visual.pendingCoinId
	visual.pendingCoinId = nil
	replacePersistentCoinObject(visual, pendingCoinId)
	placePersistentCoinAtRest(visual, seatId, visual.lastResult)
end

function placePersistentCoinAtRest(visual, seatId, result)
	local _, _, tableNormal, surfaceEndPos, flipAxisWorld = getFlipPositions(seatId, visual.coin, 0)
	if not tableNormal or not surfaceEndPos or not flipAxisWorld then
		return
	end

	visual.lastRestSpinRadians = visual.lastRestSpinRadians or getRandomRestSpinRadians()
	local flatWorldRot =
		buildFlatCoinWorldRotation(tableNormal, flipAxisWorld, result or "Heads", visual.lastRestSpinRadians)
	local endPosFlat = resolveFlatLandWorldPosition(surfaceEndPos, tableNormal, flatWorldRot, visual.coin)
	local targetCFrame = CFrame.new(endPosFlat) * flatWorldRot
	local shadowPos = surfaceEndPos + tableNormal * ((visual.baseShadowSize.X * 0.5) + VisualConfig.ShadowSurfaceGap)
	pivotCoinVisual(visual, targetCFrame)
	visual.shadow.CFrame = CFrame.new(shadowPos) * CoinVisualBaseRot
	visual.shadow.Size = visual.baseShadowSize
	visual.shadow.Transparency = VisualConfig.ShadowBaseTransparency
end

function hidePersistentCoinVisual(visual)
	if visual.shouldFollowCamera then
		FirstPersonCamera.ReturnToFirstPerson(visual.focusPart)
	end
	visual.shouldFollowCamera = false
	visual.isFlipping = false
	if visual.connection then
		visual.connection:Disconnect()
		visual.connection = nil
	end
	if visual.settleTween then
		visual.settleTween:Cancel()
		visual.settleTween = nil
	end
	if visual.settleConnection then
		visual.settleConnection:Disconnect()
		visual.settleConnection = nil
	end
	if visual.settleCFrame then
		visual.settleCFrame:Destroy()
		visual.settleCFrame = nil
	end
	setCoinObjectEnabled(visual.coin, visual.shadow, false)
	hidePulseVisual(visual.landingPulse)
	hidePulseVisual(visual.streakPulse)
end

function getCoinAssetFolder()
	local assets = Replicated.Systems.CoinFlipSystem.Assets
	return assets:FindFirstChild(CoinAssetFolderName)
end

function warnMissingCoinAsset(coinId, reason)
	local warningKey = coinId or "__missing_coin_id"
	if missingCoinAssetWarnings[warningKey] then
		return
	end

	missingCoinAssetWarnings[warningKey] = true
	warn(`[EffectSystem] {reason}`)
end

function getCoinObjectParts(coinObject)
	local parts = {}
	if coinObject:IsA("BasePart") then
		table.insert(parts, coinObject)
	elseif coinObject:IsA("Model") then
		for _, descendant in ipairs(coinObject:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
	end

	return parts
end

function getEquippedCoinAsset(coinId)
	if typeof(coinId) ~= "string" then
		return nil
	end

	local assetFolder = getCoinAssetFolder()
	if not assetFolder then
		warnMissingCoinAsset(
			coinId,
			`Missing CoinFlipSystem.Assets.{CoinAssetFolderName}; using default coin visual.`
		)
		return nil
	end

	local asset = assetFolder:FindFirstChild(coinId)
	if not asset then
		warnMissingCoinAsset(coinId, `Missing coin model asset for equipped coin: {coinId}`)
		return nil
	end
	if not asset:IsA("Model") and not asset:IsA("BasePart") then
		warnMissingCoinAsset(coinId, `Coin asset must be a Model or BasePart: {coinId}`)
		return nil
	end
	if #getCoinObjectParts(asset) == 0 then
		warnMissingCoinAsset(coinId, `Coin asset has no renderable BasePart descendants: {coinId}`)
		return nil
	end

	return asset
end

function prepareCoinObject(coinObject)
	for _, part in ipairs(getCoinObjectParts(coinObject)) do
		part.Anchored = true
		part.CanCollide = false
		part.Massless = true
	end
end

function createCoinObject(visualModel, fallbackCoin, coinId)
	local asset = getEquippedCoinAsset(coinId)
	if asset then
		local coinObject = asset:Clone()
		coinObject.Name = "EquippedCoinVisual"
		prepareCoinObject(coinObject)
		coinObject.Parent = visualModel
		setCoinObjectEnabled(fallbackCoin, nil, false)
		return coinObject, true
	end

	setCoinObjectEnabled(fallbackCoin, nil, true)
	return fallbackCoin, false
end

function getCoinFocusPart(coinObject, fallbackCoin)
	if coinObject:IsA("BasePart") then
		return coinObject
	end
	if coinObject:IsA("Model") and coinObject.PrimaryPart then
		return coinObject.PrimaryPart
	end

	return fallbackCoin
end

function getCoinObjectSize(coinObject)
	if coinObject:IsA("BasePart") then
		return coinObject.Size
	end

	return coinObject:GetExtentsSize()
end

function getCoinObjectPivot(coinObject)
	if coinObject:IsA("BasePart") then
		return coinObject.CFrame
	end

	return coinObject:GetPivot()
end

function pivotCoinObject(coinObject, targetCFrame)
	if coinObject:IsA("BasePart") then
		coinObject.CFrame = targetCFrame
	else
		coinObject:PivotTo(targetCFrame)
	end
end

function pivotCoinVisual(visual, targetCFrame)
	pivotCoinObject(visual.coin, targetCFrame)
	if visual.focusPart and not visual.focusPart:IsDescendantOf(visual.coin) then
		visual.focusPart.CFrame = targetCFrame
	end
end

function buildAirborneCoinWorldRotation(
	tableNormal,
	flipAxisWorld,
	bankReference,
	flipAngle,
	bankAngle,
	yawAngle,
	finalFlatWorldRot,
	alpha
)
	local airborneRot = CFrame.fromAxisAngle(tableNormal.Unit, yawAngle)
		* CFrame.fromAxisAngle(flipAxisWorld, flipAngle)
		* CoinVisualBaseRot
		* CFrame.fromAxisAngle(bankReference, bankAngle)
	local blendAlpha = getLandingOrientationBlendAlpha(alpha)
	if blendAlpha <= 0 then
		return airborneRot
	end

	return airborneRot:Lerp(finalFlatWorldRot, blendAlpha)
end

-- 硬币平铺在桌面：局部Y沿厚度方向对齐 `FlatThicknessLocalSign * tableNormal`，再绕桌面法线随机转向
function buildFlatCoinWorldRotation(tableNormal, flipAxisWorld, flipResult, restSpinRadians)
	local n = tableNormal.Unit
	local u = flipAxisWorld.Unit
	local yThickness = n * VisualConfig.FlatThicknessLocalSign
	local z = u:Cross(yThickness).Unit
	local basis = CFrame.fromMatrix(Vector3.zero, u, yThickness, z)
	if flipResult == "Tails" then
		basis = basis * CFrame.fromAxisAngle(u, math.pi)
	end
	return CFrame.fromAxisAngle(n, restSpinRadians or 0) * basis
end

function getRandomRestSpinRadians()
	return math.random() * math.pi * 2
end

function getRandomAirborneYawRadians(restSpinRadians)
	local direction = math.random(0, 1) == 0 and -1 or 1
	local fullTurns = math.random(VisualConfig.AirYawMinTurns, VisualConfig.AirYawMaxTurns)
	return restSpinRadians + direction * fullTurns * math.pi * 2
end

function getLandingOrientationBlendAlpha(alpha)
	if alpha <= VisualConfig.LandingOrientationBlendStart then
		return 0
	end

	local blendRange = 1 - VisualConfig.LandingOrientationBlendStart
	local t = math.clamp((alpha - VisualConfig.LandingOrientationBlendStart) / blendRange, 0, 1)
	return t * t * (3 - 2 * t)
end

function easeOutCubic(alpha)
	local inverseAlpha = 1 - alpha
	return 1 - inverseAlpha * inverseAlpha * inverseAlpha
end

function getObjectSurfaceLift(coinObject, objectCFrame, normal)
	local objectPivot = getCoinObjectPivot(coinObject)
	local minProjection = math.huge

	for _, part in ipairs(getCoinObjectParts(coinObject)) do
		local relativeCFrame = objectPivot:ToObjectSpace(part.CFrame)
		local partCFrame = objectCFrame * relativeCFrame
		local halfSize = part.Size * 0.5
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local corner =
						partCFrame:PointToWorldSpace(Vector3.new(halfSize.X * x, halfSize.Y * y, halfSize.Z * z))
					minProjection = math.min(minProjection, corner:Dot(normal))
				end
			end
		end
	end

	if minProjection == math.huge then
		return 0
	end

	return objectCFrame.Position:Dot(normal) - minProjection
end

function setFaceVisualEnabled(faceVisual, enabled)
	if not faceVisual then
		return
	end
	if faceVisual:IsA("Decal") or faceVisual:IsA("Texture") then
		faceVisual.Transparency = enabled and 0 or 1
	elseif faceVisual:IsA("SurfaceGui") or faceVisual:IsA("BillboardGui") then
		faceVisual.Enabled = enabled
	end
end

function setCoinObjectEnabled(coinObject, shadow, enabled)
	for _, part in ipairs(getCoinObjectParts(coinObject)) do
		part.Transparency = enabled and 0 or 1
	end

	if shadow then
		shadow.Transparency = enabled and VisualConfig.ShadowBaseTransparency or 1
	end
	if coinObject:IsA("BasePart") then
		setFaceVisualEnabled(coinObject:FindFirstChild("TopFace"), enabled)
		setFaceVisualEnabled(coinObject:FindFirstChild("BottomFace"), enabled)
	end
end

function hidePulseVisual(pulse)
	pulse.Transparency = 1
end

function playLandingPulse(pulse, position, color, options)
	local startSize = options and options.startSize or VisualConfig.PulseStartSize
	local endSize = options and options.endSize or VisualConfig.PulseEndSize
	local duration = options and options.duration or VisualConfig.PulseDuration
	local transparency = options and options.transparency or 0.18

	pulse.Color = color
	pulse.Transparency = transparency
	pulse.Size = Vector3.new(VisualConfig.ShadowHeight, startSize, startSize)
	pulse.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))

	local tween = TweenService:Create(pulse, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(VisualConfig.ShadowHeight, endSize, endSize),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		hidePulseVisual(pulse)
	end)
end

function getSfxSound(soundName)
	if typeof(soundName) ~= "string" or soundName == "" then
		return nil
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	local sound = sfxGroup and sfxGroup:FindFirstChild(soundName)
	if not sound or not sound:IsA("Sound") or sound.SoundId == "" then
		return nil
	end

	return sound
end

function playSfx(soundName)
	local sound = getSfxSound(soundName)
	if not sound then
		return nil
	end

	local clone = sound:Clone()
	clone.Looped = false
	clone.Parent = sound.Parent
	clone:Play()
	Debris:AddItem(clone, math.max(clone.TimeLength, 3) + 0.2)
	return clone
end

function playTimedSfx(soundName, duration)
	local sound = getSfxSound(soundName)
	if not sound then
		return
	end

	local clone = sound:Clone()
	clone.Looped = true
	clone.Parent = sound.Parent
	clone:Play()
	Debris:AddItem(clone, duration + 0.3)

	task.delay(duration, function()
		if clone.Parent then
			clone:Stop()
		end
	end)
end

function playStreakMilestoneVfx(seatId, vfxName, lifeTime)
	if typeof(vfxName) ~= "string" or vfxName == "" then
		return
	end

	local effectAsset = getStreakMilestoneVfxAsset(vfxName)
	if not effectAsset then
		warn(`[EffectSystem] Missing streak milestone VFX asset: {vfxName}`)
		return
	end

	local targetCFrame = getStreakMilestoneCFrame(seatId)
	local effectClone = buildStreakMilestoneEffectClone(effectAsset, targetCFrame)
	if not effectClone then
		warn(`[EffectSystem] Streak milestone VFX must be a Model, BasePart, Attachment, or Folder: {vfxName}`)
		return
	end

	effectClone.Parent = getEffectRuntimeParent()
	EffectSystem:PlayInsideEffects(effectClone)
	Debris:AddItem(effectClone, lifeTime or 5)
end

function getStreakMilestoneVfxAsset(vfxName)
	local assets = script.Assets
	local effectAsset = assets:FindFirstChild(vfxName)
	if effectAsset then
		return effectAsset
	end

	local effectsFolder = assets:FindFirstChild("Effects")
	return effectsFolder and effectsFolder:FindFirstChild(vfxName)
end

function getStreakMilestoneCFrame(seatId)
	local visual = activeCoinFlipVisuals[seatId] or getOrCreatePersistentCoinVisual(seatId)
	if visual then
		return getCoinObjectPivot(visual.coin)
	end

	local seatAttachment = getSeatAttachment(seatId)
	if seatAttachment then
		return seatAttachment.WorldCFrame
	end

	local seatPart = getSeatPart(seatId)
	if seatPart then
		return seatPart.CFrame
	end

	return CFrame.new()
end

function buildStreakMilestoneEffectClone(effectAsset, targetCFrame)
	if effectAsset:IsA("BasePart") then
		local effectClone = effectAsset:Clone()
		effectClone.Anchored = true
		effectClone.CanCollide = false
		effectClone.Massless = true
		effectClone.CFrame = targetCFrame
		return effectClone
	end

	if effectAsset:IsA("Model") then
		local effectClone = effectAsset:Clone()
		for _, part in ipairs(effectClone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.Massless = true
			end
		end
		effectClone:PivotTo(targetCFrame)
		return effectClone
	end

	if effectAsset:IsA("Attachment") then
		local anchor = createEffectAnchor(effectAsset.Name, targetCFrame)
		effectAsset:Clone().Parent = anchor
		return anchor
	end

	if effectAsset:IsA("Folder") then
		local anchor = createEffectAnchor(effectAsset.Name, targetCFrame)
		for _, child in ipairs(effectAsset:GetChildren()) do
			child:Clone().Parent = anchor
		end
		return anchor
	end

	return nil
end

function createEffectAnchor(effectName, targetCFrame)
	local anchor = Instance.new("Part")
	anchor.Name = `{effectName}Anchor`
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = targetCFrame
	return anchor
end

function getEffectRuntimeParent()
	return Workspace:FindFirstChild("Effects") or Workspace
end

function playConfiguredCameraShake(cameraShake)
	if not cameraShake then
		return
	end

	local shakeConfig = resolveCameraShakeConfig(cameraShake)
	cameraShakeToken += 1
	local token = cameraShakeToken
	local startTime = os.clock()
	local seed = math.random() * 1000

	RunService:UnbindFromRenderStep(CameraShakeRenderStepName)
	RunService:BindToRenderStep(CameraShakeRenderStepName, Enum.RenderPriority.Camera.Value + 1, function()
		if token ~= cameraShakeToken then
			RunService:UnbindFromRenderStep(CameraShakeRenderStepName)
			return
		end

		local elapsed = os.clock() - startTime
		if elapsed >= shakeConfig.duration then
			RunService:UnbindFromRenderStep(CameraShakeRenderStepName)
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local progress = math.clamp(elapsed / shakeConfig.duration, 0, 1)
		local fade = shakeConfig.fadeOut and (1 - progress) or 1
		local amplitude = shakeConfig.amplitude * fade
		local noiseTime = elapsed * shakeConfig.frequency
		local x = math.noise(seed, noiseTime, 0) * amplitude
		local y = math.noise(seed, 0, noiseTime) * amplitude
		local roll = math.noise(0, seed, noiseTime) * math.rad(shakeConfig.rotation) * fade
		camera.CFrame = camera.CFrame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, roll)
	end)
end

function resolveCameraShakeConfig(cameraShake)
	if typeof(cameraShake) ~= "table" then
		return {
			duration = 0.32,
			amplitude = 0.12,
			frequency = 20,
			rotation = 0.8,
			fadeOut = true,
		}
	end

	return {
		duration = cameraShake.duration or 0.32,
		amplitude = cameraShake.amplitude or 0.12,
		frequency = cameraShake.frequency or 20,
		rotation = cameraShake.rotation or 0.8,
		fadeOut = cameraShake.fadeOut ~= false,
	}
end

function clearCoinVisual(seatId)
	local visual = activeCoinFlipVisuals[seatId]
	if not visual then
		return
	end

	activeCoinFlipVisuals[seatId] = nil
	if visual.connection then
		visual.connection:Disconnect()
	end
	if visual.settleTween then
		visual.settleTween:Cancel()
	end
	if visual.settleConnection then
		visual.settleConnection:Disconnect()
	end
	if visual.settleCFrame then
		visual.settleCFrame:Destroy()
	end
	if visual.shouldFollowCamera then
		FirstPersonCamera.ReturnToFirstPerson(visual.focusPart)
	end
	visual.shadow.Size = visual.baseShadowSize
	hidePulseVisual(visual.landingPulse)
	hidePulseVisual(visual.streakPulse)
	if visual.clonedCoinObject then
		visual.coin:Destroy()
		setCoinObjectEnabled(visual.fallbackCoin, visual.shadow, false)
	else
		setCoinObjectEnabled(visual.coin, visual.shadow, false)
	end
end

return EffectSystem
