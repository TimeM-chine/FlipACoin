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

local BouncingBomb = {}
BouncingBomb.__index = BouncingBomb
setmetatable(BouncingBomb, BaseWeapon)

BouncingBomb.CanHit = true
BouncingBomb.CanBeFired = true

function BouncingBomb.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), BouncingBomb)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}
	self.activeProjectiles = {}

	self:doInitialSetup()

	return self
end

function BouncingBomb:onEquippedChanged()
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

local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = RaycastFilters.Blocks()
	return params
end

-- 检测位置附近的方块
function BouncingBomb:detectBlocksAtPosition(position, checkRadius)
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

function BouncingBomb:getEquippedToolModel()
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

function BouncingBomb:cloneProjectileModelFromEquipped(startPos)
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
	-- Use primary part as collider and weld the rest for stable thrown motion.
	primaryPart.CanCollide = true
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

function BouncingBomb:sendFire(fireInfo)
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

-- 创建爆炸特效
function BouncingBomb:createExplosionEffect(position)
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(2, 2, 2)
	explosion.Position = position
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Transparency = 0.3
	explosion.Color = Color3.fromRGB(255, 150, 0)
	explosion.Material = Enum.Material.Neon
	explosion.Parent = workspace

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = { Size = Vector3.new(10, 10, 10), Transparency = 1 }
	local tween = TweenService:Create(explosion, tweenInfo, goal)
	tween:Play()

	Debris:AddItem(explosion, 0.5)
end

-- 创建反弹子弹
function BouncingBomb:createBouncingProjectile(startPos, direction, bounceCount, damage, speed)
	if not self.player then
		return
	end

	local projectileContainer
	local projectileModel, projectilePart = self:cloneProjectileModelFromEquipped(startPos)
	local projectile = projectilePart
	if projectileModel and projectile then
		projectileContainer = projectileModel
	else
		projectile = Instance.new("Part")
		projectile.Shape = Enum.PartType.Ball
		projectile.Size = Vector3.new(1.5, 1.5, 1.5)
		projectile.Name = "BouncingBombShard"
		projectile.Color = Color3.fromRGB(100, 50, 50)
		projectile.Material = Enum.Material.Metal
		projectileContainer = projectile
	end

	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.Position = startPos
	projectileContainer.Parent = workspace

	-- 使用BodyVelocity控制运动
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = direction * speed
	bodyVelocity.Parent = projectile

	-- 添加拖尾效果
	local trail = Instance.new("Trail")
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0.3, 0)
	attachment1.Position = Vector3.new(0, -0.3, 0)
	attachment0.Parent = projectile
	attachment1.Parent = projectile
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.3
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 100, 0))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = projectile

	local currentBounces = 0
	local hitBlocks = {}

	-- 检测和处理碰撞
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not projectileContainer.Parent then
			connection:Disconnect()
			return
		end

		local currentPos = projectile.Position
		local velocity = bodyVelocity.Velocity
		local rayDir = velocity.Unit * (velocity.Magnitude * dt + 2)

		-- 射线检测
		local result = workspace:Raycast(currentPos, rayDir, createRaycastParams())

		if result and result.Instance then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local blockId = model.Name
				if not hitBlocks[blockId] then
					hitBlocks[blockId] = true

					-- 发送伤害
					local fireInfo = {
						blockIds = { blockId },
						impactPosition = result.Position,
						baseDamage = damage,
						origin = startPos,
						dir = direction,
						charge = 1,
					}
					self:sendFire(fireInfo)
				end

				-- 处理反弹
				currentBounces = currentBounces + 1
				if currentBounces <= bounceCount then
					-- 计算反弹方向
					local normal = result.Normal
					local newDir = (velocity - 2 * velocity:Dot(normal) * normal).Unit
					bodyVelocity.Velocity = newDir * speed

					-- 创建反弹特效
					local sparkle = Instance.new("Part")
					sparkle.Shape = Enum.PartType.Ball
					sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
					sparkle.Position = result.Position
					sparkle.Anchored = true
					sparkle.CanCollide = false
					sparkle.Color = Color3.fromRGB(255, 255, 100)
					sparkle.Material = Enum.Material.Neon
					sparkle.Parent = workspace
					Debris:AddItem(sparkle, 0.2)
				else
					-- 反弹次数用完，销毁子弹
					connection:Disconnect()
					Debris:AddItem(projectileContainer, 0.1)
				end
			end
		end
	end)

	-- 最大生存时间
	task.delay(5, function()
		if projectileContainer.Parent then
			connection:Disconnect()
			Debris:AddItem(projectileContainer, 0.1)
		end
	end)

	return projectileContainer
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

-- 生成炸弹并在爆炸后创建反弹子弹
function BouncingBomb:spawnBombWithBouncingProjectiles(
	startPos,
	direction,
	projectileCount,
	bounceCount,
	damage,
	fuseTime,
	projectileSpeed
)
	local bomb
	local primaryPart

	bomb, primaryPart = self:cloneProjectileModelFromEquipped(startPos)
	if bomb and primaryPart then
		local speed = self:getConfigValue("ThrowSpeed", 50)
		local upward = self:getConfigValue("ThrowLift", 30)
		primaryPart.AssemblyLinearVelocity = direction * speed + Vector3.new(0, upward, 0)
		primaryPart:ApplyImpulse(direction * speed * math.max(1, primaryPart.AssemblyMass))
		addTrailToProjectile(primaryPart, bomb)
	else
		-- 回退：尝试从ToolModels获取炸弹模型
		local weaponName = self:getConfigValue("name", "BouncingBomb1")
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

			local speed = self:getConfigValue("ThrowSpeed", 50)
			local upward = self:getConfigValue("ThrowLift", 30)
			primaryPart.AssemblyLinearVelocity = direction * speed + Vector3.new(0, upward, 0)
			addTrailToProjectile(primaryPart, bomb)
		else
			-- 如果没有模型，使用简单的球形
			bomb = Instance.new("Part")
			bomb.Shape = Enum.PartType.Ball
			bomb.Size = Vector3.new(2, 2, 2)
			bomb.Name = "BouncingBombProjectile"
			bomb.Massless = false
			bomb.CanCollide = true
			bomb.Color = Color3.fromRGB(100, 50, 50)
			bomb.Material = Enum.Material.Metal
			bomb.Position = startPos
			bomb.Parent = workspace

			local speed = self:getConfigValue("ThrowSpeed", 50)
			local upward = self:getConfigValue("ThrowLift", 30)
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

		-- 生成反弹子弹
		for i = 1, projectileCount do
			-- 随机方向
			local randomAngle = math.random() * math.pi * 2
			local randomPitch = (math.random() - 0.5) * math.pi * 0.5 -- -45到45度
			local dir = Vector3.new(
				math.cos(randomAngle) * math.cos(randomPitch),
				-- math.sin(randomPitch) + 0.3, -- 稍微向上
				math.sin(randomPitch),
				math.sin(randomAngle) * math.cos(randomPitch)
			).Unit

			-- 延迟生成，产生散开效果
			task.delay(i * 0.02, function()
				self:createBouncingProjectile(pos, dir, bounceCount, damage, projectileSpeed)
			end)
		end

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

function BouncingBomb:onActivatedChanged()
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
	local cooldown = self:getConfigValue("coolDown") or self:getConfigValue("Cooldown", 1.5)
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

	local damage = self:getConfigValue("baseDamage", 8)
	local projectileCount = self:getConfigValue("projectileCount", 5)
	local bounceCount = self:getConfigValue("bounceCount", 1)
	local fuseTime = self:getConfigValue("fuseTime", 3)
	local projectileSpeed = self:getConfigValue("projectileSpeed", 40)
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
		self:spawnBombWithBouncingProjectiles(
			delayedStartPos,
			dir,
			projectileCount,
			bounceCount,
			damage,
			fuseTime,
			projectileSpeed
		)
	end)
end

function BouncingBomb:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local ids = fireInfo.blockIds
	if not ids or #ids == 0 then
		return
	end

	local baseDamage = fireInfo.baseDamage or fireInfo.damage or self:getConfigValue("baseDamage", 8)
	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")

	local validIds = {}

	for _, blockId in ipairs(ids) do
		local blockIns = SystemMgr.systems.BlockSystem:GetBlockInsById(blockId)
		if blockIns then
			table.insert(validIds, blockId)
		end
	end

	if #validIds > 0 then
		SystemMgr.systems.BlockSystem:HurtBlocksWithWeapon(SENDER, firingPlayer, {
			blockIds = validIds,
			baseDamage = baseDamage,
		})
	end
end

function BouncingBomb:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		self:applyBlockDamage(firingPlayer, fireInfo)
	end
end

function BouncingBomb:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function BouncingBomb:stopAnimations()
	self.animTracks = {}
end

function BouncingBomb:cancelReload() end

function BouncingBomb:onDestroyed()
	BaseWeapon.onDestroyed(self)
end

return BouncingBomb
