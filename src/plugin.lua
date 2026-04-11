--[[
	Animation Effect Plugin
	A tool for syncing particle effects with animations
	Features: Multi-language support, Effect timing adjustment, Fast Weld
]]

---- Services ----
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

---- Constants ----
local COLORS = {
	background = Color3.fromRGB(30, 30, 35),
	surface = Color3.fromRGB(40, 40, 48),
	surfaceHover = Color3.fromRGB(55, 55, 65),
	surfaceActive = Color3.fromRGB(65, 65, 75),
	primary = Color3.fromRGB(76, 175, 80),
	primaryHover = Color3.fromRGB(96, 195, 100),
	danger = Color3.fromRGB(220, 53, 69),
	dangerHover = Color3.fromRGB(240, 73, 89),
	success = Color3.fromRGB(40, 167, 69),
	text = Color3.fromRGB(240, 240, 245),
	textSecondary = Color3.fromRGB(180, 180, 190),
	textMuted = Color3.fromRGB(120, 120, 130),
	border = Color3.fromRGB(60, 60, 70),
	dropdown = Color3.fromRGB(35, 35, 42),
}

local CORNER_RADIUS = UDim.new(0, 6)
local BUTTON_HEIGHT = 36
local PADDING = 8

---- Plugin Info Text (not localized, kept in English for developers) ----
local PLUGIN_INFO_TEXT = [[
-------- Animation Effect ----------
Aligns particle emitters and animations in the editor for easier pre-game setup.
Add attributes to particles or beams to modify them.

EmitDelay (number):
1. Particles will Emit by its property Rate after 'EmitDelay'.
2. Beams will be enabled after 'EmitDelay'.

EmitDuration (number):
1. If set, particles will be enabled after 'EmitDelay', then disabled after 'EmitDuration', they will not Emit(Rate) anymore.
2. Beams will be disabled after 'EmitDuration'.

-------- Fast Weld ----------
Create WeldConstraints between selected parts.
Select multiple parts and click "Fast Weld" to weld them to the first selected part.
]]

---- Localization ----
local Localization = {
	["en"] = {
		title = "Animation Effect",
		effectOff = "Effect: Off",
		effectOn = "Effect: On",
		effect = "Effect",
		animate = "Animate",
		animateEffect = "Animate+Effect",
		totalDelay = "Total Delay",
		createAttr = "Create Attr",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Language",
		fastWeld = "Fast Weld",
		info = "Info",
		close = "Close",
	},
	["zh-CN"] = {
		title = "动画特效",
		effectOff = "特效: 关",
		effectOn = "特效: 开",
		effect = "特效",
		animate = "动作",
		animateEffect = "动作+特效",
		totalDelay = "总延迟",
		createAttr = "创建属性",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "语言",
		fastWeld = "快速焊接",
		info = "说明",
		close = "关闭",
	},
	["ja"] = {
		title = "アニメーション効果",
		effectOff = "効果: オフ",
		effectOn = "効果: オン",
		effect = "効果",
		animate = "アニメ",
		animateEffect = "アニメ+効果",
		totalDelay = "総遅延",
		createAttr = "属性作成",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "言語",
		fastWeld = "高速溶接",
		info = "情報",
		close = "閉じる",
	},
	["ko"] = {
		title = "애니메이션 효과",
		effectOff = "효과: 끔",
		effectOn = "효과: 켬",
		effect = "효과",
		animate = "애니메이션",
		animateEffect = "애니+효과",
		totalDelay = "총 지연",
		createAttr = "속성 생성",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "언어",
		fastWeld = "빠른 용접",
		info = "정보",
		close = "닫기",
	},
	["es"] = {
		title = "Efecto Animación",
		effectOff = "Efecto: Off",
		effectOn = "Efecto: On",
		effect = "Efecto",
		animate = "Animar",
		animateEffect = "Animar+Efecto",
		totalDelay = "Retraso Total",
		createAttr = "Crear Attr",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Idioma",
		fastWeld = "Soldar Rápido",
		info = "Info",
		close = "Cerrar",
	},
	["pt"] = {
		title = "Efeito Animação",
		effectOff = "Efeito: Off",
		effectOn = "Efeito: On",
		effect = "Efeito",
		animate = "Animar",
		animateEffect = "Animar+Efeito",
		totalDelay = "Atraso Total",
		createAttr = "Criar Attr",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Idioma",
		fastWeld = "Soldar Rápido",
		info = "Info",
		close = "Fechar",
	},
	["de"] = {
		title = "Animation Effekt",
		effectOff = "Effekt: Aus",
		effectOn = "Effekt: An",
		effect = "Effekt",
		animate = "Animieren",
		animateEffect = "Anim+Effekt",
		totalDelay = "Gesamtverzögerung",
		createAttr = "Attr Erstellen",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Sprache",
		fastWeld = "Schnell Schweißen",
		info = "Info",
		close = "Schließen",
	},
	["fr"] = {
		title = "Effet Animation",
		effectOff = "Effet: Off",
		effectOn = "Effet: On",
		effect = "Effet",
		animate = "Animer",
		animateEffect = "Animer+Effet",
		totalDelay = "Délai Total",
		createAttr = "Créer Attr",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Langue",
		fastWeld = "Souder Rapide",
		info = "Info",
		close = "Fermer",
	},
	["ru"] = {
		title = "Эффект Анимации",
		effectOff = "Эффект: Выкл",
		effectOn = "Эффект: Вкл",
		effect = "Эффект",
		animate = "Анимация",
		animateEffect = "Аним+Эффект",
		totalDelay = "Общая Задержка",
		createAttr = "Создать Attr",
		emitDelay = "EmitDelay",
		emitDuration = "EmitDuration",
		language = "Язык",
		fastWeld = "Быстрая Сварка",
		info = "Инфо",
		close = "Закрыть",
	},
}

local LanguageNames = {
	{ code = "en", name = "English" },
	{ code = "zh-CN", name = "中文" },
	{ code = "ja", name = "日本語" },
	{ code = "ko", name = "한국어" },
	{ code = "es", name = "Español" },
	{ code = "pt", name = "Português" },
	{ code = "de", name = "Deutsch" },
	{ code = "fr", name = "Français" },
	{ code = "ru", name = "Русский" },
}

---- State ----
local currentLanguage = "en"
local effectState = false
local isWidgetInitialized = false
local connections = {}
local uiElements = {}
local settingMode = false

---- Helper Functions ----
local function getText(key)
	local lang = Localization[currentLanguage] or Localization["en"]
	return lang[key] or Localization["en"][key] or key
end

local function detectLanguage()
	local savedLang = plugin:GetSetting("language")
	if savedLang and Localization[savedLang] then
		return savedLang
	end

	local success, localeId = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)

	if success and localeId then
		-- Map locale IDs to our language codes
		local localeMap = {
			["en-us"] = "en",
			["en-gb"] = "en",
			["zh-cn"] = "zh-CN",
			["zh-tw"] = "zh-CN",
			["ja-jp"] = "ja",
			["ko-kr"] = "ko",
			["es-es"] = "es",
			["pt-br"] = "pt",
			["de-de"] = "de",
			["fr-fr"] = "fr",
			["ru-ru"] = "ru",
		}
		local lowerLocale = string.lower(localeId)
		if localeMap[lowerLocale] then
			return localeMap[lowerLocale]
		end
		-- Try matching just the language part
		local langPart = string.match(lowerLocale, "^(%a+)")
		for code, _ in pairs(Localization) do
			if string.match(string.lower(code), "^" .. langPart) then
				return code
			end
		end
	end

	return "en"
end

local function saveLanguage(langCode)
	plugin:SetSetting("language", langCode)
end

local function addConnection(conn)
	table.insert(connections, conn)
	return conn
end

local function clearConnections()
	for _, conn in connections do
		if conn and typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	connections = {}
end

---- UI Helper Functions ----
local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or CORNER_RADIUS
	corner.Parent = parent
	return corner
end

local function createPadding(parent, padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, padding or PADDING)
	pad.PaddingBottom = UDim.new(0, padding or PADDING)
	pad.PaddingLeft = UDim.new(0, padding or PADDING)
	pad.PaddingRight = UDim.new(0, padding or PADDING)
	pad.Parent = parent
	return pad
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.border
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function createButton(props)
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Size = props.size or UDim2.new(0, 100, 0, BUTTON_HEIGHT)
	button.Position = props.position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = props.backgroundColor or COLORS.surface
	button.Text = props.text or ""
	button.TextColor3 = props.textColor or COLORS.text
	button.Font = Enum.Font.GothamMedium
	button.TextSize = props.textSize or 13
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = props.parent

	createCorner(button)

	local normalColor = props.backgroundColor or COLORS.surface
	local hoverColor = props.hoverColor or COLORS.surfaceHover

	addConnection(button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hoverColor
	end))

	addConnection(button.MouseLeave:Connect(function()
		button.BackgroundColor3 = normalColor
	end))

	if props.onClick then
		addConnection(button.MouseButton1Click:Connect(props.onClick))
	end

	return button
end

local function createShortcutLabel(parent, text)
	local label = Instance.new("TextButton")
	label.Name = "shortcut"
	label.Size = UDim2.new(0, 20, 0, 16)
	label.Position = UDim2.new(1, -24, 0, 4)
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = text or ""
	label.TextColor3 = COLORS.textMuted
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.AutoButtonColor = false
	label.BorderSizePixel = 0
	label.Parent = parent

	createCorner(label, UDim.new(0, 4))

	return label
end

local function createTextBox(props)
	local textBox = Instance.new("TextBox")
	textBox.Name = props.name or "TextBox"
	textBox.Size = props.size or UDim2.new(0, 100, 0, BUTTON_HEIGHT)
	textBox.Position = props.position or UDim2.new(0, 0, 0, 0)
	textBox.BackgroundColor3 = props.backgroundColor or COLORS.surface
	textBox.Text = props.text or ""
	textBox.PlaceholderText = props.placeholder or ""
	textBox.TextColor3 = props.textColor or COLORS.text
	textBox.PlaceholderColor3 = COLORS.textMuted
	textBox.Font = Enum.Font.GothamMedium
	textBox.TextSize = props.textSize or 13
	textBox.BorderSizePixel = 0
	textBox.ClearTextOnFocus = false
	textBox.Parent = props.parent

	createCorner(textBox)

	return textBox
end

local function createDropdown(props)
	local container = Instance.new("Frame")
	container.Name = props.name or "Dropdown"
	container.Size = props.size or UDim2.new(0, 120, 0, BUTTON_HEIGHT)
	container.Position = props.position or UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = false
	container.Parent = props.parent

	local button = Instance.new("TextButton")
	button.Name = "DropdownButton"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = COLORS.surface
	button.Text = ""
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = container

	createCorner(button)
	createStroke(button, COLORS.border)

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, -30, 1, 0)
	selectedLabel.Position = UDim2.new(0, 10, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = props.defaultText or "Select..."
	selectedLabel.TextColor3 = COLORS.text
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.Font = Enum.Font.GothamMedium
	selectedLabel.TextSize = 12
	selectedLabel.Parent = button

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -25, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = COLORS.textMuted
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 10
	arrow.Parent = button

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, 0, 0, 0)
	listFrame.Position = UDim2.new(0, 0, 1, 4)
	listFrame.BackgroundColor3 = COLORS.dropdown
	listFrame.BorderSizePixel = 0
	listFrame.Visible = false
	listFrame.ZIndex = 100
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = COLORS.textMuted
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = container

	createCorner(listFrame)
	createStroke(listFrame, COLORS.border)

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = listFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 4)
	listPadding.PaddingBottom = UDim.new(0, 4)
	listPadding.PaddingLeft = UDim.new(0, 4)
	listPadding.PaddingRight = UDim.new(0, 4)
	listPadding.Parent = listFrame

	local isOpen = false

	local function closeDropdown()
		isOpen = false
		listFrame.Visible = false
		arrow.Text = "▼"
	end

	local function toggleDropdown()
		isOpen = not isOpen
		listFrame.Visible = isOpen
		arrow.Text = isOpen and "▲" or "▼"
	end

	addConnection(button.MouseButton1Click:Connect(toggleDropdown))

	local function addOption(text, value, layoutOrder)
		local optionBtn = Instance.new("TextButton")
		optionBtn.Name = "Option_" .. tostring(value)
		optionBtn.Size = UDim2.new(1, 0, 0, 28)
		optionBtn.BackgroundColor3 = COLORS.dropdown
		optionBtn.Text = text
		optionBtn.TextColor3 = COLORS.text
		optionBtn.Font = Enum.Font.GothamMedium
		optionBtn.TextSize = 12
		optionBtn.AutoButtonColor = false
		optionBtn.BorderSizePixel = 0
		optionBtn.LayoutOrder = layoutOrder or 0
		optionBtn.ZIndex = 101
		optionBtn.Parent = listFrame

		createCorner(optionBtn, UDim.new(0, 4))

		addConnection(optionBtn.MouseEnter:Connect(function()
			optionBtn.BackgroundColor3 = COLORS.surfaceHover
		end))

		addConnection(optionBtn.MouseLeave:Connect(function()
			optionBtn.BackgroundColor3 = COLORS.dropdown
		end))

		addConnection(optionBtn.MouseButton1Click:Connect(function()
			selectedLabel.Text = text
			closeDropdown()
			if props.onSelect then
				props.onSelect(value, text)
			end
		end))

		-- Update list frame height (max 150 pixels to stay within widget bounds)
		local optionCount = #listFrame:GetChildren() - 2 -- Subtract UIListLayout and UIPadding
		local desiredHeight = (optionCount * 30) + 8
		local maxHeight = 150
		listFrame.Size = UDim2.new(1, 0, 0, math.min(desiredHeight, maxHeight))

		return optionBtn
	end

	return {
		container = container,
		button = button,
		selectedLabel = selectedLabel,
		listFrame = listFrame,
		addOption = addOption,
		close = closeDropdown,
		setSelected = function(text)
			selectedLabel.Text = text
		end,
	}
end

---- Main Functions ----
local function playAnimation()
	local folder = workspace:FindFirstChild("AnimationEffect")
	if not folder then
		warn("AnimationEffect folder not found in workspace")
		return
	end

	local animation = folder:FindFirstChildOfClass("Animation")
	local model = folder:FindFirstChildOfClass("Model")
	if not animation or not model then
		warn("Animation or Model not found in AnimationEffect folder")
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("Humanoid not found in Model")
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animTrack = animator:LoadAnimation(animation)
	animTrack:Play()

	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < animTrack.Length do
			local step = RunService.Heartbeat:Wait()
			animator:StepAnimations(step)
		end
	end)
end

local function playEffect(totalDelay)
	local folder = workspace:FindFirstChild("AnimationEffect")
	if not folder then
		warn("AnimationEffect folder not found in workspace")
		return
	end

	-- Update totalDelay values
	local model = folder:FindFirstChild("Model")
	local animation = folder:FindFirstChild("Animation")
	for _, child in folder:GetChildren() do
		if child ~= model and child ~= animation then
			local delayValue = child:FindFirstChild("totalDelay")
			if not delayValue then
				delayValue = Instance.new("NumberValue")
				delayValue.Name = "totalDelay"
				delayValue.Parent = child
			end
			delayValue.Value = totalDelay
		end
	end

	task.delay(totalDelay, function()
		for _, particle in folder:GetDescendants() do
			if particle:IsA("ParticleEmitter") then
				local emitDelay = particle:GetAttribute("EmitDelay") or 0
				task.delay(emitDelay, function()
					local emitDuration = particle:GetAttribute("EmitDuration")
					if emitDuration then
						particle.Enabled = true
						task.delay(emitDuration, function()
							particle.Enabled = false
						end)
					else
						particle:Emit(particle.Rate)
					end
				end)
			elseif particle:IsA("Beam") then
				local emitDelay = particle:GetAttribute("EmitDelay") or 0
				task.delay(emitDelay, function()
					particle.Enabled = true
				end)

				local emitDuration = particle:GetAttribute("EmitDuration") or 5
				task.delay(emitDelay + emitDuration, function()
					particle.Enabled = false
				end)
			end
		end
	end)
end

local function toggleEffectState()
	effectState = not effectState
	local folder = workspace:FindFirstChild("AnimationEffect")
	if folder then
		for _, particle in folder:GetDescendants() do
			if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
				particle.Enabled = effectState
			end
		end
	end
	return effectState
end

local function createEmitDelayAttribute()
	local instances = Selection:Get()
	for _, ins in instances do
		if ins:IsA("Beam") or ins:IsA("ParticleEmitter") then
			ins:SetAttribute("EmitDelay", 0)
		end
	end
end

local function createEmitDurationAttribute()
	local instances = Selection:Get()
	for _, ins in instances do
		if ins:IsA("Beam") or ins:IsA("ParticleEmitter") then
			ins:SetAttribute("EmitDuration", 0)
		end
	end
end

local function fastWeld()
	local recording = ChangeHistoryService:TryBeginRecording("Fast Weld")
	if not recording then
		return
	end

	local instances = Selection:Get()
	if #instances < 2 then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
		return
	end

	local mother = instances[1]
	for i = 2, #instances do
		if instances[i]:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = mother
			weld.Part1 = instances[i]
			weld.Parent = mother
		end
	end

	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

---- UI Update Functions ----
local function updateAllUIText()
	if not uiElements.switchBtn then
		return
	end

	uiElements.switchBtn.Text = effectState and getText("effectOn") or getText("effectOff")
	uiElements.effectBtn.Text = getText("effect")
	uiElements.animateBtn.Text = getText("animate")
	uiElements.animateEffectBtn.Text = getText("animateEffect")
	uiElements.totalDelayLabel.Text = getText("totalDelay")
	uiElements.createAttrLabel.Text = getText("createAttr")
	uiElements.emitDelayBtn.Text = getText("emitDelay")
	uiElements.emitDurationBtn.Text = getText("emitDuration")
	if uiElements.closeBtn then
		uiElements.closeBtn.Text = getText("close")
	end
end

---- Create Main UI ----
local function createUI(widget)
	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = COLORS.background
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = false
	mainFrame.Parent = widget

	createPadding(mainFrame, 10)

	-- Top bar with language selector
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 36)
	topBar.BackgroundTransparency = 1
	topBar.ClipsDescendants = false
	topBar.Parent = mainFrame

	-- Info button (left side) - light blue color
	local infoBtnColor = Color3.fromRGB(70, 130, 180)
	local infoBtnHoverColor = Color3.fromRGB(90, 150, 200)

	local infoBtn = Instance.new("TextButton")
	infoBtn.Name = "InfoBtn"
	infoBtn.Size = UDim2.new(0, 30, 0, 30)
	infoBtn.Position = UDim2.new(0, 0, 0, 0)
	infoBtn.BackgroundColor3 = infoBtnColor
	infoBtn.Text = "i"
	infoBtn.TextColor3 = COLORS.text
	infoBtn.Font = Enum.Font.GothamBold
	infoBtn.TextSize = 16
	infoBtn.AutoButtonColor = false
	infoBtn.BorderSizePixel = 0
	infoBtn.Parent = topBar
	createCorner(infoBtn)

	addConnection(infoBtn.MouseEnter:Connect(function()
		infoBtn.BackgroundColor3 = infoBtnHoverColor
	end))
	addConnection(infoBtn.MouseLeave:Connect(function()
		infoBtn.BackgroundColor3 = infoBtnColor
	end))

	-- Info popup (initially hidden)
	local infoPopup = Instance.new("Frame")
	infoPopup.Name = "InfoPopup"
	infoPopup.Size = UDim2.new(1, -20, 1, -20)
	infoPopup.Position = UDim2.new(0, 10, 0, 10)
	infoPopup.BackgroundColor3 = COLORS.background
	infoPopup.BorderSizePixel = 0
	infoPopup.Visible = false
	infoPopup.ZIndex = 200
	infoPopup.Parent = mainFrame
	createCorner(infoPopup)
	createStroke(infoPopup, COLORS.border, 2)

	-- Info popup title
	local infoTitle = Instance.new("TextLabel")
	infoTitle.Name = "InfoTitle"
	infoTitle.Size = UDim2.new(1, 0, 0, 30)
	infoTitle.Position = UDim2.new(0, 0, 0, 8)
	infoTitle.BackgroundTransparency = 1
	infoTitle.Text = "Plugin Info"
	infoTitle.TextColor3 = COLORS.text
	infoTitle.Font = Enum.Font.GothamBold
	infoTitle.TextSize = 16
	infoTitle.ZIndex = 201
	infoTitle.Parent = infoPopup

	-- Info popup content (scrollable)
	local infoScroll = Instance.new("ScrollingFrame")
	infoScroll.Name = "InfoScroll"
	infoScroll.Size = UDim2.new(1, -20, 1, -80)
	infoScroll.Position = UDim2.new(0, 10, 0, 40)
	infoScroll.BackgroundColor3 = COLORS.surface
	infoScroll.BorderSizePixel = 0
	infoScroll.ScrollBarThickness = 8
	infoScroll.ScrollBarImageColor3 = COLORS.textMuted
	infoScroll.CanvasSize = UDim2.new(0, 0, 0, 500) -- Fixed canvas height for scrolling
	infoScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	infoScroll.ZIndex = 201
	infoScroll.Parent = infoPopup
	createCorner(infoScroll, UDim.new(0, 4))

	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.Size = UDim2.new(1, -24, 0, 480) -- Fixed height to match canvas
	infoText.Position = UDim2.new(0, 8, 0, 8)
	infoText.BackgroundTransparency = 1
	infoText.Text = PLUGIN_INFO_TEXT
	infoText.TextColor3 = COLORS.textSecondary
	infoText.Font = Enum.Font.Gotham
	infoText.TextSize = 12
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.ZIndex = 202
	infoText.Parent = infoScroll

	-- Close button for info popup
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 80, 0, 28)
	closeBtn.Position = UDim2.new(0.5, -40, 1, -38)
	closeBtn.BackgroundColor3 = COLORS.primary
	closeBtn.Text = getText("close")
	closeBtn.TextColor3 = COLORS.text
	closeBtn.Font = Enum.Font.GothamMedium
	closeBtn.TextSize = 13
	closeBtn.AutoButtonColor = false
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 201
	closeBtn.Parent = infoPopup
	createCorner(closeBtn)
	uiElements.closeBtn = closeBtn

	addConnection(closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = COLORS.primaryHover
	end))
	addConnection(closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = COLORS.primary
	end))
	addConnection(closeBtn.MouseButton1Click:Connect(function()
		infoPopup.Visible = false
	end))

	-- Info button click handler
	addConnection(infoBtn.MouseButton1Click:Connect(function()
		infoPopup.Visible = not infoPopup.Visible
	end))

	-- Language dropdown
	local languageDropdown = createDropdown({
		name = "LanguageDropdown",
		size = UDim2.new(0, 110, 0, 30),
		position = UDim2.new(1, -110, 0, 0),
		defaultText = "English",
		parent = topBar,
		onSelect = function(langCode, langName)
			currentLanguage = langCode
			saveLanguage(langCode)
			updateAllUIText()
		end,
	})

	-- Add language options
	for i, lang in ipairs(LanguageNames) do
		languageDropdown.addOption(lang.name, lang.code, i)
	end

	-- Set current language in dropdown
	for _, lang in ipairs(LanguageNames) do
		if lang.code == currentLanguage then
			languageDropdown.setSelected(lang.name)
			break
		end
	end

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, 0, 1, -46)
	contentFrame.Position = UDim2.new(0, 0, 0, 46)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ClipsDescendants = false
	contentFrame.Parent = mainFrame

	-- Row 1: Switch, Effect, Animate
	local row1 = Instance.new("Frame")
	row1.Name = "Row1"
	row1.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
	row1.BackgroundTransparency = 1
	row1.Parent = contentFrame

	-- Switch button (Effect On/Off)
	local switchBtn = createButton({
		name = "SwitchBtn",
		size = UDim2.new(0.33, -4, 1, 0),
		position = UDim2.new(0, 0, 0, 0),
		text = getText("effectOff"),
		backgroundColor = COLORS.danger,
		hoverColor = COLORS.dangerHover,
		parent = row1,
	})
	uiElements.switchBtn = switchBtn

	-- Set onClick after switchBtn is defined to avoid scope issues
	addConnection(switchBtn.MouseButton1Click:Connect(function()
		local state = toggleEffectState()
		switchBtn.Text = state and getText("effectOn") or getText("effectOff")
		switchBtn.BackgroundColor3 = state and COLORS.success or COLORS.danger
	end))

	local switchShortcut = createShortcutLabel(switchBtn, "G")

	-- Effect button
	local effectBtn = createButton({
		name = "EffectBtn",
		size = UDim2.new(0.33, -4, 1, 0),
		position = UDim2.new(0.33, 2, 0, 0),
		text = getText("effect"),
		parent = row1,
		onClick = function()
			local totalDelay = tonumber(uiElements.totalDelayBox.Text) or 0
			playEffect(totalDelay)
		end,
	})
	local effectShortcut = createShortcutLabel(effectBtn, "X")
	uiElements.effectBtn = effectBtn

	-- Animate button
	local animateBtn = createButton({
		name = "AnimateBtn",
		size = UDim2.new(0.34, -2, 1, 0),
		position = UDim2.new(0.66, 4, 0, 0),
		text = getText("animate"),
		parent = row1,
		onClick = playAnimation,
	})
	local animateShortcut = createShortcutLabel(animateBtn, "Z")
	uiElements.animateBtn = animateBtn

	-- Row 2: Total Delay (combined), Animate+Effect
	local row2 = Instance.new("Frame")
	row2.Name = "Row2"
	row2.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
	row2.Position = UDim2.new(0, 0, 0, BUTTON_HEIGHT + 8)
	row2.BackgroundTransparency = 1
	row2.Parent = contentFrame

	-- Total Delay container (label + input as one unit)
	local totalDelayContainer = Instance.new("Frame")
	totalDelayContainer.Name = "TotalDelayContainer"
	totalDelayContainer.Size = UDim2.new(0.5, -4, 1, 0)
	totalDelayContainer.Position = UDim2.new(0, 0, 0, 0)
	totalDelayContainer.BackgroundColor3 = COLORS.surface
	totalDelayContainer.BorderSizePixel = 0
	totalDelayContainer.Parent = row2
	createCorner(totalDelayContainer)

	-- Total Delay label (inside container, not a button)
	local totalDelayLabel = Instance.new("TextLabel")
	totalDelayLabel.Name = "TotalDelayLabel"
	totalDelayLabel.Size = UDim2.new(0.5, 0, 1, 0)
	totalDelayLabel.Position = UDim2.new(0, 0, 0, 0)
	totalDelayLabel.BackgroundTransparency = 1
	totalDelayLabel.Text = getText("totalDelay")
	totalDelayLabel.TextColor3 = COLORS.textSecondary
	totalDelayLabel.Font = Enum.Font.GothamMedium
	totalDelayLabel.TextSize = 12
	totalDelayLabel.Parent = totalDelayContainer
	uiElements.totalDelayLabel = totalDelayLabel

	-- Total Delay input (inside container)
	local totalDelayBox = Instance.new("TextBox")
	totalDelayBox.Name = "TotalDelayBox"
	totalDelayBox.Size = UDim2.new(0.5, -8, 1, -8)
	totalDelayBox.Position = UDim2.new(0.5, 4, 0, 4)
	totalDelayBox.BackgroundColor3 = COLORS.background
	totalDelayBox.Text = "0"
	totalDelayBox.PlaceholderText = "0"
	totalDelayBox.TextColor3 = COLORS.text
	totalDelayBox.PlaceholderColor3 = COLORS.textMuted
	totalDelayBox.Font = Enum.Font.GothamMedium
	totalDelayBox.TextSize = 13
	totalDelayBox.BorderSizePixel = 0
	totalDelayBox.ClearTextOnFocus = false
	totalDelayBox.Parent = totalDelayContainer
	createCorner(totalDelayBox, UDim.new(0, 4))
	uiElements.totalDelayBox = totalDelayBox

	-- Animate+Effect button
	local animateEffectBtn = createButton({
		name = "AnimateEffectBtn",
		size = UDim2.new(0.5, -4, 1, 0),
		position = UDim2.new(0.5, 4, 0, 0),
		text = getText("animateEffect"),
		parent = row2,
		onClick = function()
			playAnimation()
			local totalDelay = tonumber(totalDelayBox.Text) or 0
			playEffect(totalDelay)
		end,
	})
	local animateEffectShortcut = createShortcutLabel(animateEffectBtn, "C")
	uiElements.animateEffectBtn = animateEffectBtn

	-- Row 3: Create Attr container (label + EmitDelay + EmitDuration as one unit)
	local row3 = Instance.new("Frame")
	row3.Name = "Row3"
	row3.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
	row3.Position = UDim2.new(0, 0, 0, (BUTTON_HEIGHT + 8) * 2)
	row3.BackgroundTransparency = 1
	row3.Parent = contentFrame

	-- Create Attr container (all three elements as one unit)
	local createAttrContainer = Instance.new("Frame")
	createAttrContainer.Name = "CreateAttrContainer"
	createAttrContainer.Size = UDim2.new(1, 0, 1, 0)
	createAttrContainer.Position = UDim2.new(0, 0, 0, 0)
	createAttrContainer.BackgroundColor3 = COLORS.primary
	createAttrContainer.BorderSizePixel = 0
	createAttrContainer.Parent = row3
	createCorner(createAttrContainer)

	-- Create Attr label (inside container, not a button)
	local createAttrLabel = Instance.new("TextLabel")
	createAttrLabel.Name = "CreateAttrLabel"
	createAttrLabel.Size = UDim2.new(0.33, 0, 1, 0)
	createAttrLabel.Position = UDim2.new(0, 0, 0, 0)
	createAttrLabel.BackgroundTransparency = 1
	createAttrLabel.Text = getText("createAttr")
	createAttrLabel.TextColor3 = COLORS.text
	createAttrLabel.Font = Enum.Font.GothamBold
	createAttrLabel.TextSize = 12
	createAttrLabel.Parent = createAttrContainer
	uiElements.createAttrLabel = createAttrLabel

	-- EmitDelay button (inside container)
	local emitDelayBtn = Instance.new("TextButton")
	emitDelayBtn.Name = "EmitDelayBtn"
	emitDelayBtn.Size = UDim2.new(0.33, -4, 1, -8)
	emitDelayBtn.Position = UDim2.new(0.33, 2, 0, 4)
	emitDelayBtn.BackgroundColor3 = COLORS.primaryHover
	emitDelayBtn.Text = getText("emitDelay")
	emitDelayBtn.TextColor3 = COLORS.text
	emitDelayBtn.Font = Enum.Font.GothamMedium
	emitDelayBtn.TextSize = 12
	emitDelayBtn.AutoButtonColor = false
	emitDelayBtn.BorderSizePixel = 0
	emitDelayBtn.Parent = createAttrContainer
	createCorner(emitDelayBtn, UDim.new(0, 4))
	uiElements.emitDelayBtn = emitDelayBtn

	addConnection(emitDelayBtn.MouseEnter:Connect(function()
		emitDelayBtn.BackgroundColor3 = Color3.fromRGB(116, 215, 120)
	end))
	addConnection(emitDelayBtn.MouseLeave:Connect(function()
		emitDelayBtn.BackgroundColor3 = COLORS.primaryHover
	end))
	addConnection(emitDelayBtn.MouseButton1Click:Connect(createEmitDelayAttribute))

	-- EmitDuration button (inside container)
	local emitDurationBtn = Instance.new("TextButton")
	emitDurationBtn.Name = "EmitDurationBtn"
	emitDurationBtn.Size = UDim2.new(0.34, -6, 1, -8)
	emitDurationBtn.Position = UDim2.new(0.66, 2, 0, 4)
	emitDurationBtn.BackgroundColor3 = COLORS.primaryHover
	emitDurationBtn.Text = getText("emitDuration")
	emitDurationBtn.TextColor3 = COLORS.text
	emitDurationBtn.Font = Enum.Font.GothamMedium
	emitDurationBtn.TextSize = 12
	emitDurationBtn.AutoButtonColor = false
	emitDurationBtn.BorderSizePixel = 0
	emitDurationBtn.Parent = createAttrContainer
	createCorner(emitDurationBtn, UDim.new(0, 4))
	uiElements.emitDurationBtn = emitDurationBtn

	addConnection(emitDurationBtn.MouseEnter:Connect(function()
		emitDurationBtn.BackgroundColor3 = Color3.fromRGB(116, 215, 120)
	end))
	addConnection(emitDurationBtn.MouseLeave:Connect(function()
		emitDurationBtn.BackgroundColor3 = COLORS.primaryHover
	end))
	addConnection(emitDurationBtn.MouseButton1Click:Connect(createEmitDurationAttribute))

	-- Keyboard shortcuts setup
	local shortcuts = {
		[switchBtn] = { key = Enum.KeyCode.G, label = switchShortcut },
		[effectBtn] = { key = Enum.KeyCode.X, label = effectShortcut },
		[animateBtn] = { key = Enum.KeyCode.Z, label = animateShortcut },
		[animateEffectBtn] = { key = Enum.KeyCode.C, label = animateEffectShortcut },
	}

	-- Load saved shortcuts
	local savedShortcuts = plugin:GetSetting("shortcuts")
	if savedShortcuts then
		for btn, data in pairs(shortcuts) do
			local savedKey = savedShortcuts[btn.Name]
			if savedKey then
				local success, keyCode = pcall(function()
					return Enum.KeyCode[savedKey]
				end)
				if success and keyCode then
					data.key = keyCode
					data.label.Text = savedKey
				end
			end
		end
	end

	-- Shortcut customization using a hidden TextBox to capture keyboard input reliably
	-- This bypasses Studio's shortcut conflicts
	local shortcutCaptureBox = Instance.new("TextBox")
	shortcutCaptureBox.Name = "ShortcutCaptureBox"
	shortcutCaptureBox.Size = UDim2.new(0, 1, 0, 1)
	shortcutCaptureBox.Position = UDim2.new(0, -100, 0, -100)
	shortcutCaptureBox.BackgroundTransparency = 1
	shortcutCaptureBox.TextTransparency = 1
	shortcutCaptureBox.Text = ""
	shortcutCaptureBox.ClearTextOnFocus = true
	shortcutCaptureBox.Parent = mainFrame

	local currentSettingData = nil

	-- Handle keyboard input immediately when text changes
	addConnection(shortcutCaptureBox:GetPropertyChangedSignal("Text"):Connect(function()
		if not settingMode or not currentSettingData then
			return
		end

		local inputText = shortcutCaptureBox.Text:upper()
		if inputText == "" then
			return
		end

		-- Get the first character as the shortcut key
		local firstChar = inputText:sub(1, 1)
		local success, keyCode = pcall(function()
			return Enum.KeyCode[firstChar]
		end)

		if success and keyCode then
			currentSettingData.key = keyCode
			currentSettingData.label.Text = firstChar
			currentSettingData.label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

			-- Save shortcuts
			local toSave = {}
			for b, d in pairs(shortcuts) do
				toSave[b.Name] = d.key.Name
			end
			plugin:SetSetting("shortcuts", toSave)

			-- Done setting
			settingMode = false
			currentSettingData = nil
			shortcutCaptureBox:ReleaseFocus()
		else
			-- Invalid key, clear and let user try again
			shortcutCaptureBox.Text = ""
		end
	end))

	-- Handle focus lost (cancel if no key was entered)
	addConnection(shortcutCaptureBox.FocusLost:Connect(function()
		if settingMode and currentSettingData then
			-- Restore original key
			currentSettingData.label.Text = currentSettingData.key.Name
			currentSettingData.label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			settingMode = false
			currentSettingData = nil
		end
	end))

	for btn, data in pairs(shortcuts) do
		addConnection(data.label.MouseButton1Click:Connect(function()
			if settingMode then
				return
			end
			settingMode = true
			currentSettingData = data
			data.label.Text = "..."
			data.label.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

			-- Focus the hidden TextBox to capture keyboard input
			shortcutCaptureBox.Text = ""
			shortcutCaptureBox:CaptureFocus()
		end))
	end

	-- Global keyboard input using mainFrame.InputBegan (more reliable in plugins)
	mainFrame.Active = true
	addConnection(mainFrame.InputBegan:Connect(function(input)
		if settingMode then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		for btn, data in pairs(shortcuts) do
			if input.KeyCode == data.key then
				-- Manually trigger the onClick
				if btn == switchBtn then
					local state = toggleEffectState()
					switchBtn.Text = state and getText("effectOn") or getText("effectOff")
					switchBtn.BackgroundColor3 = state and COLORS.success or COLORS.danger
				elseif btn == effectBtn then
					local totalDelay = tonumber(totalDelayBox.Text) or 0
					playEffect(totalDelay)
				elseif btn == animateBtn then
					playAnimation()
				elseif btn == animateEffectBtn then
					playAnimation()
					local totalDelay = tonumber(totalDelayBox.Text) or 0
					playEffect(totalDelay)
				end
				break
			end
		end
	end))

	-- Also try UserInputService as fallback (works when widget has focus)
	addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or settingMode then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		-- Only process if widget is enabled
		if not widget.Enabled then
			return
		end

		for btn, data in pairs(shortcuts) do
			if input.KeyCode == data.key then
				if btn == switchBtn then
					local state = toggleEffectState()
					switchBtn.Text = state and getText("effectOn") or getText("effectOff")
					switchBtn.BackgroundColor3 = state and COLORS.success or COLORS.danger
				elseif btn == effectBtn then
					local totalDelay = tonumber(totalDelayBox.Text) or 0
					playEffect(totalDelay)
				elseif btn == animateBtn then
					playAnimation()
				elseif btn == animateEffectBtn then
					playAnimation()
					local totalDelay = tonumber(totalDelayBox.Text) or 0
					playEffect(totalDelay)
				end
				break
			end
		end
	end))

	return mainFrame
end

---- Plugin Initialization ----
local toolbar = plugin:CreateToolbar("Utils")
local animEffectButton = toolbar:CreateButton("Animation Effect", "Animation Effect Tool", "rbxassetid://16738934990")
local fastWeldButton = toolbar:CreateButton("Fast Weld", "Fast Weld Tool", "rbxassetid://16887205340")

-- Widget setup
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 380, 300, 300, 180)

local widget = plugin:CreateDockWidgetPluginGuiAsync("AnimationEffectV2", widgetInfo)
widget.Title = "Animation Effect"

-- Initialize language
currentLanguage = detectLanguage()

-- Function to move camera to face a target part
local function moveCameraToFolder()
	local folder = workspace:FindFirstChild("AnimationEffect")
	if not folder then
		return
	end

	-- Find a suitable BasePart to focus on
	local targetPart = nil
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			targetPart = descendant
			break
		end
	end

	-- If no BasePart found, try to find the Model
	if not targetPart then
		local model = folder:FindFirstChild("Model")
		if model then
			targetPart = model:FindFirstChild("HumanoidRootPart")
				or model.PrimaryPart
				or model:FindFirstChildWhichIsA("BasePart")
		end
	end

	if targetPart then
		-- Position camera in front of the target, facing it
		local targetCFrame = targetPart.CFrame
		workspace.CurrentCamera.CFrame = targetCFrame * CFrame.new(0, 0, -10)
		workspace.CurrentCamera.Focus = targetCFrame
	end
end

-- Animation Effect button click
animEffectButton.Click:Connect(function()
	local recording = ChangeHistoryService:TryBeginRecording("Animation Effect Setup")
	if not recording then
		return
	end

	widget.Enabled = not widget.Enabled

	if widget.Enabled then
		-- Ensure AnimationEffect folder exists
		local folder = workspace:FindFirstChild("AnimationEffect")
		if not folder then
			local templateFolder = script:FindFirstChild("AnimationEffect")
			if templateFolder then
				folder = templateFolder:Clone()
				folder.Parent = workspace
			else
				folder = Instance.new("Folder")
				folder.Name = "AnimationEffect"
				folder.Parent = workspace
			end
		end

		-- Move camera to face the folder contents
		moveCameraToFolder()

		if not isWidgetInitialized then
			createUI(widget)
			isWidgetInitialized = true
		end
	end

	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end)

-- Fast Weld button click
fastWeldButton.Click:Connect(function()
	fastWeld()
end)

-- Cleanup on plugin unload
plugin.Unloading:Connect(function()
	clearConnections()
end)
