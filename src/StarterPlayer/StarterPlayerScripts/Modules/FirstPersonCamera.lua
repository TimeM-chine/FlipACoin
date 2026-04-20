local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FirstPersonCamera = {}

local CAMERA_RENDERSTEP_NAME = "FlipACoinFirstPersonCamera"
local started = false
local currentCharacter
local currentHumanoid
local characterConnections = {}

local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function shouldHideInFirstPerson(descendant)
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
			descendant.LocalTransparencyModifier = shouldHideInFirstPerson(descendant) and 1 or 0
		end
	end
end

local function applyCameraLock()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	LocalPlayer.CameraMinZoomDistance = 10
	LocalPlayer.CameraMaxZoomDistance = 10

	if currentHumanoid and currentHumanoid.Parent and currentHumanoid.Health > 0 then
		local head = currentCharacter and currentCharacter:FindFirstChild("Head")
		if not head then
			return
		end

		local lookVector = camera.CFrame.LookVector
		local upVector = camera.CFrame.UpVector
		local cameraPosition = head.Position

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = currentHumanoid
		currentHumanoid.CameraOffset = Vector3.zero
		camera.CFrame = CFrame.lookAt(cameraPosition, cameraPosition + lookVector, upVector)
		camera.Focus = CFrame.lookAt(
			cameraPosition + lookVector,
			cameraPosition + (lookVector * 2),
			upVector
		)
		applyCharacterVisibility(currentCharacter)
	end
end

local function bindCharacter(character)
	disconnectCharacterConnections()

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
			descendant.LocalTransparencyModifier = shouldHideInFirstPerson(descendant) and 1 or 0
		end
	end))

	table.insert(characterConnections, character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			currentCharacter = nil
			currentHumanoid = nil
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

	RunService:BindToRenderStep(CAMERA_RENDERSTEP_NAME, Enum.RenderPriority.Camera.Value + 1, applyCameraLock)
	applyCameraLock()
end

return FirstPersonCamera
