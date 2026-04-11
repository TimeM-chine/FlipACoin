--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: BillboardManager.lua
--Version: 1.21
--Last Modified: 2025-12-08 10:00:00
--]]

local BillboardManager = {}

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(game.ReplicatedStorage.configs.GameConfig)

local config = { count = 100, refreshTime = 60 }
local Util = require(game.ReplicatedStorage.modules.Util)

local RankingListFolder = workspace:WaitForChild("RankingList", 30)
if not RankingListFolder then
	warn("--------------RankingListFolder not found--------------")
	return {
		initBillboard = function() end,
		savePlayerRankData = function() end,
	}
end

local topBgColors = {
	[1] = Color3.fromRGB(255, 213, 0),
	[2] = Color3.fromRGB(194, 194, 194),
	[3] = Color3.fromRGB(152, 99, 0),
}

-- local function GetFrame(name)
-- 	return RankingListFolder:WaitForChild(name):WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("Frame")
-- end

-- local rankFrames = {
-- 	power = GetFrame("power"),
-- 	wins = GetFrame("wins"),
-- 	rebirth = GetFrame("rebirth"),
-- 	eggHatched = GetFrame("eggHatched"),
-- }
local rankFrames = {
	wins = {},
	cardPackOpened = {},
}

for name, t in rankFrames do
	local rankFolder = RankingListFolder:WaitForChild(name)
	for _, model in pairs(rankFolder:GetChildren()) do
		local frame = model:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("Frame")
		frame:WaitForChild("ScrollingFrame"):WaitForChild("Template").Visible = false
		table.insert(t, frame)
	end
end

local rankPageList = {}
local userInfoCache = {}

-- Create rank item
function createRankItem(rank, userId, score, rankType, RankFrame)
	if not userInfoCache["Player_" .. userId] then
		return
	end
	local rankCard = RankFrame.ScrollingFrame:FindFirstChild("Rank" .. rank)

	if not rankCard then
		local template = RankFrame.ScrollingFrame.Template
		rankCard = template:Clone()
		if topBgColors[rank] then
			rankCard.BackgroundColor3 = topBgColors[rank]
		end
		rankCard.Visible = true
		rankCard.Name = "Rank" .. rank
		rankCard.LayoutOrder = rank
		rankCard.Parent = RankFrame.ScrollingFrame
	end

	local playerName = rankCard:WaitForChild("name")
	playerName.Text = userInfoCache["Player_" .. userId]["DisplayName"]

	local avatar = rankCard:WaitForChild("avatar")
	avatar.Image = Util.GetPlayerAvatar(userId)

	local Counts = rankCard:WaitForChild("score")
	Counts.Text = Util.FormatNumber(score)

	local rankLabel = rankCard:WaitForChild("rank")
	rankLabel.Text = "#" .. rank
end

function updateLeaderBoard(pages, rankType)
	local topTen = pages:GetCurrentPage()
	local tempRankList = {}
	local RankFrameList = rankFrames[rankType]

	local rank = 1

	-- -- update newest data to cache
	-- if not rankDataByUserId[rankType] then
	-- 	rankDataByUserId[rankType] = {}
	-- end

	for i, data in ipairs(topTen) do
		local userId = tonumber(string.match(data.key, ".*_(%d+)"))
		local score = data.value
		for _, rankFrame in pairs(RankFrameList) do
			createRankItem(rank, userId, score, rankType, rankFrame)
		end
		-- tempRankList["Player_"..userId] = playerRankData

		rank = rank + 1

		if rank == 101 then
			break
		end
	end

	-- rankDataByUserId[rankType] = tempRankList
end

--[[
	Save Player Rank Data
	@param playerUserId 
	@param count player's scrore
	@param db dbname
]]
function BillboardManager.savePlayerRankData(playerUserId, count, db)
	-- if RunService:IsStudio() then
	-- 	return
	-- end
	if playerUserId <= 0 then
		return
	end

	if not count then
		return
	end

	if count == 0 then
		return
	end

	-- check if admin
	if table.find(GameConfig.DevIds, playerUserId) then
		count = math.random(1, 10)
		-- print("admin can't save rank data")
		-- return
	end

	local playerScope = "Player_" .. playerUserId
	local billboardODS = DataStoreService:GetOrderedDataStore(db)
	local setSuccess, errorMessage = pcall(function()
		billboardODS:SetAsync(playerScope, count)
	end)

	if not setSuccess then
		warn(errorMessage)
	else
		-- print("save player rank correctly "..db.. " count="..count)
	end
end

function BillboardManager.initBillboard()
	local allPlayerIds = {}

	for rankType, _ in pairs(rankFrames) do
		local dbName = rankType

		local billboardODS = DataStoreService:GetOrderedDataStore(dbName)
		local setSuccess, pages = pcall(function()
			if string.match(dbName, "Time") then
				return billboardODS:GetSortedAsync(true, config.count)
			else
				return billboardODS:GetSortedAsync(false, config.count)
			end
		end)

		if not setSuccess then
			warn(pages)
		else
			rankPageList[rankType] = pages

			local topTen = pages:GetCurrentPage()
			for rank, data in ipairs(topTen) do
				local userId = tonumber(string.match(data.key, ".*_(%d+)"))

				if userInfoCache["Player_" .. userId] then
					continue
				end
				if table.find(allPlayerIds, userId) then
					continue
				end
				table.insert(allPlayerIds, userId)
			end
		end
	end

	local allPlayerIdsGroup = {}
	local groupCount = math.ceil(#allPlayerIds / 100)
	for i = 1, groupCount do
		local startIndex = (i - 1) * 100 + 1
		local endIndex = i * 100
		local group = {}
		for j = startIndex, endIndex do
			if allPlayerIds[j] then
				table.insert(group, allPlayerIds[j])
			end
		end
		table.insert(allPlayerIdsGroup, group)
	end

	for _, group in ipairs(allPlayerIdsGroup) do
		local success2, usersInfo = pcall(function()
			return game:GetService("UserService"):GetUserInfosByUserIdsAsync(group)
		end)
		if not success2 then
			warn(usersInfo)
			return
		else
			for _, userInfo in pairs(usersInfo) do
				local userId = userInfo.Id
				userInfoCache["Player_" .. userId] = {
					DisplayName = userInfo.DisplayName,
					Username = userInfo.Username,
				}
			end
		end
	end

	-- update all billboard
	for rankType, pageData: Pages in pairs(rankPageList) do
		updateLeaderBoard(pageData, rankType)
	end
	print("update billboard")
end

return BillboardManager
