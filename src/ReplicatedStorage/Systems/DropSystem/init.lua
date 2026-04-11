--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.2 Analysis
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

---- requires ----
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Textures = require(Replicated.configs.Textures)
local Util = require(Replicated.modules.Util)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local DropUi = { pendingCalls = {} }
setmetatable(DropUi, Types.mt)
local recordingTypes = {
	Keys.ItemType.wins,
	Keys.ItemType.candy,
}

local DropSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
DropSystem.__index = DropSystem

if IsServer then
	DropSystem.Client = setmetatable({}, DropSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	-- AnalyticsService = game:GetService("AnalyticsService")
else
	DropSystem.Server = setmetatable({}, DropSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function DropSystem:Init()
	GetSystemMgr()
end

function DropSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, args)
	else
		local Character = LocalPlayer.Character
		if Character then
			local jumpCash = script.Assets:FindFirstChild("JumpCash"):Clone()
			local tpl = jumpCash.Template
			tpl.Visible = false
			for _, rType in ipairs(recordingTypes) do
				Util.Clone(tpl, jumpCash, function(recordItem)
					recordItem.Name = rType
					recordItem.ImageLabel.Image = Textures.UnclassifiedIcons[rType]
				end)
			end
			jumpCash.Parent = Character:WaitForChild("HumanoidRootPart")
		end

		LocalPlayer.CharacterAdded:Connect(function(character)
			local jumpCash = script.Assets:FindFirstChild("JumpCash"):Clone()
			local tpl = jumpCash.Template
			tpl.Visible = false
			for _, rType in ipairs(recordingTypes) do
				Util.Clone(tpl, jumpCash, function(recordItem)
					recordItem.Name = rType
					recordItem.ImageLabel.Image = Textures.UnclassifiedIcons[rType]
				end)
			end
			jumpCash.Parent = character:WaitForChild("HumanoidRootPart")
		end)
		local pendingCalls = DropUi.pendingCalls

		DropUi = require(script.ui)
		DropUi.Init(pendingCalls)
	end
end

function DropSystem:DropItemAt(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:DropItemAt(player, args)
	else
		if not self.activeLootModels then
			self.activeLootModels = {}
			self.isProcessingCash = false
		end
		local maxSpawn = args.maxSpawn or 5
		local lootAmount = args.lootAmount or 1
		local position = args.position or LocalPlayer.Character:GetPivot().Position
		local lootType = args.lootType
		local icon = args.icon

		local lootModels = {}
		local splitAmounts = {}
		local _total = 0
		local lootToSpawn = math.min(lootAmount, maxSpawn)
		for i = 1, lootToSpawn - 1 do
			table.insert(splitAmounts, math.floor(lootAmount / lootToSpawn))
			_total += splitAmounts[i]
		end
		table.insert(splitAmounts, lootAmount - _total)

		for i = 1, lootToSpawn do
			local lootModel = script.Assets:WaitForChild("Loot"):Clone()

			-- Position the cash with random offset from impact point
			local randomOffset = Vector3.new(math.random(-3, 3), math.random(5, 7), math.random(-3, 3))
			lootModel:PivotTo(CFrame.new(position + randomOffset))
			lootModel.Loot.BillboardGui.ImageLabel.Image = icon or Textures.UnclassifiedIcons[lootType]
			lootModel:SetAttribute("Amount", splitAmounts[i])
			lootModel:SetAttribute("Type", lootType)
			lootModel.Parent = workspace

			-- Add force to make cash pop out
			local velocity = Instance.new("BodyVelocity")
			velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			velocity.Velocity = Vector3.new(math.random(-20, 20), math.random(10, 15), math.random(-20, 20))
			velocity.Parent = lootModel.PrimaryPart

			-- Add rotation
			local angularVelocity = Instance.new("BodyAngularVelocity")
			angularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			angularVelocity.AngularVelocity =
				Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
			angularVelocity.Parent = lootModel.PrimaryPart

			table.insert(lootModels, lootModel)

			-- Remove velocity after a short delay
			task.delay(0.3, function()
				if velocity and velocity.Parent then
					velocity:Destroy()
				end
				if angularVelocity and angularVelocity.Parent then
					angularVelocity:Destroy()
				end
			end)
		end

		task.delay(1, function()
			-- For each cash model, set up animation properties and add to active cash models
			for _, lootModel in ipairs(lootModels) do
				if not lootModel or not lootModel:IsDescendantOf(workspace) or not lootModel.PrimaryPart then
					continue
				end

				Util.setModelCollisionGroup(lootModel, Keys.CollisionGroup.Player)
				lootModel.PrimaryPart.Anchored = true
				-- cashModel.PrimaryPart.CanCollide = false
				lootModel.PrimaryPart.CanQuery = false
				lootModel.PrimaryPart.CanTouch = false

				-- 添加到活动模型列表
				local lootData = {
					model = lootModel,
					initialPosition = lootModel.PrimaryPart.Position,
					startTime = os.clock(),
					isFinished = false,
				}

				table.insert(self.activeLootModels, lootData)
			end

			self:StartCashProcessor()
		end)
	end
end

---- [[ Both Sides ]] ----

---- [[ Server Only ]] ----

---- [[ Client Only ]] ----
table.insert(DropSystem.whiteList, "StartCashProcessor")
function DropSystem:StartCashProcessor()
	if self.isProcessingCash then
		return
	end

	-- 标记为正在处理
	self.isProcessingCash = true

	-- 创建处理连接
	self.cashRenderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if #self.activeLootModels == 0 then
			self.cashRenderConnection:Disconnect()
			self.cashRenderConnection = nil
			self.isProcessingCash = false
			return
		end

		-- 获取玩家位置
		local playerCharacter = Players.LocalPlayer.Character
		local humanoidRootPart = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")

		if not humanoidRootPart then
			return
		end

		local playerPosition = humanoidRootPart.Position

		-- 更新所有cash模型
		for i = #self.activeLootModels, 1, -1 do
			if not self.activeLootModels[i] then
				table.remove(self.activeLootModels, i)
				continue
			end

			local lootData = self.activeLootModels[i]

			-- 安全检查：确保所有必需值都存在
			if
				not lootData
				or not lootData.model
				or not lootData.model:IsDescendantOf(workspace)
				or not lootData.model.PrimaryPart
				or lootData.isFinished
			then
				table.remove(self.activeLootModels, i)
				continue
			end

			local lootModel = lootData.model

			-- 计算时间和距离
			local timeElapsed = os.clock() - lootData.startTime
			local maxDuration = 5 -- 增加最大动画时间

			if timeElapsed > maxDuration then
				-- 如果超时直接销毁
				lootData.isFinished = true
				if lootModel and lootModel.Parent then
					lootModel:Destroy()
				end
				table.remove(self.activeLootModels, i)
				continue
			end

			-- 计算当前位置到玩家距离
			local distance = (lootModel.PrimaryPart.Position - playerPosition).Magnitude

			-- 固定速度方法 - 每帧移动固定百分比的距离
			local percentPerFrame = 0.1
			local minSpeed = 0.5 -- 最小移动速度（防止太慢）

			-- ���位置 = 当前位置 + (目标�������������置 - 当前�����置) * 百分比
			local direction = (playerPosition - lootModel.PrimaryPart.Position).Unit
			local moveDistance = math.max(distance * percentPerFrame, minSpeed * deltaTime)
			local newPosition = lootModel.PrimaryPart.Position + direction * moveDistance

			-- 更新模型位置
			if lootModel and lootModel.Parent then
				lootModel:PivotTo(CFrame.new(newPosition))
			end

			-- 检查是否达到了玩家（使用更小的阈值确��能�����达）
			if distance < 1 then
				-- 完成动画
				lootData.isFinished = true

				self:UpdateJumpCashDisplay(lootModel:GetAttribute("Amount"), lootModel:GetAttribute("Type"))
				if lootModel and lootModel.Parent then
					lootModel:Destroy()
				end

				-- 从列表中移除
				table.remove(self.activeLootModels, i)
			end
		end
	end)
end

local uiTween = {}
local tweenBigInfo = TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut)
local tweenSmallInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

function DropSystem:UpdateJumpCashDisplay(lootAmount, lootType)
	local playerCharacter = Players.LocalPlayer.Character
	local humanoidRootPart = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		return
	end

	if not self.currentJumpLootAmount then
		self.currentJumpLootAmount = {}
		for _, rType in ipairs(recordingTypes) do
			self.currentJumpLootAmount[rType] = 0
		end
	end

	-- 创建或获取 JumpCashGui 实例
	if not self.jumpCashGui or not self.jumpCashGui.Parent then
		self.jumpCashGui = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart"):WaitForChild("JumpCash")
	end

	-- 累加金额
	self.currentJumpLootAmount[lootType] = (self.currentJumpLootAmount[lootType] or 0) + lootAmount
	self.jumpCashGui[lootType].amount.Text = "x" .. Util.FormatNumber(self.currentJumpLootAmount[lootType])
	self.jumpCashGui[lootType].Visible = true
	if not self.jumpCashGui[lootType]:FindFirstChild("UIScale") then
		local UIScale = Instance.new("UIScale")
		UIScale.Parent = self.jumpCashGui[lootType]
	end
	if not uiTween[lootType] then
		uiTween[lootType] = {}
	end
	if uiTween[lootType].big then
		uiTween[lootType].big:Cancel()
	end
	if uiTween[lootType].small then
		uiTween[lootType].small:Cancel()
	end
	uiTween[lootType].big = TweenService:Create(self.jumpCashGui[lootType].UIScale, tweenBigInfo, { Scale = 1.3 })
	uiTween[lootType].small = TweenService:Create(self.jumpCashGui[lootType].UIScale, tweenSmallInfo, { Scale = 1 })
	uiTween[lootType].big:Play()
	uiTween[lootType].big.Completed:Once(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			uiTween[lootType].small:Play()
		else
			self.jumpCashGui[lootType].UIScale.Scale -= 0.05
		end
	end)

	if self.jumpCashTimer then
		task.cancel(self.jumpCashTimer)
		self.jumpCashTimer = nil
	end

	self.jumpCashTimer = task.delay(2, function()
		self:ResetJumpCashDisplay()
	end)

	self.jumpCashGui.Enabled = true -- 确保可见
end

function DropSystem:ResetJumpCashDisplay()
	if self.jumpCashGui and self.jumpCashGui.Parent then
		self.jumpCashGui.Enabled = false
		for _, rType in ipairs(recordingTypes) do
			self.jumpCashGui[rType].Visible = false
		end
	end
	self.jumpCashGui = nil
	for _, rType in ipairs(recordingTypes) do
		self.currentJumpLootAmount[rType] = 0
	end
	self.jumpCashTimer = nil
end

return DropSystem
