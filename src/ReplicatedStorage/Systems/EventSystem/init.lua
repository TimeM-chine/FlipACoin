--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local EventPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local TableModule = require(Replicated.modules.TableModule)
local ModelModule = require(Replicated.modules.ModelModule)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass
local santaIsPresent = false
local santaModel = nil
local originalTransparentParts = {}
local santaPrompt = nil
local santaScheduleId = nil
local santaArrivalCountdown = 0

---- client variables ----
local LocalPlayer, ClientData, EventUi

local EventSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
EventSystem.__index = EventSystem

if IsServer then
	EventSystem.Client = setmetatable({}, EventSystem)
	EventSystem.AllClients = setmetatable({}, EventSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	EventSystem.Server = setmetatable({}, EventSystem)
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

function EventSystem:Init()
	GetSystemMgr()

	if IsServer then
		-- 初始化Santa模型和状态
		local eventFolder = workspace:WaitForChild("Boxes"):WaitForChild("Event")
		santaModel = eventFolder:WaitForChild("Santa")

		-- 记录原本透明的Part
		for _, descendant in santaModel:GetDescendants() do
			if descendant:IsA("BasePart") and descendant.Transparency == 1 then
				table.insert(originalTransparentParts, descendant)
			end
		end

		-- 初始状态：Santa透明且不可交互
		ModelModule.SetModelTransparency(santaModel, 1, originalTransparentParts)

		-- 创建ProximityPrompt
		local primaryPart = santaModel.PrimaryPart or santaModel:FindFirstChildOfClass("BasePart")
		if primaryPart then
			santaPrompt = Instance.new("ProximityPrompt")
			santaPrompt.HoldDuration = 1
			santaPrompt.ActionText = "Get Candy"
			santaPrompt.RequiresLineOfSight = false
			santaPrompt.Enabled = false
			santaPrompt.Parent = primaryPart
		end

		-- 启动Santa循环计时器
		self:StartSantaTimer()
	end
end

function EventSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.players[player.UserId] = {}

		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		if event.eventId ~= EventPresets.EventId then
			local DefaultData = require(Replicated.configs.DefaultData)
			playerIns:SetOneData(Keys.DataKey.event, DefaultData.event)
		end

		self.Client:PlayerAdded(player, {
			event = event,
			santaState = {
				isPresent = santaIsPresent,
				remaining = santaArrivalCountdown,
			},
		})
	else
		ClientData:SetOneData(Keys.DataKey.event, args.event)
		EventUi = require(script.ui)
		EventUi.Init(args.santaState)
	end
end

function EventSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerCache = self.players[player.UserId]
		if playerCache and playerCache.eventTask then
			task.cancel(playerCache.eventTask)
		end

		self.players[player.UserId] = nil
	end
end

function EventSystem:AddWins(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local count = args.count

		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		event.wins = event.wins + count
		self.Client:AddWins(player, {
			event = event,
			count = count,
		})
	else
		ClientData:SetOneData(Keys.DataKey.event, args.event)
		EventUi.AddWins(args)
	end
end

function EventSystem:TryClaim(sender, player, args)
	if IsServer then
		player = player or sender
		local count = args.count
		local auto = args.auto

		if auto then
			SystemMgr.systems.PetSystem:AutoHatchEgg(SENDER, player, {
				eggName = EventPresets.Rewards[1].itemName,
			})
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)

		if event.count < count then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough count",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		self:AddCount(SENDER, player, {
			count = -count,
			reason = "claim",
		})

		SystemMgr.systems.PetSystem:HatchEgg(SENDER, player, {
			eggName = EventPresets.Rewards[1].itemName,
			count = count,
		})

		return true
	end
end

function EventSystem:TryBuyEventChest(sender, player, args)
	if IsServer then
		player = player or sender
		local count = args.count
		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		-- warn(event.wins, EventPresets.ChestPrice * count)
		if event.wins < EventPresets.ChestPrice * count then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough Candy",
			})
			return
		end

		self:AddWins(SENDER, player, {
			count = -EventPresets.ChestPrice * count,
		})

		SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, {
			itemType = Keys.ItemType.cardPacks,
			count = count,
			name = EventPresets.CardPack1,
			reason = "event card pack",
		})
	end
end

function EventSystem:TryBuyEventItem(sender, player, args)
	if IsServer then
		player = player or sender
		local itemIndex = args.itemIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		local item = EventPresets.CandyShop[itemIndex]
		if event.wins < item.price then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough Candy",
			})
			return
		end

		self:AddWins(SENDER, player, {
			count = -item.price,
		})

		SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, {
			itemType = item.item.itemType,
			count = item.item.count,
			name = item.item.name,
			reason = "event item",
		})
	end
end

function EventSystem:BuyWinsMultiplier(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local multiplierIndex = args.multiplierIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		event.multiplierIndex = multiplierIndex
		self.Client:BuyWinsMultiplier(player, {
			event = event,
		})
	else
		ClientData:SetOneData(Keys.DataKey.event, args.event)
		EventUi.BuyWinsMultiplier(args)
	end
end

---- [[ Server Only - Santa Logic ]] ----

function EventSystem:StartSantaTimer()
	if not IsServer then
		return
	end

	-- 使用ScheduleModule统一调度定时任务
	santaArrivalCountdown = EventPresets.SantaArrivalInterval
	santaScheduleId = ScheduleModule.AddSchedule(1, function()
		if santaIsPresent then
			-- Santa在场，倒计时离开时间
			santaArrivalCountdown = santaArrivalCountdown - 1
			if santaArrivalCountdown <= 0 then
				-- Santa离开
				self:_SantaLeave()
				-- 重置为到达间隔
				santaArrivalCountdown = EventPresets.SantaArrivalInterval
			end
		else
			-- Santa不在，倒计时到达时间
			santaArrivalCountdown = santaArrivalCountdown - 1
			if santaArrivalCountdown <= 0 then
				-- Santa到达
				self:_SantaArrive()
				-- 重置为停留时长
				santaArrivalCountdown = EventPresets.SantaStayDuration
			end
		end
	end)
end

function EventSystem:_SantaArrive()
	if not IsServer then
		return
	end

	santaIsPresent = true

	-- 设置Santa为可见
	ModelModule.SetModelTransparency(santaModel, 0, originalTransparentParts)
	ModelModule.SetModelCollide(santaModel, true)

	-- 启用ProximityPrompt
	if santaPrompt then
		santaPrompt.Enabled = true
	end

	-- 给所有在线玩家发放candy
	for _, player in Players:GetPlayers() do
		local candyAmount = math.random(EventPresets.SantaArrivalCandyMin, EventPresets.SantaArrivalCandyMax)
		local playerIns = PlayerServerClass.GetIns(player)
		local event = playerIns:GetOneData(Keys.DataKey.event)
		candyAmount = candyAmount * (1 + event.multiplierIndex)
		self:AddWins(SENDER, player, {
			count = candyAmount,
		})
	end

	-- 播放santaArrive音效给所有客户端
	SystemMgr.systems.MusicSystem.AllClients:Play2dMusic({
		musicName = "santaArrive",
		musicGroup = "SFX",
		unreliable = true,
	})

	-- 通知客户端Santa到达
	self.AllClients:SantaArrive({})
end

function EventSystem:_SantaLeave()
	if not IsServer then
		return
	end

	santaIsPresent = false

	-- 设置Santa为透明
	ModelModule.SetModelTransparency(santaModel, 1, originalTransparentParts)
	ModelModule.SetModelCollide(santaModel, false)

	-- 禁用ProximityPrompt
	if santaPrompt then
		santaPrompt.Enabled = false
	end

	-- 通知客户端Santa离开
	self.AllClients:SantaLeave({})
end

function EventSystem:SantaArrive(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		args.unreliable = true
		self.AllClients:SantaArrive(args)
	else
		EventUi.SantaArrive(args)
	end
end

function EventSystem:SantaLeave(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		args.unreliable = true
		self.AllClients:SantaLeave(args)
	else
		EventUi.SantaLeave(args)
	end
end

function EventSystem:TryInteractWithSanta(sender, player, args)
	if IsServer then
		player = player or sender

		-- 服务端验证Santa是否在场
		if not santaIsPresent then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Santa comes later",
			})
			return
		end

		-- 给予1-5随机candy
		local candyAmount = math.random(EventPresets.SantaInteractionCandyMin, EventPresets.SantaInteractionCandyMax)
		self:AddWins(SENDER, player, {
			count = candyAmount,
		})

		-- 10%概率播放santaLaugh音效
		if math.random() < EventPresets.SantaLaughChance then
			SystemMgr.systems.MusicSystem.Client:Play2dMusic(player, {
				musicName = "santaLaugh",
				musicGroup = "SFX",
			})
		end
	end
end

return EventSystem
