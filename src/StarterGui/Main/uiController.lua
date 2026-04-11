--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: 1.1.2 -- add got modal
--Version: 1.4.2 updated SetOneLineTip
--Last Modified: 2025-09-25 5:23:15
--]]

local Debris = game:GetService("Debris")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local GamepadEnabled = UserInputService.GamepadEnabled

---- requires ----
local Textures = require(Replicated.configs.Textures)
local Util = require(Replicated.modules.Util)
local ScheduleModule = require(Replicated.modules.ScheduleModule)

---- variables ----
local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = script.Parent.Parent
local Notifications = PlayerGui:WaitForChild("Notifications")
local Box = Notifications:WaitForChild("Box")
local hideUnitWhenPush = {}
local notifyOder = 0
local connections = {}
local btnRecalls = {}
local coolDown = false
local coolDownTime = 0.2
local guideButton = nil
local guideFrame = nil

local Main = PlayerGui:WaitForChild("Main")
local Frames = Main:WaitForChild("Frames")
local MaskFrame = Frames:WaitForChild("Mask")
local Elements = Main:WaitForChild("Elements")
local ripple = Elements:WaitForChild("ripple")
local frameCache, modalFrame

local rippleTween = TweenService:Create(ripple, TweenInfo.new(0.7), { Size = UDim2.new(0, 0, 0, 0) })
rippleTween:Play()
rippleTween.Completed:Connect(function()
	task.wait(0.3)
	ripple.Size = UDim2.fromScale(1, 1)
	rippleTween:Play()
end)

---- main ----
local controller = {}

local NotificationStorage = {}

local function refreshNotificationLifetime(entry, duration)
	entry.token = (entry.token or 0) + 1
	local token = entry.token
	task.delay(duration, function()
		if entry.token ~= token then
			return
		end
		if entry.unit and entry.unit.Parent then
			entry.unit:Destroy()
		end
	end)
end

function controller.SetNotification(args: { text: string, soundName: string, lastTime: number, textColor: Color3 })
	local text = args.text
	local soundName = args.soundName
	local duration = args.lastTime or 3
	local textColor = args.textColor or Color3.new(1, 1, 1)
	local template = Notifications:FindFirstChild("Templates"):FindFirstChild("Template")
	local entry = NotificationStorage[text]
	if entry then
		local unit = entry.unit
		local count = entry.count
		local newCount = count + 1
		entry.count = newCount
		unit.Text = `{text} (x {newCount})`
		refreshNotificationLifetime(entry, duration)
		return
	end
	Util.Clone(template, Box, function(unit)
		unit.Text = text
		unit.Visible = true
		unit.TextColor3 = textColor
		controller.ScaleUnit(unit, 1.2)
		local newEntry = {
			unit = unit,
			token = 0,
			count = 1,
		}
		NotificationStorage[text] = newEntry
		unit.Destroying:Once(function()
			NotificationStorage[text] = nil
		end)
		refreshNotificationLifetime(newEntry, duration)

		if soundName and SoundService:FindFirstChild(soundName, true) then
			SoundService:FindFirstChild(soundName, true):Play()
		end
	end)
end

function controller.OpenFrame(name)
	local frame: Frame = Frames:FindFirstChild(name)
	if not frame then
		warn(`There is no frame {name}`)
		return
	end

	if frameCache then
		if frameCache == frame then
			return
		end
		frameCache.Visible = false
	end
	frameCache = frame
	frame.Visible = true
	controller.SetUnitJump(frame)

	CAS:BindActionAtPriority("GAMEPAD_CLOSE_FRAME", function(_, state, input)
		-- print("GAMEPAD_CLOSE_FRAME", state, input.KeyCode)
		if state == Enum.UserInputState.Begin then
			if frameCache then
				controller.CloseFrame(frameCache.Name)
			end
		end
	end, false, 2, Enum.KeyCode.ButtonB)

	for _, unit in hideUnitWhenPush do
		unit.Visible = false
	end

	if GamepadEnabled then
		local btns = frame:GetDescendants()
		for _, btn in pairs(btns) do
			if not btn:IsA("GuiButton") then
				continue
			end
			if btn.Name == "X" then
				continue
			end
			GuiService.SelectedObject = btn
			break
		end
	end
	return frame
end

function controller.CloseFrame(name)
	local frame
	if name then
		frame = Frames:FindFirstChild(name)
	end
	if frame then
		frame.Visible = false
		frameCache = nil
	elseif frameCache then
		frameCache.Visible = false
		frameCache = nil
	end

	for _, unit in hideUnitWhenPush do
		unit.Visible = true
	end

	if GamepadEnabled then
		GuiService.SelectedObject = nil
	end

	CAS:UnbindAction("GAMEPAD_CLOSE_FRAME")
end

function controller.OpenModal(args)
	local title = args.title
	local content = args.content
	local confirmRecall = args.confirmRecall
	local cancelRecall = args.cancelRecall

	if not modalFrame then
		modalFrame = Elements:WaitForChild("Modal")
	end
	local cons = {}
	modalFrame.Visible = true
	controller.SetUnitJump(modalFrame)
	modalFrame.content.Text = content
	modalFrame.title.Text = title

	local confirm: TextButton = modalFrame.confirm
	local cancel: TextButton = modalFrame.cancel
	local confirmCon = confirm.MouseButton1Click:Connect(function()
		if confirmRecall then
			confirmRecall()
		end
		modalFrame.Visible = false
		for _, c in cons do
			c:Disconnect()
		end
	end)
	table.insert(cons, confirmCon)
	local cancelCon = cancel.MouseButton1Click:Connect(function()
		if cancelRecall then
			cancelRecall()
		end
		modalFrame.Visible = false
		for _, c in cons do
			c:Disconnect()
		end
	end)

	table.insert(cons, cancelCon)
end

function controller.SetUIBlink(element, endSignal: RBXScriptSignal)
	local blinkFrame = StarterGui.units.blink.blink:Clone()
	blinkFrame.Parent = element
	local stroke = blinkFrame.UIStroke

	if element:FindFirstChildOfClass("UICorner") then
		element.UICorner:Clone().Parent = blinkFrame
	end

	local ti = TweenInfo.new(1)
	local tween1 = TweenService:Create(stroke, ti, { Transparency = 1 })
	local tween0 = TweenService:Create(stroke, ti, { Transparency = 0 })
	tween0:Play()
	tween1.Completed:Connect(function()
		tween0:Play()
	end)
	tween0.Completed:Connect(function()
		tween1:Play()
	end)
	endSignal = endSignal or element.InputEnded
	endSignal:Once(function()
		tween1:Destroy()
		tween0:Destroy()
		blinkFrame:Destroy()
	end)
	-- Debris:AddItem(blinkFrame, 5)
	return blinkFrame
end

local function RemoveButtonConn(btn)
	for _, conn in pairs(connections[btn]) do
		conn:Disconnect()
		conn = nil
	end
	btnRecalls[btn] = nil
end

function controller.SetGuideButton(btn, frame)
	frame = frame or btn
	if btn then
		if guideFrame and guideFrame ~= frame then
			controller.SetGuideButton(nil)
		end

		Main.ScreenInsets = Enum.ScreenInsets.None
		MaskFrame.BackgroundTransparency = 0.5
		MaskFrame.Visible = true
		ripple.Visible = true
		ripple.Parent = btn

		frame:SetAttribute("OriginalZIndex", frame.ZIndex)
		frame.ZIndex += MaskFrame.ZIndex
		for _, des in frame:GetDescendants() do
			if des:IsA("GuiObject") then
				des:SetAttribute("OriginalZIndex", des.ZIndex)
				des.ZIndex += MaskFrame.ZIndex
			end
		end
	else
		if guideButton then
			Main.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
			MaskFrame.Visible = false
			ripple.Visible = false
			ripple.Parent = Elements
			for _, des in guideFrame:GetDescendants() do
				if des:IsA("GuiObject") then
					local orig = des:GetAttribute("OriginalZIndex")
					if orig then
						des.ZIndex = orig
					end
				end
			end
			local orig = guideFrame:GetAttribute("OriginalZIndex")
			if orig then
				guideFrame.ZIndex = orig
			end
		end
	end
	guideButton = btn
	guideFrame = frame
end

function controller.SetButtonHoverAndClick(btn, fun, playSound)
	if connections[btn] then
		RemoveButtonConn(btn)
	end
	local conns = {}
	btnRecalls[btn] = fun
	local scale = 1
	-- if btn:FindFirstChild("UIScale") then
	--     scale = btn.UIScale.Scale
	-- end
	local rotate = 0
	local RotateIcon = btn:FindFirstChild("RotateIcon", true)
	if RotateIcon then
		rotate = RotateIcon.Rotation
	end
	conns.MouseEnter = btn.MouseEnter:Connect(function()
		controller.ScaleUnit(btn, scale + 0.15)
		SoundService.SFX.hoverBtn:Play()
		if RotateIcon then
			controller.RotateUnit(RotateIcon, rotate + math.random(-20, 20))
		end
	end)

	conns.MouseLeave = btn.MouseLeave:Connect(function()
		controller.ScaleUnit(btn, scale)
		if RotateIcon then
			controller.RotateUnit(RotateIcon, rotate)
		end
	end)
	local desBtn
	if not btn:IsA("GuiButton") then
		desBtn = btn:FindFirstChildWhichIsA("GuiButton")
		if not desBtn then
			desBtn = Instance.new("TextButton")
			desBtn.Name = "clickBtn"
			desBtn.AutoButtonColor = false
			desBtn.Size = UDim2.fromScale(1, 1)
			desBtn.BackgroundTransparency = 1
			desBtn.ZIndex = btn.ZIndex + 1
			desBtn.Text = ""
			if btn:FindFirstChild("UIListLayout") or btn:FindFirstChild("UIGridLayout") then
				local ignoreFolder = Instance.new("Folder")
				ignoreFolder.Name = "ignoreFolder"
				ignoreFolder.Parent = btn
				desBtn.Parent = ignoreFolder
			else
				desBtn.Parent = btn
			end
		end
	else
		desBtn = btn
	end

	if desBtn then
		conns.MouseButton1Down = desBtn.MouseButton1Down:Connect(function()
			-- HapticService:SetMotor("Gamepad1", Enum.VibrationMotor.Large, 0.5)
			-- task.delay(0.025, function()
			-- 	return HapticService:SetMotor("Gamepad1", Enum.VibrationMotor.Large, 0)
			-- end)
			controller.ScaleUnit(desBtn, scale - 0.075)
		end)

		conns.MouseButton1Up = desBtn.MouseButton1Up:Connect(function()
			controller.ScaleUnit(desBtn, scale)
		end)

		conns.MouseButton1Click = desBtn.MouseButton1Click:Connect(function()
			if coolDown == false then
				if guideButton and btn:IsDescendantOf(Main) then
					local allowedByGuideButton =
						guideButton == btn or guideButton:IsDescendantOf(btn)
					local allowedByGuideFrame = guideFrame and (btn == guideFrame or btn:IsDescendantOf(guideFrame))
					if not (allowedByGuideButton or allowedByGuideFrame) then
						return
					end
				end
				coolDown = true
				if fun then
					fun()
					if playSound ~= false then
						SoundService.SFX.clickBtn:Play()
					end
					if btn:FindFirstChild("redDot") then
						btn.redDot.Visible = false
					end
				else
					print("No function", btn.Name)
				end
				task.wait(coolDownTime)
				coolDown = false
			end
		end)

		conns.ListenRemoved = btn.AncestryChanged:Connect(function()
			if not btn.Parent then
				RemoveButtonConn(btn)
			end
		end)
	end

	connections[btn] = conns
	return conns
end

function controller.GetButtonRecall(btn)
	return btnRecalls[btn]
end

function controller.SetUnitJump(unit, delta)
	delta = delta or 0.15
	local scale = 1
	controller.ScaleUnit(unit, scale + delta)
	local RotateIcon = unit:FindFirstChild("RotateIcon")
	if RotateIcon then
		controller.RotateUnit(RotateIcon, math.random(-20, 20))
	end
	task.delay(0.2, function()
		controller.ScaleUnit(unit, scale)
		if RotateIcon then
			controller.RotateUnit(RotateIcon, 0)
		end
	end)
end

function controller.SetFallingNumber(value, frame)
	local fallingNumber: TextLabel = PlayerGui.Templates.fallingNumber:Clone()
	if value >= 0 then
		fallingNumber.Text = "+" .. Util.FormatNumber(value)
	else
		fallingNumber.Text = "-" .. value
		fallingNumber.UIGradient.Color = PlayerGui.Gradients.Red.Color
	end
	fallingNumber.Visible = true
	fallingNumber.Parent = frame

	local targetPos = UDim2.new(0.5, math.random(-20, 20), 0.5, math.random(50, 80))
	controller.RotateUnit(fallingNumber, math.random(-30, 30))
	fallingNumber:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
	Debris:AddItem(fallingNumber, 0.5)
end

function controller.ScaleUnit(unit, scale)
	local UIScale = unit:FindFirstChild("UIScale")
	if not UIScale then
		UIScale = Instance.new("UIScale")
		UIScale.Parent = unit
	end
	local tween = TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Scale = scale,
	})
	tween:Play()
	return tween
end

function controller.RotateUnit(unit, rotate)
	local ti = TweenInfo.new(0.2)
	local tween = TweenService:Create(unit, ti, { Rotation = rotate })
	tween:Play()
end

local Connections = {}
function controller.PetViewport(pet, viewportFrame, CFrameOffset)
	CFrameOffset = CFrameOffset or CFrame.new(0, 0, 0)
	-- local orientation, petSize = petModel:GetBoundingBox()
	if Connections[viewportFrame] then
		for _, conn in pairs(Connections[viewportFrame]) do
			Connections[viewportFrame][_]:Disconnect()
			conn = nil
		end
	end

	local conns = {}

	if viewportFrame:FindFirstChild("Camera") then
		viewportFrame:FindFirstChild("Camera"):Destroy()
	end
	if viewportFrame:FindFirstChild("WorldModel") then
		viewportFrame:FindFirstChild("WorldModel"):Destroy()
	end
	local orientation, petSize, posPart
	if pet:IsA("Model") then
		orientation, petSize = pet:GetBoundingBox()
		pet.Parent = viewportFrame
		posPart = pet.PrimaryPart
		for _, part in pairs(pet:GetChildren()) do
			if part:IsA("BasePart") then
				if part == posPart then
					continue
				end
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = posPart
				weld.Parent = part
			end
		end
	else
		local tempModel = Instance.new("Model")
		pet.Parent = tempModel
		tempModel.PrimaryPart = pet
		petSize = tempModel:GetExtentsSize()
		pet.Parent = viewportFrame
		tempModel:Destroy()
		posPart = pet

		for _, part in pairs(pet:GetChildren()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = posPart
				weld.Parent = part
			end
		end
	end

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	local maxDim = math.max(petSize.X, petSize.Y, petSize.Z)
	camera.CFrame = CFrame.new(
		posPart.Position + posPart.CFrame.LookVector * (maxDim / (2 * math.tan(math.rad(35))) + 2),
		posPart.Position
	)
	-- camera.Focus = CFrame.new(posPart.Position)
	viewportFrame.CurrentCamera = camera
	local WorldModel = Instance.new("WorldModel")
	WorldModel.Parent = viewportFrame
	pet.Parent = WorldModel
	-- if pet:IsA("Model") then
	-- 	pet:PivotTo(CFrame.new(posPart.CFrame.Position) * CFrameOffset)
	-- else
	-- 	pet.CFrame = CFrame.new(posPart.CFrame.Position) * CFrameOffset
	-- end
	local u17 = false

	if pet:IsA("Model") then
		pet:PivotTo(pet:GetPivot() * CFrameOffset)
	else
		pet.CFrame = pet.CFrame * CFrameOffset
	end

	posPart:SetAttribute("OriginalCFrame", posPart.CFrame)

	conns.MouseEnter = viewportFrame.MouseEnter:Connect(function()
		if conns.rotate then
			return
		end

		conns.rotate = RunService.RenderStepped:Connect(function()
			if pet:IsA("Model") then
				pet:PivotTo(pet:GetPivot() * CFrame.Angles(0, 0.05, 0))
			else
				pet.CFrame = pet.CFrame * CFrame.Angles(0, 0.05, 0)
			end
		end)
		-- if u17 then
		-- 	return nil
		-- end
		-- u17 = true
		-- task.delay(0.5, function()
		-- 	u17 = false
		-- 	return u17
		-- end)
		-- TweenService:Create(camera, TweenInfo.new(0.5), {
		-- 	FieldOfView = 60,
		-- }):Play()
		-- TweenService:Create(posPart, TweenInfo.new(0.5), {
		-- 	CFrame = posPart:GetAttribute("OriginalCFrame") * CFrame.Angles(0, math.rad(-45), 0),
		-- }):Play()
	end)

	local u18 = false

	conns.MouseLeave = viewportFrame.MouseLeave:Connect(function()
		if conns.rotate then
			conns.rotate:Disconnect()
			conns.rotate = nil
		end
		-- if u18 then
		-- 	return nil
		-- end
		-- u18 = true
		-- task.delay(0.5, function()
		-- 	u18 = false
		-- 	return u18
		-- end)
		-- TweenService:Create(camera, TweenInfo.new(0.5), {
		-- 	FieldOfView = 70,
		-- }):Play()
		-- TweenService:Create(posPart, TweenInfo.new(0.5), {
		-- 	CFrame = posPart:GetAttribute("OriginalCFrame"),
		-- }):Play()
	end)

	-- u13[viewportFrame] = pet

	Connections[viewportFrame] = conns
end

function controller.HideUnitWhenPush(unit)
	table.insert(hideUnitWhenPush, unit)
end

function controller.RippleMouse()
	local assets = Elements.ripple:Clone()
	assets.Visible = true

	local mouse = LocalPlayer:GetMouse()
	local viewport = workspace.CurrentCamera.ViewportSize

	assets.Position = UDim2.fromScale(mouse.X / viewport.X, (mouse.Y + 36) / viewport.Y)
	local tween = TweenService:Create(assets, TweenInfo.new(0.2), {
		Size = UDim2.fromScale(0, 0),
		ImageTransparency = 1,
	})

	tween:Play()
	tween.Completed:Connect(function()
		assets:Destroy()
	end)

	assets.Parent = Main
end

function controller.ClearScrollChildren(scroll)
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("GuiObject") then
			continue
		end

		if child.Name == "Template" then
			if child:GetAttribute("isClone") then
				child:Destroy()
			end
			continue
		end

		child:Destroy()
	end
end

local TipConnections = {}
function controller.SetHoverFrame(
	frame,
	args: { frameName: string, title: string, rarity: string, infoList: { string } }
)
	local frameName = args.frameName or "ItemInfoHoverTip"
	local ToolTips = PlayerGui.ToolTips

	local title = args.title
	local rarity = args.rarity
	local infoList = args.infoList

	local tipFrame = ToolTips:FindFirstChild(frameName)
	if TipConnections[frame] then
		for _, conn in pairs(TipConnections[frame]) do
			TipConnections[frame][_]:Disconnect()
			conn = nil
		end

		if tipFrame.Visible then
			tipFrame.Visible = false
		end
	end

	local conns = {}
	conns.MouseEnter = frame.MouseEnter:Connect(function()
		-- name
		tipFrame:WaitForChild("NameList"):WaitForChild("Title").Text = title

		-- rarity
		local Rarity = tipFrame:WaitForChild("NameList"):WaitForChild("Rarity")
		if rarity then
			Rarity.Text = rarity
			-- Rarity.UIGradient.Color =
			Rarity.Visible = true
		else
			Rarity.Visible = false
		end

		local InfoList = tipFrame:WaitForChild("InfoList")

		for i, textLabel in ipairs(InfoList:GetChildren()) do
			textLabel.Text = infoList[tonumber(i)] or ""
		end

		tipFrame.Visible = true
		local anchorPoint = Vector2.new(0, 0)

		conns.InputBegan = UserInputService.InputBegan:Connect(function(inputObj)
			if inputObj.UserInputType == Enum.UserInputType.Touch then
				tipFrame.Position = UDim2.fromOffset(inputObj.Position.X, inputObj.Position.Y)
				tipFrame.AnchorPoint = anchorPoint
			end
		end)

		conns.InputChange = UserInputService.InputChanged:Connect(function(inputObj)
			if
				inputObj.UserInputType == Enum.UserInputType.MouseMovement
				or inputObj.UserInputType == Enum.UserInputType.Touch
			then
				tipFrame.Position = UDim2.fromOffset(inputObj.Position.X, inputObj.Position.Y)
				tipFrame.AnchorPoint = anchorPoint
			end
		end)

		conns.MouseLeave = frame.MouseLeave:Connect(function()
			conns.InputBegan:Disconnect()
			conns.InputChange:Disconnect()
			conns.MouseLeave:Disconnect()
			tipFrame.Visible = false
		end)
	end)

	TipConnections[frame] = conns
end

function controller.SetOneLineTip(frame, args)
	local tipFrame = args.frameName or "OneLineTip"
	local ToolTips = PlayerGui.ToolTips

	local text = args.text

	tipFrame = ToolTips:FindFirstChild(tipFrame):Clone()
	tipFrame:WaitForChild("TextLabel").Text = text
	tipFrame.Parent = ToolTips

	if TipConnections[frame] then
		for _, conn in pairs(TipConnections[frame]) do
			TipConnections[frame][_]:Disconnect()
			conn = nil
		end

		if tipFrame.Visible then
			tipFrame.Visible = false
		end
	end

	local conns = {}
	conns.MouseEnter = frame.MouseEnter:Connect(function()
		tipFrame.Visible = true
		tipFrame:WaitForChild("UIScale").Scale = 0
		tipFrame.Visible = true
		tipFrame.AnchorPoint = Vector2.new(0, 0)
		TweenService:Create(tipFrame.UIScale, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()

		conns.InputChange = UserInputService.InputChanged:Connect(function(inputObj)
			if
				inputObj.UserInputType == Enum.UserInputType.MouseMovement
				or inputObj.UserInputType == Enum.UserInputType.Touch
			then
				-- Get screen size and tip frame size
				local viewport = workspace.CurrentCamera.ViewportSize
				local mouseX = inputObj.Position.X
				local mouseY = inputObj.Position.Y

				-- Wait for the tip frame to load properly
				local textLabel = tipFrame:WaitForChild("TextLabel")

				-- Calculate tip frame size
				local tipWidth = textLabel.TextBounds.X + 20 -- Add padding
				local tipHeight = textLabel.TextBounds.Y + 10 -- Add padding

				-- Calculate desired position with offset
				local offsetX = viewport.X * 0.01 -- 0.01 scale to offset
				local offsetY = -(viewport.Y * 0.03) -- -0.03 scale to offset

				local desiredX = mouseX + offsetX
				local desiredY = mouseY + offsetY

				-- Check boundaries and adjust position
				-- Right edge check
				if desiredX + tipWidth > viewport.X then
					desiredX = mouseX - tipWidth - offsetX -- Position to left of cursor
				end

				-- Left edge check
				if desiredX < 0 then
					desiredX = 5 -- Small margin from left edge
				end

				-- Bottom edge check
				if desiredY + tipHeight > viewport.Y then
					desiredY = mouseY - tipHeight + offsetY -- Position above cursor
				end

				-- Top edge check
				if desiredY < 0 then
					desiredY = 5 -- Small margin from top edge
				end

				tipFrame.Position = UDim2.fromOffset(desiredX, desiredY)
			end
		end)

		conns.MouseLeave = frame.MouseLeave:Connect(function()
			conns.InputChange:Disconnect()
			conns.MouseLeave:Disconnect()
			controller.ScaleUnit(tipFrame, 0).Completed:Wait()
			tipFrame.Visible = false
		end)
	end)

	TipConnections[frame] = conns
	return tipFrame
end

----[[ timer module ]]----
local TimedLabel = {}

local function UpdateFunc(textLabel, counterInfo)
	if typeof(counterInfo.format) == "function" then
		textLabel.Text = counterInfo.format(counterInfo.startTime + counterInfo.duration - os.time())
	elseif counterInfo.format == "clock" then
		textLabel.Text = Util.FormatCountDown(counterInfo.startTime + counterInfo.duration - os.time(), true)
	else
		textLabel.Text = counterInfo.startTime + counterInfo.duration - os.time()
	end
end

ScheduleModule.AddSchedule(1, function()
	for textLabel, counterInfo in pairs(TimedLabel) do
		-- counterInfo = {startTime, duration, finishedText}
		if counterInfo.startTime + counterInfo.duration < os.time() then
			TimedLabel[textLabel] = nil
			if counterInfo.callback then
				counterInfo.callback()
			end
		else
			UpdateFunc(textLabel, counterInfo)
			if counterInfo.duringCallback then
				counterInfo.duringCallback(counterInfo.startTime + counterInfo.duration - os.time())
			end
		end
	end
end)

function controller.AddTimerLabel(args: {
	textLabel: TextLabel,
	startTime: number,
	duration: number,
	callback: any,
	duringCallback: any,
	format: string,
})
	local startTime = args.startTime or os.time()
	local format = args.format or "clock"
	TimedLabel[args.textLabel] = {
		startTime = startTime,
		duration = args.duration,
		callback = args.callback,
		duringCallback = args.duringCallback,
		format = format,
	}
	UpdateFunc(args.textLabel, TimedLabel[args.textLabel])
end

function controller.CancelTimer(args)
	TimedLabel[args.textLabel] = nil
end

function controller.GetTimer(args)
	return TimedLabel[args.textLabel]
end

----[[ rotate gradient ]]----
local rotateGradient = {}
RunService.RenderStepped:Connect(function()
	for _, gradient in ipairs(rotateGradient) do
		gradient.Rotation += 1
		if gradient.Rotation >= 360 then
			gradient.Rotation = 0
		end
	end
end)

function controller.AddRotateGradient(gradient)
	table.insert(rotateGradient, gradient)
	gradient:GetPropertyChangedSignal("Parent"):Connect(function()
		if not gradient.Parent then
			for _, g in ipairs(rotateGradient) do
				if g == gradient then
					table.remove(rotateGradient, _)
					break
				end
			end
		end
	end)
end

----[[ Rewards ]]----
local RewardsFrame = Elements:WaitForChild("Rewards")
local rewardScroll = RewardsFrame:WaitForChild("ScrollingFrame")
local rewardTemplate = rewardScroll:WaitForChild("Template")
rewardTemplate.Visible = false
local slideTi = TweenInfo.new(0.5)
local closeTask = nil

local function CloseReward()
	TweenService:Create(RewardsFrame, slideTi, { Position = UDim2.fromScale(0.5, -0.5) }):Play()
end

local function OpenReward()
	if closeTask then
		task.cancel(closeTask)
	end
	TweenService:Create(RewardsFrame, slideTi, { Position = UDim2.fromScale(0.5, 0.2) }):Play()
	closeTask = task.delay(3, function()
		CloseReward()
	end)
end

function controller.AddReward(args: { icon: string, count: number })
	OpenReward()
	local icon = args.icon
	local count = args.count
	local card = Util.Clone(rewardTemplate, rewardScroll, function(unit)
		if type(icon) == "string" then
			unit.icon.Image = icon
		else
			unit.icon.Visible = false
			unit.view.Visible = true
			controller.PetViewport(icon:Clone(), unit.view)
		end
		unit.Visible = true
		unit.count.Text = "x" .. Util.FormatNumber(count)
	end)

	task.delay(3, function()
		local tween = TweenService:Create(card, slideTi, { Size = UDim2.new(0, 0, 0, 0) })
		tween:Play()
		tween.Completed:Wait()
		card:Destroy()
	end)
end

----[[ Countdown Modal ]]----
local CountdownModal = Frames:WaitForChild("CountdownModal", 5)
if CountdownModal then
	function controller.OpenCountdownModal(args)
		local countdown = args.countdown or 5
		local confirmCallback = function()
			if args.confirmCallback then
				args.confirmCallback()
			end
			controller.CloseFrame("CountdownModal")
			controller.CancelTimer({
				textLabel = CountdownModal.countdown,
			})
		end
		local cancelCallback = function()
			if args.cancelCallback then
				args.cancelCallback()
			end
			controller.CloseFrame("CountdownModal")
			controller.CancelTimer({
				textLabel = CountdownModal.countdown,
			})
		end
		local description = args.description

		if CountdownModal.Visible then
			controller.CancelTimer({
				textLabel = CountdownModal.countdown,
			})
		end

		CountdownModal.description.Text = description
		controller.OpenFrame("CountdownModal")
		controller.AddTimerLabel({
			textLabel = CountdownModal.countdown,
			duration = countdown,
			callback = function()
				if cancelCallback then
					cancelCallback()
				end
			end,
			format = "number",
		})

		controller.SetButtonHoverAndClick(CountdownModal.confirm, function()
			confirmCallback()
		end)
		controller.SetButtonHoverAndClick(CountdownModal.cancel, function()
			cancelCallback()
		end)
	end
end

return controller
