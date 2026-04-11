local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local HitBox = require(script.Parent.Parent.Libraries.HitBox)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local RaycastFilters = require(Replicated.configs.RaycastFilters)

local COOL_DOWN_TIME = 0.2
local alreadyHit = {}

local Punch = {}
Punch.__index = Punch
setmetatable(Punch, BaseWeapon)
Punch.CanHit = true

function Punch.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Punch)

	self.curSlashNum = 0
	self.curSlashTrack = nil
	self.nextFireTime = 0
	self.characterConnection = nil
	self.closestTarget = nil
	self.connections = {}
	self.HitBoxes = {}

	self:doInitialSetup()

	return self
end

function Punch:onEquippedChanged()
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
		-- Stop all animation tracks
		local humanoid = character:WaitForChild("Humanoid")
		local animator = humanoid:WaitForChild("Animator")
		for _, playingTrack in animator:GetPlayingAnimationTracks() do
			playingTrack:Stop(0)
			playingTrack:Destroy()
		end

		if self.equipped then
			local function setupHitBoxPart(attackPart)
				local function onHit(RaycastResult, segment)
					if not RaycastResult then
						return
					end

					local hitInfo = {
						part = RaycastResult.Instance,
						p = RaycastResult.Position,
						n = RaycastResult.Normal,
						m = RaycastResult.Material,
						d = RaycastResult.Distance,
						name = nil,
					}

					local onHitHumanoid = SystemMgr.systems.WeaponSystem.getHumanoid(hitInfo.part)
					if onHitHumanoid then
						hitInfo.name = onHitHumanoid.Parent.Name
					else
						return
					end

					if alreadyHit[hitInfo.name] then
						return
					end
					alreadyHit[hitInfo.name] = true

					if self.player == Players.LocalPlayer then
						local hitInfoClone = table.clone(hitInfo)
						SystemMgr.systems.WeaponSystem.Server:WeaponHit({
							player = self.player,
							instance = self.instance,
							hitInfo = hitInfoClone,
						})

						SystemMgr.systems.AnimateSystem:PlayAnimation(nil, nil, {
							actor = onHitHumanoid.Parent,
							animKey = "grass",
							animName = "hit",
						})
					end
				end

				if not attackPart:FindFirstChild("DmgPoint") then
					local dmgPoint = Instance.new("Attachment")
					dmgPoint.Name = "DmgPoint"
					dmgPoint.Parent = attackPart
				end

				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = RaycastFilters.GrassesAndPlayersExcept(self.player)
				self.HitBoxes[attackPart] = HitBox.new(attackPart, raycastParams)
				-- self.HitBoxes[attackPart]:SetCastData({
				-- 	CastType = "Blockcast",
				-- 	CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(90), 0, 0),
				-- 	Size = Vector3.new(1, 1, 1),
				-- })

				if self.connections[attackPart] then
					self.connections[attackPart]:Disconnect()
					self.connections[attackPart] = nil
				end
				self.connections[attackPart] = self.HitBoxes[attackPart]:OnHit(onHit)
			end

			-- add hand and legs here
			setupHitBoxPart(character:WaitForChild("LeftLowerArm"))
			setupHitBoxPart(character:WaitForChild("LeftHand"))
			setupHitBoxPart(character:WaitForChild("RightLowerArm"))
			setupHitBoxPart(character:WaitForChild("RightHand"))
		else
			--
			for part, hitBox in pairs(self.HitBoxes) do
				if self.connections[part] then
					self.connections[part]:Disconnect()
					self.connections[part] = nil
				end

				hitBox:Destroy()
				self.HitBoxes[part] = nil
			end
		end
	end
end

function Punch:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if not IsServer and self.activated then
		-- last animation playing
		if self.curSlashTrack and self.curSlashTrack.IsPlaying then
			return
		end

		if self.nextFireTime <= tick() then
			self.nextFireTime = tick() + COOL_DOWN_TIME
		end

		if self.player == Players.LocalPlayer then
			SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, { musicName = "Punch" })
		end

		local slashCount = self:getConfigValue("SlashCount", 3)
		if self.curSlashNum >= slashCount then
			self.curSlashNum = 1
		else
			self.curSlashNum += 1
		end

		-- Effect
		self:fire(nil, nil, nil, self.curSlashNum)

		alreadyHit = {}
		for _, hitBox in self.HitBoxes do
			if hitBox then
				hitBox:HitStart()
			end
		end

		local slashName = self:getConfigValue("SlashAnimation", "Slash")
		self.curSlashTrack = self:getAnimTrack(slashName .. self.curSlashNum) :: AnimationTrack
		self.curSlashTrack.Looped = false
		self.curSlashTrack:Play()
		if self.player and self.player:GetAttribute("AttackSpeed") then
			self.curSlashTrack:AdjustSpeed(self.player:GetAttribute("AttackSpeed"))
		end

		if not self.connections["slash"] then
			self.connections["slash"] = self.curSlashTrack.Stopped:Connect(function()
				for _, hitBox in self.HitBoxes do
					if hitBox then
						hitBox:HitStop()
					end
				end

				self.connections["slash"]:Disconnect()
				self.connections["slash"] = nil
			end)
		end
	elseif IsServer then --and self.activated then
		if self.nextFireTime <= tick() then
			self.nextFireTime = tick() + COOL_DOWN_TIME
		end
	end
end

function Punch:simulateFire(_firingPlayer, fireInfo, ownerCharacter)
	BaseWeapon.simulateFire(self, fireInfo, ownerCharacter)

	if not ownerCharacter then
		return
	end

	local character = ownerCharacter
	if not character then
		return
	end

	if not character.PrimaryPart then
		return
	end

	local curSlashNum = 1
	if fireInfo and fireInfo.curSlashNum then
		curSlashNum = fireInfo.curSlashNum
	end

	local effectName = "Punch" .. curSlashNum
	local targetPart = character.PrimaryPart
	local targetCFrame = character.PrimaryPart.CFrame
	local effectPart = script.Parent.Parent.Assets.Effects:FindFirstChild(effectName)
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
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = effectP:IsA("Model") and effectP.PrimaryPart or effectP
	weld.Part1 = targetPart
	weld.Parent = effectP
	effectP.Parent = character
	SystemMgr.systems.EffectSystem:PlayInsideEffects(effectP)

	Debris:AddItem(effectP, 1)
end

function Punch:stopAnimations()
	self.animTracks = {}
end

function Punch:cancelReload() end

function Punch:onDestroyed()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	BaseWeapon.onDestroyed(self)
end

return Punch
