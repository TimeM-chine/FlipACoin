local Lighting = game:GetService("Lighting")
local folder = Lighting:WaitForChild("Blue")
local defaultFolder = Lighting:WaitForChild("Default")

local Blue = {}

function Blue:Start()
	for _, child in folder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
		child:Clone().Parent = Lighting
	end
end

function Blue:Stop()
	for _, child in defaultFolder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
		child:Clone().Parent = Lighting
	end
end

return Blue
