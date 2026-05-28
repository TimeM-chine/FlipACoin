local players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LoadingScreenTemplate = ReplicatedFirst:WaitForChild("LoadingScreen")

function run()
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	local loadingScreen = LoadingScreenTemplate:Clone()
	loadingScreen.LocalScript.Enabled = false
	loadingScreen.Parent = players.LocalPlayer:WaitForChild("PlayerGui")

	task.spawn(function()
		require(loadingScreen.Loader).Start()
	end)
end

run()
