-- ================================================================================
-- some functions for Model
-- ================================================================================
local TweenService = game:GetService("TweenService")

local ModelModule = {}

function ModelModule.SetModelTransparency(model, ratio, whiteList)
	whiteList = whiteList or {}
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") and not table.find(whiteList, des) then
			des.Transparency = ratio
		end
	end
end

function ModelModule.SetModelCollide(model, collide, whiteList)
	whiteList = whiteList or {}
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") and not table.find(whiteList, des) then
			des.CanCollide = collide
		end
	end
end

function ModelModule.SetModelAnchor(model, anchor)
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") then
			des.Anchored = anchor
		end
	end
end

function ModelModule.SetModelProperty(model, propertyTable)
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") then
			for property, value in propertyTable do
				des[property] = value
			end
		end
	end
end

function ModelModule.TweenModelSize(model, t, ratio, whiteList)
	whiteList = whiteList or {}
	local parts = model:GetDescendants()
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(t) -- Change the duration as desired
			local size = part.Size * ratio
			local originalSize = Instance.new("Vector3Value")
			originalSize.Name = "OriginalSize"
			originalSize.Value = part.Size
			originalSize.Parent = part
			local tween = TweenService:Create(part, tweenInfo, { Size = size })
			tween:Play()
		end
	end
end

function ModelModule.ResetModelSize(model, t, whiteList)
	whiteList = whiteList or {}
	local parts = model:GetDescendants()
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(t) -- Change the duration as desired
			local originalSize = part:FindFirstChild("OriginalSize")
			if originalSize then
				local tween = TweenService:Create(part, tweenInfo, { Size = originalSize.Value })
				tween:Play()
			end
		end
	end
end

function ModelModule.SetModelCollisionGroup(model: Model, groupId)
	-- change the collision group of the model
	for _, des in model:GetDescendants() do
		if des:IsA("BasePart") then
			des.CollisionGroup = groupId
		end
	end
	model.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = groupId
		end
	end)
end

function ModelModule.GetMass(model)
	local totalMass = 0
	-- Loop through all the parts in the model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Get the mass of each part and add it to the total mass
			totalMass = totalMass + part:GetMass()
		end
	end
	return totalMass
end

function ModelModule.SetPlayerTransparency(player, args)
	local ratio = args.ratio or 1
	local whiteList = args.whiteList or {}
	local duration = args.duration or 1

	local Character
	if player:IsA("Model") then
		Character = player
	else
		Character = player.Character or player.CharacterAdded:Wait()
	end

	for _, des in Character:GetDescendants() do
		if des:IsA("BasePart") then
			if des.Transparency == 1 and not table.find(whiteList, des) then
				table.insert(whiteList, des)
			end
		end
	end

	ModelModule.SetModelTransparency(Character, ratio, whiteList)
	local resetRatio = 1 - ratio
	task.wait(duration)
	ModelModule.SetModelTransparency(Character, resetRatio, whiteList)
end

function ModelModule.GetModelBottomY(model)
	local boxCf, boxSize = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - boxSize.Y / 2
	return bottomY
end

function ModelModule.AlignModelToGround(model, groundHeight)
	local bottomY = ModelModule.GetModelBottomY(model)
	local offsetY = groundHeight - bottomY
	local newPivot = model:GetPivot() + Vector3.new(0, offsetY, 0)
	model:PivotTo(newPivot)
	return newPivot
end

return ModelModule
