local players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local RobStar = ReplicatedFirst:WaitForChild("RobStar")

function run()
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	RobStar.Parent = players.LocalPlayer.PlayerGui
	RobStar.LocalScript.Enabled = true
end

run()
