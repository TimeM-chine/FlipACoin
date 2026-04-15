---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local ScheduleModule = require(Replicated.modules.ScheduleModule)
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Util = require(Replicated.modules.Util)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

local BillboardColors = {
	Background = Color3.fromRGB(20, 24, 30),
	Stroke = Color3.fromRGB(255, 214, 124),
	Title = Color3.fromRGB(255, 245, 213),
	Name = Color3.fromRGB(248, 248, 248),
	Detail = Color3.fromRGB(205, 214, 229),
	Cash = Color3.fromRGB(134, 255, 178),
	Open = Color3.fromRGB(145, 221, 160),
	Warm = Color3.fromRGB(255, 210, 125),
	Hot = Color3.fromRGB(255, 160, 110),
	Jackpot = Color3.fromRGB(255, 113, 113),
}

---- server variables ----
local PlayerServerClass

---- client variables ----
local TableSeatUi = { pendingCalls = {} }
setmetatable(TableSeatUi, Types.mt)

local TableSeatSystem: Types.System = {
	whiteList = {
		"GetPlayerSeatId",
		"GetTablePlayers",
		"IsPlayerSeated",
		"RegisterActivity",
		"GetClientSeatState",
		"GetAudiencePlayers",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
TableSeatSystem.__index = TableSeatSystem

if IsServer then
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	TableSeatSystem.Client = setmetatable({}, TableSeatSystem)
else
	TableSeatSystem.Server = setmetatable({}, TableSeatSystem)
end

local function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

local function buildSeatState(self, player)
	self:_EnsureSeatCatalog()

	local mySeatId = self._playerSeats[player.UserId]
	local occupiedSeats = {}
	local tablePlayerUserIds = {}
	local seatOrder = self._seatOrder or {}
	local seatDisplayEntries = {}

	for _, seatId in ipairs(seatOrder) do
		local occupant = self._seatOwners[seatId]
		if occupant and occupant:IsDescendantOf(Players) then
			occupiedSeats[seatId] = occupant.UserId
			table.insert(tablePlayerUserIds, occupant.UserId)
		end

		table.insert(seatDisplayEntries, self:_BuildSeatDisplayEntry(seatId, occupant))
	end

	return {
		mySeatId = mySeatId,
		seatId = mySeatId,
		isSeated = mySeatId ~= nil,
		occupiedSeats = occupiedSeats,
		tablePlayerUserIds = tablePlayerUserIds,
		seatOrder = table.clone(seatOrder),
		seatDisplayEntries = seatDisplayEntries,
		openSeatCount = math.max(#seatOrder - #tablePlayerUserIds, 0),
		isSpectating = mySeatId == nil,
	}
end

local function getSeatBillboardTone(streak)
	if streak >= 10 then
		return "Jackpot", BillboardColors.Jackpot
	end
	if streak >= 8 then
		return "On Fire", BillboardColors.Hot
	end
	if streak >= 4 then
		return "Heating Up", BillboardColors.Warm
	end
	return "Ready", BillboardColors.Open
end

local function getSeatBillboardAdornee(self, seatId)
	local tableModel = Workspace:FindFirstChild(Presets.TableModelName)
	local attachmentsFolder = tableModel and tableModel:FindFirstChild("Attachments")
	local marker = attachmentsFolder and attachmentsFolder:FindFirstChild(`{seatId}Marker`)
	local attachment = marker and marker:FindFirstChildWhichIsA("Attachment")
	if attachment then
		return attachment
	end

	local seatRecord = self._seats and self._seats[seatId]
	return seatRecord and seatRecord.seat or nil
end

local function ensureSeatBillboard(self, seatId)
	local seatRecord = self._seats and self._seats[seatId]
	if not seatRecord or not seatRecord.seat then
		return nil
	end

	if seatRecord.billboard and seatRecord.billboard.Parent then
		seatRecord.billboard.Adornee = getSeatBillboardAdornee(self, seatId)
		return seatRecord.billboard
	end

	local billboard = seatRecord.seat:WaitForChild("SeatInfoBillboard")
	billboard.Adornee = getSeatBillboardAdornee(self, seatId)

	seatRecord.billboard = billboard
	return billboard
end

local function refreshSeatBillboards(self)
	if not IsServer then
		return
	end

	self:_EnsureSeatCatalog()

	for _, seatId in ipairs(self._seatOrder or {}) do
		local entry = self:_BuildSeatDisplayEntry(seatId, self._seatOwners[seatId])
		local billboard = ensureSeatBillboard(self, seatId)
		local frame = billboard.Frame
		local seatLabel = frame.SeatLabel
		local statusLabel = frame.StatusLabel
		local nameLabel = frame.NameLabel
		local detailLabel = frame.DetailLabel
		local cashLabel = frame.CashLabel

		seatLabel.Text = entry.seatId
		statusLabel.Text = entry.statusText
		statusLabel.TextColor3 = entry.statusColor
		nameLabel.Text = entry.displayName
		detailLabel.Text = entry.detailText
		cashLabel.Text = entry.cashText
		billboard.Enabled = true
	end
end

local function refreshPromptAttributes(self, seatId)
	local seatRecord = self._seats[seatId]
	if not seatRecord or not seatRecord.prompt then
		return
	end

	seatRecord.prompt:SetAttribute("SeatId", seatId)
	seatRecord.prompt:SetAttribute("Occupied", self._seatOwners[seatId] ~= nil)
end

local function refreshLocalPromptVisibility(self)
	if IsServer then
		return
	end

	self:_EnsureSeatCatalog()

	local seatState = self._localSeatState or {
		occupiedSeats = {},
		isSpectating = true,
	}
	local hideAllPrompts = seatState.isSpectating == false

	for seatId, seatRecord in pairs(self._seats or {}) do
		local prompt = seatRecord.prompt
		if not prompt then
			continue
		end

		prompt.Enabled = (not hideAllPrompts) and seatState.occupiedSeats[seatId] == nil
	end
end

local function syncCoinFlipSeatState(self, player, seatState)
	local coinFlipSystem = GetSystemMgr().systems.CoinFlipSystem
	if not coinFlipSystem or not coinFlipSystem.Client or not coinFlipSystem.Client.SeatStateChanged then
		return
	end

	local coinFlipSeatState = table.clone(seatState)
	coinFlipSeatState.seatId = seatState.mySeatId
	coinFlipSeatState.isSeated = seatState.mySeatId ~= nil

	coinFlipSystem.Client:SeatStateChanged(player, {
		seatState = coinFlipSeatState,
	})
end

local function broadcastSeatStates(self)
	local systemMgr = GetSystemMgr()

	refreshSeatBillboards(self)

	for _, player in ipairs(Players:GetPlayers()) do
		local seatState = buildSeatState(self, player)
		self.Client:SeatStateChanged(player, seatState)
		syncCoinFlipSeatState(self, player, seatState)
	end

	for _, occupant in pairs(self._seatOwners) do
		if occupant and occupant:IsDescendantOf(Players) then
			systemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(occupant)
		end
	end
end

local function clearSeatOwnership(self, player, notifyReason)
	local seatId = self._playerSeats[player.UserId]
	if not seatId then
		return
	end

	local seatRecord = self._seats[seatId]
	local currentOccupant = self._seatOwners[seatId]
	if currentOccupant == player then
		self._seatOwners[seatId] = nil
	end
	self._playerSeats[player.UserId] = nil
	self._lastActivity[player.UserId] = nil

	if seatRecord and seatRecord.seat then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and seatRecord.seat.Occupant == humanoid then
			humanoid.Sit = false
		end
	end

	refreshPromptAttributes(self, seatId)
	GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(player)

	if notifyReason == "afk" then
		GetSystemMgr().systems.GuiSystem:SetNotification(SENDER, player, {
			text = "You were removed from the seat for inactivity.",
			lastTime = 2.5,
			textColor = Color3.fromRGB(255, 216, 128),
		})
	end

	broadcastSeatStates(self)
end

function TableSeatSystem:_EnsureSeatCatalog()
	self._seats = self._seats or {}
	self._seatOrder = self._seatOrder or {}
	self._seatOwners = self._seatOwners or {}
	self._playerSeats = self._playerSeats or {}
	self._lastActivity = self._lastActivity or {}

	local tableModel = Workspace:FindFirstChild(Presets.TableModelName)
	local seatsFolder = tableModel and tableModel:FindFirstChild(Presets.SeatsFolderName)
	if not seatsFolder then
		return
	end

	for _, seat in ipairs(seatsFolder:GetChildren()) do
		if not seat:IsA("Seat") then
			continue
		end

		local seatId = seat:GetAttribute("SeatId") or seat.Name
		if not self._seats[seatId] then
			table.insert(self._seatOrder, seatId)
		end

		local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)
		self._seats[seatId] = {
			seat = seat,
			prompt = prompt,
		}
		refreshPromptAttributes(self, seatId)

		if not IsServer then
			continue
		end

		self._seatPromptConnections = self._seatPromptConnections or {}
		self._seatOccupantConnections = self._seatOccupantConnections or {}

		if prompt and not self._seatPromptConnections[prompt] then
			self._seatPromptConnections[prompt] = prompt.Triggered:Connect(function(player)
				self:RequestSit(SENDER, player, {
					seatId = seatId,
				})
			end)
		end

		if not self._seatOccupantConnections[seat] then
			self._seatOccupantConnections[seat] = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local humanoid = seat.Occupant
				if humanoid then
					local occupantPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
					if occupantPlayer and self._seatOwners[seatId] ~= occupantPlayer then
						local previousSeat = self._playerSeats[occupantPlayer.UserId]
						if previousSeat and previousSeat ~= seatId then
							clearSeatOwnership(self, occupantPlayer)
						end
						self._seatOwners[seatId] = occupantPlayer
						self._playerSeats[occupantPlayer.UserId] = seatId
						self._lastActivity[occupantPlayer.UserId] = os.clock()
						refreshPromptAttributes(self, seatId)
						GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(occupantPlayer)
						broadcastSeatStates(self)
					end
					return
				end

				local seatedPlayer = self._seatOwners[seatId]
				if seatedPlayer and seatedPlayer:IsDescendantOf(Players) then
					clearSeatOwnership(self, seatedPlayer)
				else
					self._seatOwners[seatId] = nil
					refreshPromptAttributes(self, seatId)
					broadcastSeatStates(self)
				end
			end)
		end
	end
end

function TableSeatSystem:_BuildSeatDisplayEntry(seatId, occupant)
	if not IsServer then
		return {
			seatId = seatId,
			displayName = "Open Seat",
			coinName = "",
			streak = 0,
			cash = 0,
			cashText = "",
			statusText = "Available",
			statusColor = BillboardColors.Open,
			detailText = "Sit down to start flipping.",
			isOccupied = false,
		}
	end

	local entry = {
		seatId = seatId,
		displayName = "Open Seat",
		coinName = "",
		streak = 0,
		cash = 0,
		cashText = "",
		statusText = "Available",
		statusColor = BillboardColors.Open,
		detailText = "Sit down to start flipping.",
		isOccupied = false,
	}

	if not occupant or not occupant:IsDescendantOf(Players) then
		return entry
	end

	local playerIns = PlayerServerClass.GetIns(occupant, false)
	local runData = playerIns and playerIns:GetOneData(dataKey.runData) or {}
	local streak = runData.currentStreak or 0
	local equippedCoin = playerIns and (playerIns:GetOneData(dataKey.equippedCoin) or "Rusty Penny") or "Rusty Penny"
	local cash = playerIns and (playerIns:GetOneData(dataKey.wins) or 0) or 0
	local statusText, statusColor = getSeatBillboardTone(streak)

	entry.userId = occupant.UserId
	entry.displayName = occupant.DisplayName
	entry.coinName = equippedCoin
	entry.streak = streak
	entry.cash = cash
	entry.cashText = `$ {Util.FormatNumber(cash, true)}`
	entry.statusText = statusText
	entry.statusColor = statusColor
	entry.detailText = `Streak {streak} | {equippedCoin}`
	entry.isOccupied = true

	return entry
end

function TableSeatSystem:Init()
	GetSystemMgr()
	self:_EnsureSeatCatalog()

	if IsServer then
		self._afkScheduleId = ScheduleModule.AddSchedule(Presets.AfkCheckInterval, function()
			local now = os.clock()
			for userId, seatId in pairs(self._playerSeats) do
				local player = Players:GetPlayerByUserId(userId)
				if not player then
					self._seatOwners[seatId] = nil
					self._playerSeats[userId] = nil
					self._lastActivity[userId] = nil
					refreshPromptAttributes(self, seatId)
				elseif now - (self._lastActivity[userId] or now) >= Presets.AfkKickSeconds then
					clearSeatOwnership(self, player, "afk")
				end
			end
		end)
	else
		refreshLocalPromptVisibility(self)
	end
end

function TableSeatSystem:GetPlayerSeatId(player)
	return self._playerSeats and self._playerSeats[player.UserId] or nil
end

function TableSeatSystem:GetTablePlayers(seatId)
	local tablePlayers = {}
	for _, orderedSeatId in ipairs(self._seatOrder or {}) do
		local player = self._seatOwners[orderedSeatId]
		if player and player:IsDescendantOf(Players) then
			table.insert(tablePlayers, player)
		end
	end
	return tablePlayers
end

function TableSeatSystem:GetAudiencePlayers(seatId)
	return Players:GetPlayers()
end

function TableSeatSystem:IsPlayerSeated(player)
	return self:GetPlayerSeatId(player) ~= nil
end

function TableSeatSystem:RegisterActivity(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if not self:IsPlayerSeated(player) then
		return
	end

	self._lastActivity[player.UserId] = os.clock()
end

function TableSeatSystem:GetClientSeatState(player)
	return buildSeatState(self, player)
end

function TableSeatSystem:RefreshAudienceState(sender)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	broadcastSeatStates(self)
end

function TableSeatSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local seatState = buildSeatState(self, player)
		self.Client:PlayerAdded(player, {
			seatState = seatState,
		})
		syncCoinFlipSeatState(self, player, seatState)
	else
		local pendingCalls = TableSeatUi.pendingCalls

		TableSeatUi = require(script.ui)
		TableSeatUi.Init()

		for _, call in ipairs(pendingCalls) do
			TableSeatUi[call.functionName](table.unpack(call.args))
		end

		self._localSeatState = args and args.seatState or {
			occupiedSeats = {},
			tablePlayerUserIds = {},
			isSpectating = true,
		}
		refreshLocalPromptVisibility(self)
	end
end

function TableSeatSystem:PlayerRemoving(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	clearSeatOwnership(self, player)
end

function TableSeatSystem:RequestSit(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end

	local seatId = args and args.seatId
	if typeof(seatId) ~= "string" then
		return
	end

	self:_EnsureSeatCatalog()
	local seatRecord = self._seats[seatId]
	if not seatRecord then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local occupant = self._seatOwners[seatId]
	if occupant and occupant ~= player and occupant:IsDescendantOf(Players) then
		return
	end

	local currentSeatId = self._playerSeats[player.UserId]
	if currentSeatId and currentSeatId ~= seatId then
		clearSeatOwnership(self, player)
	end

	self._seatOwners[seatId] = player
	self._playerSeats[player.UserId] = seatId
	self._lastActivity[player.UserId] = os.clock()
	refreshPromptAttributes(self, seatId)
	seatRecord.seat:Sit(humanoid)

	GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(player)
	broadcastSeatStates(self)
end

function TableSeatSystem:RequestStand(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end

	clearSeatOwnership(self, player)
end

function TableSeatSystem:SeatStateChanged(sender, player, args)
	if IsServer then
		return
	end

	self._localSeatState = args or {
		occupiedSeats = {},
		tablePlayerUserIds = {},
		isSpectating = true,
	}
	refreshLocalPromptVisibility(self)
end

return TableSeatSystem
