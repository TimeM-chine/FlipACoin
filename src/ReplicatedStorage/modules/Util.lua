-- version 1.1

local UIS = game:GetService("UserInputService")
local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")

local Util = {}

function Util.getDateTime()
	return DateTime.now():FormatUniversalTime("YY-MM-DD HH:mm:ss", "en_us")
end

-- get current week number on UTC
function Util.getWeekNumberOfYear()
	return os.date("%Y_%U", os.time(os.date("!*t")))
end

-- get time from now to someday
function Util.GetTimeToSomeday(year, month, day, hour, minute, second)
	local currentTime = os.time()
	local somedayDate = os.date("*t", currentTime)
	somedayDate.year = year
	somedayDate.month = month
	somedayDate.day = day
	somedayDate.hour = hour
	somedayDate.min = minute
	somedayDate.sec = second

	local somedayTime = os.time(somedayDate)

	local timeRemaining = somedayTime - currentTime

	if timeRemaining < 0 then
		timeRemaining = 0
	end
	return timeRemaining
end

function Util.WeekendToMondayTime()
	local currentTime = os.time()
	local currentDayOfWeek = tonumber(os.date("%w", currentTime))

	-- w 0-7 (Sunday is day 0)
	if currentDayOfWeek ~= 6 and currentDayOfWeek ~= 0 and currentDayOfWeek ~= 1 then
		return 0
	end

	local daysUntilNextMonday = (8 - currentDayOfWeek) % 7

	local nextMondayDate = os.date("*t", currentTime + daysUntilNextMonday * 86400)

	nextMondayDate.hour = 12
	nextMondayDate.min = 0
	nextMondayDate.sec = 0

	local nextMondayTime = os.time(nextMondayDate)

	local timeRemaining = nextMondayTime - currentTime

	if timeRemaining < 0 then
		timeRemaining = 0
	end
	return timeRemaining
end

function Util.getOrdinalNumber(number)
	local suffix = "th"
	local lastDigit = number % 10
	local secondLastDigit = math.floor(number / 10) % 10

	if secondLastDigit ~= 1 then
		if lastDigit == 1 then
			suffix = "st"
		elseif lastDigit == 2 then
			suffix = "nd"
		elseif lastDigit == 3 then
			suffix = "rd"
		end
	end

	return number .. suffix
end

-- format time to %H%M
function Util.FormatPlayTime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local second = math.floor((seconds % 3600) % 60)
	local str = ""
	if days > 0 then
		str = str .. days .. "d"
		str = string.format("%dd%dh", days, hours)
	elseif hours > 0 then
		str = string.format("%dh%dm", hours, minutes)
	elseif minutes > 0 then
		str = string.format("%dm%ds", minutes, second)
	else
		str = string.format("%ds", second)
	end

	return str
end

-- formate countdown time to %H:%M:%S
function Util.FormatCountDown(seconds, showSeconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local sec = math.floor(seconds % 60)
	local str = ""

	if showSeconds == nil then
		showSeconds = true
	end

	if hours > 0 then
		if showSeconds then
			str = string.format("%02d:%02d:%02d", hours, minutes, sec)
		else
			str = string.format("%02d:%02d", hours, minutes)
		end
	else
		if showSeconds then
			str = string.format("%02d:%02d", minutes, sec)
		else
			str = string.format("%02d", minutes)
		end
	end

	return str
end

-- format number to 1.2k or 1.2m
function Util.FormatNumber(number, stripTrailingZero)
	if number >= 1000000000000000000000000000000000000 then
		number = string.format("%.1fUd", number / 1000000000000000000000000000000000000)
	elseif number >= 1000000000000000000000000000000000 then
		number = string.format("%.1fDc", number / 1000000000000000000000000000000000)
	elseif number >= 1000000000000000000000000000000 then
		number = string.format("%.1fNo", number / 1000000000000000000000000000000)
	elseif number >= 1000000000000000000000000000 then
		number = string.format("%.1fOc", number / 1000000000000000000000000000)
	elseif number >= 1000000000000000000000000 then
		number = string.format("%.1fSp", number / 1000000000000000000000000)
	elseif number >= 1000000000000000000000 then
		number = string.format("%.1fSx", number / 1000000000000000000000)
	elseif number >= 1000000000000000000 then
		number = string.format("%.1fQi", number / 1000000000000000000)
	elseif number >= 1000000000000000 then
		number = string.format("%.1fQa", number / 1000000000000000)
	elseif number >= 1000000000000 then
		number = string.format("%.1fT", number / 1000000000000)
	elseif number >= 1000000000 then
		number = string.format("%.1fB", number / 1000000000)
	elseif number >= 1000000 then
		number = string.format("%.1fM", number / 1000000)
	elseif number >= 10000 then
		number = string.format("%.1fK", number / 1000)
	else
		return tostring(number)
	end

	if stripTrailingZero then
		number = string.gsub(number, "%.0+", "")
	end

	return number
end

-- 讲model 加入碰撞组
function Util.setModelCollisionGroup(model, groupId)
	for key, part in pairs(model:GetDescendants()) do
		if part:IsA("Part") or part:IsA("MeshPart") then
			part.CollisionGroup = groupId
		end
	end
end

-- 检测input是否在一个frame下
function Util.InputInFrame(inputObject, frame)
	local frameCornerTopLeft: Vector2 = frame.AbsolutePosition
	local frameCornerBottomRight = frameCornerTopLeft + frame.AbsoluteSize

	-- 如果设备是console，position需要换成thumbstick1.position
	local inputPosition = nil
	if inputObject.UserInputType == Enum.UserInputType.Gamepad1 then
		inputPosition = UIS:GetMouseLocation()
	else
		inputPosition = inputObject.Position
	end
	if inputPosition.X >= frameCornerTopLeft.X and inputPosition.Y >= frameCornerTopLeft.Y then
		if inputPosition.X <= frameCornerBottomRight.X and inputPosition.Y <= frameCornerBottomRight.Y then
			return true
		end
	end
	return false
end

function Util.InputBeginAllDevice(inputObject)
	if
		inputObject.UserInputType == Enum.UserInputType.MouseButton1
		or inputObject.UserInputType == Enum.UserInputType.Touch
		or inputObject.UserInputType == Enum.UserInputType.Gamepad1
	then
		return true
	else
		return false
	end
end

-- 根据概率随机从一个table中选出一个
function Util.randomByProbability(t)
	local total = 0
	for k, v in pairs(t) do
		total = total + v
	end
	local random = math.random() * total
	local sum = 0
	for k, v in pairs(t) do
		sum = sum + v
		if random <= sum then
			return k
		end
	end
end

-- 从列表中随机选择一个
function Util.randomFromList(list)
	list = Util.deepCopyTable(list)
	return list[math.random(1, #list)]
end

--  给用户发徽章
function Util.awardBadge(player, badgeId)
	local awarded, errorMessage = pcall(function()
		BadgeService:AwardBadge(player.UserId, badgeId)
	end)
	if not awarded then
		warn("awardBadge Error", errorMessage)
	else
		print("awardBadge success")
	end
end

-- 自定义爆炸效果
function Util.Explode(explosion, position)
	if not explosion then
		return
	end
	explosion.Position = position

	game:GetService("TweenService")
		:Create(
			explosion.Attachment.PointLight,
			TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Brightness = 0 }
		)
		:Play()

	for _, v in ipairs(explosion:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

-- deep cope table
function Util.deepCopyTable(tb)
	local lookup_table = {}
	local function _copy(t)
		if type(t) ~= "table" then
			return t
		elseif lookup_table[t] then
			return lookup_table[t]
		end
		local new_table = {}
		lookup_table[t] = new_table
		for index, value in pairs(t) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(t))
	end
	return _copy(tb)
end

-- for weapon and pets session
function Util.insertTbl(t, value)
	local nextEmptyIndex = #t + 1
	for i = 1, #t do
		if next(t[i]) == nil then
			nextEmptyIndex = i
			break
		end
	end
	t[nextEmptyIndex] = value

	return nextEmptyIndex
end

function Util.DictionaryLength(dic)
	local count = 0
	for k, v in pairs(dic) do
		count = count + 1
	end

	return count
end

function Util.createRegion3(center, size)
	local region = Region3.new(center - size / 2, center + size / 2)
	return region
end

function Util.isInRegion3(region, point)
	local relative = (point - region.CFrame.Position) / region.Size
	return -0.5 <= relative.X
		and relative.X <= 0.5
		and -0.5 <= relative.Y
		and relative.Y <= 0.5
		and -0.5 <= relative.Z
		and relative.Z <= 0.5
end

function Util.ancestorHasTag(instance, tag)
	local currentInstance = instance
	while currentInstance do
		if CollectionService:HasTag(currentInstance, tag) then
			return true
		else
			currentInstance = currentInstance.Parent
		end
	end

	return false
end

function Util.ancestorTagged(instance)
	local currentInstance = instance
	while currentInstance do
		local tags = CollectionService:GetTags(currentInstance)
		if #tags > 0 then
			return tags[1]
		else
			currentInstance = currentInstance.Parent
		end
	end

	return nil
end

function Util.GetPlayerAvatar(UserId, size)
	size = size or 48
	return `rbxthumb://type=AvatarHeadShot&id={UserId}&w={size}&h={size}`
end

function Util.Round(number, decimals: number)
	decimals = decimals or 1
	return string.format(`%.{decimals}f`, number)
end

function Util.Clone(ins, parent, func)
	local clone = ins:Clone()
	func(clone)
	clone:SetAttribute("isClone", true)
	clone.Parent = parent
	return clone
end

function Util.ClonePlayerCharacter(player: Player)
	player.Character.Archivable = true
	local clone = player.Character:Clone()
	player.Character.Archivable = false
	return clone
end

function Util.GetRobuxText(text)
	return "\u{E002} " .. text
end

return Util
