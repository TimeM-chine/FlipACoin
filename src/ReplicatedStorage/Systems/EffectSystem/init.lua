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
local UserInputService = game:GetService("UserInputService")

---- requires ----
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass
local tableReactionCooldowns = {}

---- client variables ----
local LocalPlayer
local FirstPersonCamera
local activeCoinFlipVisuals = {}
local VisualConfig = Presets.CoinFlipVisuals
local SceneInteractionConfig = Presets.SceneInteractions
local CoinAssetFolderName = "Coins"
local missingCoinAssetWarnings = {}
local cameraShakeToken = 0
local CameraShakeRenderStepName = "StreakMilestoneCameraShake"
local sceneInteractionConnection
local activeDecorationShakes = {}
local activeHotStreakSpotlights = {}
local lastTableTapTime = 0
local missingHotStreakSpotlightWarningShown = false

-- 旧硬币 / 阴影模板的基准朝向；真实硬币空中姿态由最终平铺姿态反推，避免绕竖直轴自旋
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
		"PlayerRemoving",
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
		setupSceneInteractions()
	end
end

function EffectSystem:PlayerRemoving(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		tableReactionCooldowns[player.UserId] = nil
	else
		--
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

function EffectSystem:RequestTableReaction(sender, player, args)
	if IsServer then
		player = player or sender
		if sender ~= player or not player or not player:IsA("Player") or not player:IsDescendantOf(Players) then
			return
		end

		local seatId = SystemMgr.systems.TableSeatSystem:GetPlayerSeatId(player)
		if not seatId then
			return
		end

		local now = os.clock()
		if now - (tableReactionCooldowns[player.UserId] or 0) < SceneInteractionConfig.TableReactionCooldown then
			return
		end
		tableReactionCooldowns[player.UserId] = now

		self.AllClients:PlayTableReaction({
			unreliable = true,
			seatId = seatId,
			actorUserId = player.UserId,
		})
	else
		--
	end
end

function EffectSystem:PlayTableReaction(sender, player, args)
	if IsServer then
		return
	end
	if typeof(args) ~= "table" or args.actorUserId == LocalPlayer.UserId then
		return
	end
	if typeof(args.seatId) ~= "string" then
		return
	end

	local _, _, tableNormal, surfaceEndPos = getFlipPositions(args.seatId)
	if not tableNormal or not surfaceEndPos then
		return
	end

	playSfx(SceneInteractionConfig.TableTapSoundName)
	playTableTapRipple(surfaceEndPos, tableNormal)
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
		return visual
	end
	if getVisualCoinCount(args) > 1 then
		return playMultiCoinFlipVisual(visual, seatId, args)
	end
	clearTransientCoinVisuals(visual)

	local coinObject = visual.coin
	local shadow = visual.shadow
	local landingPulse = visual.landingPulse
	local streakPulse = visual.streakPulse
	local baseCoinSize = getCoinObjectSize(coinObject)
	local baseShadowSize = shadow.Size
	local result = args.result == "Tails" and "Tails" or "Heads"
	local edgeStand = args.edgeStand == true
	local restSpinRadians = getRandomRestSpinRadians()
	local finalRotation = math.rad(VisualConfig.SpinTurns * 360) + (result == "Tails" and math.pi or 0)
	local airborneRotation = finalRotation
	local startPos, endPos, tableNormal, surfaceEndPos, flipAxisWorld = getFlipPositions(seatId)
	if not startPos or not endPos or not tableNormal or not surfaceEndPos then
		hidePersistentCoinVisual(visual)
		if landedCallback then
			landedCallback()
		end
		return
	end
	local flatWorldRot = if edgeStand
		then buildEdgeStandCoinWorldRotation(tableNormal, flipAxisWorld, restSpinRadians)
		else buildFlatCoinWorldRotation(tableNormal, flipAxisWorld, result, restSpinRadians)
	local endPosFlat = resolveFlatLandWorldPosition(surfaceEndPos, tableNormal, flatWorldRot, visual.coin)
	startPos = endPosFlat
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
	local isObservedFlip = visualOptions and visualOptions.isObserved == true
	local isObservedMilestone = visualOptions and visualOptions.isMilestone == true
	local observedStreak = visualOptions and (visualOptions.streak or 0) or 0
	local edgeStandCoinIndex = args.edgeStand == true and args.edgeStandCoinIndex or nil
	local shouldPlayResultSfx = not visualOptions or visualOptions.playResultSfx ~= false
	local shouldShowObservedStreakPulse = isObservedFlip
		and result == "Heads"
		and (observedStreak >= VisualConfig.StreakPulseMinimum or isObservedMilestone)
	local shouldShowObservedHighlight = isObservedFlip
		and not isObservedMilestone
		and observedStreak >= VisualConfig.ObservedHighlightMinimum
	local shouldShowEdgeStandHighlight = edgeStand

	local startWorldRot =
		buildAirborneCoinWorldRotation(tableNormal, flipAxisWorld, bankReference, 0, finalRotation, 0, flatWorldRot)
	pivotCoinVisual(visual, CFrame.new(startPos) * startWorldRot)
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
			finalRotation,
			bankAngle,
			flatWorldRot
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

		local pulseColor = getLandingPulseColor(result, isObservedFlip)
		local landingPulseOptions = getLandingPulseOptions(result, isObservedFlip)
		playSfx("coinLand")
		playLandingPulse(landingPulse, shadowPos, pulseColor, landingPulseOptions)
		playCoinLandingBurst(surfaceEndPos, tableNormal, result)
		if shouldShowObservedStreakPulse then
			playLandingPulse(streakPulse, shadowPos, VisualConfig.StreakPulseColor, {
				startSize = VisualConfig.StreakPulseStartSize,
				endSize = getObservedStreakPulseEndSize(observedStreak),
				duration = VisualConfig.StreakPulseDuration,
				transparency = 0.22,
			})
		end
		if shouldShowObservedHighlight then
			playCoinVisualHighlight(seatId, visual, {
				duration = VisualConfig.ObservedHighlightDuration,
				fillColor = VisualConfig.ObservedHighlightFillColor,
				outlineColor = VisualConfig.ObservedHighlightOutlineColor,
				fillTransparency = VisualConfig.ObservedHighlightFillTransparency,
				outlineTransparency = VisualConfig.ObservedHighlightOutlineTransparency,
			})
		end
		if shouldShowEdgeStandHighlight then
			playCoinVisualHighlight(seatId, visual, {
				duration = VisualConfig.MilestoneHighlightDuration,
				fillColor = VisualConfig.MilestoneHighlightFillColor,
				outlineColor = VisualConfig.MilestoneHighlightOutlineColor,
				fillTransparency = VisualConfig.MilestoneHighlightFillTransparency,
				outlineTransparency = VisualConfig.MilestoneHighlightOutlineTransparency,
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
			if shouldPlayResultSfx then
				playSfx(result == "Heads" and "headsWin" or "tailsLose")
			end
			refreshPendingCoinVisual(visual, seatId)
			if landedCallback then
				task.delay(VisualConfig.ResultRevealDelay or 0, landedCallback)
			end
		end)
	end)

	return visual
end

function playMultiCoinFlipVisual(visual, seatId, args)
	args = args or {}
	local landedCallback = args and args.landedCallback
	local coinCount = getVisualCoinCount(args)
	local primaryIndex = getPrimaryVisualCoinIndex(args, coinCount)
	local states = {}
	local visualOptions = args.visualOptions
	local overallResult = args.result == "Tails" and "Tails" or "Heads"
	local isObservedFlip = visualOptions and visualOptions.isObserved == true
	local isObservedMilestone = visualOptions and visualOptions.isMilestone == true
	local observedStreak = visualOptions and (visualOptions.streak or 0) or 0
	local shouldPlayResultSfx = not visualOptions or visualOptions.playResultSfx ~= false
	local shouldShowObservedStreakPulse = isObservedFlip
		and overallResult == "Heads"
		and (observedStreak >= VisualConfig.StreakPulseMinimum or isObservedMilestone)
	local shouldShowObservedHighlight = isObservedFlip
		and not isObservedMilestone
		and observedStreak >= VisualConfig.ObservedHighlightMinimum

	clearTransientCoinVisuals(visual)

	for coinIndex = 1, coinCount do
		local coinVisual = visual
		if coinIndex ~= primaryIndex then
			coinVisual = createTransientCoinVisual(visual, args and args.coinId)
			if coinVisual then
				visual.transientCoinVisuals = visual.transientCoinVisuals or {}
				table.insert(visual.transientCoinVisuals, coinVisual)
			end
		end
		if not coinVisual then
			continue
		end

		applyTemporaryMultiCoinScale(coinVisual, coinCount)
		local result = getVisualCoinResult(args, coinIndex)
		local edgeStand = coinIndex == edgeStandCoinIndex
		local restSpinRadians = getRandomRestSpinRadians()
		local finalRotation = math.rad(VisualConfig.SpinTurns * 360) + (result == "Tails" and math.pi or 0)
		local startPos, endPos, tableNormal, surfaceEndPos, flipAxisWorld =
			getFlipPositions(seatId, coinIndex, coinCount)
		if not startPos or not endPos or not tableNormal or not surfaceEndPos or not flipAxisWorld then
			clearTransientCoinVisuals(visual)
			hidePersistentCoinVisual(visual)
			if landedCallback then
				landedCallback()
			end
			return visual
		end

		local baseCoinSize = getCoinObjectSize(coinVisual.coin)
		local baseShadowSize = coinVisual.shadow.Size
		local flatWorldRot = if edgeStand
			then buildEdgeStandCoinWorldRotation(tableNormal, flipAxisWorld, restSpinRadians)
			else buildFlatCoinWorldRotation(tableNormal, flipAxisWorld, result, restSpinRadians)
		local endPosFlat = resolveFlatLandWorldPosition(surfaceEndPos, tableNormal, flatWorldRot, coinVisual.coin)
		local travel = endPosFlat - startPos
		local arcHeight = math.max(VisualConfig.ArcHeight, travel.Magnitude * VisualConfig.ArcHeightTravelFactor)
		local travelFlat = travel - tableNormal * travel:Dot(tableNormal)
		local bankReference = travelFlat.Magnitude > 1e-4 and travelFlat.Unit or flipAxisWorld:Cross(tableNormal).Unit
		local shadowPos = surfaceEndPos + (tableNormal * ((baseShadowSize.X * 0.5) + VisualConfig.ShadowSurfaceGap))

		coinVisual.shadow.Size = baseShadowSize
		coinVisual.shadow.Transparency = VisualConfig.ShadowBaseTransparency
		coinVisual.baseShadowSize = baseShadowSize

		local startWorldRot =
			buildAirborneCoinWorldRotation(tableNormal, flipAxisWorld, bankReference, 0, finalRotation, 0, flatWorldRot)
		pivotCoinVisual(coinVisual, CFrame.new(startPos) * startWorldRot)
		coinVisual.shadow.CFrame = CFrame.new(startPos.X, shadowPos.Y, startPos.Z) * CoinVisualBaseRot

		table.insert(states, {
			coinVisual = coinVisual,
			result = result,
			restSpinRadians = restSpinRadians,
			finalRotation = finalRotation,
			startPos = startPos,
			endPosFlat = endPosFlat,
			tableNormal = tableNormal,
			surfaceEndPos = surfaceEndPos,
			flipAxisWorld = flipAxisWorld,
			flatWorldRot = flatWorldRot,
			travel = travel,
			arcHeight = arcHeight,
			bankReference = bankReference,
			baseCoinSize = baseCoinSize,
			baseShadowSize = baseShadowSize,
			shadowPos = shadowPos,
			edgeStand = edgeStand,
			isPrimary = coinVisual == visual,
		})
	end

	if #states == 0 then
		if landedCallback then
			landedCallback()
		end
		return visual
	end

	visual.shouldFollowCamera = args.shouldFollowCamera == true
	visual.isFlipping = true

	local startTime = os.clock()
	local airborneDuration = VisualConfig.TravelDuration
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
		for _, state in ipairs(states) do
			local height = math.sin(alpha * math.pi) * state.arcHeight
			local position = state.startPos + (state.travel * alpha) + state.tableNormal * height
			local flipAngle = state.finalRotation * alpha
			local bankAngle = math.sin(alpha * math.pi) * VisualConfig.BankAngle
			local shadowAlpha = math.clamp(height / state.arcHeight, 0, 1)
			local shadowScale = VisualConfig.ShadowMaxScale
				- ((VisualConfig.ShadowMaxScale - VisualConfig.ShadowMinScale) * shadowAlpha)
			local shadowTransparency = VisualConfig.ShadowBaseTransparency
				+ ((VisualConfig.ShadowMaxTransparency - VisualConfig.ShadowBaseTransparency) * shadowAlpha)
			local coinWorldRot = buildAirborneCoinWorldRotation(
				state.tableNormal,
				state.flipAxisWorld,
				state.bankReference,
				flipAngle,
				state.finalRotation,
				bankAngle,
				state.flatWorldRot
			)
			local coinCFrame = CFrame.new(position) * coinWorldRot
			pivotCoinVisual(state.coinVisual, coinCFrame)
			state.coinVisual.shadow.CFrame = CFrame.new(position.X, state.shadowPos.Y, position.Z) * CoinVisualBaseRot
			state.coinVisual.shadow.Size = Vector3.new(
				state.baseShadowSize.X,
				state.baseCoinSize.Y * shadowScale,
				state.baseCoinSize.Z * shadowScale
			)
			state.coinVisual.shadow.Transparency = shadowTransparency
		end

		if alpha < 1 then
			return
		end

		visual.connection:Disconnect()
		visual.connection = nil
		playSfx("coinLand")

		for _, state in ipairs(states) do
			local pulseColor = getLandingPulseColor(state.result, isObservedFlip)
			local landingPulseOptions = getLandingPulseOptions(state.result, isObservedFlip)
			playLandingPulse(state.coinVisual.landingPulse, state.shadowPos, pulseColor, landingPulseOptions)
			playCoinLandingBurst(state.surfaceEndPos, state.tableNormal, state.result)
			if state.edgeStand then
				playCoinVisualHighlight(seatId, state.coinVisual, {
					duration = VisualConfig.MilestoneHighlightDuration,
					fillColor = VisualConfig.MilestoneHighlightFillColor,
					outlineColor = VisualConfig.MilestoneHighlightOutlineColor,
					fillTransparency = VisualConfig.MilestoneHighlightFillTransparency,
					outlineTransparency = VisualConfig.MilestoneHighlightOutlineTransparency,
				})
			end
		end
		if shouldShowObservedStreakPulse then
			local primaryState = getPrimaryMultiCoinState(states)
			playLandingPulse(
				primaryState.coinVisual.streakPulse,
				primaryState.shadowPos,
				VisualConfig.StreakPulseColor,
				{
					startSize = VisualConfig.StreakPulseStartSize,
					endSize = getObservedStreakPulseEndSize(observedStreak),
					duration = VisualConfig.StreakPulseDuration,
					transparency = 0.22,
				}
			)
		end
		if shouldShowObservedHighlight then
			playCoinVisualHighlight(seatId, visual, {
				duration = VisualConfig.ObservedHighlightDuration,
				fillColor = VisualConfig.ObservedHighlightFillColor,
				outlineColor = VisualConfig.ObservedHighlightOutlineColor,
				fillTransparency = VisualConfig.ObservedHighlightFillTransparency,
				outlineTransparency = VisualConfig.ObservedHighlightOutlineTransparency,
			})
		end

		local completedSettles = 0
		local function finishSettle()
			completedSettles += 1
			if completedSettles < #states then
				return
			end

			local primaryState = getPrimaryMultiCoinState(states)
			visual.isFlipping = false
			visual.lastResult = overallResult
			visual.lastRestSpinRadians = primaryState.restSpinRadians
			if visual.shouldFollowCamera then
				FirstPersonCamera.ReturnToFirstPerson(visual.focusPart)
			end
			visual.shouldFollowCamera = false
			if shouldPlayResultSfx then
				playSfx(overallResult == "Heads" and "headsWin" or "tailsLose")
			end
			refreshPendingCoinVisual(visual, seatId)
			if landedCallback then
				task.delay(VisualConfig.ResultRevealDelay or 0, landedCallback)
			end
		end

		for _, state in ipairs(states) do
			local settleCFrame = Instance.new("CFrameValue")
			settleCFrame.Value = getCoinObjectPivot(state.coinVisual.coin)
			state.settleCFrame = settleCFrame
			state.settleConnection = settleCFrame:GetPropertyChangedSignal("Value"):Connect(function()
				pivotCoinVisual(state.coinVisual, settleCFrame.Value)
			end)
			if state.isPrimary then
				visual.settleCFrame = settleCFrame
				visual.settleConnection = state.settleConnection
			end

			local settleTween = TweenService:Create(
				settleCFrame,
				TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Value = CFrame.new(state.endPosFlat) * state.flatWorldRot,
				}
			)
			state.settleTween = settleTween
			if state.isPrimary then
				visual.settleTween = settleTween
			end
			settleTween:Play()

			local shadowEndFlat = Vector3.new(state.endPosFlat.X, state.shadowPos.Y, state.endPosFlat.Z)
			local shadowTween = TweenService:Create(
				state.coinVisual.shadow,
				TweenInfo.new(VisualConfig.LandingDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					CFrame = CFrame.new(shadowEndFlat) * CoinVisualBaseRot,
					Size = state.baseShadowSize,
					Transparency = VisualConfig.ShadowBaseTransparency,
				}
			)
			shadowTween:Play()

			settleTween.Completed:Once(function(playbackState)
				if playbackState ~= Enum.PlaybackState.Completed then
					return
				end
				if state.settleConnection then
					state.settleConnection:Disconnect()
					state.settleConnection = nil
				end
				if state.settleCFrame then
					state.settleCFrame:Destroy()
					state.settleCFrame = nil
				end
				state.settleTween = nil
				if state.isPrimary then
					visual.settleConnection = nil
					visual.settleCFrame = nil
					visual.settleTween = nil
				end
				finishSettle()
			end)
		end
	end)

	return visual
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
			if visual and not visual.isFlipping and not visual.transientCoinVisuals then
				placePersistentCoinAtRest(visual, entry.seatId, visual.lastResult)
			elseif visual then
				visual.pendingCoinId = entry.equippedCoin or visual.pendingCoinId
			end
		end
	end
	refreshHotStreakSpotlights(args.seatDisplayEntries)

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

	if args.suppressSfx ~= true then
		playSfx(args.sfx)
	end
	local playedVfx = playStreakMilestoneVfx(args.seatId, args.vfx, args.lifeTime)
	if playedVfx then
		playCoinVisualHighlight(args.seatId, activeCoinFlipVisuals[args.seatId], {
			duration = VisualConfig.MilestoneHighlightDuration,
			fillColor = VisualConfig.MilestoneHighlightFillColor,
			outlineColor = VisualConfig.MilestoneHighlightOutlineColor,
			fillTransparency = VisualConfig.MilestoneHighlightFillTransparency,
			outlineTransparency = VisualConfig.MilestoneHighlightOutlineTransparency,
		})
	else
		playStreakMilestoneFallback(args.seatId, args.streak)
	end
	if args.suppressCameraShake ~= true then
		playConfiguredCameraShake(args.cameraShake)
	end
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

function getFlipPositions(seatId, coinIndex, coinCount)
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
	local actorStartPos = startPos
	local outward = startPos - surfaceCenter
	outward = outward - (tableNormal * outward:Dot(tableNormal))
	if outward.Magnitude < 0.001 then
		outward = Vector3.new(1, 0, 0)
	else
		outward = outward.Unit
	end

	local rawSeatId = seatRecord and seatRecord.rawSeatId or seatId
	local landingAnchor = getCoinLandingAnchor(tableModel, rawSeatId)
	local landingAnchorPosition = landingAnchor and getAnchorPosition(landingAnchor)
	local surfaceEndPos = centerPos + (outward * VisualConfig.LandingRadius)
	if dynamicSeatCFrame then
		surfaceEndPos = getDynamicCoinLandingSurfacePosition(dynamicSeatCFrame, tableTop, tableNormal, surfaceCenter)
	elseif landingAnchorPosition then
		surfaceEndPos = landingAnchorPosition - tableNormal * (landingAnchorPosition - surfaceCenter):Dot(tableNormal)
	end
	if coinCount and coinCount > 1 and coinIndex then
		surfaceEndPos = getFanSurfaceEndPosition(actorStartPos, surfaceEndPos, tableNormal, coinIndex, coinCount)
	end

	local landingOutward = surfaceEndPos - surfaceCenter
	landingOutward = landingOutward - (tableNormal * landingOutward:Dot(tableNormal))
	if landingOutward.Magnitude < 0.001 then
		landingOutward = outward
	else
		landingOutward = landingOutward.Unit
	end

	local flipAxisWorld = landingOutward:Cross(tableNormal)
	if flipAxisWorld.Magnitude < 1e-4 then
		flipAxisWorld = Vector3.new(0, 0, 1)
	else
		flipAxisWorld = flipAxisWorld.Unit
	end

	local endPos = surfaceEndPos
	if not coinCount or coinCount <= 1 then
		startPos = surfaceEndPos
	end

	return startPos, endPos, tableNormal, surfaceEndPos, flipAxisWorld
end

function getFanSurfaceEndPosition(actorStartPos, centerSurfaceEndPos, tableNormal, coinIndex, coinCount)
	local n = tableNormal.Unit
	local actorSurfacePos = actorStartPos - n * (actorStartPos - centerSurfaceEndPos):Dot(n)
	local centerAxis = projectVectorToPlane(centerSurfaceEndPos - actorSurfacePos, n)
	if centerAxis.Magnitude < 0.001 then
		return centerSurfaceEndPos
	end

	local maxIndexOffset = math.max((coinCount - 1) * 0.5, 1)
	local angleStep = math.min(VisualConfig.MultiCoinFanAngleStep, VisualConfig.MultiCoinFanMaxAngle / maxIndexOffset)
	local angleOffset = (coinIndex - ((coinCount + 1) * 0.5)) * angleStep
	local rotatedAxis = CFrame.fromAxisAngle(n, angleOffset):VectorToWorldSpace(centerAxis.Unit)
	return actorSurfacePos + rotatedAxis * centerAxis.Magnitude
end

function getDynamicCoinLandingSurfacePosition(seatCFrame, tableTop, tableNormal, surfaceCenter)
	local inward = seatCFrame.LookVector - tableNormal * seatCFrame.LookVector:Dot(tableNormal)
	if inward.Magnitude < 0.001 then
		inward = (surfaceCenter - seatCFrame.Position)
			- tableNormal * (surfaceCenter - seatCFrame.Position):Dot(tableNormal)
	end
	if inward.Magnitude < 0.001 then
		inward = tableTop.CFrame.LookVector
	else
		inward = inward.Unit
	end

	local rawPosition = seatCFrame.Position + inward * 2.55
	return rawPosition - tableNormal * (rawPosition - surfaceCenter):Dot(tableNormal)
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
			clearTransientCoinVisuals(visual)
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
	local _, _, tableNormal, surfaceEndPos, flipAxisWorld = getFlipPositions(seatId)
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
	clearTransientCoinVisuals(visual)
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

function getVisualCoinCount(args)
	local coinCount = tonumber(args and args.coinCount) or 1
	local coinResults = args and args.coinResults
	if typeof(coinResults) == "table" then
		coinCount = math.max(coinCount, #coinResults)
	end

	return math.clamp(math.floor(coinCount), 1, VisualConfig.MultiCoinMaxCount)
end

function getMultiCoinVisualScale(coinCount)
	local scaleByCount = VisualConfig.MultiCoinScaleByCount
	return scaleByCount and scaleByCount[coinCount] or 1
end

function applyTemporaryMultiCoinScale(coinVisual, coinCount)
	local scale = getMultiCoinVisualScale(coinCount)
	if scale >= 0.999 then
		return
	end
	if coinVisual.multiCoinScaleApplied then
		return
	end

	local coinObject = coinVisual.coin
	if coinObject:IsA("Model") then
		coinVisual.originalCoinScale = coinObject:GetScale()
		coinObject:ScaleTo(coinVisual.originalCoinScale * scale)
	elseif coinObject:IsA("BasePart") then
		coinVisual.originalCoinSize = coinObject.Size
		coinObject.Size = coinObject.Size * scale
	end
	coinVisual.multiCoinScaleApplied = true
end

function restoreTemporaryMultiCoinScale(coinVisual)
	if not coinVisual.multiCoinScaleApplied then
		return
	end

	local coinObject = coinVisual.coin
	if coinObject:IsA("Model") and coinVisual.originalCoinScale then
		coinObject:ScaleTo(coinVisual.originalCoinScale)
	elseif coinObject:IsA("BasePart") and coinVisual.originalCoinSize then
		coinObject.Size = coinVisual.originalCoinSize
	end
	coinVisual.multiCoinScaleApplied = nil
	coinVisual.originalCoinScale = nil
	coinVisual.originalCoinSize = nil
end

function getVisualCoinResult(args, coinIndex)
	local coinResults = args and args.coinResults
	local result = typeof(coinResults) == "table" and coinResults[coinIndex] or nil
	if result == "Tails" then
		return "Tails"
	end
	if result == "Heads" then
		return "Heads"
	end

	return args and args.result == "Tails" and "Tails" or "Heads"
end

function getPrimaryVisualCoinIndex(args, coinCount)
	local overallResult = args and args.result == "Tails" and "Tails" or "Heads"
	local centerIndex = (coinCount + 1) * 0.5
	local primaryIndex = math.clamp(math.round(centerIndex), 1, coinCount)
	local bestDistance = math.huge

	for coinIndex = 1, coinCount do
		if getVisualCoinResult(args, coinIndex) == overallResult then
			local distance = math.abs(coinIndex - centerIndex)
			if distance < bestDistance then
				bestDistance = distance
				primaryIndex = coinIndex
			end
		end
	end

	return primaryIndex
end

function getPrimaryMultiCoinState(states)
	for _, state in ipairs(states) do
		if state.isPrimary then
			return state
		end
	end

	return states[1]
end

function createTransientCoinVisual(baseVisual, coinId)
	local coinObject = cloneCoinObjectForTransient(baseVisual, coinId)
	if not coinObject then
		return nil
	end

	local shadow = baseVisual.shadow:Clone()
	shadow.Name = "TransientShadow"
	shadow.Parent = baseVisual.shadow.Parent
	local landingPulse = baseVisual.landingPulse:Clone()
	landingPulse.Name = "TransientLandingPulse"
	landingPulse.Parent = baseVisual.landingPulse.Parent
	local streakPulse = baseVisual.streakPulse:Clone()
	streakPulse.Name = "TransientStreakPulse"
	streakPulse.Parent = baseVisual.streakPulse.Parent

	local coinVisual = {
		coin = coinObject,
		shadow = shadow,
		landingPulse = landingPulse,
		streakPulse = streakPulse,
		focusPart = getTransientCoinFocusPart(coinObject),
		baseShadowSize = shadow.Size,
		isTransient = true,
	}
	setCoinObjectEnabled(coinObject, shadow, true)
	hidePulseVisual(landingPulse)
	hidePulseVisual(streakPulse)

	return coinVisual
end

function cloneCoinObjectForTransient(baseVisual, coinId)
	local asset = getEquippedCoinAsset(coinId)
	local source = asset or baseVisual.fallbackCoin
	if not source then
		return nil
	end

	local coinObject = source:Clone()
	coinObject.Name = "TransientCoinVisual"
	prepareCoinObject(coinObject)
	coinObject.Parent = baseVisual.model
	return coinObject
end

function getTransientCoinFocusPart(coinObject)
	if coinObject:IsA("BasePart") then
		return coinObject
	end
	if coinObject:IsA("Model") and coinObject.PrimaryPart then
		return coinObject.PrimaryPart
	end

	return getCoinObjectParts(coinObject)[1]
end

function clearTransientCoinVisuals(visual)
	restoreTemporaryMultiCoinScale(visual)
	if not visual.transientCoinVisuals then
		return
	end

	for _, transient in ipairs(visual.transientCoinVisuals) do
		restoreTemporaryMultiCoinScale(transient)
		if transient.settleTween then
			transient.settleTween:Cancel()
			transient.settleTween = nil
		end
		if transient.settleConnection then
			transient.settleConnection:Disconnect()
			transient.settleConnection = nil
		end
		if transient.settleCFrame then
			transient.settleCFrame:Destroy()
			transient.settleCFrame = nil
		end
		if transient.coin and transient.coin.Parent then
			transient.coin:Destroy()
		end
		if transient.shadow and transient.shadow.Parent then
			transient.shadow:Destroy()
		end
		if transient.landingPulse and transient.landingPulse.Parent then
			transient.landingPulse:Destroy()
		end
		if transient.streakPulse and transient.streakPulse.Parent then
			transient.streakPulse:Destroy()
		end
	end

	visual.transientCoinVisuals = nil
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
		warnMissingCoinAsset(coinId, `Missing CoinFlipSystem.Assets.{CoinAssetFolderName}; using default coin visual.`)
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
	fallbackFlipAxisWorld,
	bankReference,
	flipAngle,
	finalRotation,
	bankAngle,
	finalFlatWorldRot
)
	local n = tableNormal.Unit
	local flipAxisWorld = projectVectorToPlane(finalFlatWorldRot.RightVector, n)
	if flipAxisWorld.Magnitude < 1e-4 then
		flipAxisWorld = fallbackFlipAxisWorld
	else
		flipAxisWorld = flipAxisWorld.Unit
	end

	local remainingFlipAngle = finalRotation - flipAngle
	local airborneRot = CFrame.fromAxisAngle(flipAxisWorld, -remainingFlipAngle) * finalFlatWorldRot
	local bankAxis = projectVectorToPlane(bankReference, n)
	if bankAxis.Magnitude < 1e-4 then
		return airborneRot
	end

	return CFrame.fromAxisAngle(bankAxis.Unit, bankAngle) * airborneRot
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

function buildEdgeStandCoinWorldRotation(tableNormal, flipAxisWorld, restSpinRadians)
	local n = tableNormal.Unit
	local u = projectVectorToPlane(flipAxisWorld, n)
	if u.Magnitude < 1e-4 then
		u = n:Cross(Vector3.xAxis)
	end
	if u.Magnitude < 1e-4 then
		u = n:Cross(Vector3.zAxis)
	end

	local yThickness = u.Unit * VisualConfig.FlatThicknessLocalSign
	local z = n:Cross(yThickness).Unit
	local basis = CFrame.fromMatrix(Vector3.zero, n, yThickness, z)
	return CFrame.fromAxisAngle(n, restSpinRadians or 0) * basis
end

function getRandomRestSpinRadians()
	return math.random() * math.pi * 2
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

function getLandingPulseColor(result, isObservedFlip)
	if isObservedFlip and result == "Heads" then
		return VisualConfig.ObservedHeadsPulseColor
	end
	if isObservedFlip then
		return VisualConfig.ObservedTailsPulseColor
	end

	return result == "Heads" and VisualConfig.HeadsPulseColor or VisualConfig.TailsPulseColor
end

function getLandingPulseOptions(result, isObservedFlip)
	if not isObservedFlip then
		return nil
	end
	if result == "Heads" then
		return {
			startSize = VisualConfig.ObservedHeadsPulseStartSize,
			endSize = VisualConfig.ObservedHeadsPulseEndSize,
			duration = VisualConfig.ObservedHeadsPulseDuration,
			transparency = VisualConfig.ObservedHeadsPulseTransparency,
		}
	end

	return {
		startSize = VisualConfig.ObservedTailsPulseStartSize,
		endSize = VisualConfig.ObservedTailsPulseEndSize,
		duration = VisualConfig.ObservedTailsPulseDuration,
		transparency = VisualConfig.ObservedTailsPulseTransparency,
	}
end

function getObservedStreakPulseEndSize(streak)
	local streakOverMinimum = math.max((streak or 0) - VisualConfig.StreakPulseMinimum, 0)
	return VisualConfig.StreakPulseEndSize
		+ math.clamp(streakOverMinimum, 0, 10) * VisualConfig.ObservedStreakPulseGrowth
end

function playCoinVisualHighlight(seatId, visual, options)
	local target = visual and visual.coin or getSeatPart(seatId)
	if not target then
		return
	end

	playHighlightFlash(target, options)
end

function playHighlightFlash(target, options)
	local duration = options and options.duration or VisualConfig.ObservedHighlightDuration
	local highlight = Instance.new("Highlight")
	highlight.Name = "CoinFlipHighlight"
	highlight.Adornee = target
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = options and options.fillColor or VisualConfig.ObservedHighlightFillColor
	highlight.OutlineColor = options and options.outlineColor or VisualConfig.ObservedHighlightOutlineColor
	highlight.FillTransparency = options and options.fillTransparency or VisualConfig.ObservedHighlightFillTransparency
	highlight.OutlineTransparency = options and options.outlineTransparency
		or VisualConfig.ObservedHighlightOutlineTransparency
	highlight.Parent = getEffectRuntimeParent()

	local tween =
		TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FillTransparency = 1,
			OutlineTransparency = 1,
		})
	tween:Play()
	tween.Completed:Once(function()
		highlight:Destroy()
	end)
	Debris:AddItem(highlight, duration + 0.12)
end

function playSfx(soundName)
	return GetSystemMgr().systems.MusicSystem:PlayLocalSfx({
		musicName = soundName,
	})
end

function playTimedSfx(soundName, duration)
	return GetSystemMgr().systems.MusicSystem:PlayTimedLocalSfx({
		musicName = soundName,
		duration = duration,
	})
end

function setupSceneInteractions()
	if sceneInteractionConnection then
		sceneInteractionConnection:Disconnect()
		sceneInteractionConnection = nil
	end

	sceneInteractionConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local result = raycastSceneInteraction(input)
		if not result then
			return
		end

		local decorationModel = getClickedDecorationModel(result.Instance)
		if decorationModel then
			playDecorationInteraction(decorationModel)
			return
		end

		if isTableTopHit(result.Instance) then
			playTableTapInteraction(result.Position, result.Normal)
		end
	end)
end

function raycastSceneInteraction(input)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local pointerPosition = input.Position
	local ray = camera:ScreenPointToRay(pointerPosition.X, pointerPosition.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterDescendants = {}
	if LocalPlayer.Character then
		table.insert(filterDescendants, LocalPlayer.Character)
	end
	local tableModel = getTableModel()
	local coinVisuals = tableModel and tableModel:FindFirstChild("CoinVisuals")
	if coinVisuals then
		table.insert(filterDescendants, coinVisuals)
	end
	rayParams.FilterDescendantsInstances = filterDescendants

	return Workspace:Raycast(ray.Origin, ray.Direction * SceneInteractionConfig.RaycastDistance, rayParams)
end

function getClickedDecorationModel(target)
	local runtimeFolder = getDecorationsRuntimeFolder()
	if not runtimeFolder or not target:IsDescendantOf(runtimeFolder) then
		return nil
	end

	local current = target
	while current and current ~= runtimeFolder do
		if current:IsA("Model") and string.match(current.Name, "Decoration$") then
			return current
		end
		current = current.Parent
	end

	return nil
end

function getDecorationsRuntimeFolder()
	local tableModel = getTableModel()
	local assets = tableModel and tableModel:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("DecorationsRuntime") or nil
end

function isTableTopHit(target)
	local tableModel = getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	return tableTop and (target == tableTop or target:IsDescendantOf(tableTop)) or false
end

function playDecorationInteraction(decorationModel)
	playDecorationShake(decorationModel)
	playHighlightFlash(decorationModel, {
		duration = SceneInteractionConfig.DecorationHighlightDuration,
		fillColor = SceneInteractionConfig.DecorationHighlightFillColor,
		outlineColor = SceneInteractionConfig.DecorationHighlightOutlineColor,
		fillTransparency = SceneInteractionConfig.DecorationHighlightFillTransparency,
		outlineTransparency = SceneInteractionConfig.DecorationHighlightOutlineTransparency,
	})
end

function playDecorationShake(decorationModel)
	if activeDecorationShakes[decorationModel] then
		return
	end
	if not decorationModel.Parent then
		return
	end

	activeDecorationShakes[decorationModel] = true
	local originalPivot = decorationModel:GetPivot()
	local tableNormal = getSceneTableNormal()
	local anchorPoint, tiltAxisX, tiltAxisZ = getDecorationBottomShakeFrame(decorationModel, originalPivot, tableNormal)
	local startTime = os.clock()
	local seed = math.random() * math.pi * 2
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not decorationModel.Parent then
			activeDecorationShakes[decorationModel] = nil
			connection:Disconnect()
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / SceneInteractionConfig.DecorationShakeDuration, 0, 1)
		if alpha >= 1 then
			decorationModel:PivotTo(originalPivot)
			activeDecorationShakes[decorationModel] = nil
			connection:Disconnect()
			return
		end

		local fade = 1 - alpha
		local wave = math.sin(alpha * math.pi * SceneInteractionConfig.DecorationShakeOscillations + seed)
		local counterWave = math.cos(alpha * math.pi * (SceneInteractionConfig.DecorationShakeOscillations + 1) + seed)
		local xRotation = wave * SceneInteractionConfig.DecorationShakeAngle * fade
		local zRotation = counterWave * SceneInteractionConfig.DecorationShakeAngle * 0.72 * fade
		local tiltRotation = CFrame.fromAxisAngle(tiltAxisX, xRotation) * CFrame.fromAxisAngle(tiltAxisZ, zRotation)
		decorationModel:PivotTo(CFrame.new(anchorPoint) * tiltRotation * CFrame.new(-anchorPoint) * originalPivot)
	end)
end

function getSceneTableNormal()
	local tableModel = getTableModel()
	local tableTop = tableModel and tableModel:FindFirstChild("TableTop")
	if tableTop and tableTop:IsA("BasePart") then
		local normal = getTableSurfaceData(tableTop)
		return normal.Unit
	end

	return Vector3.yAxis
end

function getDecorationBottomShakeFrame(decorationModel, modelCFrame, normal)
	local n = normal.Unit
	local xAxis = projectVectorToPlane(modelCFrame.RightVector, n)
	if xAxis.Magnitude < 0.001 then
		xAxis = projectVectorToPlane(modelCFrame.LookVector, n)
	end
	if xAxis.Magnitude < 0.001 then
		xAxis = n:Cross(Vector3.xAxis)
	end
	if xAxis.Magnitude < 0.001 then
		xAxis = n:Cross(Vector3.zAxis)
	end
	xAxis = xAxis.Unit
	local zAxis = n:Cross(xAxis).Unit

	local minX = math.huge
	local maxX = -math.huge
	local minZ = math.huge
	local maxZ = -math.huge
	local minNormal = math.huge

	for _, part in ipairs(getCoinObjectParts(decorationModel)) do
		local halfSize = part.Size * 0.5
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local corner =
						part.CFrame:PointToWorldSpace(Vector3.new(halfSize.X * x, halfSize.Y * y, halfSize.Z * z))
					local xProjection = corner:Dot(xAxis)
					local zProjection = corner:Dot(zAxis)
					minX = math.min(minX, xProjection)
					maxX = math.max(maxX, xProjection)
					minZ = math.min(minZ, zProjection)
					maxZ = math.max(maxZ, zProjection)
					minNormal = math.min(minNormal, corner:Dot(n))
				end
			end
		end
	end

	if minNormal == math.huge then
		return modelCFrame.Position, xAxis, zAxis
	end

	local anchorPoint = xAxis * ((minX + maxX) * 0.5) + zAxis * ((minZ + maxZ) * 0.5) + n * minNormal
	return anchorPoint, xAxis, zAxis
end

function projectVectorToPlane(vector, normal)
	return vector - normal * vector:Dot(normal)
end

function playTableTapInteraction(position, normal)
	local now = os.clock()
	if now - lastTableTapTime < SceneInteractionConfig.TableTapCooldown then
		return
	end
	lastTableTapTime = now

	playSfx(SceneInteractionConfig.TableTapSoundName)
	playTableTapRipple(position, normal)
	EffectSystem.Server:RequestTableReaction()
end

function playTableTapRipple(position, normal)
	local ripple = Instance.new("Part")
	ripple.Name = "TableTapRipple"
	ripple.Shape = Enum.PartType.Cylinder
	ripple.Anchored = true
	ripple.CanCollide = false
	ripple.CanTouch = false
	ripple.CanQuery = false
	ripple.CastShadow = false
	ripple.Material = Enum.Material.Neon
	ripple.Color = SceneInteractionConfig.TableTapRippleColor
	ripple.Transparency = SceneInteractionConfig.TableTapRippleTransparency
	ripple.Size = Vector3.new(
		SceneInteractionConfig.TableTapRippleThickness,
		SceneInteractionConfig.TableTapRippleStartSize,
		SceneInteractionConfig.TableTapRippleStartSize
	)
	ripple.CFrame = getCylinderSurfaceCFrame(position + normal.Unit * 0.045, normal)
	ripple.Parent = getEffectRuntimeParent()

	local tween = TweenService:Create(
		ripple,
		TweenInfo.new(SceneInteractionConfig.TableTapRippleDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(
				SceneInteractionConfig.TableTapRippleThickness,
				SceneInteractionConfig.TableTapRippleEndSize,
				SceneInteractionConfig.TableTapRippleEndSize
			),
			Transparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Once(function()
		ripple:Destroy()
	end)
	Debris:AddItem(ripple, SceneInteractionConfig.TableTapRippleDuration + 0.12)
end

function playCoinLandingBurst(position, normal, result)
	local burstAsset = script.Assets:FindFirstChild(VisualConfig.LandingBurstAssetName)
	if not burstAsset or not burstAsset:IsA("Attachment") then
		return
	end

	local holder = Instance.new("Part")
	holder.Name = "CoinLandingBurst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.CastShadow = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = getCylinderSurfaceCFrame(position + normal.Unit * VisualConfig.LandingBurstSurfaceGap, normal)
	holder.Parent = getEffectRuntimeParent()

	local burst = burstAsset:Clone()
	burst.Parent = holder
	if result == "Tails" then
		tintBurstParticles(burst, Color3.fromRGB(255, 163, 112), Color3.fromRGB(255, 96, 65))
	else
		tintBurstParticles(burst, Color3.fromRGB(255, 238, 142), Color3.fromRGB(255, 182, 67))
	end

	EffectSystem:PlayInsideEffects(holder)
	Debris:AddItem(holder, VisualConfig.LandingBurstLifetime)
end

function tintBurstParticles(container, primaryColor, secondaryColor)
	for _, particle in ipairs(container:GetDescendants()) do
		if particle:IsA("ParticleEmitter") and particle.Name ~= "TableDust" then
			particle.Color = ColorSequence.new(primaryColor, secondaryColor)
		end
	end
end

function getCylinderSurfaceCFrame(position, normal)
	local xVector = normal.Unit
	local yReference = math.abs(xVector:Dot(Vector3.yAxis)) > 0.98 and Vector3.xAxis or Vector3.yAxis
	local zVector = xVector:Cross(yReference).Unit
	local yVector = zVector:Cross(xVector).Unit
	return CFrame.fromMatrix(position, xVector, yVector, zVector)
end

function playStreakMilestoneVfx(seatId, vfxName, lifeTime)
	if typeof(vfxName) ~= "string" or vfxName == "" then
		return false
	end

	local effectAsset = getStreakMilestoneVfxAsset(vfxName)
	if not effectAsset then
		warn(`[EffectSystem] Missing streak milestone VFX asset: {vfxName}`)
		return false
	end

	local targetCFrame = getStreakMilestoneCFrame(seatId)
	local effectClone = buildStreakMilestoneEffectClone(effectAsset, targetCFrame)
	if not effectClone then
		warn(`[EffectSystem] Streak milestone VFX must be a Model, BasePart, Attachment, or Folder: {vfxName}`)
		return false
	end

	effectClone.Parent = getEffectRuntimeParent()
	EffectSystem:PlayInsideEffects(effectClone)
	Debris:AddItem(effectClone, lifeTime or 5)
	return true
end

function playStreakMilestoneFallback(seatId, streak)
	local visual = activeCoinFlipVisuals[seatId] or getOrCreatePersistentCoinVisual(seatId)
	if visual then
		local streakBonus = math.clamp((streak or 0) - 5, 0, 10) * VisualConfig.ObservedStreakPulseGrowth
		playLandingPulse(visual.streakPulse, visual.shadow.Position, VisualConfig.MilestoneFallbackPulseColor, {
			startSize = VisualConfig.MilestoneFallbackPulseStartSize,
			endSize = VisualConfig.MilestoneFallbackPulseEndSize + streakBonus,
			duration = VisualConfig.MilestoneFallbackPulseDuration,
			transparency = VisualConfig.MilestoneFallbackPulseTransparency,
		})
		playCoinVisualHighlight(seatId, visual, {
			duration = VisualConfig.MilestoneHighlightDuration,
			fillColor = VisualConfig.MilestoneHighlightFillColor,
			outlineColor = VisualConfig.MilestoneHighlightOutlineColor,
			fillTransparency = VisualConfig.MilestoneHighlightFillTransparency,
			outlineTransparency = VisualConfig.MilestoneHighlightOutlineTransparency,
		})
		return
	end

	playCoinVisualHighlight(seatId, nil, {
		duration = VisualConfig.MilestoneHighlightDuration,
		fillColor = VisualConfig.MilestoneHighlightFillColor,
		outlineColor = VisualConfig.MilestoneHighlightOutlineColor,
		fillTransparency = VisualConfig.MilestoneHighlightFillTransparency,
		outlineTransparency = VisualConfig.MilestoneHighlightOutlineTransparency,
	})
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

function refreshHotStreakSpotlights(seatDisplayEntries)
	local activeSeats = {}

	for _, entry in ipairs(seatDisplayEntries) do
		if typeof(entry.seatId) ~= "string" then
			continue
		end

		local shouldShowSpotlight = entry.isOccupied == true
			and (entry.streak or 0) >= VisualConfig.HotStreakSpotlightMinimum
		if shouldShowSpotlight then
			local head, targetKey = getHotStreakActorHead(entry)
			if head then
				activeSeats[entry.seatId] = true
				ensureHotStreakSpotlight(entry.seatId, head, targetKey)
			else
				removeHotStreakSpotlight(entry.seatId)
			end
		else
			removeHotStreakSpotlight(entry.seatId)
		end
	end

	local staleSeatIds = {}
	for seatId in pairs(activeHotStreakSpotlights) do
		if not activeSeats[seatId] then
			table.insert(staleSeatIds, seatId)
		end
	end
	for _, seatId in ipairs(staleSeatIds) do
		removeHotStreakSpotlight(seatId)
	end
end

function getHotStreakActorHead(entry)
	if entry.isFake == true then
		local model = findFakeActorModel(entry.fakeId)
		local head = model and model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head, `fake:{entry.fakeId}`
		end
		return nil
	end

	if typeof(entry.userId) ~= "number" then
		return nil
	end

	local player = Players:GetPlayerByUserId(entry.userId)
	local character = player and player.Character
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head, `player:{entry.userId}`
	end

	return nil
end

function ensureHotStreakSpotlight(seatId, head, targetKey)
	local current = activeHotStreakSpotlights[seatId]
	if
		current
		and current.instance
		and current.instance.Parent
		and current.head == head
		and current.targetKey == targetKey
	then
		return
	end

	removeHotStreakSpotlight(seatId)

	local spotlight = buildHotStreakSpotlightClone(head)
	if not spotlight then
		return
	end

	activeHotStreakSpotlights[seatId] = {
		head = head,
		instance = spotlight,
		targetKey = targetKey,
	}
end

function removeHotStreakSpotlight(seatId)
	local current = activeHotStreakSpotlights[seatId]
	if not current then
		return
	end

	activeHotStreakSpotlights[seatId] = nil
	if current.instance and current.instance.Parent then
		current.instance:Destroy()
	end
end

function buildHotStreakSpotlightClone(head)
	local effectAsset = getHotStreakSpotlightAsset()
	if not effectAsset then
		return nil
	end

	if effectAsset:IsA("Attachment") or effectAsset:IsA("Folder") then
		local effectClone = effectAsset:Clone()
		effectClone.Name = "HotStreakSpotlight"
		effectClone.Parent = head
		EffectSystem:PlayInsideEffects(effectClone)
		return effectClone
	end

	if effectAsset:IsA("BasePart") then
		local effectClone = effectAsset:Clone()
		effectClone.Name = "HotStreakSpotlight"
		prepareHotStreakSpotlightPart(effectClone, head)
		effectClone.CFrame = head.CFrame * VisualConfig.HotStreakSpotlightOffset
		effectClone.Parent = head
		weldHotStreakPartToHead(effectClone, head)
		EffectSystem:PlayInsideEffects(effectClone)
		return effectClone
	end

	if effectAsset:IsA("Model") then
		local effectClone = effectAsset:Clone()
		effectClone.Name = "HotStreakSpotlight"
		effectClone.Parent = head
		effectClone:PivotTo(head.CFrame * VisualConfig.HotStreakSpotlightOffset)
		for _, descendant in ipairs(effectClone:GetDescendants()) do
			if descendant:IsA("BasePart") then
				prepareHotStreakSpotlightPart(descendant, head)
				weldHotStreakPartToHead(descendant, head)
			end
		end
		EffectSystem:PlayInsideEffects(effectClone)
		return effectClone
	end

	warn(`[EffectSystem] Hot streak spotlight asset must be a Model, BasePart, Attachment, or Folder.`)
	return nil
end

function getHotStreakSpotlightAsset()
	local effectAsset = script.Assets:FindFirstChild(VisualConfig.HotStreakSpotlightAssetName)
	if effectAsset then
		return effectAsset
	end

	if not missingHotStreakSpotlightWarningShown then
		missingHotStreakSpotlightWarningShown = true
		warn(`[EffectSystem] Missing hot streak spotlight asset: {VisualConfig.HotStreakSpotlightAssetName}`)
	end
	return nil
end

function prepareHotStreakSpotlightPart(part, head)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.AssemblyLinearVelocity = head.AssemblyLinearVelocity
	part.AssemblyAngularVelocity = head.AssemblyAngularVelocity
end

function weldHotStreakPartToHead(part, head)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "HotStreakSpotlightWeld"
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
end

function findFakeActorModel(fakeId)
	if typeof(fakeId) ~= "string" then
		return nil
	end

	local tableModel = Workspace:FindFirstChild("CoinFlipTable")
	local assetsFolder = tableModel and tableModel:FindFirstChild("Assets")
	local runtimeFolder = assetsFolder and assetsFolder:FindFirstChild("FakePlayersRuntime")
	local model = runtimeFolder and runtimeFolder:FindFirstChild(fakeId)
	if model and model:IsA("Model") then
		return model
	end

	model = Workspace:FindFirstChild(fakeId, true)
	if model and model:IsA("Model") then
		return model
	end

	return nil
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
