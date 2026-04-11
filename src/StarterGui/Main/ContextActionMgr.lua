--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: This module is responsible for managing the ContextActionService and its bindings.
--Last Modified: 2024-03-16 4:50:33
--]]

---- services ----
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

---- requires ----
local uiController = require(script.Parent:WaitForChild("uiController"))

---- variables ----
local TouchEnabled = UserInputService.TouchEnabled
local GamepadEnabled = UserInputService.GamepadEnabled

local frameBindings = {}

local ContextActionMgr = {}

function ContextActionMgr.AddFrameBinding(
	args: { btn: GuiObject, frame: Frame, keys: { Enum.KeyCode }, actionKey: string }
)
	local btn = args.btn
	local frame: Frame = args.frame or btn.Parent
	local keys = args.keys
	local actionKey = args.actionKey or frame.Name .. btn.Name
	local fun = uiController.GetButtonRecall(btn)
	if not fun then
		warn("No function found for button: " .. frame.Name .. "." .. btn.Name)
		return
	end

	-- print("Adding frame binding: "..frame.Name..","..btn.Name, args)
	if btn:FindFirstChild("gamepadKeyImg") and GamepadEnabled then
		local gamepadKeyImg = btn.gamepadKeyImg
		gamepadKeyImg.Visible = true
		gamepadKeyImg.Image = UserInputService:GetImageForKeyCode(keys[1])
	end

	if not frameBindings[frame] then
		frameBindings[frame] = {}
	end
	frameBindings[frame][actionKey] = args

	if frame:IsA("ScreenGui") then
		if frame.Enabled then
			ContextActionService:BindAction(actionKey, function(actionName, inputState, inputObject)
				if inputState ~= Enum.UserInputState.Begin then
					return
				end
				fun(actionName, inputState, inputObject)
			end, false, unpack(keys))
		end

		frame:GetPropertyChangedSignal("Enabled"):Connect(function()
			if frame.Enabled then
				for _actionKey, _args in pairs(frameBindings[frame]) do
					local _fun = uiController.GetButtonRecall(_args.btn)
					ContextActionService:BindAction(_actionKey, function(actionName, inputState, inputObject)
						if inputState ~= Enum.UserInputState.Begin then
							return
						end
						_fun(actionName, inputState, inputObject)
					end, false, unpack(_args.keys))
				end
			else
				for _actionKey, _args in pairs(frameBindings[frame]) do
					ContextActionService:UnbindAction(_actionKey)
				end
			end
		end)
	else
		if frame.Visible then
			ContextActionService:BindAction(actionKey, function(actionName, inputState, inputObject)
				if inputState ~= Enum.UserInputState.Begin then
					return
				end
				fun(actionName, inputState, inputObject)
			end, false, unpack(keys))
		end

		frame:GetPropertyChangedSignal("Visible"):Connect(function()
			if frame.Visible then
				for _actionKey, _args in pairs(frameBindings[frame]) do
					local _fun = uiController.GetButtonRecall(_args.btn)
					ContextActionService:BindAction(_actionKey, function(actionName, inputState, inputObject)
						if inputState ~= Enum.UserInputState.Begin then
							return
						end
						_fun(actionName, inputState, inputObject)
					end, false, unpack(_args.keys))
				end
			else
				for _actionKey, _args in pairs(frameBindings[frame]) do
					ContextActionService:UnbindAction(_actionKey)
				end
			end
		end)
	end
end

return ContextActionMgr
