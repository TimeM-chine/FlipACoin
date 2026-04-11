-- This script replaces a player's default walk animation. Insert into ServerScriptService.

-- Services
local Players = game:GetService("Players")

-- Animation ID - Each one must be a number, like 616163682
local walkAnimationID = 0
local idleAnimationID = 0

local replacementAnimations = {
	{
		name = "run",
		id = (walkAnimationID ~= 0 and "http://www.roblox.com/asset/?id=" .. walkAnimationID) or "",
		isLoaded = false,
	},
	{
		name = "idle",
		id = (idleAnimationID ~= 0 and "http://www.roblox.com/asset/?id=" .. idleAnimationID) or "",
		isLoaded = false,
	},
}

-- Local Functions
local function onCharacterAdded(character)
	task.wait(1) -- You want to wait for the Animate script to load and run

	local humanoid = character:WaitForChild("Humanoid")
	for _, playingTracks in pairs(humanoid:GetPlayingAnimationTracks()) do
		playingTracks:Stop(0)
	end

	local animateScript = character:WaitForChild("Animate")

	for _, anim in ipairs(replacementAnimations) do
		if not anim.isLoaded then
			continue
		end

		local animations = animateScript:WaitForChild(anim.name):GetChildren()
		-- Overwrite the IDs of all idle animation instances
		for _, animVariant in ipairs(animations) do
			animVariant.AnimationId = anim.id

			-- If you really want to prevent the animations from being changed by something else you could do this too
			animVariant:GetPropertyChangedSignal("AnimationId"):Connect(function()
				animVariant.AnimationId = anim.id
			end)
		end
	end

	-- Stop all currently playing animation tracks on the player
	for _, playingAnimation in pairs(humanoid:GetPlayingAnimationTracks()) do
		playingAnimation:Stop()
		playingAnimation:Destroy()
	end
end

local function onPlayerAdded(player)
	--Only run this code if an animation actually is loaded in.
	local character = player.Character or player.CharacterAdded:wait()
	onCharacterAdded(character)
end

-- On Startup
for _, anim in ipairs(replacementAnimations) do
	--Check if there is an animation to load, if so, continue this script.
	if anim.id ~= "" then
		print("Valid Animation ID found. Replacing default animation")
		anim.isLoaded = true
	else
		print(anim.name .. " animation ID is blank. Keeping default animation")
	end
end

-- Connections
Players.PlayerAdded:Connect(onPlayerAdded)
