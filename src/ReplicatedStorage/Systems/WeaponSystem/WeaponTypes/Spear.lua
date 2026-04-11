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

local Spear = {}
Spear.__index = Spear
setmetatable(Spear, BaseWeapon)

Spear.CanHit = true

function Spear.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Spear)

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

function Spear:onEquippedChanged()
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
			local animateScript = character:WaitForChild("Animate")
			animateScript.toolnone.ToolNoneAnim.AnimationId = "rbxassetid://86413609132742"
			local animFolder = script.Parent.Parent.Assets.Animations
			animateScript.run.RunAnim.AnimationId = animFolder:FindFirstChild("SpearRun").AnimationId
			animateScript.walk.WalkAnim.AnimationId = animFolder:FindFirstChild("SpearWalk").AnimationId
			animateScript.idle.Animation1.AnimationId = animFolder:FindFirstChild("SpearIdle").AnimationId
			animateScript.idle.Animation2.AnimationId = animFolder:FindFirstChild("SpearIdle").AnimationId
			animateScript.Enabled = false
			task.delay(0.05, function()
				animateScript.Enabled = true
			end)

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

					if self.player == Players.LocalPlayer and self.player:GetAttribute("inRun") then
						local hitInfoClone = table.clone(hitInfo)
						if self.player:GetAttribute("pvp") then
							local victimPlayer = Players:GetPlayerFromCharacter(onHitHumanoid.Parent)
							if
								victimPlayer
								and victimPlayer:GetAttribute("pvp")
								and victimPlayer:GetAttribute("inRun")
								and (not victimPlayer:GetAttribute("isDead"))
							then
								hitInfoClone.victimPlayer = victimPlayer
							end
						end
						SystemMgr.systems.WeaponSystem.Server:WeaponHit({
							player = self.player,
							instance = self.instance,
							hitInfo = hitInfoClone,
						})

						local grassId = hitInfo.name
						if grassId then
							SystemMgr.systems.GrassSystem:DamageGrasses(nil, nil, {
								grassIdList = { grassId },
							})
						end
					end
				end

				if attackPart:IsA("Model") then
				else
					local size = attackPart.Size

					-- Find the longest dimension
					local longestAxis = "Y"
					local longestLength = size.Y
					if size.X > longestLength then
						longestAxis = "X"
						longestLength = size.X
					end
					if size.Z > longestLength then
						longestAxis = "Z"
						longestLength = size.Z
					end

					-- Calculate number of points needed (spaced 1 stud apart)
					local numPoints = math.max(1, math.ceil(longestLength))
					local spacing = longestLength / numPoints

					for i = 1, numPoints do
						local dmgPoint = Instance.new("Attachment")
						dmgPoint.Name = "DmgPoint"

						-- Position along the longest axis, centered around origin
						local offset = (i - 0.5) * spacing - longestLength / 2
						if longestAxis == "X" then
							dmgPoint.Position = Vector3.new(offset, 0, 0)
						elseif longestAxis == "Y" then
							dmgPoint.Position = Vector3.new(0, offset, 0)
						else -- Z
							dmgPoint.Position = Vector3.new(0, 0, offset)
						end

						dmgPoint.Parent = attackPart
					end
				end

				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = RaycastFilters.GrassesAndPlayersExcept(self.player)
				self.HitBoxes[attackPart] = HitBox.new(attackPart, raycastParams)
				self.HitBoxes[attackPart]:OnHit(onHit)
			end

			local spear: Model = character:WaitForChild("SpearModel", 10)

			if spear then
				setupHitBoxPart(spear:WaitForChild("dmgPart"))
			else
				warn("no spear")
				-- add hand and legs here
				setupHitBoxPart(character:WaitForChild("LeftLowerArm"))
				setupHitBoxPart(character:WaitForChild("LeftHand"))
				setupHitBoxPart(character:WaitForChild("RightLowerArm"))
				setupHitBoxPart(character:WaitForChild("RightHand"))
			end
		else
			for part, hitBox in pairs(self.HitBoxes) do
				hitBox:Destroy()
				self.HitBoxes[part] = nil
			end
		end
	end
end

function Spear:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if not IsServer and self.activated then
		-- last animation playing
		if self.curSlashTrack and self.curSlashTrack.IsPlaying then
			return
		end

		if self.nextFireTime <= tick() then
			self.nextFireTime = tick() + COOL_DOWN_TIME
		end

		SystemMgr.systems.MusicSystem:PlayMusic(
			nil,
			nil,
			{ musicName = "Swing1", part = self.player.Character.PrimaryPart }
		)

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

function Spear:simulateFire(_firingPlayer, fireInfo, ownerCharacter)
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

	local effectName = "Spear" .. curSlashNum
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

function Spear:stopAnimations()
	self.animTracks = {}
end

function Spear:cancelReload() end

function Spear:onDestroyed()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	BaseWeapon.onDestroyed(self)
end

return Spear
