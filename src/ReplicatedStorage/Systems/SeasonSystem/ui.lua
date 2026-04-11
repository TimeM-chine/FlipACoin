---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local SeasonPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local PetPresets = require(Replicated.Systems.PetSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local SeasonFrame = Frames:WaitForChild("Season"):WaitForChild("Frame")

---- logic variables ----
local countDownTask, curTab


local SeasonUi = {}

function SeasonUi.Init()
    local SideBar = SeasonFrame:WaitForChild("SideBar")

    curTab = SeasonFrame:WaitForChild("Pass")
    curTab.Visible = true

    SeasonFrame:WaitForChild("Quests").Visible = false
    SeasonFrame:WaitForChild("Premium").Visible = false

    for _, button in ipairs(SideBar:GetChildren()) do
        if button:IsA("TextButton") then
            uiController.SetButtonHoverAndClick(button, function()
                if curTab then
                    curTab.Visible = false
                end
                curTab = SeasonFrame:WaitForChild(button.Name)
                curTab.Visible = true
            end)
        end
    end

     -- update countdown
     local dailyReset = SeasonFrame:WaitForChild("Quests"):WaitForChild("Daily"):WaitForChild("Reset")
     local weeklyReset = SeasonFrame:WaitForChild("Quests"):WaitForChild("Weekly"):WaitForChild("Reset")
     local premiumCountdown = SeasonFrame:WaitForChild("Pass"):WaitForChild("Countdown")
    
    if not countDownTask then
        task.spawn(function()
            while task.wait(1) do
                
                local dayLeftTime = calculateDailyCountdown(SeasonPresets.startTime)

                if dayLeftTime == GameConfig.OneDay - 10 then
                    SystemMgr.systems.SeasonSystem.Server:ResetQuests()
                end

                dailyReset.Text = `Reset in {Util.FormatPlayTime(dayLeftTime)}`

                local weekLeftTime = calculateWeeklyCountdown(SeasonPresets.startTime)

                weeklyReset.Text = `Reset in {Util.FormatPlayTime(weekLeftTime)}`

                local seasonLeftTime = SeasonPresets.endTime - os.time()
                premiumCountdown.Text = string. format("%s", Util.FormatPlayTime(seasonLeftTime))
            end
        end)
    end
end


function SeasonUi.UpdateQuests()
    local Quests = SeasonFrame:WaitForChild("Quests")
    local DailyQuests = Quests:WaitForChild("Daily"):WaitForChild("DailyQuests")

    local season = ClientData:GetOneData(Keys.DataKey.season)

    for i = 1, #SeasonPresets.DailyQuests do
        if DailyQuests:FindFirstChild('Quest'..i) then
            local child = DailyQuests['Quest'..i]
            child:WaitForChild("QuestIcon").Image = Textures.GetIcon({itemType = "quest", itemName = SeasonPresets.DailyQuests[i].questType})
            child:WaitForChild("QuestName").Text  = SeasonPresets.DailyQuests[i].title
            child:WaitForChild("QuestDescription").Text  = SeasonPresets.DailyQuests[i].description
            local now = season.dailyQuests[i].now
            local target = SeasonPresets.DailyQuests[i].target
            child:WaitForChild("Progress").Text = string.format("%s/%s", Util.FormatNumber(now, true), Util.FormatNumber(target, true))
            child:WaitForChild("QuestGain").Text = `{SeasonPresets.DailyQuests[i].exp} exp`
        end
    end

    local WeeklyQuests = Quests:WaitForChild("Weekly"):WaitForChild("WeeklyQuests")
    for i = 1, #SeasonPresets.WeeklyQuests do
        if WeeklyQuests:FindFirstChild('Quest'..i) then
            local child = WeeklyQuests['Quest'..i]
            child:WaitForChild("QuestIcon").Image = Textures.GetIcon({itemType = "quest", itemName = SeasonPresets.WeeklyQuests[i].questType})
            child:WaitForChild("QuestName").Text  = SeasonPresets.WeeklyQuests[i].title
            child:WaitForChild("QuestDescription").Text  = SeasonPresets.WeeklyQuests[i].description
            local now = season.weeklyQuests[i].now
            local target = SeasonPresets.WeeklyQuests[i].target
            child:WaitForChild("Progress").Text = string.format("%s/%s", Util.FormatNumber(now, true), Util.FormatNumber(target, true))
            child:WaitForChild("QuestGain").Text = `{SeasonPresets.WeeklyQuests[i].exp} exp`
        end
    end
end

function SeasonUi.UpdatePass()
    local season = ClientData:GetOneData(Keys.DataKey.season)

    local Pass = SeasonFrame:WaitForChild("Pass")
    local ScrollingFrame = Pass:WaitForChild("ScrollingFrame")

    local LevelTpl = SeasonFrame:WaitForChild("Templates"):WaitForChild("LevelTpl")

    local totalLevel = #SeasonPresets.Pass

    for index, levelReward in ipairs(SeasonPresets.Pass) do
        local lock = true
        local newLevel = ScrollingFrame:FindFirstChild("Level"..index)
        if not newLevel then
            newLevel = LevelTpl:Clone()
            newLevel.Name = "Level"..index
            newLevel.LayoutOrder = index
            newLevel.Visible = true
        end
        
        -- level lock
        local LevelBar = newLevel:WaitForChild("LevelBar")
        LevelBar:FindFirstChild("Level").Text = index
        local Decoration = LevelBar:FindFirstChild("Decoration")
        local freeSkip = newLevel:WaitForChild("Free"):WaitForChild("SkipButton")
        local premiumSkip = newLevel:WaitForChild("Premium"):WaitForChild("SkipButton")
        local freeLockFrame = newLevel:WaitForChild("Free"):WaitForChild("LockFrame")
        local premiumLockFrame = newLevel:WaitForChild("Premium"):WaitForChild("LockFrame")

        if index == totalLevel then
            LevelBar:WaitForChild("Bar").Visible = false
        end

        if season['level'] >= index then
            Decoration:WaitForChild("Unlock").Enabled = true
            Decoration:WaitForChild("Lock").Enabled = false

            freeSkip.Visible = false
            premiumSkip.Visible = false

            freeLockFrame.Visible = false
            premiumLockFrame.Visible = false

            lock = false
        else
            Decoration:WaitForChild("Unlock").Enabled = false
            Decoration:WaitForChild("Lock").Enabled = true
            if index == season['level'] + 1 then
                freeSkip.Visible = true
                uiController.SetButtonHoverAndClick(freeSkip, function()
                    MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.skipSeasonLevel.productId)
                end)

                premiumSkip.Visible = true
                uiController.SetButtonHoverAndClick(premiumSkip, function()
                    MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.skipSeasonLevel.productId)
                end)

                freeLockFrame.Visible = true
                premiumLockFrame.Visible = true
            else
                freeSkip.Visible = false
                premiumSkip.Visible = false

                freeLockFrame.Visible = true
                premiumLockFrame.Visible = true
            end
        end

        -- level reward
        for claimType, info in pairs(levelReward) do
            
            if claimType == "exp" then
                continue
            end

            local newCard = newLevel:FindFirstChild(claimType)

            local Icon = newCard:WaitForChild("Icon")
            if info.itemType == Keys.ItemType.pet then
                local viewport = Icon:FindFirstChildOfClass("ViewportFrame")
                if not viewport then
                    viewport = Instance.new("ViewportFrame")
                    viewport.Size = UDim2.fromScale(2, 2)
                    viewport.Position = UDim2.fromScale(.5, .5)
                    viewport.AnchorPoint = Vector2.new(.5, .5)
                    viewport.BackgroundTransparency = 1
                    viewport.ZIndex = Icon.ZIndex
                    viewport.Parent = Icon
                    
                    uiController.PetViewport(PetPresets.PetsList[info.itemName].mesh, viewport)
                    
                    Icon.Image = ""
                    local Count = newCard:WaitForChild("Count")
                    Count.Text = info['itemName']
                end
            else
                Icon.Image = Textures.GetIcon(info)
                
                local Count = newCard:WaitForChild("Count")
                Count.Text = info["text"]
            end

            -- check if claimed
            if season['claimList'][claimType..index] then
                newCard:FindFirstChild("Title").Text = "CLAIMED"
                newCard:FindFirstChild("Title").TextColor3 = Color3.fromRGB(234, 7, 7)
            else
                if lock then
                    newCard.Title.Text = ""
                else
                    newCard.Title.Text = "CLAIM!"
                    newCard.Title.TextColor3 = Color3.fromRGB(64, 229, 14)
                    -- button
                    uiController.SetButtonHoverAndClick(newCard, function()
                        SystemMgr.systems.SeasonSystem.Server:ClaimReward({level = index, claimType = claimType})
                    end)
                end
            end
        end

        newLevel.Parent = ScrollingFrame
    end

    -- cur level
    local XPBar = Pass:WaitForChild("XPBar")
    local AmountLVL = XPBar:WaitForChild("AmountLVL")
    local AmountXP = XPBar:WaitForChild("AmountXP")
    local ProgressBar = XPBar:WaitForChild("ProgressBar")
    local unlockAll = Pass:WaitForChild("UnlockAll")
    local ResetPass = Pass:WaitForChild("ResetPass")

    if season['level'] == totalLevel then
        AmountLVL.Text = totalLevel
        AmountXP.Text = "MAX"
        ProgressBar.Size = UDim2.fromScale(1, 1)
        
        unlockAll.Visible = false

        ResetPass.Visible = true
        uiController.SetButtonHoverAndClick(ResetPass, function()
            -- check if claim all reward
            for index, levelReward in ipairs(SeasonPresets.Pass) do
                for claimType, info in pairs(levelReward) do
                    if claimType == "exp" then
                        continue
                    end

                    if season['premiumPass'] == true then
                        if not season['claimList'][claimType..index] then
                            print(claimType..index)
                            uiController.SetNotification({
                                text = "You have unclaimed Premium Rewards, please claim them first."
                            })
                            return
                        end
                    else
                        if claimType == "Premium" then
                            continue
                        end
                    end
                    if not season['claimList'][claimType..index] then
                        print(claimType..index)
                        uiController.SetNotification({
                            text = "You have unclaimed Premium Rewards, please claim them first."
                        })
                        return
                    end
                end
            end
            MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.resetSeason.productId)
        end)
        
    else
        AmountLVL.Text = season['level'] + 1
        AmountXP.Text = string.format("%d/%d exp", season['exp'], SeasonPresets.Pass[season['level'] + 1]['exp'])
        ProgressBar.Size = UDim2.fromScale(season['exp'] / SeasonPresets.Pass[season['level'] + 1]['exp'], 1)
    
        ResetPass.Visible = false
        unlockAll.Visible = true
        uiController.SetButtonHoverAndClick(unlockAll, function()
            MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.skipAllSeasonLevel.productId)
        end)
    end


    -- premium pass
    local Premium = SeasonFrame:WaitForChild("Premium")
    local Buy = Premium:WaitForChild("Buy")
    local BuyButton = Pass:WaitForChild("Tiers"):WaitForChild("PremiumPass"):WaitForChild("BuyButton")
    
    if season['premiumPass'] then
        Buy:WaitForChild("TextLabel").Text = "Owned"
        BuyButton:WaitForChild("TextLabel").Text = "Owned"
    else
        Buy:WaitForChild("TextLabel").Text = string.format("\u{E002} %s", EcoPresets.Products.seasonPremium.price)
        BuyButton:WaitForChild("TextLabel").Text = string.format("\u{E002} %s", EcoPresets.Products.seasonPremium.price)

        uiController.SetButtonHoverAndClick(Buy, function()
            MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.seasonPremium.productId)
        end)

        uiController.SetButtonHoverAndClick(BuyButton, function()
            MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.seasonPremium.productId)
        end)
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

return SeasonUi