local players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

-- local loadingScreen = ReplicatedFirst:WaitForChild("LoadingScreen")
local RobStar = ReplicatedFirst:WaitForChild("RobStar")

function run()
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	-- loadingScreen.Parent = players.LocalPlayer.PlayerGui
	RobStar.Parent = players.LocalPlayer.PlayerGui
	RobStar.LocalScript.Enabled = true
end

run()
