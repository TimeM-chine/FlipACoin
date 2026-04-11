local Debris = game:GetService("Debris")
local Bezier = require(script.Parent.Bezier)

local Projectile = {}
Projectile.__index = Projectile

--[=[
    创建一个抛物线

    -- fromCFrame 
    -- toCFrame
    -- bullet
]=]
function Projectile.new(startCFrame: CFrame, endCFrame: CFrame, bullet: Instance, hit: Instance, ifDebris: boolean)
	local self = setmetatable({}, Projectile)

	self._finishedEvent = Instance.new("BindableEvent")
	self.Finished = self._finishedEvent.Event

	self.StartCFrame = startCFrame
	self.EndCFrame = endCFrame
	self.Bullet = bullet
	self.Hit = hit
	self.Speed = 10
	self.CurveType = "QuadBezier"
	self.DebrisTime = 0
	self.Rotation = { 0, 0, 0 }

	if ifDebris == nil then
		self.IfDebris = true
	else
		self.IfDebris = ifDebris
	end
	return self
end

function Projectile:doEffect()
	if self.Bullet == nil then
		return
	end

	local bullet = self.Bullet
	-- bullet.CFrame = self.StartCFrame
	-- bullet.Parent = workspace.Effects

	local bezierAngle = math.random(-45, 45)
	local bezierOffset = 0

	local Elapsed = 0
	local distance = (self.StartCFrame.Position - self.EndCFrame.Position).Magnitude
	local durationTime = distance / self.Speed
	local midPoint = Bezier.GetMiddlePosition(self.StartCFrame, self.EndCFrame, bezierAngle, bezierOffset)

	local primaryPart = nil
	if bullet:IsA("Model") then
		primaryPart = bullet.PrimaryPart
	else
		primaryPart = bullet
	end
	local stepConn = nil
	self.IsActive = true
	-- 如果bullet子项有sound，则播放
	if bullet:FindFirstChild("Sound") then
		bullet.Sound:Play()
	end
	stepConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		-- local success, error = pcall(function()
		Elapsed += dt
		local ratioTime = Elapsed / durationTime
		local curvePos = nil
		if self.CurveType == "QuadBezier" then
			curvePos = Bezier.QuadBezier(ratioTime, self.StartCFrame.Position, midPoint, self.EndCFrame.Position)
		elseif self.CurveType == "Linear" then
			curvePos = self.StartCFrame.Position:Lerp(self.EndCFrame.Position, ratioTime)
		end

		-- fly over
		if Elapsed >= durationTime then
			stepConn:Disconnect()
			stepConn = nil
			if self.IfDebris then
				Debris:AddItem(primaryPart, self.DebrisTime)
			end

			if bullet:FindFirstChild("Humanoid") then
				bullet.PrimaryPart.Position = self.EndCFrame.Position + Vector3.new(0, 5, 0)
			end
			self:doHitEffect()

			self._finishedEvent:Fire()
			self.IsActive = false
		elseif primaryPart then
			primaryPart.CFrame = CFrame.fromMatrix(
				curvePos,
				primaryPart.CFrame.XVector,
				primaryPart.CFrame.YVector,
				primaryPart.CFrame.ZVector
			) * CFrame.Angles(table.unpack(self.Rotation))
			self.CurrentCFrame = primaryPart.CFrame
		end
		-- end)

		-- if not success then
		--     if stepConn then
		-- 		stepConn:Disconnect()/
		-- 		stepConn = nil
		--     end
		--     print(error)
		-- end
	end)
end

--[[
	碰撞粒子效果
]]
function Projectile:doHitEffect()
	if self.Hit then
		local hitEffect = self.Hit
		hitEffect.CFrame = self.EndCFrame
		hitEffect.Parent = workspace.Effects

		-- 如果hitEffect子项有sound，则播放
		if hitEffect:FindFirstChild("Sound") then
			hitEffect.Sound:Play()
		end

		game:GetService("Debris"):AddItem(hitEffect, 2)

		for _, v in ipairs(hitEffect:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
end

return Projectile
