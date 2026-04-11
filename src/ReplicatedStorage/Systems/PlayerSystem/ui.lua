---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local Util = require(Replicated.modules.Util)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ClientData = require(Replicated.Systems.ClientData)
local PlayerPresets = require(script.Parent.Presets)
local DoorPresets = require(Replicated.Systems.DoorSystem.Presets)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local Elements = Main:WaitForChild("Elements")
local ExpBar = Elements:WaitForChild("ExpBar")
local bar = ExpBar:WaitForChild("Bar")
local levelFrame = ExpBar:WaitForChild("Level")
local levelText = levelFrame:WaitForChild("level")
local expText = levelFrame:WaitForChild("exp")

local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local PlayerUi = {}

-- 经验条适配配置
local EXP_BAR_CONFIG = {
	baseWidth = 0.5, -- 基础宽度 (Scale)
	baseHeight = 24, -- 基础高度 (像素)
	minHeight = 5, -- 最小高度 (像素)
	maxHeight = 36, -- 最大高度 (像素)
	mobileWidthScale = 0.5, -- 移动端宽度比例
	pcPositionY = 0.88, -- PC端 Y 位置（更靠近底部）
	mobilePositionY = 0.78, -- 移动端 Y 位置
}

-- 根据屏幕尺寸调整经验条
local function AdaptExpBar()
	local camera = workspace.CurrentCamera

	local viewportSize = camera.ViewportSize
	local screenWidth = viewportSize.X
	local screenHeight = viewportSize.Y
	local aspectRatio = screenWidth / screenHeight

	-- 判断是否为移动端（基于宽高比和屏幕尺寸）
	local isMobile = aspectRatio < 1.5 or screenWidth < 1200

	-- 计算合适的宽度
	local widthScale = isMobile and EXP_BAR_CONFIG.mobileWidthScale or EXP_BAR_CONFIG.baseWidth

	-- 计算合适的高度（使用像素保持一致性）
	-- 根据屏幕高度调整，但限制在合理范围内
	local heightPixels = math.clamp(screenHeight * 0.025, EXP_BAR_CONFIG.minHeight, EXP_BAR_CONFIG.maxHeight)

	-- 计算 Y 位置：PC端更低，移动端保持原位
	local positionY = isMobile and EXP_BAR_CONFIG.mobilePositionY or EXP_BAR_CONFIG.pcPositionY

	-- 应用尺寸和位置
	ExpBar.Size = UDim2.new(widthScale, 0, 0, heightPixels)
	ExpBar.Position = UDim2.new(0.5, 0, positionY, 0)
end

function PlayerUi.Init()
	AdaptExpBar()
	PlayerUi.AddExp()
	-- 监听屏幕尺寸变化（如窗口大小调整、设备旋转）
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(AdaptExpBar)
end

function PlayerUi.AddExp()
	local exp = ClientData:GetOneData(dataKey.exp)
	local level = ClientData:GetOneData(dataKey.level)
	levelText.Text = `Lv.{level}`

	local levelUpExp = PlayerPresets.Levels[level].levelUpExp
	expText.Text = `({exp}/{levelUpExp})`
	bar.Size = UDim2.fromScale(math.clamp(exp / levelUpExp, 0, 1), 1)
end

return PlayerUi
