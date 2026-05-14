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

---- [[ UI ]] ----
local PlayerGui, Main, uiController

local EffectSystem: Types.System = {
	whiteList = {
		"PlayInsideEffects",
		"ToggleInsideEffects",
		"PlayCoinFlipVisual",
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

	local visualModel, coin, shadow, landingPulse, streakPulse = getCoinVisual(seatId)
	if not visualModel or not coin or not shadow or not landingPulse or not streakPulse then
		if landedCallback then
			landedCallback()
		end
		return
	end

	clearCoinVisual(seatId)
	local coinObject, clonedCoinObject = createCoinObject(visualModel, coin, args and args.coinId)
	local baseCoinSize = getCoinObjectSize(coinObject)
	local baseShadowSize = shadow.Size
	local result = args.result
	local finalRotation = math.rad(VisualConfig.SpinTurns * 360) + (result == "Tails" and math.pi or 0)
	local airborneRotation = math.rad((VisualConfig.SpinTurns + 0.35) * 360) + (result == "Tails" and math.pi or 0)
	local finalObjectRotation = CFrame.Angles(finalRotation, 0, math.rad(90))
	local startPos, endPos, tableNormal, surfaceEndPos = getFlipPositions(seatId, coinObject, finalObjectRotation)
	if not startPos or not endPos or not tableNormal or not surfaceEndPos then
		if clonedCoinObject then
			coinObject:Destroy()
		else
			setCoinObjectEnabled(coin, nil, false)
		end
		if landedCallback then
			landedCallback()
		end
		return
	end

	shadow.Size = baseShadowSize
	shadow.Transparency = VisualConfig.ShadowBaseTransparency

	local visual = {
		model = visualModel,
		coin = coinObject,
		focusPart = coin,
		fallbackCoin = coin,
		clonedCoinObject = clonedCoinObject,
		shadow = shadow,
		landingPulse = landingPulse,
		streakPulse = streakPulse,
		baseShadowSize = baseShadowSize,
		shouldFollowCamera = args.shouldFollowCamera == true,
	}
	activeCoinFlipVisuals[seatId] = visual

	local startTime = os.clock()
	local arcHeight =
		math.max(VisualConfig.ArcHeight, (startPos - endPos).Magnitude * VisualConfig.ArcHeightTravelFactor)
	local travel = endPos - startPos
	local airborneDuration = VisualConfig.TravelDuration
	local shadowPos = surfaceEndPos + (tableNormal * ((baseShadowSize.X * 0.5) + VisualConfig.ShadowSurfaceGap))
	local visualOptions = args.visualOptions
	local observedStreak = visualOptions and (visualOptions.streak or 0) or 0
	local shouldShowObservedStreakPulse = visualOptions
		and visualOptions.isObserved == true
		and result == "Heads"
		and observedStreak >= VisualConfig.StreakPulseMinimum

	pivotCoinVisual(visual, CFrame.new(startPos) * CFrame.Angles(0, 0, math.rad(90)))
	shadow.CFrame = CFrame.new(startPos.X, shadowPos.Y, startPos.Z) * CFrame.Angles(0, 0, math.rad(90))
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
		local position = startPos + (travel * alpha) + Vector3.new(0, height, 0)
		local flipAngle = airborneRotation * alpha
		local bankAngle = math.sin(alpha * math.pi) * VisualConfig.BankAngle
		local shadowAlpha = math.clamp(height / arcHeight, 0, 1)
		local shadowScale = VisualConfig.ShadowMaxScale
			- ((VisualConfig.ShadowMaxScale - VisualConfig.ShadowMinScale) * shadowAlpha)
		local shadowTransparency = VisualConfig.ShadowBaseTransparency
			+ ((VisualConfig.ShadowMaxTransparency - VisualConfig.ShadowBaseTransparency) * shadowAlpha)

		local coinCFrame = CFrame.new(position)
			* CFrame.Angles(flipAngle, 0, math.rad(90))
			* CFrame.Angles(0, bankAngle, 0)
		pivotCoinVisual(visual, coinCFrame)
		shadow.CFrame = CFrame.new(position.X, shadowPos.Y, position.Z) * CFrame.Angles(0, 0, math.rad(90))
		shadow.Size = Vector3.new(baseShadowSize.X, baseCoinSize.Y * shadowScale, baseCoinSize.Z * shadowScale)
		shadow.Transparency = shadowTransparency

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil

		local pulseColor = result == "Heads" and VisualConfig.HeadsPulseColor or VisualConfig.TailsPulseColor
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
				Value = CFrame.new(endPos) * finalObjectRotation,
			}
		)
		visual.settleTween = settleTween
		settleTween:Play()

		local shadowTween = TweenService:Create(
			shadow,
			TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(shadowPos) * CFrame.Angles(0, 0, math.rad(90)),
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
			if visual.shouldFollowCamera then
				FirstPersonCamera.ReturnToFirstPerson(visual.focusPart)
			end
			if landedCallback then
				task.delay(VisualConfig.ResultRevealDelay or 0, landedCallback)
			end
			task.delay(VisualConfig.CleanupDelay, function()
				local latestVisual = activeCoinFlipVisuals[seatId]
				if latestVisual == visual then
					clearCoinVisual(seatId)
				end
			end)
		end)
	end)
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
	local assets = tableModel and tableModel:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("CoinVisuals") or nil
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

function getFlipPositions(seatId, coinObject, finalObjectRotation)
	local seatRecord = getSeatRecord(seatId)
	local tableModel = seatRecord and seatRecord.tableModel or getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return nil, nil, nil, nil
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
		return nil, nil, nil, nil
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + (tableNormal * halfThickness)
	local centerPos = centerAttachment and centerAttachment.WorldPosition or surfaceCenter
	local outward = startPos - surfaceCenter
	outward = outward - (tableNormal * outward:Dot(tableNormal))
	if outward.Magnitude < 0.001 then
		outward = Vector3.new(1, 0, 0)
	else
		outward = outward.Unit
	end

	local surfaceEndPos = centerPos + (outward * VisualConfig.LandingRadius)
	local surfaceLift = getObjectSurfaceLift(coinObject, CFrame.new() * finalObjectRotation, tableNormal)
	local endPos = surfaceEndPos + (tableNormal * (surfaceLift + VisualConfig.CoinSurfaceGap))

	return startPos, endPos, tableNormal, surfaceEndPos
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
	if visual.focusPart ~= visual.coin then
		visual.focusPart.CFrame = targetCFrame
	end
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
