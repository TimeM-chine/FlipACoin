local Players = game:GetService("Players")

local RaycastFilters = {}

function RaycastFilters.Grasses()
	return {
		workspace:FindFirstChild("Grasses"):FindFirstChild("ClientGrass"),
	}
end

function RaycastFilters.PlayersExcept(player)
	local filter = {}

	for _, p in Players:GetPlayers() do
		if p == player then
			continue
		end

		if not p.Character then
			continue
		end

		if p.Character.Parent ~= workspace then
			continue
		end

		if p.Character:GetAttribute("isDead") then
			continue
		end

		table.insert(filter, p.Character)
	end

	return filter
end

function RaycastFilters.Blocks()
	return {
		workspace:FindFirstChild("Blocks"):FindFirstChild("ClientBlocks"),
	}
end

function RaycastFilters.GrassesAndPlayersExcept(player)
	local filter = RaycastFilters.Grasses()
	for _, char in RaycastFilters.PlayersExcept(player) do
		table.insert(filter, char)
	end

	return filter
end

return RaycastFilters
