--[[
--Author: TimeM_chine
--Created Date: Mon Apr 29 2024
--Description: SpaceModule.lua
--Version: 1.0
--Last Modified: 2024-05-25 3:54:23
--]]

local Debris = game:GetService("Debris")

local SpaceModule = {}

function SpaceModule.GetPartBoundsInRadius(args: {position: Vector3, radius: number, visible: boolean, overlapParams: OverlapParams})
    local position = args.position
	local radius = args.radius
	local visible = args.visible
	local overlapParams = args.overlapParams
	local parts = workspace:GetPartBoundsInRadius(position, radius, overlapParams)
	
	if visible then
		local rangePart = Instance.new("Part")
		rangePart.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
		rangePart.Anchored = true
		rangePart.CanCollide = false
		rangePart.CanTouch = false
		rangePart.CanQuery = false
		rangePart.CFrame = CFrame.new(position)
		rangePart.Shape = Enum.PartType.Ball
		rangePart.Transparency = 0.5
		rangePart.Parent = workspace
		Debris:AddItem(rangePart, 5)
	end
	return parts
end

function SpaceModule.GetPartBoundsInBox(args: {cf: CFrame, size: Vector3, visible: boolean, overlapParams: OverlapParams})
    local cf = args.cf
	local size = args.size
	local visible = args.visible
	local overlapParams = args.overlapParams
	local parts = workspace:GetPartBoundsInBox(cf, size, overlapParams)
	
	if visible then
		local rangePart = Instance.new("Part")
		rangePart.Size = size
		rangePart.Anchored = true
		rangePart.CanCollide = false
		rangePart.CanTouch = false
		rangePart.CanQuery = false
		rangePart.CFrame = cf
		rangePart.Transparency = 0.5
		rangePart.Parent = workspace
		Debris:AddItem(rangePart, 5)
	end
	return parts
end

return SpaceModule