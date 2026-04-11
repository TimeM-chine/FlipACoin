local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Replicated = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local RaycastFilters = require(Replicated.configs.RaycastFilters)
local WeaponPresets = require(script.Parent.Parent.Presets)

local SENDER = SystemMgr.SENDER
local BLOCK_SIZE = BlockPresets.BlockSize or 8

local Bomb = {}
Bomb.__index = Bomb
setmetatable(Bomb, BaseWeapon)

Bomb.CanHit = true
Bomb.CanBeFired = true

function Bomb.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Bomb)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}

	self:doInitialSetup()

	return self
end

function Bomb:onEquippedChanged()
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

-- 收集立方体范围内的方块
function Bomb:collectBlocksInCube(center, explosionSize)
	local blockIds = {}
	local seen = {}

	-- 计算立方体边界
	local halfSize = (explosionSize * BLOCK_SIZE) / 2
	local minPos = center - Vector3.new(halfSize, halfSize, halfSize)
	local maxPos = center + Vector3.new(halfSize, halfSize, halfSize)

	-- 使用GetPartBoundsInBox获取立方体范围内的方块
	local size = Vector3.new(explosionSize * BLOCK_SIZE, explosionSize * BLOCK_SIZE, explosionSize * BLOCK_SIZE)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(center), size, createOverlapParams())

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

function Bomb:getEquippedToolModel()
	local character = self.player and self.player.Character
	if not character then
		return nil
	end

	local weaponType = self:getConfigValue("weaponType")
	if not weaponType then
		return nil
	end

	local model = character:FindFirstChild(`{weaponType}Model`)
	if model and model:IsA("Model") then
		return model
	end

	return nil
end

function Bomb:cloneProjectileModelFromEquipped(startPos)
	local equippedModel = self:getEquippedToolModel()
	if not equippedModel then
		return nil, nil
	end

	local projectileModel = equippedModel:Clone()

	local baseParts = {}
	for _, desc in ipairs(projectileModel:GetDescendants()) do
		if desc:IsA("Motor6D") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			table.insert(baseParts, desc)
			desc.Anchored = false
			desc.Massless = false
			desc.CanCollide = false
		end
	end

	local primaryPart = projectileModel.PrimaryPart
	if not primaryPart then
		local handle = projectileModel:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			primaryPart = handle
		end
	end
	if not primaryPart then
		local rootPart = projectileModel:FindFirstChild("RootPart")
		if rootPart and rootPart:IsA("BasePart") then
			primaryPart = rootPart
		end
	end
	if not primaryPart then
		for _, desc in ipairs(projectileModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				primaryPart = desc
				break
			end
		end
	end

	if not primaryPart then
		projectileModel:Destroy()
		return nil, nil
	end

	projectileModel.PrimaryPart = primaryPart
	-- Use primary part as the collider so bomb can hit blocks without multi-part jitter.
	primaryPart.CanCollide = true

	-- Force projectile model to move as one rigid body so throw direction stays stable.
	for _, part in ipairs(baseParts) do
		if part ~= primaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primaryPart
			weld.Part1 = part
			weld.Parent = primaryPart
		end
	end

	projectileModel:PivotTo(CFrame.new(startPos))
	projectileModel.Parent = workspace

	return projectileModel, primaryPart
end

function Bomb:sendFire(fireInfo)
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

-- 创建炸弹爆炸特效
function Bomb:createExplosionEffect(position)
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(2, 2, 2)
	explosion.Position = position
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Transparency = 0.3
	explosion.Color = Color3.fromRGB(255, 100, 0)
	explosion.Material = Enum.Material.Neon
	explosion.Parent = workspace

	-- 爆炸动画
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = { Size = Vector3.new(12, 12, 12), Transparency = 1 }
	local tween = TweenService:Create(explosion, tweenInfo, goal)
	tween:Play()

	Debris:AddItem(explosion, 0.5)
end

local function addTrailToProjectile(primaryPart, projectileModel)
	local partColor = Color3.fromRGB(200, 200, 200)
	for _, desc in ipairs(projectileModel:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Transparency < 1 then
			partColor = desc.Color
			break
		end
	end

	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0.5, 0)
	attachment1.Position = Vector3.new(0, -0.5, 0)
	attachment0.Parent = primaryPart
	attachment1.Parent = primaryPart

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.5
	trail.Color = ColorSequence.new(partColor, partColor)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = primaryPart
end

-- 生成炸弹投射物
function Bomb:spawnProjectile(startPos, direction, explosionSize, damage, fuseTime)
	local bomb
	local primaryPart

	bomb, primaryPart = self:cloneProjectileModelFromEquipped(startPos)
	if bomb and primaryPart then
		local speed = self:getConfigValue("ThrowSpeed", 60)
		local upward = self:getConfigValue("ThrowLift", 25)
		primaryPart.AssemblyLinearVelocity = direction * speed + Vector3.new(0, upward, 0)
		primaryPart:ApplyImpulse(direction * speed * math.max(1, primaryPart.AssemblyMass))
		addTrailToProjectile(primaryPart, bomb)
	else
		-- 回退：尝试从ToolModels获取炸弹模型
		local weaponName = self:getConfigValue("name", "Bomb1")
		local bombModel = WeaponPresets.GetWeaponModel(weaponName)
		if bombModel and bombModel.PrimaryPart then
			bomb = bombModel
			bomb:SetPrimaryPartCFrame(CFrame.new(startPos))

			for _, part in ipairs(bomb:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Massless = false
					part.CanCollide = true
				end
			end

			primaryPart = bomb.PrimaryPart
			primaryPart.Anchored = false
			bomb.Parent = workspace

			local speed = self:getConfigValue("ThrowSpeed", 60)
			local upward = self:getConfigValue("ThrowLift", 25)
			primaryPart.AssemblyLinearVelocity = direction * speed + Vector3.new(0, upward, 0)
			addTrailToProjectile(primaryPart, bomb)
		else
			-- 如果没有模型，使用简单的球形
			bomb = Instance.new("Part")
			bomb.Shape = Enum.PartType.Ball
			bomb.Size = Vector3.new(2, 2, 2)
			bomb.Name = "BombProjectile"
			bomb.Massless = false
			bomb.CanCollide = true
			bomb.Color = Color3.fromRGB(50, 50, 50)
			bomb.Material = Enum.Material.Metal
			bomb.Position = startPos
			bomb.Parent = workspace

			local speed = self:getConfigValue("ThrowSpeed", 60)
			local upward = self:getConfigValue("ThrowLift", 25)
			bomb.AssemblyLinearVelocity = direction * speed + Vector3.new(0, upward, 0)
			addTrailToProjectile(bomb, bomb)
		end
	end

	local exploded = false
	local function explode()
		if exploded then
			return
		end
		exploded = true

		local pos
		if bomb:IsA("Model") then
			pos = bomb.PrimaryPart and bomb.PrimaryPart.Position or startPos
		else
			pos = bomb.Position
		end

		-- 创建爆炸特效
		self:createExplosionEffect(pos)
		SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, {
			musicName = "explode",
		})

		-- 收集立方体范围内的方块
		local blockIds = self:collectBlocksInCube(pos, explosionSize)
		local fireInfo = {
			blockIds = blockIds,
			impactPosition = pos,
			baseDamage = damage,
			explosionSize = explosionSize,
			damageRange = explosionSize,
			origin = startPos,
			dir = direction,
			charge = 1,
		}

		self:sendFire(fireInfo)

		-- 销毁炸弹
		if bomb:IsA("Model") then
			for _, part in ipairs(bomb:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
		else
			bomb.Anchored = true
		end
		Debris:AddItem(bomb, 0.1)
	end

	-- 3秒倒计时后爆炸
	fuseTime = fuseTime or 3
	task.delay(fuseTime, explode)
	task.spawn(function()
		local bigTime = 1
		while bigTime < 30 do
			bomb:ScaleTo(bomb:GetScale() * 1.01)
			bigTime += 1
			task.wait(0.1)
		end
	end)

	return bomb
end

function Bomb:onActivatedChanged()
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

	local now = tick()
	local cooldown = self:getConfigValue("coolDown") or self:getConfigValue("Cooldown", 1)
	local attackSpeedMult = self.player and self.player:GetAttribute("AttackSpeed") or 1
	if typeof(attackSpeedMult) == "number" and attackSpeedMult > 0 then
		cooldown = cooldown / attackSpeedMult
	end
	if now < self.nextFireTime then
		return
	end
	self.nextFireTime = now + cooldown

	-- SystemMgr.systems.MusicSystem:PlayMusic(
	-- 	nil,
	-- 	nil,
	-- 	{ musicName = "Swing1", part = self.player.Character.PrimaryPart }
	-- )

	local slashName = self:getConfigValue("SlashAnimation", "Slash")
	self.curSlashTrack = self:getAnimTrack(slashName) :: AnimationTrack
	self.curSlashTrack.Looped = false
	self.curSlashTrack:Play()
	if self.player and self.player:GetAttribute("AttackSpeed") then
		self.curSlashTrack:AdjustSpeed(self.player:GetAttribute("AttackSpeed"))
	end

	local character = self.player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local damage = self:getConfigValue("baseDamage", 10)
	local explosionSize = self:getConfigValue("explosionSize", 2)
	local fuseTime = self:getConfigValue("fuseTime", 3)
	local attackRange = self:getConfigValue("attackRange", 30)
	local startPos = hrp.Position + hrp.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)

	local mouse = Players.LocalPlayer and Players.LocalPlayer:GetMouse()
	local dir
	local targetPos
	if mouse and mouse.Hit then
		targetPos = mouse.Hit.Position
		dir = (targetPos - startPos)
		if dir.Magnitude > 0 then
			dir = dir.Unit
		else
			dir = hrp.CFrame.LookVector
		end
	else
		targetPos = startPos + hrp.CFrame.LookVector * attackRange * BLOCK_SIZE
		dir = hrp.CFrame.LookVector
	end

	local attackDistance = (targetPos - hrp.Position).Magnitude
	local maxAttackDistance = (attackRange + 0.5) * BLOCK_SIZE
	if attackDistance > maxAttackDistance then
		return
	end

	task.delay(0.2, function()
		local character2 = self.player and self.player.Character
		if not character2 then
			return
		end
		local hrpNow = character2:FindFirstChild("HumanoidRootPart")
		if not hrpNow then
			return
		end
		local delayedStartPos = hrpNow.Position + hrpNow.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)
		self:spawnProjectile(delayedStartPos, dir, explosionSize, damage, fuseTime)
	end)
end

function Bomb:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local center = fireInfo.impactPosition
	local ids = fireInfo.blockIds
	if not center or not ids or #ids == 0 then
		return
	end

	local baseDamage = fireInfo.baseDamage or self:getConfigValue("baseDamage", 10)
	local explosionSize = fireInfo.explosionSize or self:getConfigValue("explosionSize", 2)
	local attackRange = fireInfo.attackRange or self:getConfigValue("attackRange", 30)
	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")
	local maxThrow = self:getConfigValue("MaxThrowDistance", 200)
	if hrp and (center - hrp.Position).Magnitude > maxThrow then
		return
	end

	-- 立方体范围检查
	local halfSize = (explosionSize * BLOCK_SIZE) / 2 + BLOCK_SIZE * 0.5

	local validIds = {}

	for _, blockId in ipairs(ids) do
		local block = SystemMgr.systems.BlockSystem:GetBlockInsById(blockId)
		if block then
			local blockPos = block.position
			local diff = blockPos - center
			-- 检查是否在立方体范围内
			if math.abs(diff.X) <= halfSize and math.abs(diff.Y) <= halfSize and math.abs(diff.Z) <= halfSize then
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

function Bomb:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		self:applyBlockDamage(firingPlayer, fireInfo)
	end
end

function Bomb:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function Bomb:stopAnimations()
	self.animTracks = {}
end

function Bomb:cancelReload() end

function Bomb:onDestroyed()
	BaseWeapon.onDestroyed(self)
end

return Bomb
