---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local RebirthPresets = require(script.Parent.Presets)
local Util = require(Replicated.modules.Util)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local RebirthFrame = Frames:WaitForChild("Rebirth")
local RebirthButton = Main.Buttons.LeftBar.Buttons.RebirthButton
local TopBar = Main:WaitForChild("Elements"):WaitForChild("TopBar")
local topRebirth = TopBar:WaitForChild("rebirth")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----



local RebirthUi = {}


function RebirthUi.Init()
    RebirthUi.UpdateUi({
        rebirth = ClientData:GetOneData(Keys.DataKey.rebirth),
        wins = ClientData:GetOneData(Keys.DataKey.wins)
    })
    uiController.SetButtonHoverAndClick(RebirthFrame.Rebirth, function()
        SystemMgr.systems.RebirthSystem.Server:TryRebirth()
    end)

    uiController.SetButtonHoverAndClick(RebirthFrame.SkipRebirth, function()
        MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.skipRebirth.productId)
    end)
end


function RebirthUi.UpdateUi(args)
    local rebirth = args.rebirth or ClientData:GetOneData(Keys.DataKey.rebirth)
    local wins = args.wins

    local boost = RebirthPresets.RebirthConfig[rebirth].boost
    RebirthFrame.oldRebirth.TextLabel.Text = rebirth
    RebirthFrame.oldBoost.TextLabel.Text = (1+boost) * 100 .. "%"
    RebirthFrame.oldTier.Text = RebirthPresets.Tier[rebirth]

    local newRebirth = rebirth + 1
    if RebirthPresets.RebirthConfig[newRebirth] then
        local newBoost = RebirthPresets.RebirthConfig[newRebirth].boost
        RebirthFrame.newRebirth.TextLabel.Text = newRebirth
        topRebirth.value.Text = rebirth
        RebirthFrame.newBoost.TextLabel.Text = (1+newBoost) * 100 .. "%"
        RebirthFrame.newTier.Text = RebirthPresets.Tier[newRebirth]

        local p = math.min(wins/RebirthPresets.RebirthConfig[rebirth].cost, 1)
        RebirthButton.progress.Text = Util.Round(p*100) .. "%"
        if p >= 1 then
            RebirthButton.RedDot.Visible = true
        else
            RebirthButton.RedDot.Visible = false
        end
        RebirthFrame.progress.progressBar.bar.Size = UDim2.fromScale(p, 1)
        RebirthFrame.progress.TextLabel.Text = Util.FormatNumber(wins) .. "/" .. Util.FormatNumber(RebirthPresets.RebirthConfig[rebirth].cost)
    else
        RebirthFrame.newRebirth.TextLabel.Text = "Max"
        RebirthFrame.newBoost.TextLabel.Text = "Max"
        RebirthFrame.newTier.Text = "Max"
        RebirthFrame.RebirthButton.Visible = false

        RebirthFrame.progress.progressBar.Size = UDim2.fromScale(1, 1)
        RebirthFrame.progress.TextLabel.Text = Util.FormatNumber(wins) .. "/Max"
    end
end

return RebirthUi