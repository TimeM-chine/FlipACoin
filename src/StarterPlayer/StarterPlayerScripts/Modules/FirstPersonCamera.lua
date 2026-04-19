local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local function setCharacterVisibility(character, transparency)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.LocalTransparencyModifier = transparency
		end
	end
end

local function applyCameraLock()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	LocalPlayer.CameraMinZoomDistance = 0.5
	LocalPlayer.CameraMaxZoomDistance = 0.5

	if currentHumanoid and currentHumanoid.Parent and currentHumanoid.Health > 0 then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = currentHumanoid
		setCharacterVisibility(currentCharacter, 1)
	end

	if not UserInputService.TouchEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

local function bindCharacter(character)
	disconnectCharacterConnections()

	currentCharacter = character
	currentHumanoid = character and character:FindFirstChildOfClass("Humanoid") or nil

	if not character then
		return
	end

	setCharacterVisibility(character, 1)

	table.insert(characterConnections, character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.LocalTransparencyModifier = 1
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
