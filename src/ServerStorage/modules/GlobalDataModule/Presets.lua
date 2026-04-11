local Replicated = game:GetService("ReplicatedStorage")
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)

local GlobalDataPresets = {}

GlobalDataPresets.LimitedPets = {}

for petName, v in pairs(EcoPresets.Products.limitedPets) do
    GlobalDataPresets.LimitedPets[petName] = 0  -- purchased amount
end

return GlobalDataPresets