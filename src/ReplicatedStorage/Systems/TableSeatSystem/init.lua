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
	local seatOrder = self._seatOrder or {}
	local seatSnapshot = self:_BuildSeatDisplaySnapshot()

	return {
		mySeatId = mySeatId,
		seatId = mySeatId,
		isSeated = mySeatId ~= nil,
		occupiedSeats = seatSnapshot.occupiedSeats,
		tablePlayerUserIds = seatSnapshot.tablePlayerUserIds,
		seatOrder = table.clone(seatOrder),
		seatDisplayEntries = seatSnapshot.seatDisplayEntries,
		openSeatCount = math.max(#seatOrder - #seatSnapshot.tablePlayerUserIds, 0),
		isSpectating = mySeatId == nil,
		featuredSeatId = seatSnapshot.featuredSeatId,
		featuredSeatPlayerName = seatSnapshot.featuredSeatPlayerName,
		featuredSeatLabel = seatSnapshot.featuredSeatLabel,
		featuredSeatStreak = seatSnapshot.featuredSeatStreak,
		featuredSeatReason = seatSnapshot.featuredSeatReason,
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

local function getFeaturedSeatMeta(entry, secondsSinceActivity)
	local streak = entry.streak or 0
	if streak >= 8 then
		return "Table Fever", BillboardColors.Jackpot, `Best streak on table: {streak}`
	end
	if streak >= 4 then
		return "Hot Seat", BillboardColors.Hot, `Best streak on table: {streak}`
	end
	if streak >= 2 then
		return "Rising", BillboardColors.Warm, `Streak building: {streak}`
	end
	if typeof(secondsSinceActivity) == "number" and secondsSinceActivity <= Presets.HotSeat.RecentSeatWindow then
		return "Live Now", BillboardColors.Warm, "Most recent action at the table"
	end
	return "Featured", BillboardColors.Open, "Best seat to watch right now"
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
	local seatSnapshot = self:_BuildSeatDisplaySnapshot()
	local seatEntryMap = {}
	for _, entry in ipairs(seatSnapshot.seatDisplayEntries) do
		seatEntryMap[entry.seatId] = entry
	end

	for _, seatId in ipairs(self._seatOrder or {}) do
		local entry = seatEntryMap[seatId]
		local billboard = ensureSeatBillboard(self, seatId)
		if not entry or not billboard then
			continue
		end

		local frame = billboard.Frame
		local seatLabel = frame.SeatLabel
		local statusLabel = frame.StatusLabel
		local nameLabel = frame.NameLabel
		local detailLabel = frame.DetailLabel
		local cashLabel = frame.CashLabel
		local stroke = frame:FindFirstChildOfClass("UIStroke")

		seatLabel.Text = entry.seatId
		statusLabel.Text = entry.isFeatured and (entry.featuredBadgeText or entry.statusText) or entry.statusText
		statusLabel.TextColor3 = entry.isFeatured and (entry.featuredBadgeColor or entry.statusColor) or entry.statusColor
		nameLabel.Text = entry.displayName
		detailLabel.Text = entry.isFeatured and (entry.featuredDetailText or entry.detailText) or entry.detailText
		cashLabel.Text = entry.cashText
		frame.BackgroundTransparency = entry.isFeatured and 0.08 or 0.18
		if stroke then
			stroke.Color = entry.isFeatured and (entry.featuredBadgeColor or BillboardColors.Stroke) or BillboardColors.Stroke
			stroke.Transparency = entry.isFeatured and 0.04 or 0.22
			stroke.Thickness = entry.isFeatured and 1.65 or 1.25
		end
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

	for seatId, seatRecord in pairs(self._seats or {}) do
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

local function clearSeatOwnership(self, player)
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
		if prompt then
			prompt.Enabled = false
		end
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
						GetSystemMgr().systems.CoinFlipSystem:HandleGuideSit(SENDER, occupantPlayer)
					end
					return
				end

				local seatedPlayer = self._seatOwners[seatId]
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
					self._seatOwners[seatId] = nil
					refreshPromptAttributes(self, seatId)
					broadcastSeatStates(self)
				end
			end)
		end
	end
end

function TableSeatSystem:_FindOpenSeatId(player)
	self:_EnsureSeatCatalog()

	local currentSeatId = self._playerSeats[player.UserId]
	if currentSeatId then
		local currentRecord = self._seats[currentSeatId]
		local currentOwner = self._seatOwners[currentSeatId]
		if currentRecord and (not currentOwner or currentOwner == player or not currentOwner:IsDescendantOf(Players)) then
			return currentSeatId
		end
	end

	for _, seatId in ipairs(self._seatOrder or {}) do
		local seatRecord = self._seats[seatId]
		local owner = self._seatOwners[seatId]
		if seatRecord and (not owner or not owner:IsDescendantOf(Players)) then
			return seatId
		end
	end

	return nil
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

	local function trySeatOnce()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seatId = self:_FindOpenSeatId(player)

		if humanoid and seatId then
			return self:RequestSit(SENDER, player, {
				seatId = seatId,
				autoAssigned = true,
			})
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

		warn(`[TableSeatSystem] Failed to auto-seat {player.Name}: no available seat or humanoid.`)
	end)
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

function TableSeatSystem:_BuildSeatDisplaySnapshot()
	self:_EnsureSeatCatalog()

	local occupiedSeats = {}
	local tablePlayerUserIds = {}
	local seatDisplayEntries = {}
	local featuredEntry
	local featuredScore = -math.huge
	local featuredActivityAge = math.huge
	local featuredStreak = -1
	local featuredCash = -1

	for _, seatId in ipairs(self._seatOrder or {}) do
		local occupant = self._seatOwners[seatId]
		if occupant and occupant:IsDescendantOf(Players) then
			occupiedSeats[seatId] = occupant.UserId
			table.insert(tablePlayerUserIds, occupant.UserId)
		end

		local entry = self:_BuildSeatDisplayEntry(seatId, occupant)
		table.insert(seatDisplayEntries, entry)

		if entry.isOccupied then
			local lastActivityAt = self._lastActivity[entry.userId]
			local secondsSinceActivity = nil
			if typeof(lastActivityAt) == "number" then
				secondsSinceActivity = math.max(os.clock() - lastActivityAt, 0)
			end

			local activityWindow = Presets.HotSeat.RecentActivityWindow
			local recentActivityBonus = 0
			if typeof(secondsSinceActivity) == "number" then
				recentActivityBonus = math.max(activityWindow - math.min(secondsSinceActivity, activityWindow), 0)
					* Presets.HotSeat.RecentActivityWeight
			end
			local cashBonus = math.min(
				math.floor((entry.cash or 0) / Presets.HotSeat.CashBonusDivisor),
				Presets.HotSeat.MaxCashBonus
			)
			local score = ((entry.streak or 0) * Presets.HotSeat.StreakWeight) + recentActivityBonus + cashBonus

			entry.secondsSinceActivity = secondsSinceActivity
			entry.heatScore = score

			local activityAge = typeof(secondsSinceActivity) == "number" and secondsSinceActivity or math.huge
			if score > featuredScore
				or (score == featuredScore and (entry.streak or 0) > featuredStreak)
				or (score == featuredScore and (entry.streak or 0) == featuredStreak and activityAge < featuredActivityAge)
				or (
					score == featuredScore
					and (entry.streak or 0) == featuredStreak
					and activityAge == featuredActivityAge
					and (entry.cash or 0) > featuredCash
				)
			then
				featuredEntry = entry
				featuredScore = score
				featuredActivityAge = activityAge
				featuredStreak = entry.streak or 0
				featuredCash = entry.cash or 0
			end
		end
	end

	local featuredSeatId
	local featuredSeatPlayerName
	local featuredSeatLabel
	local featuredSeatStreak
	local featuredSeatReason

	if featuredEntry then
		local badgeText, badgeColor, detailText =
			getFeaturedSeatMeta(featuredEntry, featuredEntry.secondsSinceActivity)
		featuredEntry.isFeatured = true
		featuredEntry.featuredBadgeText = badgeText
		featuredEntry.featuredBadgeColor = badgeColor
		featuredEntry.featuredDetailText = detailText

		featuredSeatId = featuredEntry.seatId
		featuredSeatPlayerName = featuredEntry.displayName
		featuredSeatLabel = badgeText
		featuredSeatStreak = featuredEntry.streak or 0
		featuredSeatReason = detailText
	end

	return {
		occupiedSeats = occupiedSeats,
		tablePlayerUserIds = tablePlayerUserIds,
		seatDisplayEntries = seatDisplayEntries,
		featuredSeatId = featuredSeatId,
		featuredSeatPlayerName = featuredSeatPlayerName,
		featuredSeatLabel = featuredSeatLabel,
		featuredSeatStreak = featuredSeatStreak,
		featuredSeatReason = featuredSeatReason,
	}
end

function TableSeatSystem:Init()
	GetSystemMgr()
	self:_EnsureSeatCatalog()

	if IsServer then
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

	local seatId = args and args.seatId
	if typeof(seatId) ~= "string" then
		return false
	end

	self:_EnsureSeatCatalog()
	local seatRecord = self._seats[seatId]
	if not seatRecord then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local occupant = self._seatOwners[seatId]
	if occupant and occupant ~= player and occupant:IsDescendantOf(Players) then
		return false
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
	return true
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
