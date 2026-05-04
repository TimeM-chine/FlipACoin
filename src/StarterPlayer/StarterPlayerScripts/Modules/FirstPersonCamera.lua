local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FirstPersonCamera = {}

local CAMERA_RENDERSTEP_NAME = "FlipACoinFirstPersonCamera"
local FREE_CAMERA_ZOOM_DISTANCE = 10
local FREE_FIELD_OF_VIEW = 70
local FOLLOW_FIELD_OF_VIEW = 68
local FOLLOW_LERP_ALPHA = 0.34
local FOLLOW_TARGET_OFFSET = Vector3.new(0, 0.08, 0)
local DEFAULT_FOLLOW_DURATION = 1.1
local HEAD_POSE_SEND_INTERVAL = 1 / 12
local HEAD_POSE_FORCE_INTERVAL = 0.35
local HEAD_POSE_DELTA = math.rad(1.5)
local HEAD_POSE_PITCH_LIMIT = math.rad(35)
local HEAD_POSE_YAW_LIMIT = math.rad(90)
local CAMERA_YAW_LIMIT = math.rad(90)
local started = false
local currentCharacter
local currentHumanoid
local characterConnections = {}
local coinFollowState
local SystemMgr
local lastHeadPosePitch = 0
local lastHeadPoseYaw = 0
local lastHeadPoseSentAt = 0
local lastHeadPoseForceSentAt = 0

local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function shouldHideForFirstPerson(descendant)
	if descendant:IsA("BasePart") then
		if descendant.Name == "Head" then
			return true
		end

		local accessory = descendant.Parent
		if accessory and accessory:IsA("Accessory") then
			return true
		end
	end

	return false
end

local function applyCharacterVisibility(character)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = shouldHideForFirstPerson(descendant) and 1 or 0
		end
	end
end

local function getHead()
	if not currentCharacter then
		return nil
	end

	local head = currentCharacter:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	return nil
end

local function getRootPart()
	if not currentCharacter then
		return nil
	end

	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getCharacterSystem()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
	end

	local characterSystem = SystemMgr.systems.CharacterSystem
	if not characterSystem or not characterSystem.Server or not characterSystem.Server.HeadPoseChanged then
		return nil
	end

	return characterSystem
end

local function clearCoinFollow(coin)
	if coin and coinFollowState and coinFollowState.coin ~= coin then
		return
	end

	coinFollowState = nil
end

local function sendHeadPose(pitch, yaw, force)
	local now = os.clock()
	if not force and now - lastHeadPoseSentAt < HEAD_POSE_SEND_INTERVAL then
		return
	end

	local pitchDelta = math.abs(pitch - lastHeadPosePitch)
	local yawDelta = math.abs(yaw - lastHeadPoseYaw)
	if not force and pitchDelta < HEAD_POSE_DELTA and yawDelta < HEAD_POSE_DELTA and now - lastHeadPoseForceSentAt < HEAD_POSE_FORCE_INTERVAL then
		return
	end

	local characterSystem = getCharacterSystem()
	if not characterSystem then
		return
	end

	characterSystem.Server:HeadPoseChanged({
		pitch = pitch,
		yaw = yaw,
		unreliable = true,
	})

	lastHeadPosePitch = pitch
	lastHeadPoseYaw = yaw
	lastHeadPoseSentAt = now
	if force or pitchDelta >= HEAD_POSE_DELTA or yawDelta >= HEAD_POSE_DELTA then
		lastHeadPoseForceSentAt = now
	end
end

local function updateHeadPoseFromCamera(camera)
	local rootPart = getRootPart()
	if not rootPart then
		sendHeadPose(0, 0, false)
		return
	end

	local localLook = rootPart.CFrame:VectorToObjectSpace(camera.CFrame.LookVector)
	local pitch = math.asin(math.clamp(localLook.Y, -1, 1))
	local yaw = math.atan2(-localLook.X, -localLook.Z)

	sendHeadPose(
		math.clamp(pitch, -HEAD_POSE_PITCH_LIMIT, HEAD_POSE_PITCH_LIMIT),
		math.clamp(yaw, -HEAD_POSE_YAW_LIMIT, HEAD_POSE_YAW_LIMIT),
		false
	)
end

local function clampLookToRootYaw(lookVector)
	local rootPart = getRootPart()
	if not rootPart then
		return lookVector
	end

	local localLook = rootPart.CFrame:VectorToObjectSpace(lookVector)
	local pitch = math.asin(math.clamp(localLook.Y, -0.98, 0.98))
	local yaw = math.atan2(-localLook.X, -localLook.Z)
	yaw = math.clamp(yaw, -CAMERA_YAW_LIMIT, CAMERA_YAW_LIMIT)

	local pitchCos = math.cos(pitch)
	local clampedLocalLook = Vector3.new(
		-math.sin(yaw) * pitchCos,
		math.sin(pitch),
		-math.cos(yaw) * pitchCos
	)
	return rootPart.CFrame:VectorToWorldSpace(clampedLocalLook)
end

local function applyFreeFirstPerson(camera)
	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	LocalPlayer.CameraMinZoomDistance = FREE_CAMERA_ZOOM_DISTANCE
	LocalPlayer.CameraMaxZoomDistance = FREE_CAMERA_ZOOM_DISTANCE
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = FREE_FIELD_OF_VIEW

	if currentHumanoid and currentHumanoid.Parent then
		camera.CameraSubject = currentHumanoid
		currentHumanoid.CameraOffset = Vector3.zero
	end

	local head = getHead()
	if not head then
		return
	end

	local lookVector = clampLookToRootYaw(camera.CFrame.LookVector)
	local upVector = camera.CFrame.UpVector
	local cameraPosition = head.Position

	camera.CFrame = CFrame.lookAt(cameraPosition, cameraPosition + lookVector, upVector)
	camera.Focus = CFrame.lookAt(cameraPosition + lookVector, cameraPosition + (lookVector * 2), upVector)
	applyCharacterVisibility(currentCharacter)
	updateHeadPoseFromCamera(camera)
end

local function applyCoinFollow(camera)
	local state = coinFollowState
	if not state then
		return false
	end

	if os.clock() >= state.releaseAt or not state.coin or not state.coin:IsDescendantOf(Workspace) then
		clearCoinFollow()
		return false
	end

	local head = getHead()
	if not head then
		clearCoinFollow()
		return false
	end

	local cameraPosition = head.Position
	local targetPosition = state.coin.Position + FOLLOW_TARGET_OFFSET
	local lookOffset = targetPosition - cameraPosition
	if lookOffset.Magnitude < 0.001 then
		return true
	end

	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOLLOW_FIELD_OF_VIEW

	local targetLookVector = clampLookToRootYaw((targetPosition - cameraPosition).Unit)
	local targetCFrame = CFrame.lookAt(cameraPosition, cameraPosition + targetLookVector, Vector3.yAxis)
	if state.isFresh then
		camera.CFrame = targetCFrame
		state.isFresh = false
	else
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, FOLLOW_LERP_ALPHA)
	end
	camera.Focus = CFrame.lookAt(targetPosition, targetPosition + targetCFrame.LookVector, Vector3.yAxis)
	applyCharacterVisibility(currentCharacter)
	updateHeadPoseFromCamera(camera)

	return true
end

local function applyCamera()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	if not currentHumanoid or not currentHumanoid.Parent or currentHumanoid.Health <= 0 then
		clearCoinFollow()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = FREE_FIELD_OF_VIEW
		sendHeadPose(0, 0, true)
		return
	end

	if applyCoinFollow(camera) then
		return
	end

	applyFreeFirstPerson(camera)
end

local function bindCharacter(character)
	disconnectCharacterConnections()
	clearCoinFollow()

	currentCharacter = character
	currentHumanoid = nil

	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		currentHumanoid = humanoid
	end

	applyCharacterVisibility(character)

	table.insert(characterConnections, character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = shouldHideForFirstPerson(descendant) and 1 or 0
		end
	end))

	table.insert(characterConnections, character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			currentCharacter = nil
			currentHumanoid = nil
			clearCoinFollow()
			disconnectCharacterConnections()
		end
	end))
end

function FirstPersonCamera.Start()
	if started then
		return
	end
	started = true

	bindCharacter(LocalPlayer.Character)
	LocalPlayer.CharacterAdded:Connect(bindCharacter)

	RunService:BindToRenderStep(CAMERA_RENDERSTEP_NAME, Enum.RenderPriority.Camera.Value + 1, applyCamera)
	applyCamera()
end

function FirstPersonCamera.FollowCoin(coin, args)
	if not coin or not coin:IsA("BasePart") then
		return
	end

	local duration = args and args.duration or DEFAULT_FOLLOW_DURATION
	coinFollowState = {
		coin = coin,
		releaseAt = os.clock() + duration,
		isFresh = true,
	}
end

function FirstPersonCamera.ReturnToFirstPerson(coin)
	clearCoinFollow(coin)
	applyCamera()
end

return FirstPersonCamera
