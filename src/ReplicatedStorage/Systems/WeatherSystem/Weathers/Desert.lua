
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local folder = Lighting:WaitForChild("Desert")
local defaultFolder = Lighting:WaitForChild("Default")


local sandClone, isSand, currentRate

local Desert = {}


function Desert:Start()
	for _, child in folder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
		child:Clone().Parent = Lighting
	end
	isSand = true
	sandClone = script.Parent.Parent.Assets:WaitForChild("Sandstorm"):Clone()
	sandClone.Parent = workspace.Weather
	currentRate = 50
	checkInOpen()
end

function Desert:Stop()
	isSand = false
	toggleRainAnimation(0)
	if sandClone then
		sandClone:Destroy()
	end
    for _, child in defaultFolder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
        child:Clone().Parent = Lighting
    end
end

function toggleRainAnimation(rate)
	currentRate = rate
	if sandClone then
		for i,v in pairs(sandClone:GetChildren()) do
			if v:IsA("ParticleEmitter") then

				local tween = TweenService:Create(v, TweenInfo.new(0.05, Enum.EasingStyle.Quad), {["Rate"] = rate})
				tween:Play()

			end
		end
		task.wait(0.05)
	end
end


function checkInOpen()

	while isSand and sandClone  do

		if workspace.CurrentCamera then
			local params = RaycastParams.new()
			params.RespectCanCollide = false
			if game.Players.LocalPlayer and game.Players.LocalPlayer.Character and game.Players.LocalPlayer:FindFirstChild("Humanoid") then
				params.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}

				local roof = workspace:Raycast(game.Players.LocalPlayer.Character:GetPivot().Position + Vector3.new(0,3.5,0), Vector3.new(0,1000,0), params)
				if not roof and currentRate == 0 then
					toggleRainAnimation(57)
				elseif roof and currentRate ~= 0 then
					toggleRainAnimation(0)
				end
	
				sandClone.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 0, -10)
			end

		end
		task.wait(.1)

	end
end

return Desert
