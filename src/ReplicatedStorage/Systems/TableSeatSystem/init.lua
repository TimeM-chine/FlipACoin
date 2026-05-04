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
		"GetPlayerSeatAssignment",
		"GetSeatRecordByDisplayId",
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

local function getSeatRecord(self, seatKey)
	if typeof(seatKey) ~= "string" then
		return nil
	end

	return self._seats and self._seats[seatKey] or nil
end

local function getSeatDisplayId(self, seatKey)
	local seatRecord = getSeatRecord(self, seatKey)
	return seatRecord and seatRecord.displaySeatId or nil
end

local function getPlayerSeatRecord(self, player)
	local seatKey = self._playerSeats and self._playerSeats[player.UserId]
	return getSeatRecord(self, seatKey)
end

local function resolveSeatKey(self, seatIdentifier)
	if typeof(seatIdentifier) ~= "string" then
		return nil
	end

	if self._seats and self._seats[seatIdentifier] then
		return seatIdentifier
	end

	return self._seatDisplayLookup and self._seatDisplayLookup[seatIdentifier] or nil
end

local function getTableSortPosition(tableModel)
	local anchor = tableModel.PrimaryPart or tableModel:FindFirstChildWhichIsA("BasePart", true)
	return anchor and anchor.Position or Vector3.zero
end

local function buildSeatState(self, player)
	self:_EnsureSeatCatalog()

	local mySeatRecord = getPlayerSeatRecord(self, player)
	local mySeatId = mySeatRecord and mySeatRecord.displaySeatId or nil
	local seatOrder = {}
	for _, seatKey in ipairs(self._seatOrder or {}) do
		table.insert(seatOrder, getSeatDisplayId(self, seatKey) or seatKey)
	end
	local seatSnapshot = self:_BuildSeatDisplaySnapshot()
	local assignmentStatus
	local assignmentMessage

	if not mySeatId then
		local isWaitingForSeat = self._playersWaitingForSeat and self._playersWaitingForSeat[player.UserId] == true
		if isWaitingForSeat then
			if seatSnapshot.openSeatCount > 0 then
				assignmentStatus = "assigning"
				assignmentMessage = "Seat opening detected. Seating you..."
			else
				assignmentStatus = "full"
				assignmentMessage = "All coin flip seats are full. Waiting for the next open seat..."
			end
		elseif seatSnapshot.openSeatCount > 0 then
			assignmentStatus = "assigning"
			assignmentMessage = "Finding an available seat..."
		end
	end

	return {
		mySeatId = mySeatId,
		seatId = mySeatId,
		isSeated = mySeatId ~= nil,
		occupiedSeats = seatSnapshot.occupiedSeats,
		tablePlayerUserIds = seatSnapshot.tablePlayerUserIds,
		seatOrder = table.clone(seatOrder),
		seatDisplayEntries = seatSnapshot.seatDisplayEntries,
		openSeatCount = seatSnapshot.openSeatCount,
		isSpectating = mySeatId == nil,
		tableId = mySeatRecord and mySeatRecord.tableId or nil,
		assignmentStatus = assignmentStatus,
		assignmentMessage = assignmentMessage,
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

local function disableSeatBillboards(self)
	if not IsServer then
		return
	end

	self:_EnsureSeatCatalog()

	for _, seatKey in ipairs(self._seatOrder or {}) do
		local seatRecord = getSeatRecord(self, seatKey)
		local billboard = seatRecord and seatRecord.seat and seatRecord.seat:FindFirstChild("SeatInfoBillboard")
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = false
			seatRecord.billboard = billboard
		end
	end
end

local function refreshPromptAttributes(self, seatKey)
	local seatRecord = getSeatRecord(self, seatKey)
	if not seatRecord or not seatRecord.prompt then
		return
	end

	seatRecord.prompt:SetAttribute("SeatId", seatRecord.displaySeatId or seatRecord.rawSeatId)
	seatRecord.prompt:SetAttribute("SeatKey", seatKey)
	seatRecord.prompt:SetAttribute("Occupied", self._seatOwners[seatKey] ~= nil)
end

local function refreshLocalPromptVisibility(self)
	if IsServer then
		return
	end

	self:_EnsureSeatCatalog()

	for _, seatRecord in pairs(self._seats or {}) do
		local prompt = seatRecord.prompt
		if not prompt then
			continue
		end

		prompt.Enabled = false
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

	disableSeatBillboards(self)

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

local function clearSeatOwnership(self, player)
	local seatKey = self._playerSeats[player.UserId]
	if not seatKey then
		return
	end

	local seatRecord = getSeatRecord(self, seatKey)
	local currentOccupant = self._seatOwners[seatKey]
	if currentOccupant == player then
		self._seatOwners[seatKey] = nil
	end
	self._playerSeats[player.UserId] = nil
	self._lastActivity[player.UserId] = nil

	if seatRecord and seatRecord.seat then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and seatRecord.seat.Occupant == humanoid then
			humanoid.Sit = false
		end
	end

	refreshPromptAttributes(self, seatKey)
	GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(player)
	self:_TryAssignWaitingPlayers()
	broadcastSeatStates(self)
end

local function bindPlayerCharacterAutoSeat(self, player)
	self._playerCharacterConnections = self._playerCharacterConnections or {}
	if self._playerCharacterConnections[player.UserId] then
		return
	end

	self._playerCharacterConnections[player.UserId] = player.CharacterAdded:Connect(function()
		self:_QueueAutoSeat(player)
	end)
end

local function disconnectPlayerCharacterAutoSeat(self, player)
	local connections = self._playerCharacterConnections
	local connection = connections and connections[player.UserId]
	if not connection then
		return
	end

	connection:Disconnect()
	connections[player.UserId] = nil
end

function TableSeatSystem:_EnsureSeatCatalog()
	self._seats = self._seats or {}
	self._seatOrder = self._seatOrder or {}
	self._seatDisplayLookup = self._seatDisplayLookup or {}
	self._seatOwners = self._seatOwners or {}
	self._playerSeats = self._playerSeats or {}
	self._lastActivity = self._lastActivity or {}

	local tableModels = {}
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == Presets.TableModelName then
			local seatsFolder = descendant:FindFirstChild(Presets.SeatsFolderName)
			if seatsFolder then
				table.insert(tableModels, descendant)
			end
		end
	end

	if #tableModels == 0 then
		return
	end

	table.sort(tableModels, function(modelA, modelB)
		local tableIdA = tostring(modelA:GetAttribute("TableId") or "")
		local tableIdB = tostring(modelB:GetAttribute("TableId") or "")
		if tableIdA ~= tableIdB then
			if tableIdA == "" then
				return false
			end
			if tableIdB == "" then
				return true
			end
			return tableIdA < tableIdB
		end

		local posA = getTableSortPosition(modelA)
		local posB = getTableSortPosition(modelB)
		if posA.Z ~= posB.Z then
			return posA.Z < posB.Z
		end
		if posA.X ~= posB.X then
			return posA.X < posB.X
		end
		return modelA.Name < modelB.Name
	end)

	local discoveredSeatKeys = {}
	local seatOrder = {}
	local seatDisplayLookup = {}
	local hasMultipleTables = #tableModels > 1

	for tableIndex, tableModel in ipairs(tableModels) do
		local tableId = tableModel:GetAttribute("TableId")
		if typeof(tableId) ~= "string" or tableId == "" then
			tableId = `Table{tableIndex}`
		end

		local tableLabel = tableModel:GetAttribute("TableLabel")
		if typeof(tableLabel) ~= "string" or tableLabel == "" then
			tableLabel = `T{tableIndex}`
		end

		local seatsFolder = tableModel:FindFirstChild(Presets.SeatsFolderName)
		if not seatsFolder then
			continue
		end

		local seats = {}
		for _, seat in ipairs(seatsFolder:GetChildren()) do
			if seat:IsA("Seat") then
				table.insert(seats, seat)
			end
		end

		table.sort(seats, function(seatA, seatB)
			local seatIdA = tostring(seatA:GetAttribute("SeatId") or seatA.Name)
			local seatIdB = tostring(seatB:GetAttribute("SeatId") or seatB.Name)
			return seatIdA < seatIdB
		end)

		for _, seat in ipairs(seats) do
			local rawSeatId = tostring(seat:GetAttribute("SeatId") or seat.Name)
			local seatKey = `{tableId}:{rawSeatId}`
			local displaySeatId = hasMultipleTables and `{tableLabel}-{rawSeatId}` or rawSeatId
			local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)

			if prompt then
				prompt.Enabled = false
			end

			table.insert(seatOrder, seatKey)
			seatDisplayLookup[displaySeatId] = seatKey
			discoveredSeatKeys[seatKey] = true

			self._seats[seatKey] = self._seats[seatKey] or {}
			self._seats[seatKey].seat = seat
			self._seats[seatKey].prompt = prompt
			self._seats[seatKey].tableId = tableId
			self._seats[seatKey].tableLabel = tableLabel
			self._seats[seatKey].displaySeatId = displaySeatId
			self._seats[seatKey].rawSeatId = rawSeatId
			self._seats[seatKey].tableModel = tableModel
			refreshPromptAttributes(self, seatKey)

			if not IsServer then
				continue
			end

			self._seatPromptConnections = self._seatPromptConnections or {}
			self._seatOccupantConnections = self._seatOccupantConnections or {}

			if not self._seatOccupantConnections[seat] then
				self._seatOccupantConnections[seat] = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
					local humanoid = seat.Occupant
					if humanoid then
						local occupantPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
						if occupantPlayer and self._seatOwners[seatKey] ~= occupantPlayer then
							local previousSeat = self._playerSeats[occupantPlayer.UserId]
							if previousSeat and previousSeat ~= seatKey then
								clearSeatOwnership(self, occupantPlayer)
							end
							self._seatOwners[seatKey] = occupantPlayer
							self._playerSeats[occupantPlayer.UserId] = seatKey
							self._lastActivity[occupantPlayer.UserId] = os.clock()
							self._playersWaitingForSeat = self._playersWaitingForSeat or {}
							self._playersWaitingForSeat[occupantPlayer.UserId] = nil
							refreshPromptAttributes(self, seatKey)
							GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(occupantPlayer)
							broadcastSeatStates(self)
							GetSystemMgr().systems.CoinFlipSystem:HandleGuideSit(SENDER, occupantPlayer)
						end
						return
					end

					local seatedPlayer = self._seatOwners[seatKey]
					if seatedPlayer and seatedPlayer:IsDescendantOf(Players) then
						local seatedHumanoid = seatedPlayer.Character and seatedPlayer.Character:FindFirstChildOfClass("Humanoid")
						if seatedHumanoid and seatedHumanoid.Health > 0 then
							task.defer(function()
								self:_QueueAutoSeat(seatedPlayer)
							end)
							return
						end

						clearSeatOwnership(self, seatedPlayer)
					else
						self._seatOwners[seatKey] = nil
						refreshPromptAttributes(self, seatKey)
						self:_TryAssignWaitingPlayers()
						broadcastSeatStates(self)
					end
				end)
			end
		end
	end

	for seatKey in pairs(self._seats) do
		if not discoveredSeatKeys[seatKey] then
			self._seats[seatKey] = nil
		end
	end

	self._seatOrder = seatOrder
	self._seatDisplayLookup = seatDisplayLookup
end

function TableSeatSystem:_FindOpenSeatKey(player)
	self:_EnsureSeatCatalog()

	local currentSeatKey = self._playerSeats[player.UserId]
	if currentSeatKey then
		local currentRecord = self._seats[currentSeatKey]
		local currentOwner = self._seatOwners[currentSeatKey]
		if currentRecord and (not currentOwner or currentOwner == player or not currentOwner:IsDescendantOf(Players)) then
			return currentSeatKey
		end
	end

	for _, seatKey in ipairs(self._seatOrder or {}) do
		local seatRecord = self._seats[seatKey]
		local owner = self._seatOwners[seatKey]
		if seatRecord and (not owner or not owner:IsDescendantOf(Players)) then
			return seatKey
		end
	end

	return nil
end

function TableSeatSystem:_TryAssignWaitingPlayers()
	if not IsServer then
		return
	end

	self._playersWaitingForSeat = self._playersWaitingForSeat or {}
	self._seatWaitQueue = self._seatWaitQueue or {}

	while #self._seatWaitQueue > 0 do
		local userId = self._seatWaitQueue[1]
		local player = Players:GetPlayerByUserId(userId)
		if not player or not player:IsDescendantOf(Players) then
			self._playersWaitingForSeat[userId] = nil
			table.remove(self._seatWaitQueue, 1)
			continue
		end

		if self._playerSeats[userId] then
			self._playersWaitingForSeat[userId] = nil
			table.remove(self._seatWaitQueue, 1)
			continue
		end

		if not self:_FindOpenSeatKey(player) then
			return
		end

		table.remove(self._seatWaitQueue, 1)
		self._playersWaitingForSeat[userId] = nil
		self:_QueueAutoSeat(player)
	end
end

function TableSeatSystem:_QueueAutoSeat(player)
	if not IsServer then
		return
	end
	if not player or not player:IsDescendantOf(Players) then
		return
	end

	self._autoSeatTokens = self._autoSeatTokens or {}
	local token = (self._autoSeatTokens[player.UserId] or 0) + 1
	self._autoSeatTokens[player.UserId] = token
	self._playersWaitingForSeat = self._playersWaitingForSeat or {}
	self._seatWaitQueue = self._seatWaitQueue or {}

	local function markWaitingForSeat(message)
		if self._playersWaitingForSeat[player.UserId] then
			broadcastSeatStates(self)
			return
		end

		self._playersWaitingForSeat[player.UserId] = true
		table.insert(self._seatWaitQueue, player.UserId)
		GetSystemMgr().systems.GuiSystem:SetNotification(SENDER, player, {
			text = message or "All coin flip seats are full. Waiting for the next open seat...",
			lastTime = 3.2,
			textColor = Color3.fromRGB(255, 224, 158),
		})
		broadcastSeatStates(self)
	end

	local function clearWaitingForSeat()
		if not self._playersWaitingForSeat[player.UserId] then
			return
		end

		self._playersWaitingForSeat[player.UserId] = nil
		for index = #self._seatWaitQueue, 1, -1 do
			if self._seatWaitQueue[index] == player.UserId then
				table.remove(self._seatWaitQueue, index)
			end
		end
	end

	local function isPlayerActuallySeated(seatKey, humanoid)
		local seatRecord = getSeatRecord(self, seatKey)
		return seatRecord and seatRecord.seat.Occupant == humanoid and self._playerSeats[player.UserId] == seatKey
	end

	local function trySeatOnce()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seatKey = self:_FindOpenSeatKey(player)

		if humanoid and seatKey and isPlayerActuallySeated(seatKey, humanoid) then
			clearWaitingForSeat()
			return true
		end

		if humanoid and seatKey then
			self:RequestSit(SENDER, player, {
				seatId = seatKey,
				autoAssigned = true,
			})
			if isPlayerActuallySeated(seatKey, humanoid) then
				clearWaitingForSeat()
				return true
			end
		end

		return false
	end

	if trySeatOnce() then
		return
	end

	task.spawn(function()
		for attempt = 1, Presets.AutoSeatMaxAttempts do
			if self._autoSeatTokens[player.UserId] ~= token or not player:IsDescendantOf(Players) then
				return
			end

			if trySeatOnce() then
				return
			end

			task.wait(Presets.AutoSeatRetryInterval)
		end

		if not self:_FindOpenSeatKey(player) then
			markWaitingForSeat()
			return
		end

		markWaitingForSeat("Seat is ready. Waiting for your character to sit...")
	end)
end

function TableSeatSystem:_BuildSeatDisplayEntry(seatKey, occupant)
	local seatRecord = getSeatRecord(self, seatKey)
	local displaySeatId = seatRecord and seatRecord.displaySeatId or seatKey
	if not IsServer then
		return {
			seatKey = seatKey,
			seatId = displaySeatId,
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
		seatKey = seatKey,
		seatId = displaySeatId,
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

function TableSeatSystem:_BuildSeatDisplaySnapshot()
	self:_EnsureSeatCatalog()

	local occupiedSeats = {}
	local tablePlayerUserIds = {}
	local seatDisplayEntries = {}
	local openSeatCount = 0

	for _, seatKey in ipairs(self._seatOrder or {}) do
		local occupant = self._seatOwners[seatKey]
		if occupant and occupant:IsDescendantOf(Players) then
			occupiedSeats[getSeatDisplayId(self, seatKey) or seatKey] = occupant.UserId
			table.insert(tablePlayerUserIds, occupant.UserId)
		end

		local entry = self:_BuildSeatDisplayEntry(seatKey, occupant)
		table.insert(seatDisplayEntries, entry)
		if not entry.isOccupied then
			openSeatCount += 1
		end
	end

	return {
		occupiedSeats = occupiedSeats,
		tablePlayerUserIds = tablePlayerUserIds,
		seatDisplayEntries = seatDisplayEntries,
		openSeatCount = openSeatCount,
	}
end

function TableSeatSystem:Init()
	GetSystemMgr()
	self:_EnsureSeatCatalog()

	if IsServer then
		disableSeatBillboards(self)
		self._afkScheduleId = ScheduleModule.AddSchedule(Presets.AfkCheckInterval, function()
			for userId, seatId in pairs(self._playerSeats) do
				local player = Players:GetPlayerByUserId(userId)
				if not player then
					self._seatOwners[seatId] = nil
					self._playerSeats[userId] = nil
					self._lastActivity[userId] = nil
					refreshPromptAttributes(self, seatId)
				end
			end
		end)
	else
		refreshLocalPromptVisibility(self)
	end
end

function TableSeatSystem:GetPlayerSeatId(player)
	local seatRecord = getPlayerSeatRecord(self, player)
	return seatRecord and seatRecord.displaySeatId or nil
end

function TableSeatSystem:GetPlayerSeatAssignment(player)
	local seatRecord = getPlayerSeatRecord(self, player)
	if not seatRecord then
		return nil
	end

	return {
		seatId = seatRecord.displaySeatId,
		rawSeatId = seatRecord.rawSeatId,
		tableId = seatRecord.tableId,
		tableLabel = seatRecord.tableLabel,
		seat = seatRecord.seat,
		tableModel = seatRecord.tableModel,
	}
end

function TableSeatSystem:GetSeatRecordByDisplayId(displaySeatId)
	self:_EnsureSeatCatalog()
	local seatKey = resolveSeatKey(self, displaySeatId)
	return getSeatRecord(self, seatKey)
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

		bindPlayerCharacterAutoSeat(self, player)
		self:_QueueAutoSeat(player)

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

	disconnectPlayerCharacterAutoSeat(self, player)
	self._autoSeatTokens = self._autoSeatTokens or {}
	self._autoSeatTokens[player.UserId] = nil
	self._playersWaitingForSeat = self._playersWaitingForSeat or {}
	self._playersWaitingForSeat[player.UserId] = nil
	self._seatWaitQueue = self._seatWaitQueue or {}
	for index = #self._seatWaitQueue, 1, -1 do
		if self._seatWaitQueue[index] == player.UserId then
			table.remove(self._seatWaitQueue, index)
		end
	end
	clearSeatOwnership(self, player)
end

function TableSeatSystem:RequestSit(sender, player, args)
	if not IsServer then
		return false
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return false
	end

	self:_EnsureSeatCatalog()
	local seatId = args and args.seatId
	local seatKey = resolveSeatKey(self, seatId)
	if not seatKey then
		return false
	end

	local seatRecord = self._seats[seatKey]
	if not seatRecord then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local seatOccupant = seatRecord.seat.Occupant
	local occupant = self._seatOwners[seatKey]
	if occupant and occupant ~= player and occupant:IsDescendantOf(Players) then
		return false
	end
	if seatOccupant and seatOccupant ~= humanoid then
		local seatOccupantPlayer = Players:GetPlayerFromCharacter(seatOccupant.Parent)
		if seatOccupantPlayer and seatOccupantPlayer ~= player then
			return false
		end
	end

	local currentSeatKey = self._playerSeats[player.UserId]
	if currentSeatKey and currentSeatKey ~= seatKey then
		clearSeatOwnership(self, player)
	end

	if seatRecord.seat.Occupant == humanoid then
		self._seatOwners[seatKey] = player
		self._playerSeats[player.UserId] = seatKey
		self._lastActivity[player.UserId] = os.clock()
		refreshPromptAttributes(self, seatKey)
		GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(player)
		broadcastSeatStates(self)
		return true
	end

	seatRecord.seat:Sit(humanoid)
	if seatRecord.seat.Occupant == humanoid then
		self._seatOwners[seatKey] = player
		self._playerSeats[player.UserId] = seatKey
		self._lastActivity[player.UserId] = os.clock()
		refreshPromptAttributes(self, seatKey)
		GetSystemMgr().systems.PlayerSystem:UpdatePlayerHeadGui(player)
		broadcastSeatStates(self)
		return true
	end

	return false
end

function TableSeatSystem:RequestStand(sender, player, args)
	if not IsServer then
		return false
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return false
	end

	if player and player:IsDescendantOf(Players) then
		self:_QueueAutoSeat(player)
	end

	return false
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
