-- Functions
local function lerp(a, b, c)
	return a + (b - a) * c
end

return {
	GetMiddlePosition = function(StartPosition, TargetPosition, Angle, Offset)
		if typeof(StartPosition) ~= "Vector3" then
			StartPosition = StartPosition.Position
		end

		if typeof(TargetPosition) ~= "Vector3" then
			TargetPosition = TargetPosition.Position
		end

		if not Angle then
			Angle = 0
		end

		if not Offset then
			Offset = 1
		else
			Offset = 1 + Offset
		end

		local HalfVector3 = (StartPosition - TargetPosition) * 0.5 --起始与目标之间一半长度的向量
		local MiddlePosition = StartPosition - HalfVector3 --中间位置点
		local RotateCFrame = CFrame.new(MiddlePosition, TargetPosition) --从起始与目标之间的中心点指向目标的向量,用此向量进行旋转

		RotateCFrame = RotateCFrame * CFrame.Angles(0, 0, math.rad(Angle)) --根据角度旋转此向量
		local Radius = HalfVector3.Magnitude * Offset --旋转半径

		local ResultPosition = MiddlePosition + RotateCFrame.UpVector * Radius --中间位置 + 旋转后的上朝向 * 半径

		return ResultPosition
	end,

	QuadBezier = function(t, p0, p1, p2)
		local l1 = lerp(p0, p1, t)
		local l2 = lerp(p1, p2, t)
		local Quad = lerp(l1, l2, t)
		return Quad
	end,

	getVector2FromAngle = function(p0: Vector2, p2: Vector2, angle: number)
		local distance = (p0 - p2).Magnitude
		local acDis = distance * math.cos(math.rad(angle))

		local newangle = angle + math.rad(math.pi / 2)
		local y = acDis * math.cos(math.rad(newangle)) + p0.Y
		local x = acDis * math.cos(math.rad(newangle))
	end,
}
