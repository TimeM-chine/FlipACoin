

local ClientData = {}
ClientData._Data = {}

local initialized = false

function ClientData.InitData(data)
    ClientData._Data = data
    initialized = true
    local flag = Instance.new("BoolValue")
    flag.Name = "initialized"
    flag.Parent = script
end

function ClientData:GetOneData(key)
    if not initialized then
        -- warn("ClientData not initialized")
        script:WaitForChild("initialized")
    end
    return self._Data[key]
end

function ClientData:GetAllData()
    if not initialized then
        -- warn("ClientData not initialized")
        script:WaitForChild("initialized")
    end
    return self._Data
end

function ClientData:SetOneData(key, value)
    if not initialized then
        -- warn("ClientData not initialized")
        script:WaitForChild("initialized")
    end
    self._Data[key] = value
end

function ClientData:SetDataTable(t)
    if not initialized then
        -- warn("ClientData not initialized")
        script:WaitForChild("initialized")
    end
    for k, v in pairs(t) do
        self._Data[k] = v
    end
end

-- function ClientData.WaitForInitialize()
--     if not initialized then
--         script:WaitForChild("initialized")
--     end
-- end

return ClientData