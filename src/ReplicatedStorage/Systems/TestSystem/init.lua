local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Keys = require(Replicated.configs.Keys)
local DebugData = require(Replicated.configs.DebugData)
local Presets = require(script.Presets)
local RebirthPresets = require(Replicated.Systems.RebirthSystem.Presets)
local ScheduleModule = require(Replicated.modules.ScheduleModule)
local TableModule = require(Replicated.modules.TableModule)
local Types = require(Replicated.configs.Types)

local IsServer = RunService:IsServer()
local dataKey = Keys.DataKey
local SENDER, SystemMgr, PlayerServerClass
local TestUi = { pendingCalls = {} }
setmetatable(TestUi, Types.mt)

local TestSystem = {
	whiteList = {
		"ConsumeForcedOutcome",
		"SendLongSessionSample",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
TestSystem.__index = TestSystem

if IsServer then
	TestSystem.Client = setmetatable({}, TestSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	TestSystem.Server = setmetatable({}, TestSystem)
end

local function getSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

local function buildRebirthTree(coinSpread)
	return {
		polishedStart = coinSpread,
		chainStart = 0,
		quickStart = 0,
		luckyStart = 0,
	}
end

local function countPlayerDescendants(player)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	return playerGui and #playerGui:GetDescendants() or 0
end

local function cancelPlayerSchedules(state)
	if not state then
		return
	end
	for _, scheduleId in ipairs({ state.longSessionScheduleId, state.autoFlipScheduleId }) do
		if scheduleId then
			ScheduleModule.CancelSchedule(scheduleId)
		end
	end
end

function TestSystem:Init()
	assert(RunService:IsStudio(), "TestSystem must only load in Studio")
	getSystemMgr()
	if not IsServer then
		TestUi = require(script.ui)
		TestUi.Init()
	end
end

function TestSystem:PlayerAdded(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.Client:ScenarioApplied(player, {
			scenario = "freshRun",
			status = "Studio QA ready",
		})
	else
		TestUi.Init()
	end
end

function TestSystem:PlayerRemoving(sender, player)
	if not IsServer or sender ~= SENDER then
		return
	end
	local state = self.players[player.UserId]
	cancelPlayerSchedules(state)
	self.players[player.UserId] = nil
end

function TestSystem:ApplyScenario(sender, player, args)
	if not IsServer or not RunService:IsStudio() then
		return
	end
	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) then
		return
	end
	local scenarioName = args and args.scenario
	local scenario = typeof(scenarioName) == "string" and Presets.Scenarios[scenarioName]
	if not scenario then
		self.Client:ScenarioApplied(player, { status = "Rejected unknown scenario" })
		return
	end

	local playerIns = PlayerServerClass.GetIns(player, false)
	if not playerIns then
		self.Client:ScenarioApplied(player, { status = "Profile is not ready" })
		return
	end

	local oldState = self.players[player.UserId]
	cancelPlayerSchedules(oldState)
	local rebirthTree = buildRebirthTree(scenario.coinSpread)
	local runData = RebirthPresets.BuildFlipACoinRunBaseline(rebirthTree, scenario.rebirth)
	for key, value in pairs(TableModule.DeepCopy(DebugData)) do
		playerIns:SetOneData(key, value)
	end
	playerIns:SetOneData(dataKey.wins, scenario.cash)
	playerIns:SetOneData(dataKey.rebirth, scenario.rebirth)
	playerIns:SetOneData(dataKey.fateShards, scenario.fateShards)
	playerIns:SetOneData(dataKey.rebirthTree, rebirthTree)
	playerIns:SetOneData(dataKey.runData, runData)
	playerIns:SetOneData(dataKey.autoFlipUnlocked, scenario.autoFlipUnlocked == true)

	local state = {
		scenario = scenarioName,
		forcedOutcome = scenario.forcedOutcome,
		startedAt = os.clock(),
		startingFlips = playerIns:GetOneData(dataKey.lifetimeFlips),
	}
	self.players[player.UserId] = state
	local coinFlipState = SystemMgr.systems.CoinFlipSystem.players[player.UserId]
	if coinFlipState then
		coinFlipState.nextFlipAt = 0
	end
	SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
	SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
	SystemMgr.systems.TableSeatSystem:RegisterActivity(SENDER, player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player)

	if scenarioName == "longSession" then
		task.defer(function()
			if player:IsDescendantOf(Players) and self.players[player.UserId] == state then
				self:SendLongSessionSample(SENDER, player)
			end
		end)
		state.longSessionScheduleId = ScheduleModule.AddSchedule(300, function()
			if not player:IsDescendantOf(Players) or self.players[player.UserId] ~= state then
				return
			end
			self:SendLongSessionSample(SENDER, player)
			if os.clock() - state.startedAt >= 1800 then
				cancelPlayerSchedules(state)
				state.longSessionScheduleId = nil
				state.autoFlipScheduleId = nil
			end
		end)
		state.autoFlipScheduleId = ScheduleModule.AddSchedule(1.1, function()
			if not player:IsDescendantOf(Players) or self.players[player.UserId] ~= state then
				return
			end
			SystemMgr.systems.CoinFlipSystem:RequestFlip(SENDER, player, {
				inputSource = "studioLongSession",
				inputType = "StudioQA",
			})
		end)
	end

	self.Client:ScenarioApplied(player, {
		scenario = scenarioName,
		status = scenario.forcedOutcome and "Ready - next Flip is forced" or "Ready",
		qaAction = scenario.qaAction,
	})
end

function TestSystem:SendLongSessionSample(sender, player)
	if not IsServer or sender ~= SENDER then
		return
	end
	local state = self.players[player.UserId]
	if not state or state.scenario ~= "longSession" then
		return
	end
	local playerIns = PlayerServerClass.GetIns(player, false)
	if not playerIns then
		return
	end
	local currentFlips = playerIns:GetOneData(dataKey.lifetimeFlips)
	local elapsed = os.clock() - state.startedAt
	local sampleElapsed = math.min(math.floor(elapsed / 300 + 0.5) * 300, 1800)
	self.Client:LongSessionSample(player, {
		elapsed = sampleElapsed,
		flips = currentFlips - state.startingFlips,
		cash = playerIns:GetOneData(dataKey.wins),
		seatId = SystemMgr.systems.TableSeatSystem:GetPlayerSeatId(player),
		luaMemoryKb = gcinfo(),
		playerGuiDescendants = countPlayerDescendants(player),
	})
end

function TestSystem:ConsumeForcedOutcome(sender, player, args)
	if not IsServer or not RunService:IsStudio() or sender ~= SENDER then
		return nil
	end
	local state = self.players[player.UserId]
	if not state or not state.forcedOutcome then
		return nil
	end
	local forcedOutcome = state.forcedOutcome
	state.forcedOutcome = nil
	return Presets.BuildForcedOutcome(forcedOutcome, args.runData, args.bonusStats)
end

function TestSystem:ScenarioApplied(sender, player, args)
	if IsServer then
		return
	end
	TestUi.Init()
	TestUi.ScenarioApplied(args)
end

function TestSystem:LongSessionSample(sender, player, args)
	if IsServer then
		return
	end
	TestUi.Init()
	TestUi.LongSessionSample(args)
end

return TestSystem
