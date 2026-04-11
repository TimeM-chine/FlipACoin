local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local Keys = require(Replicated.configs.Keys)

local SENDER = SystemMgr.SENDER
local BLOCK_SIZE = BlockPresets.BlockSize or 8
local dataKey = Keys.DataKey

local PlayerServerClass = nil
if IsServer then
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
end

local Drill = {}
Drill.__index = Drill
setmetatable(Drill, BaseWeapon)

Drill.CanHit = true
Drill.CanBeFired = true

function Drill.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Drill)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}
	self.isDrilling = false
	self.drillConnection = nil

	self:doInitialSetup()

	return self
end

function Drill:onEquippedChanged()
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

		-- 当取消装备时，停止钻探
		if not self.equipped then
			self:stopDrilling()
		end
	end
end

local function getZoneStartPos(zoneIndex: number)
	local baseHeight = BlockPresets.Zone1Height or BlockPresets.FloorHeight
	if zoneIndex % 2 == 1 then
		return BlockPresets.OddZonePos + Vector3.new(0, baseHeight - BlockPresets.ZoneGap * (zoneIndex - 1), 0)
	end
	return BlockPresets.EvenZonePos + Vector3.new(0, baseHeight - BlockPresets.ZoneGap * (zoneIndex - 1), 0)
end

local function getPlayerZoneIndex(player: Player): number?
	if not IsServer or not PlayerServerClass then
		return nil
	end
	local playerIns = PlayerServerClass.GetIns(player)
	if not playerIns then
		return nil
	end
	local zoneIndex = playerIns:GetOneData(dataKey.nowZone)
	if typeof(zoneIndex) ~= "number" then
		return nil
	end
	return zoneIndex
end

function Drill:sendFire(fireInfo)
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

-- 执行一次钻探
function Drill:performDrill()
	if not self.activated then
		self:stopDrilling()
		return
	end

	local character = self.player and self.player.Character
	if not character then
		self:stopDrilling()
		return
	end

	local now = tick()
	local cooldown = self:getConfigValue("drillFrequency") or self:getConfigValue("coolDown", 0.15)
	local attackSpeedMult = self.player and self.player:GetAttribute("AttackSpeed") or 1
	if typeof(attackSpeedMult) == "number" and attackSpeedMult > 0 then
		cooldown = cooldown / attackSpeedMult
	end
	if now < self.nextFireTime then
		return
	end
	self.nextFireTime = now + cooldown

	local drillWidth = self:getConfigValue("drillWidth", 1)

	local damage = self:getConfigValue("baseDamage", 8)
	local fireInfo = {
		baseDamage = damage,
		drillWidth = drillWidth,
		origin = self.player and self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
				and self.player.Character.HumanoidRootPart.Position
			or Vector3.new(),
		dir = Vector3.new(0, -1, 0),
		charge = 1,
	}

	self:sendFire(fireInfo)
end

-- 开始持续钻探
function Drill:startDrilling()
	if self.isDrilling then
		return
	end

	self.isDrilling = true
	SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, {
		musicName = "drill",
	})

	-- 使用Heartbeat实现高频攻击
	self.drillConnection = RunService.Heartbeat:Connect(function()
		if self.activated and self.equipped then
			self:performDrill()
		else
			self:stopDrilling()
		end
	end)
end

-- 停止钻探
function Drill:stopDrilling()
	self.isDrilling = false
	SystemMgr.systems.MusicSystem:Stop2dMusic(nil, nil, {
		musicName = "drill",
	})
	if self.drillConnection then
		self.drillConnection:Disconnect()
		self.drillConnection = nil
	end
end

function Drill:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if IsServer then
		return
	end

	if self.player ~= Players.LocalPlayer then
		return
	end

	if self.activated then
		-- 开始钻探
		SystemMgr.systems.MusicSystem:PlayMusic(
			nil,
			nil,
			{ musicName = "Swing1", part = self.player.Character.PrimaryPart }
		)

		local slashName = self:getConfigValue("SlashAnimation", "Slash")
		self.curSlashTrack = self:getAnimTrack(slashName) :: AnimationTrack
		self.curSlashTrack.Looped = true -- 循环播放钻探动画
		self.curSlashTrack:Play()
		if self.player and self.player:GetAttribute("AttackSpeed") then
			self.curSlashTrack:AdjustSpeed(self.player:GetAttribute("AttackSpeed"))
		end

		self:startDrilling()
	else
		-- 停止钻探
		self:stopDrilling()
		if self.curSlashTrack then
			self.curSlashTrack:Stop()
		end
	end
end

function Drill:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local baseDamage = fireInfo.baseDamage or fireInfo.damage or self:getConfigValue("baseDamage", 8)

	local drillWidth = fireInfo.drillWidth or self:getConfigValue("drillWidth", 1)
	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return
	end

	local playerPos = hrp.Position
	local maxDistance = BLOCK_SIZE * 3 -- 最大钻探距离

	local zoneIndex = getPlayerZoneIndex(firingPlayer)
	if not zoneIndex then
		return
	end

	local zoneStartPos = getZoneStartPos(zoneIndex)
	if not zoneStartPos then
		return
	end

	local lineCount = BlockPresets.LineCount or 0
	if lineCount <= 0 then
		return
	end

	local relX = playerPos.X - zoneStartPos.X
	local relZ = playerPos.Z - zoneStartPos.Z
	local baseI = math.floor(relX / BLOCK_SIZE) + 1
	local baseJ = math.floor(relZ / BLOCK_SIZE) + 1
	baseI = math.clamp(baseI, 1, lineCount)
	baseJ = math.clamp(baseJ, 1, lineCount)

	local depth = math.floor((zoneStartPos.Y - playerPos.Y) / BLOCK_SIZE) + 1
	depth = math.max(0, depth)

	local anchorPos = zoneStartPos + Vector3.new((baseI - 1) * BLOCK_SIZE, -depth * BLOCK_SIZE, (baseJ - 1) * BLOCK_SIZE)

	local startI
	local endI
	local startJ
	local endJ
	if drillWidth % 2 == 1 then
		local half = math.floor(drillWidth / 2)
		startI = baseI - half
		endI = baseI + half
		startJ = baseJ - half
		endJ = baseJ + half
	else
		local half = drillWidth / 2
		local biasX = (playerPos.X - anchorPos.X) >= 0 and 0 or -1
		local biasZ = (playerPos.Z - anchorPos.Z) >= 0 and 0 or -1
		local startOffsetX = -half + 1 + biasX
		local startOffsetZ = -half + 1 + biasZ
		startI = baseI + startOffsetX
		endI = startI + drillWidth - 1
		startJ = baseJ + startOffsetZ
		endJ = startJ + drillWidth - 1
	end

	local validIds = {}
	for i = startI, endI do
		if i >= 1 and i <= lineCount then
			for j = startJ, endJ do
				if j >= 1 and j <= lineCount then
					local blockId = `B_{zoneIndex}_{depth}_{i}_{j}`
					local blockIns = SystemMgr.systems.BlockSystem:GetBlockInsById(blockId)
					if blockIns then
						local blockPos = blockIns.position
						if blockPos and blockPos.Y < playerPos.Y then
							if (playerPos - blockPos).Magnitude <= maxDistance + BLOCK_SIZE then
								table.insert(validIds, blockId)
							end
						end
					end
				end
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

function Drill:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		self:applyBlockDamage(firingPlayer, fireInfo)
	end
end

function Drill:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function Drill:stopAnimations()
	self:stopDrilling()
	if self.curSlashTrack then
		self.curSlashTrack:Stop()
	end
	self.animTracks = {}
end

function Drill:cancelReload() end

function Drill:onDestroyed()
	self:stopDrilling()
	BaseWeapon.onDestroyed(self)
end

return Drill
