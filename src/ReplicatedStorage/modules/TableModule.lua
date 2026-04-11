--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: TableModule.lua
--Version: 1.2.1
--Last Modified: 2024-04-19 3:14:43
--]]

local TableModule = {}

function TableModule.Choices(t: table, num: number, isDict)
	t = table.clone(t)
	num = num or 1
	if t[1] and not isDict then -- indicates that 't' is a number table
		if #t <= num then
			return t
		end

		local results = {}
		for i = 1, num do
			local randomIndex = math.random(1, #t)
			results[i] = t[randomIndex]
			table.remove(t, randomIndex)
		end

		return results
	else -- 't' is a key-value type table
		local totalWeight = 0
		for key, weight in pairs(t) do
			totalWeight = totalWeight + weight
		end

		local results = {}
		for i = 1, num do
			local randomValue = math.random() * totalWeight
			local weightSum = 0
			for key, weight in pairs(t) do
				weightSum = weightSum + weight
				if randomValue <= weightSum then
					table.insert(results, key)
					totalWeight = totalWeight - weight
					break
				end
			end
		end

		return results
	end
end

function TableModule.SetFirstNil(t, v)
	local nextEmptyIndex = #t + 1
	for i = 1, #t do
		if not t[i] then -- nil or false
			nextEmptyIndex = i
			break
		end
	end
	if type(v) == "table" then
		if v.index == nil then
			v.index = nextEmptyIndex
		end
	end
	t[nextEmptyIndex] = v

	return nextEmptyIndex
end

function TableModule.DeepCopy(t)
	local lookup_table = {}
	local function _copy(T)
		if type(T) ~= "table" then
			return T
		elseif lookup_table[T] then
			return lookup_table[T]
		end
		local new_table = {}
		lookup_table[T] = new_table
		for index, value in pairs(T) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(T))
	end
	return _copy(t)
end

function TableModule.Shuffle(t)
	local ct = TableModule.DeepCopy(t)
	local n = #ct
	while n > 1 do
		local k = math.random(n)
		ct[n], ct[k] = ct[k], ct[n]
		n = n - 1
	end
	return ct
end

function TableModule.RemoveByValue(t, value)
	for i, v in ipairs(t) do
		if v == value then
			table.remove(t, i)
			return i
		end
	end
end

function TableModule.Length(t)
	local len = 0
	for _, _ in pairs(t) do
		len = len + 1
	end
	return len
end

function TableModule.TrueLength(t)
	local len = 0
	for _, v in pairs(t) do
		if v then
			len = len + 1
		end
	end
	return len
end

function TableModule.IsEqual(t1, t2)
	for k, v in pairs(t1) do
		if t2[k] ~= v then
			return false
		end
	end
	return true
end

function TableModule.Keys(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end

function TableModule.Values(t)
	local values = {}
	for _, value in pairs(t) do
		table.insert(values, value)
	end
	return values
end

return TableModule
