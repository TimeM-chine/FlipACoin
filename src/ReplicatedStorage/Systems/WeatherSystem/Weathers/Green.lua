
local Lighting = game:GetService("Lighting")
local folder = Lighting:WaitForChild("Green")
local defaultFolder = Lighting:WaitForChild("Default")


local Green = {}


function Green:Start()
	for _, child in folder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
		child:Clone().Parent = Lighting
	end
end

function Green:Stop()
    for _, child in defaultFolder:GetChildren() do
		local old = Lighting:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
        child:Clone().Parent = Lighting
    end
end

return Green
