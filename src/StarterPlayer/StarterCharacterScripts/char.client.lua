-- local UserInputService = game:GetService("UserInputService")

-- -- Double Jump
-- local character = script.Parent
-- local humanoid: Humanoid = character:WaitForChild("Humanoid")
-- -- humanoid.WalkSpeed = 60
-- local canDoubleJump = false
-- local hasDoubleJumped = false
-- local oldPower, doubleJumpTrack
-- local TIME_BETWEEN_JUMPS = 0.2
-- local DOUBLE_JUMP_POWER_MULTIPLIER = 1.5

-- function onJumpRequest()
-- 	if
-- 		not character
-- 		or not humanoid
-- 		or not character:IsDescendantOf(workspace)
-- 		or humanoid:GetState() == Enum.HumanoidStateType.Dead
-- 	then
-- 		return
-- 	end

-- 	if canDoubleJump and not hasDoubleJumped then
-- 		hasDoubleJumped = true
-- 		humanoid.JumpPower = oldPower * DOUBLE_JUMP_POWER_MULTIPLIER
-- 		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
-- 		doubleJumpTrack:Play()
-- 	end
-- end

-- hasDoubleJumped = false
-- canDoubleJump = false
-- oldPower = humanoid.JumpPower
-- humanoid.UseJumpPower = true
-- local doubleJumpAnimation = Instance.new("Animation")
-- doubleJumpAnimation.AnimationId = "http://www.roblox.com/asset/?id=507765000"
-- doubleJumpTrack = humanoid:FindFirstChild("Animator"):LoadAnimation(doubleJumpAnimation)
-- doubleJumpTrack.Priority = Enum.AnimationPriority.Movement

-- humanoid.StateChanged:Connect(function(old, new)
-- 	if new == Enum.HumanoidStateType.Landed then
-- 		canDoubleJump = false
-- 		hasDoubleJumped = false
-- 		humanoid.JumpPower = oldPower
-- 	elseif new == Enum.HumanoidStateType.Freefall then
-- 		task.wait(TIME_BETWEEN_JUMPS)
-- 		canDoubleJump = true
-- 	elseif new == Enum.HumanoidStateType.FallingDown then
-- 		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
-- 	end
-- end)

-- UserInputService.JumpRequest:Connect(onJumpRequest)

-- -- while task.wait(2) do
-- -- 	local animator:Animator = humanoid:WaitForChild("Animator")
-- -- 	local tracks = animator:GetPlayingAnimationTracks()

-- -- 	for _, track:AnimationTrack in tracks do
-- -- 		local animation = track.Animation
-- -- 		print(animation.Name, animation.AnimationId)
-- -- 	end
-- -- end

-- local FastRoad = workspace:FindFirstChild("FastRoad")
-- if not FastRoad then
-- 	return
-- end

-- local character = script.Parent
-- local humanoid = character:WaitForChild("Humanoid")
-- local rootPart = character:WaitForChild("HumanoidRootPart")

-- local fastRoadParts = {}
-- for _, obj in FastRoad:GetChildren() do
-- 	if obj:IsA("Part") then
-- 		table.insert(fastRoadParts, obj)
-- 	end
-- end

-- FastRoad.ChildAdded:Connect(function(obj)
-- 	if obj:IsA("Part") then
-- 		table.insert(fastRoadParts, obj)
-- 	end
-- end)

-- local function isOnFastRoad()
-- 	local rootPos = rootPart.Position
-- 	for _, part in fastRoadParts do
-- 		local partPos = part.Position
-- 		local partSize = part.Size
-- 		if math.abs(rootPos.X - partPos.X) <= partSize.X / 2 and math.abs(rootPos.Z - partPos.Z) <= partSize.Z / 2 then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

-- game:GetService("RunService").RenderStepped:Connect(function()
-- 	if isOnFastRoad() then
-- 		humanoid.WalkSpeed = 40
-- 	else
-- 		humanoid.WalkSpeed = 20
-- 	end
-- end)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
-- humanoid.UseJumpPower = true
humanoid.JumpHeight = 12
-- warn(humanoid.UseJumpPower, humanoid.JumpHeight)
