--[[
--Author: TimeM_chine
--Created Date: Mon Oct 16 2023
--Description: init.lua
--Last Modified: 2024-05-25 7:42:16
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Lightning = game:GetService("Lighting")

---- requires ----
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Zone = require(Replicated.modules.Zone)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local MonsterMgr = require(Replicated.Systems.MonsterSystem.MonsterMgr)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local SitesFolder = workspace:WaitForChild("Sites")
local dataKey = Keys.DataKey
local monsterSates = Keys.MonsterSates

---- server variables ----
local PlayerServerClass
local serverInfZone = {
    state = "waiting",
    players = {},
    firstPlayer = nil,
    level = 0,
    teleportTask = nil,
}
local spiderBoss = {
    state = monsterSates.Idle,
    spawnTask = nil,
}

---- client variables ----
local LocalPlayer, camera
local clientUnlock = 1 -- easy 1, normal 2, hard 3

---- [[ UI ]] ----
local PlayerGui, Main, uiController, infLevelFrame

local SiteSystem:Types.System = {
    whiteList = {},
    players = {},
    tasks = {},
    IsLoaded = false
}
SiteSystem.__index = SiteSystem

if IsServer then
    SiteSystem.Client = setmetatable({}, SiteSystem)
    SiteSystem.AllClients = setmetatable({}, SiteSystem)
    local ServerStorage = game:GetService("ServerStorage")
    PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
    SiteSystem.Server = setmetatable({}, SiteSystem)
    LocalPlayer = Players.LocalPlayer
    PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    Main = PlayerGui:WaitForChild("Main")
    infLevelFrame = Main:WaitForChild("Elements"):WaitForChild("InfLevel")
    uiController = require(Main:WaitForChild("uiController"))
    camera = workspace.CurrentCamera
end

function GetSystemMgr()
    if not SystemMgr then
        SystemMgr = require(Replicated.Systems.SystemMgr)
        SENDER = SystemMgr.SENDER
    end
    return SystemMgr
end

function SiteSystem:Init()
    GetSystemMgr()
    if IsServer then
        task.delay(10, function()
            self:SpawnSpiderBoss(SENDER)  -- 服务器启动时，生成第一个Boss
        end)
    end
end

function SiteSystem:PlayerAdded(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end

        local playerIns = PlayerServerClass.GetIns(player)
        local unlocked = playerIns:GetOneData(dataKey.infCity).unlocked
        args = {
            unlocked = unlocked,
            spiderBoss = spiderBoss,
        }
        self.Client:PlayerAdded(player, args)
    else
        clientUnlock = args.unlocked
        local tavern = SitesFolder:WaitForChild("tavern")
        local tavernSpawn = tavern:WaitForChild("Spawn")
        local tavernExit = tavern:WaitForChild("Exit")
        local container = tavern:WaitForChild("Container")

        local tavernDoor = SitesFolder:WaitForChild("tavernDoor")
        local doorSpawn = tavernDoor:WaitForChild("Spawn")
        local entrance = tavernDoor:WaitForChild("Entrance")

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local exitZone = Zone.new(tavernExit)
        exitZone.localPlayerEntered:Connect(function()
            character:PivotTo(doorSpawn.CFrame + Vector3.new(0, 5, 0))
        end)

        local entranceZone = Zone.new(entrance)
        entranceZone.localPlayerEntered:Connect(function()
            if SystemMgr.systems.GuideSystem.NeedGuide() then
                local bindableEvent = Replicated.Systems.GuideSystem.Assets.GuideEvent :: BindableEvent
                bindableEvent:Fire(4)
            end
            character:PivotTo(tavernSpawn.CFrame + Vector3.new(0, 5, 0))
        end)

        local containerZone = Zone.new(container)
        containerZone.localPlayerEntered:Connect(function()
            uiController.OpenFrame("PetShop")
        end)
        containerZone.localPlayerExited:Connect(function()
            uiController.CloseFrame("PetShop")
        end)

        ---------- [[ infinity city ]] ----------
        local infTeleport = SitesFolder:WaitForChild("InfTeleport")
        local infTeleportZone = Zone.new(infTeleport)
        infTeleportZone.localPlayerEntered:Connect(function()
            self.Server:PlayerEntered({zoneName = "infTeleport"})
        end)
        infTeleportZone.localPlayerExited:Connect(function()
            self.Server:PlayerExited({zoneName = "infTeleport"})
        end)

        for i = 1, 3 do
            local btn = infLevelFrame:WaitForChild(i)
            uiController.SetButtonHoverAndClick(btn, function()
                self.Server:ChooseInfLevel({level = i})
            end)
        end

        local forgePart = SitesFolder:WaitForChild("forge")
        local forgeZone = Zone.new(forgePart)
        forgeZone.localPlayerEntered:Connect(function()
            uiController.OpenFrame("Blade")
            local bladeUi = require(Replicated.Systems.BladeSystem.ui)
            bladeUi.SelectBladeMenu("forge")

            if SystemMgr.systems.GuideSystem.NeedGuide() then
                local bindableEvent = Replicated.Systems.GuideSystem.Assets.GuideEvent :: BindableEvent
                bindableEvent:Fire(2)
            end
        end)

        ---------- [[ spider mountain ]] ----------
        local spdMtD = SitesFolder:WaitForChild("spiderMountainDoor")
        local spdMt = SitesFolder:WaitForChild("spiderMountain"):WaitForChild("Part")
        local spdMtDZone = Zone.new(spdMtD.PrimaryPart)
        spdMtDZone.localPlayerEntered:Connect(function()
            character:PivotTo(spdMt.CFrame + Vector3.new(math.random(-10, 10), 5, math.random(-10, 10)))
            for _, child in ipairs(Lightning:GetChildren()) do
                if not child:IsA("Folder") then
                    child:Destroy()
                end
            end
    
            local spdLight = Lightning:FindFirstChild("spiderMountain")
            for _, child in ipairs(spdLight:GetChildren()) do
                child:Clone().Parent = Lightning
            end
    
            for key, value in pairs(Presets.Lighting.spiderMountain) do
                Lightning[key] = value
            end
        end)

        local spdMtB = SitesFolder:WaitForChild("spiderMountainBack")
        local spdMtBZone = Zone.new(spdMtB.PrimaryPart)
        spdMtBZone.localPlayerEntered:Connect(function()
            character:PivotTo(spdMtD.PrimaryPart.CFrame * CFrame.new(0, 0, -30))
            for _, child in ipairs(Lightning:GetChildren()) do
                if not child:IsA("Folder") then
                    child:Destroy()
                end
            end
    
            local spdLight = Lightning:FindFirstChild("mainLand")
            for _, child in ipairs(spdLight:GetChildren()) do
                child:Clone().Parent = Lightning
            end
    
            for key, value in pairs(Presets.Lighting.mainLand) do
                Lightning[key] = value
            end
            self.Server:PlayerEntered({zoneName = "SpiderMountainBack"})
        end)

        if args.spiderBoss.state == monsterSates.Dead then -- 处理蜘蛛山UI
            self:SpiderBossDie()
        else
            self:SpawnSpiderBoss()
        end
    end
end

function SiteSystem:PlayerEntered(sender, player, args)
    if IsServer then
        player = player or sender
        local zoneName = args.zoneName

        if zoneName == "infTeleport" then
            table.insert(serverInfZone.players, player)
            if not serverInfZone.firstPlayer then
                serverInfZone.firstPlayer = player
            end
            print(player.Name, "entered infTeleport", serverInfZone)
            if not serverInfZone.teleportTask then
                serverInfZone.teleportTask = task.spawn(function()
                    local waitTime = 20
                    local infTeleport = SitesFolder:WaitForChild("InfTeleport")
                    infTeleport.TpGui.Frame.timer.Visible = true
                    while waitTime > 0 do
                        infTeleport.TpGui.Frame.timer.Text = waitTime
                        waitTime -= 1
                        task.wait(1)
                    end

                    for _, plr in ipairs(serverInfZone.players) do
                        self:TeleportPrepare(SENDER, plr)
                    end
                    
                    local teleportOptions = Instance.new("TeleportOptions")
                    teleportOptions.ShouldReserveServer = true
                    local teleportData = {
                        level = serverInfZone.level,
                    }
                    teleportOptions:SetTeleportData(teleportData)
                    TeleportService:TeleportAsync(GameConfig.InfCityPlaceId, serverInfZone.players, teleportOptions)
                end)
            end
            args = {
                zoneName = zoneName,
                firstPlayer = serverInfZone.firstPlayer,
            }
            self.AllClients:PlayerEntered(args)
        elseif zoneName == "SpiderMountainBack" then
            SystemMgr.systems.PetSystem:ClearTarget(SENDER, player)
        end
    else
        local zoneName = args.zoneName
        
        if zoneName == "infTeleport" then
            local firstPlayer = args.firstPlayer
            if firstPlayer == LocalPlayer then
                infLevelFrame.Visible = true
            else
                local infTeleport = SitesFolder:WaitForChild(zoneName)
                infTeleport.CanCollide = true
            end
        end
    end
end

function SiteSystem:PlayerExited(sender, player, args)
    if IsServer then
        player = player or sender
        local zoneName = args.zoneName
        if zoneName == "infTeleport" then
            print(player.Name, "exited infTeleport", serverInfZone)
            for i = 1, #serverInfZone.players do
                if serverInfZone.players[i] == player then
                    table.remove(serverInfZone.players, i)

                    if #serverInfZone.players == 0 then
                        if serverInfZone.teleportTask then
                            task.cancel(serverInfZone.teleportTask)
                            serverInfZone.teleportTask = nil
                        end
                        self:ResetInfTeleport(SENDER)
                    end
                    break
                end
            end
        end
        self.Client:PlayerExited(player, args)
    else
        infLevelFrame.Visible = false
    end
end

function SiteSystem:ChooseInfLevel(sender, player, args)
    if IsServer then
        player = player or sender
        if player ~= serverInfZone.firstPlayer then
            return
        end
        local level = args.level
        local playerIns = PlayerServerClass.GetIns(player)
        local unlocked = playerIns:GetOneData(dataKey.infCity).unlocked
        if level > unlocked then
            SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
                text = "You haven't unlocked this level yet.",
                textColor = Color3.new(1, 0, 0)
            })
            return
        end
        serverInfZone.level = level
        print(player.Name, "choosed inf level", level)

        local infTeleport = SitesFolder:WaitForChild("InfTeleport")
        infTeleport.TpGui.Frame.difficulty.Visible = true
        local diffT = {"Easy", "Normal", "Hard"}
        infTeleport.TpGui.Frame.difficulty.Text = diffT[level]
        self.AllClients:ChooseInfLevel({player = player, level = level})
    else
        player = args.player
        local level = args.level

        infLevelFrame.Visible = false
        local infTeleport = SitesFolder:WaitForChild("InfTeleport")
        local colors = {
            Color3.new(0, 1, 0),
            Color3.new(1, 1, 0),
            Color3.new(1, 0, 0),
        }
        infTeleport.Color = colors[level]
        if player ~= LocalPlayer then
            if level <= clientUnlock then
                infTeleport.CanCollide = false
            end
        end
    end
end

function SiteSystem:TeleportPrepare(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end
        local chr = player.Character
        local rootPart = chr:WaitForChild("HumanoidRootPart")
        chr:PivotTo(CFrame.new(0, 200, 0))
        rootPart.Anchored = true
        self.Client:TeleportPrepare(player)
    else
        task.spawn(function()
            camera.CameraType = Enum.CameraType.Scriptable
            local ti = TweenInfo.new(7)
            local newCf = CFrame.new(-2.139, 48.833, 18.17)
            TweenService:Create(camera, ti, {
                CFrame = newCf
            }):Play()

            local frame = LocalPlayer.PlayerGui.Teleport.Frame
            frame.Visible = true
            ti = TweenInfo.new(7)
            TweenService:Create(frame, ti, {
                BackgroundTransparency = 0,
            }):Play()
        end)
    end
end

function SiteSystem:ResetInfTeleport(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end
        if serverInfZone.teleportTask then
            task.cancel(serverInfZone.teleportTask)
        end
        serverInfZone = {
            state = "waiting",
            players = {},
            level = 0,
            teleportTask = nil,
            firstPlayer = nil
        }
        local infTeleport = SitesFolder:WaitForChild("InfTeleport")
        infTeleport.TpGui.Frame.timer.Visible = false
        infTeleport.TpGui.Frame.difficulty.Visible = false
        self.AllClients:ResetInfTeleport()
    else
        local infTeleportZone = SitesFolder:WaitForChild("InfTeleport")
        infTeleportZone.CanCollide = false
        infTeleportZone.Color = Color3.new(1, 1, 1)
    end
end

-------- [[ spider mountain ]] --------

function SiteSystem:SpawnSpiderBoss(sender, player, args)
    if IsServer then
        if sender ~= SENDER then
            return
        end
        local bossSpawner = SitesFolder:WaitForChild("spiderMountain"):WaitForChild("bossSpawner")
        bossSpawner.BillboardGui.Enabled = false

        local boss = MonsterMgr.CreateBoss({
            spawner = bossSpawner,
            name = "RuiBoss",
            level = 20,
            autoRespawn = false,
            deadRecall = function()
                self:SpiderBossDie()
            end
        })

        spiderBoss.state = monsterSates.Idle

        self.AllClients:SpawnSpiderBoss()
    else
        local bossSpawner = SitesFolder:WaitForChild("spiderMountain"):WaitForChild("bossSpawner")
        local boss = MonsterMgr.CreateBoss({
            spawner = bossSpawner,
            name = "RuiBoss",
        })
        bossSpawner.BillboardGui.Enabled = false

        local spdMtD = SitesFolder:WaitForChild("spiderMountainDoor")
        local gui = spdMtD:WaitForChild("Container"):WaitForChild("BillboardGui").Frame
        gui.lock.Visible = false
        gui.timer.Visible = false
    end
end

function SiteSystem:SpiderBossDie(sender, player, args)
    if IsServer then
        local bossSpawner = SitesFolder:WaitForChild("spiderMountain"):WaitForChild("bossSpawner")
        bossSpawner.BillboardGui.Enabled = true

        local nextSpawnTime = GetNextHalfHour()
        print("next spawn time", nextSpawnTime - os.time())
        task.delay(nextSpawnTime - os.time(), function()
            self:SpawnSpiderBoss(SENDER)
        end)
        
        self.AllClients:SpiderBossDie()
    else
        local bossSpawner = SitesFolder:WaitForChild("spiderMountain"):WaitForChild("bossSpawner")
        local timerLabel = bossSpawner.BillboardGui.Frame.timer
        local nextSpawnTime = GetNextHalfHour()

        SystemMgr.systems.TimerSystem:AddTimerLabel(nil, nil, {
            textLabel = timerLabel,
            startTime = os.time(),
            duration = nextSpawnTime - os.time(),
        })

        local spdMtD = SitesFolder:WaitForChild("spiderMountainDoor")
        local gui = spdMtD:WaitForChild("Container"):WaitForChild("BillboardGui").Frame
        gui.lock.Visible = true
        gui.timer.Visible = true

        SystemMgr.systems.TimerSystem:AddTimerLabel(nil, nil, {
            textLabel = gui.timer,
            startTime = os.time(),
            duration = nextSpawnTime - os.time(),
        })
    end
end


------ [[ server ]] -------
function GetNextHalfHour()
    local now = os.time()
    -- local timeGamp = GameConfig.HalfHour
    local timeGamp = GameConfig.OneMinute * 5
    local nextTime = math.floor(now / timeGamp) * timeGamp + timeGamp
    return nextTime
end

return SiteSystem