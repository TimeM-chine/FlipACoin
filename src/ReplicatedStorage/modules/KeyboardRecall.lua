-- ================================================================================
-- on key press -> client and server side
-- ================================================================================

---- services ----
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

---- events ----
local UISEvent = game.ReplicatedStorage.RemoteEvents.UISEvent

local recalls = {}

function recalls.SetClientRecall(key, recall)
	if recalls[key] then
		recalls[key].onClient = recall
	else
		recalls[key] = {}
		recalls[key].onClient = recall
	end
end

function recalls.SetServerRecall(key, recall)
	if recalls[key] then
		recalls[key].onServer = recall
	else
		recalls[key] = {}
		recalls[key].onServer = recall
	end
end

if RS:IsClient() then
	UIS.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if recalls[input.KeyCode] then
					UISEvent:FireServer(input.KeyCode)
					local func = recalls[input.KeyCode].onClient
					if func then
						func()
					end
				end
			end
		end
	end)
end

if RS:IsServer() then
	UISEvent.OnServerEvent:Connect(function(player, code)
		if recalls[code] then
			local func = recalls[code].onServer
			if func then
				func(player)
			end
		end
	end)
end

return recalls
