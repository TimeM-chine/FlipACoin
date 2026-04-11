--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: Save data not related to player
--Version: 1.0
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")

---- requires ----
local GlobalDataPresets = require(script.Presets)

---- variables ----
local GLOBAL_DATA = "GlobalData"
local IsStudio = RunService:IsStudio()
local IsLoaded = false
local dataStore = DataStoreService:GetDataStore(GLOBAL_DATA)
local memoryStore = MemoryStoreService:GetHashMap(GLOBAL_DATA)
local EXPIRE_TIME = 60 * 60 * 24 * 30 -- 1 week

local GlobalDataModule = {}

function GlobalDataModule.Init()
	local success, res = pcall(function()
		for key, value in pairs(GlobalDataPresets) do
			local storedValue = memoryStore:GetAsync(key)
			if not storedValue then
				-- dataStore:SetAsync(key, value)
				memoryStore:SetAsync(key, value, EXPIRE_TIME)
				-- else
				-- memoryStore:SetAsync(key, storedValue, EXPIRE_TIME)
			end
		end

		return true
	end)

	if success then
		local folder = Instance.new("Folder")
		folder.Name = "IsLoaded"
		folder.Parent = script
		IsLoaded = true
	end
end

function GlobalDataModule.GetMemoryStore(storeName)
	if not IsLoaded then
		script:WaitForChild("IsLoaded")
	end
	local success, res = pcall(function()
		local data = memoryStore:GetAsync(storeName)
		return data
	end)
	return success and res or nil
end

function GlobalDataModule.GetMemoryValue(storeName, key)
	if not IsLoaded then
		script:WaitForChild("IsLoaded")
	end
	local success, res = pcall(function()
		local data = memoryStore:GetAsync(storeName)
		return data[key]
	end)
	return success and res or nil
end

-- function GlobalDataModule.AddMemoryValue(storeName, key, value)
--     if not IsLoaded then
--         script:WaitForChild("IsLoaded")
--     end
--     local success, res = pcall(function()
--         memoryStore:UpdateAsync(storeName, function(oldTable)
--             oldTable[key] += value
--             return oldTable
--         end, EXPIRE_TIME)

--         -- if not IsStudio then
--         --     dataStore:UpdateAsync(storeName, function(oldTable)
--         --         oldTable[key] += value
--         --         return oldTable
--         --     end)
--         -- end

--         return true
--     end)
--     return success and res or nil
-- end

function GlobalDataModule.BuyLimitedPet(petName, count)
	if not IsLoaded then
		script:WaitForChild("IsLoaded")
	end
	local success, res = pcall(function()
		memoryStore:UpdateAsync("LimitedPets", function(oldTable)
			local newValue = oldTable[petName] + count
			oldTable[petName] = newValue
			return oldTable
		end, EXPIRE_TIME)

		-- if not IsStudio then
		--     dataStore:UpdateAsync(storeName, function(oldTable)
		--         oldTable[key] += value
		--         return oldTable
		--     end)
		-- end

		return true
	end)
	return success and res or nil
end

return GlobalDataModule
