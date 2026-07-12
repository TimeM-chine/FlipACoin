local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")

local Icon = require(Replicated.Packages.topbarplus)
local Presets = require(script.Parent.Presets)

local SystemMgr = require(Replicated.Systems.SystemMgr)
local LocalPlayer = Players.LocalPlayer
local Main = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local uiController = require(Main:WaitForChild("uiController"))

local TestUi = {}
local initialized = false
local panel
local statusLabel
local currentScenarioLabel
local sampleHistoryLabel
local qaOverlayState
local runtimeErrorCount = 0
local longSessionSamples = {}

local function applyScenario(scenario)
	statusLabel.Text = "Applying..."
	SystemMgr.systems.TestSystem.Server:ApplyScenario({ scenario = scenario })
end

local function countVisibleDescendants(root)
	local count = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") and descendant.Visible then
			count += 1
		end
	end
	return count
end

local function countInputContexts(root)
	local count = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("InputContext") then
			count += 1
		end
	end
	return count
end

local function setQaOverlayIsolation(isOpen)
	local playerGui = LocalPlayer.PlayerGui
	local tutor = Main.Frames:FindFirstChild("Tutor")
	local guidePrompt = Main.Elements.CoinFlipHUD.Content.CenterPanel:FindFirstChild("GuidePrompt")
	local notifications = playerGui:FindFirstChild("Notifications")
	if isOpen then
		qaOverlayState = {
			tutorVisible = tutor and tutor.Visible,
			guidePromptVisible = guidePrompt and guidePrompt.Visible,
			notificationsEnabled = notifications and notifications.Enabled,
		}
		if tutor then
			tutor.Visible = false
		end
		if notifications then
			notifications.Enabled = false
		end
		if guidePrompt then
			guidePrompt.Visible = false
		end
	elseif qaOverlayState then
		if tutor then
			tutor.Visible = qaOverlayState.tutorVisible == true
		end
		if notifications then
			notifications.Enabled = qaOverlayState.notificationsEnabled == true
		end
		if guidePrompt then
			guidePrompt.Visible = qaOverlayState.guidePromptVisible == true
		end
		qaOverlayState = nil
	end
end

local function runNotificationPriorityScenario()
	local announcementSystem = SystemMgr.systems.AnnouncementSystem
	announcementSystem:PlayAnnouncement(nil, nil, {
		kind = "streakMilestone",
		streak = 5,
		text = "QA normal streak",
		textColor = Color3.fromRGB(255, 224, 158),
		duration = 1.2,
	})
	task.delay(0.15, function()
		announcementSystem:PlayAnnouncement(nil, nil, {
			kind = "comboMilestone",
			comboTier = 5,
			text = "QA high priority highlight",
			textColor = Color3.fromRGB(255, 242, 168),
			duration = 2.4,
		})
	end)
end

function TestUi.Init()
	if initialized or not RunService:IsStudio() then
		return
	end
	panel = Frames:WaitForChild("StudioQA")
	if not panel then
		warn("[TestSystem] Frames.StudioQA is missing; Studio QA panel binding skipped")
		return
	end
	initialized = true
	statusLabel = panel.Header:WaitForChild("Status")
	currentScenarioLabel = panel.Body:WaitForChild("CurrentScenario")
	sampleHistoryLabel = panel.Body:WaitForChild("SampleHistory")
	panel.Visible = false
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		setQaOverlayIsolation(panel.Visible)
	end)
	ScriptContext.Error:Connect(function()
		runtimeErrorCount += 1
	end)

	local scenarioButtons = panel.Body.Scenarios
	for _, scenario in ipairs(Presets.ScenarioOrder) do
		local button = scenarioButtons:WaitForChild(scenario)
		uiController.SetButtonHoverAndClick(button, function()
			applyScenario(scenario)
		end)
	end
	uiController.SetButtonHoverAndClick(panel.X, function()
		uiController.CloseFrame("StudioQA")
	end)
	uiController.SetButtonHoverAndClick(panel.Body.Reset, function()
		applyScenario("freshRun")
	end)

	local qaIcon = Icon.new()
		:align("Right")
		:setName("StudioQA")
		:setLabel("QA")
		:setOrder(100)
		:setCaption("Studio QA")
		:autoDeselect(false)
	qaIcon.toggled:Connect(function(isSelected)
		if isSelected then
			uiController.OpenFrame("StudioQA")
		else
			uiController.CloseFrame("StudioQA")
		end
	end)
end

function TestUi.ScenarioApplied(args)
	if not initialized or not currentScenarioLabel or not statusLabel then
		return
	end
	if args.scenario then
		currentScenarioLabel.Text = `Scenario: {args.scenario}`
	end
	statusLabel.Text = args.status or "Ready"
	if args.qaAction == "notificationPriority" then
		uiController.CloseFrame("StudioQA")
		runNotificationPriorityScenario()
	end
end

function TestUi.LongSessionSample(args)
	if not initialized or not statusLabel then
		return
	end
	local activeNotifications = uiController.GetQaNotificationCount()
	local inputContexts = countInputContexts(Main)
	local sample = {
		elapsed = args.elapsed,
		flips = args.flips,
		cash = args.cash,
		seatId = args.seatId or "none",
		luaMemoryKb = args.luaMemoryKb,
		playerGuiDescendants = args.playerGuiDescendants,
		coinVisuals = SystemMgr.systems.EffectSystem:GetQaActiveCoinCount(),
		activeNotifications = activeNotifications,
		inputContexts = inputContexts,
		runtimeErrors = runtimeErrorCount,
		unparentedInstances = "scene-analysis",
	}
	table.insert(longSessionSamples, sample)
	while #longSessionSamples > 7 do
		table.remove(longSessionSamples, 1)
	end

	local lines = {}
	for _, entry in ipairs(longSessionSamples) do
		table.insert(
			lines,
			`{math.floor(entry.elapsed / 60)}m F{entry.flips} ${entry.cash} M{entry.luaMemoryKb} UI{entry.playerGuiDescendants} C{entry.coinVisuals} N{entry.activeNotifications} I{entry.inputContexts} E{entry.runtimeErrors}`
		)
	end
	sampleHistoryLabel.Text = table.concat(lines, "\n")
	statusLabel.Text = `{math.floor(args.elapsed / 60)}m | {args.flips} flips | {args.luaMemoryKb} KB | {activeNotifications} notify | {inputContexts} contexts`
	print(`[TestSystem][LongSession] {HttpService:JSONEncode(longSessionSamples)}`)
end

return TestUi
