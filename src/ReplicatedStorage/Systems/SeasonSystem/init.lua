--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.2 Analysis
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

---- requires ----
local SeasonPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local TableModule = require(Replicated.modules.TableModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData, SeasonUi


local SeasonSystem:Types.System = {
    whiteList = {},
    players = {},
    tasks = {},
    IsLoaded = false
}
SeasonSystem.__index = SeasonSystem

if IsServer then
    SeasonSystem.Client = setmetatable({}, SeasonSystem)
    -- Template.AllClients = setmetatable({}, Template)
    local ServerStorage = game:GetService("ServerStorage")
    PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
    -- AnalyticsService = game:GetService("AnalyticsService")
else
    SeasonSystem.Server = setmetatable({}, SeasonSystem)
    LocalPlayer = Players.LocalPlayer
    ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
    if not SystemMgr then
        SystemMgr = require(Replicated.Systems.SystemMgr)
        SENDER = SystemMgr.SENDER
    end
    return SystemMgr
end

function SeasonSystem:Init()
    GetSystemMgr()
end

function SeasonSystem:PlayerAdded(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        if not playerIns then
            return
        end

        local season = playerIns:GetOneData(Keys.DataKey.season)
        if season.seasonNum ~= SeasonPresets.SeasonNum then
            self:ResetSeason(SENDER, player)
        else
            self:UpdatePass(SENDER, player)
            self:UpdateQuests(SENDER, player)
        end

        self.Client:PlayerAdded(player)
    else
        SeasonUi = require(script.ui)
        SeasonUi.Init()
    end
end

function SeasonSystem:UpdateQuests(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        if not playerIns then
            return
        end

        local season = playerIns:GetOneData(Keys.DataKey.season)
        local dayNum, weekNum = calculateDayAndWeekCount(SeasonPresets.startTime)
        if dayNum ~= season.dayNum then
            season.dayNum = dayNum
            season.dailyQuests = {}
            for index, dailyQuest in ipairs(SeasonPresets.DailyQuests) do
                table.insert(season.dailyQuests, {
                    index = index,
                    now = 0,
                    target = dailyQuest.Target,
                })
            end
        end
       
        if weekNum ~= season.weekNum then
            season.weekNum = weekNum
            season.weeklyQuests = {}
            for index, weeklyQuest in ipairs(SeasonPresets.WeeklyQuests) do
                table.insert(season.weeklyQuests, {
                    index = index,
                    now = 0,
                    target = weeklyQuest.Target,
                })
            end
        end
        self.Client:UpdateQuests(player, {
            season = season
        })
    else
        ClientData:SetOneData(Keys.DataKey.season, args.season)
        if not SeasonUi then
            SeasonUi = require(script.ui)
        end
        SeasonUi.UpdateQuests()
    end
end

function SeasonSystem:UpdatePass(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)
        self.Client:UpdatePass(player, {
            season = season
        })
    else
        ClientData:SetOneData(Keys.DataKey.season, args.season)
        if not SeasonUi then
            SeasonUi = require(script.ui)
        end
        SeasonUi.UpdatePass()
    end
end

function SeasonSystem:ResetQuests(sender, player, args)
    if IsServer then
        player = player or sender
        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)
        local dayNum, weekNum = calculateDayAndWeekCount(SeasonPresets.startTime)
        if dayNum ~= season.dayNum then
            season.dayNum = dayNum
            season.dailyQuests = {}
            for index, dailyQuest in ipairs(SeasonPresets.DailyQuests) do
                table.insert(season.dailyQuests, {
                    index = index,
                    now = 0,
                    target = dailyQuest.Target,
                })
            end
        end
        
        if weekNum ~= season.weekNum then
            season.weekNum = weekNum
            season.weeklyQuests = {}
            for index, weeklyQuest in ipairs(SeasonPresets.WeeklyQuests) do
                table.insert(season.weeklyQuests, {
                    index = index,
                    now = 0,
                    target = weeklyQuest.Target,
                })
            end
        end

        self:UpdateQuests(SENDER, player)
    end
end

function SeasonSystem:ResetSeason(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)
        season.seasonNum = SeasonPresets.SeasonNum
        season.level = 0
        season.exp = 0
        season.claimList = {}

        season.dailyQuests = {}
        for index, dailyQuest in ipairs(SeasonPresets.DailyQuests) do
            table.insert(season.dailyQuests, {
                index = index,
                now = 0,
                target = dailyQuest.Target,
            })
        end

        season.weeklyQuests = {}
        for index, weeklyQuest in ipairs(SeasonPresets.WeeklyQuests) do
            table.insert(season.weeklyQuests, {
                index = index,
                now = 0,
                target = weeklyQuest.Target,
            })
        end

        self:UpdatePass(SENDER, player)
        self:UpdateQuests(SENDER, player)
    end
end

function SeasonSystem:AddQuestProgress(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end
        local questType = args.questType
        local progress = args.value
        local name = args.name
        local rarity = args.rarity
        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)

        for index, dailyQuest in season.dailyQuests do
            local target = SeasonPresets.DailyQuests[index].target
            if dailyQuest.now >= target then continue end
            if SeasonPresets.DailyQuests[index].questType == questType then
                if questType == Keys.QuestType.hatchRarityPet then
                    if args.rarity == SeasonPresets.DailyQuests[index].rarity then
                        dailyQuest.now += progress
                    end
                else
                    dailyQuest.now += progress
                end

                if dailyQuest.now >= target then
                    season['exp'] += SeasonPresets.DailyQuests[dailyQuest.index].exp
                end
            end
        end

        for index, weeklyQuest in season.weeklyQuests do
            local target = SeasonPresets.WeeklyQuests[index].target
            if weeklyQuest.now >= target then continue end
            if SeasonPresets.WeeklyQuests[index].questType == questType then
                if questType == Keys.QuestType.hatchRarityPet then
                    if args.rarity == SeasonPresets.WeeklyQuests[index].rarity then
                        weeklyQuest.now += progress
                    end
                else
                    weeklyQuest.now += progress
                end

                if weeklyQuest.now >= target then
                    season['exp'] += SeasonPresets.WeeklyQuests[weeklyQuest.index].exp
                end
            end
        end

        -- set level
        if SeasonPresets.Pass[season['level'] + 1] then
            if season['exp'] >= SeasonPresets.Pass[season['level'] + 1]['exp'] then
                self:LevelUp(SENDER, player, {})
            end
        end

        self:UpdatePass(SENDER, player)
        self:UpdateQuests(SENDER, player)
    end
end

function SeasonSystem:ClaimReward(sender, player, args)
    if IsServer then
        player = player or sender

        local level = args.level
        local claimType = args.claimType

        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)

        local levelReward = SeasonPresets.Pass[level]
        if not levelReward then
            return
        end
        local rewardInfo = levelReward[claimType]
        if not rewardInfo then
            return
        end

        -- check if can claim
        if level > season['level'] then
            SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                text = "You can't claim this reward yet.",
            })
            return
        end

        -- check if premium
        if claimType == "Premium" then
            if not season["premiumPass"] then
                SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                    text = "You need premium to claim this reward.",
                })
                MarketplaceService:PromptProductPurchase(player, EcoPresets.Products.seasonPremium.productId)
                return
            end
        end
       
        -- check if claimed already
        if  season['claimList'][claimType..level] then
            SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                text = "You have claimed this reward already.",
            })
            return
        end

        -- check inventory full
        if rewardInfo['itemType'] == Keys.ItemType.pet or rewardInfo['itemType'] == Keys.ItemType.egg then
            local pets = playerIns:GetOneData(Keys.DataKey.pets)
            local petInventorySize = playerIns:GetOneData(Keys.DataKey.petInventorySize)
            local owned = TableModule.TrueLength(pets)
            if petInventorySize < owned + rewardInfo['count'] then
                SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                    text = "Inventory Is Full"
                })
                return
            end
        end

        season['claimList'][claimType..level] = true

        -- add resource
        SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, rewardInfo)

        self:UpdatePass(SENDER, player)
    end
end


function SeasonSystem:LevelUp(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local maxLevel = args.maxLevel
        local ifPay = args.ifPay

        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)

        if maxLevel then
            local totalLevel = #SeasonPresets.Pass
            season['level'] = totalLevel
            season['exp'] = 0
        else
            local currentLevel = season['level']
            local nextLevel = currentLevel + 1

            if ifPay then
                season['level'] = nextLevel
                season['exp'] = 0
            else
                while true do
                    if SeasonPresets.Pass[nextLevel] then
                        if season['exp'] >= SeasonPresets.Pass[nextLevel]['exp'] then
    
                            season['level'] = nextLevel
                            season['exp'] = season['exp'] - SeasonPresets.Pass[nextLevel]['exp']
    
                            nextLevel = nextLevel + 1
                        else
                            break
                        end
                    else
                        break
                    end
                end
            end
        end

        SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
            text = "🎉You Can Claim your Season Reward Now",
        })
        self:UpdatePass(SENDER, player)
    end
end

function SeasonSystem:BuySeasonPass(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local season = playerIns:GetOneData(Keys.DataKey.season)
        season.premiumPass = true
        self:UpdatePass(SENDER, player)
    end
end


function calculateDailyCountdown(initialTime)
	local currentTime = os.time()
    -- calculate which day
	local elapseTime = currentTime - initialTime
	local days = math.floor(elapseTime / GameConfig.OneDay)

	-- left time
	local timeDifference = initialTime + GameConfig.OneDay - currentTime
	timeDifference = timeDifference + GameConfig.OneDay * days


	return timeDifference
end

function calculateWeeklyCountdown(initialTime)
	local currentTime = os.time()
	local oneWeekInSeconds = GameConfig.OneWeek

    -- calculate which week
	local elapseTime = currentTime - initialTime
	local weeks = math.floor(elapseTime / oneWeekInSeconds)

	-- left time
	local timeDifference = initialTime + oneWeekInSeconds - currentTime
	timeDifference = timeDifference + oneWeekInSeconds * weeks


    return timeDifference
end

function calculateDayAndWeekCount(initialTime)
	local currentTime = os.time()
	local oneDayInSeconds = GameConfig.OneDay
	local oneWeekInSeconds = GameConfig.OneWeek
    
	-- elapse time
	local timeDifference = currentTime - initialTime

	-- calculate which day
	local days = math.ceil(timeDifference / oneDayInSeconds)

	-- calculate which week
	local weeks = math.ceil(timeDifference / oneWeekInSeconds)

	return days, weeks
end

return SeasonSystem