local Replicated = game:GetService("ReplicatedStorage")
local ShapecastHitbox = require(Replicated.Packages.shapecasthitbox)

ShapecastHitbox.Settings.Debug_Visible = false

local ActiveHitboxes = {}

local function create_new_hitbox(...)
	local instance = select(1, ...)

	if ActiveHitboxes[instance] then
		ActiveHitboxes[instance]:Destroy()
	end

	local newHitbox = ShapecastHitbox.new(...)
	ActiveHitboxes[instance] = newHitbox

	return ActiveHitboxes[instance]
end

local function get_hitbox(instance: Instance)
	return ActiveHitboxes[instance]
end

local function remove_hitbox(instance: Instance)
	if ActiveHitboxes[instance] then
		ActiveHitboxes[instance]:Destroy()
	end

	ActiveHitboxes[instance] = nil
end

return {
	new = create_new_hitbox,
	GetHitbox = get_hitbox,
	RemoveHitbox = remove_hitbox,
}
