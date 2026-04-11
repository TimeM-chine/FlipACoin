local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local RaycastFilters = require(Replicated.configs.RaycastFilters)
local WeaponPresets = require(script.Parent.Parent.Presets)

local SENDER = SystemMgr.SENDER
local BLOCK_SIZE = BlockPresets.BlockSize or 8

local OrbitingBoomerang = {}
OrbitingBoomerang.__index = OrbitingBoomerang
setmetatable(OrbitingBoomerang, BaseWeapon)

OrbitingBoomerang.CanHit = true
OrbitingBoomerang.CanBeFired = true

function OrbitingBoomerang.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), OrbitingBoomerang)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}
	self.isSpinning = false
	self.spinConnection = nil
	self.hitBlocks = {} -- 已经击中的方块，避免重复伤害
	self.orbitingModel = nil

	self:doInitialSetup()

	return self
end

function OrbitingBoomerang:onEquippedChanged()
	if not IsServer then
		if Players.LocalPlayer ~= self.player then
			return
		end
		local character = self.player.Character
		if not character then
			return
		end
		if not character.Parent then
			return
		end
	end
end

local function createOverlapParams()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local filters = RaycastFilters.Blocks()
	params.FilterDescendantsInstances = filters
	return params
end

-- 在指定位置检测方块
function OrbitingBoomerang:detectBlocksAtPosition(position, checkRadius)
	local blockIds = {}
	local seen = {}

	local parts = workspace:GetPartBoundsInRadius(position, checkRadius or BLOCK_SIZE, createOverlapParams())

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			local blockId = model.Name
			if blockId and not seen[blockId] then
				seen[blockId] = true
				table.insert(blockIds, blockId)
			end
		end
	end

	return blockIds
end

function OrbitingBoomerang:sendFire(fireInfo)
	fireInfo.id = fireInfo.id or self.nextShotId
	self.nextShotId += 1

	if not IsServer then
		self:onFired(self.player, fireInfo, false)
		SystemMgr.systems.WeaponSystem.Server:WeaponFired({
			instance = self.instance,
			fireInfo = fireInfo,
		})
	else
		self:onFired(self.player, fireInfo, false)
	end
end

-- 创建旋转武器模型
function OrbitingBoomerang:createOrbitingModel()
	local weaponName = self:getConfigValue("name", "OrbitingBoomerang1")
	local model = WeaponPresets.GetWeaponModel(weaponName)

	if model then
		-- 设置模型属性
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = true
				part.Transparency = 0 -- 确保可见
			end
		end

		-- 确保模型有 PrimaryPart
		if not model.PrimaryPart then
			local firstPart = model:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				model.PrimaryPart = firstPart
			end
		end

		model.Parent = workspace
		return model
	else
		-- 创建简单的视觉效果作为备用
		local part = Instance.new("Part")
		part.Name = "OrbitingBoomerangVisual"
		part.Size = Vector3.new(4, 0.5, 1.5)
		part.Color = Color3.fromRGB(100, 200, 255)
		part.Material = Enum.Material.Neon
		part.CanCollide = false
		part.Anchored = true
		part.Transparency = 0
		part.Parent = workspace
		return part
	end
end

-- 销毁旋转武器模型
function OrbitingBoomerang:destroyOrbitingModel()
	if self.orbitingModel then
		Debris:AddItem(self.orbitingModel, 0.1)
		self.orbitingModel = nil
	end
end

-- 执行旋转攻击
function OrbitingBoomerang:performSpinAttack()
	if self.isSpinning then
		return
	end

	self.isSpinning = true
	self.hitBlocks = {}

	local character = self.player and self.player.Character
	if not character then
		self.isSpinning = false
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		self.isSpinning = false
		return
	end

	local radius = self:getConfigValue("radius", 12)
	local layers = self:getConfigValue("layers", 1)
	local orbitSpeed = self:getConfigValue("orbitSpeed", 360) -- 公转速度(度/秒)
	local selfRotationSpeed = self:getConfigValue("selfRotationSpeed", 720) -- 自转速度(度/秒)
	local damage = self:getConfigValue("baseDamage", 10)

	-- 计算旋转一圈需要的时间
	local spinDuration = 360 / orbitSpeed

	-- 创建旋转模型
	self.orbitingModel = self:createOrbitingModel()

	-- 设置模型初始位置（玩家前方）
	if self.orbitingModel then
		local initialPos = hrp.Position + Vector3.new(radius, 0, 0)
		if self.orbitingModel:IsA("Model") and self.orbitingModel.PrimaryPart then
			self.orbitingModel:SetPrimaryPartCFrame(CFrame.new(initialPos))
		else
			self.orbitingModel.CFrame = CFrame.new(initialPos)
		end
		-- print(`[OrbitingBoomerang] Model initial position set to: {initialPos}`)
	end

	local startTime = tick()
	local orbitAngle = 0 -- 公转角度
	local selfRotation = 0 -- 自转角度

	-- 旋转循环
	self.spinConnection = RunService.Heartbeat:Connect(function(dt)
		if not self.isSpinning then
			return
		end

		-- 检查角色是否还存在
		if not hrp or not hrp.Parent then
			self:finishSpin()
			return
		end

		local elapsed = tick() - startTime
		if elapsed >= spinDuration then
			-- 旋转完成
			self:finishSpin()
			return
		end

		-- 更新公转角度
		orbitAngle = orbitAngle + orbitSpeed * dt

		-- 更新自转角度
		selfRotation = selfRotation + selfRotationSpeed * dt

		-- 计算模型位置（绕玩家公转）
		local centerPos = hrp.Position
		local orbitAngleRad = math.rad(orbitAngle)
		local offsetX = math.cos(orbitAngleRad) * radius
		local offsetZ = math.sin(orbitAngleRad) * radius
		local modelPos = centerPos + Vector3.new(offsetX, 0, offsetZ)

		-- 设置模型位置和朝向（包含自转）
		local selfRotationRad = math.rad(selfRotation)
		if self.orbitingModel then
			if self.orbitingModel:IsA("Model") and self.orbitingModel.PrimaryPart then
				self.orbitingModel:SetPrimaryPartCFrame(CFrame.new(modelPos) * CFrame.Angles(0, selfRotationRad, 0))
			else
				self.orbitingModel.CFrame = CFrame.new(modelPos) * CFrame.Angles(0, selfRotationRad, 0)
			end
		end

		-- 检测当前位置的方块（多层）并立即造成伤害
		local newHitBlockIds = {}
		for layerOffset = 0, layers - 1 do
			local yOffset = -layerOffset * BLOCK_SIZE
			local checkPos = modelPos + Vector3.new(0, yOffset, 0)
			local hitBlockIds = self:detectBlocksAtPosition(checkPos, BLOCK_SIZE)

			for _, blockId in ipairs(hitBlockIds) do
				if not self.hitBlocks[blockId] then
					self.hitBlocks[blockId] = true
					table.insert(newHitBlockIds, blockId)
				end
			end
		end

		-- 如果有新击中的方块，立即发送伤害
		if #newHitBlockIds > 0 then
			local fireInfo = {
				blockIds = newHitBlockIds,
				center = modelPos,
				baseDamage = damage,
				origin = centerPos,
				dir = Vector3.new(),
				charge = 1,
			}
			self:sendFire(fireInfo)
		end
	end)
end

-- 完成旋转
function OrbitingBoomerang:finishSpin()
	self.isSpinning = false

	if self.spinConnection then
		self.spinConnection:Disconnect()
		self.spinConnection = nil
	end

	-- 销毁旋转模型
	self:destroyOrbitingModel()

	-- 清空已击中方块记录
	self.hitBlocks = {}
end

function OrbitingBoomerang:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if IsServer then
		return
	end

	if not self.activated then
		return
	end
	if self.player ~= Players.LocalPlayer then
		return
	end

	-- 如果正在旋转，不响应
	if self.isSpinning then
		return
	end

	local now = tick()
	local cooldown = self:getConfigValue("coolDown") or self:getConfigValue("Cooldown", 2)
	local attackSpeedMult = self.player and self.player:GetAttribute("AttackSpeed") or 1
	if typeof(attackSpeedMult) == "number" and attackSpeedMult > 0 then
		cooldown = cooldown / attackSpeedMult
	end
	if now < self.nextFireTime then
		return
	end
	self.nextFireTime = now + cooldown

	SystemMgr.systems.MusicSystem:PlayMusic(
		nil,
		nil,
		{ musicName = "Swing1", part = self.player.Character.PrimaryPart }
	)

	local slashName = self:getConfigValue("SlashAnimation", "Slash")
	self.curSlashTrack = self:getAnimTrack(slashName) :: AnimationTrack
	self.curSlashTrack.Looped = false
	self.curSlashTrack:Play()
	if self.player and self.player:GetAttribute("AttackSpeed") then
		self.curSlashTrack:AdjustSpeed(self.player:GetAttribute("AttackSpeed"))
	end

	-- 开始旋转攻击
	self:performSpinAttack()
end

function OrbitingBoomerang:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local ids = fireInfo.blockIds
	if not ids or #ids == 0 then
		return
	end

	local baseDamage = fireInfo.baseDamage or fireInfo.damage or self:getConfigValue("baseDamage", 10)
	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return
	end

	local playerPos = hrp.Position
	local radius = self:getConfigValue("radius", 12)
	local layers = self:getConfigValue("layers", 1)
	local maxDistance = radius + BLOCK_SIZE * 2

	local validIds = {}

	for _, blockId in ipairs(ids) do
		local blockIns = SystemMgr.systems.BlockSystem:GetBlockInsById(blockId)
		if blockIns then
			local blockPos = blockIns.position
			local horizontalDist = math.sqrt((blockPos.X - playerPos.X) ^ 2 + (blockPos.Z - playerPos.Z) ^ 2)
			local verticalDist = playerPos.Y - blockPos.Y

			-- 检查水平距离和垂直范围
			if
				horizontalDist <= maxDistance
				and verticalDist >= -BLOCK_SIZE
				and verticalDist <= layers * BLOCK_SIZE
			then
				table.insert(validIds, blockId)
			end
		end
	end

	if #validIds > 0 then
		SystemMgr.systems.BlockSystem:HurtBlocksWithWeapon(SENDER, firingPlayer, {
			blockIds = validIds,
			baseDamage = baseDamage,
		})
	end
end

function OrbitingBoomerang:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		self:applyBlockDamage(firingPlayer, fireInfo)
	end
end

function OrbitingBoomerang:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function OrbitingBoomerang:stopAnimations()
	if self.spinConnection then
		self.spinConnection:Disconnect()
		self.spinConnection = nil
	end
	self.isSpinning = false
	self:destroyOrbitingModel()
	self.animTracks = {}
end

function OrbitingBoomerang:cancelReload() end

function OrbitingBoomerang:onDestroyed()
	self:stopAnimations()
	BaseWeapon.onDestroyed(self)
end

return OrbitingBoomerang
