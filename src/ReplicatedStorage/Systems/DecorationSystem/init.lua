---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

---- requires ----
local DecorationPresets = require(script.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local RuntimeFolderName = DecorationPresets.RuntimeFolderName
local TableDecorationAssetFolderName = DecorationPresets.TableDecorationAssetFolderName
local ChairAssetFolderName = DecorationPresets.ChairAssetFolderName
local DefaultTableDecorationAssetName = DecorationPresets.DefaultTableDecorationAssetName
local WorkspaceTableDecorationName = DecorationPresets.WorkspaceTableDecorationName
local TableDecorationSurfaceGap = DecorationPresets.TableDecorationSurfaceGap
local Keys = require(Replicated.configs.Keys)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass

---- client variables ----

local DecorationSystem: Types.System = {
	whiteList = {
		"RefreshPlayerDecoration",
		"RefreshAllDecorations",
		"ClearPlayerDecoration",
		"TweenAllDecorations",
		"RefreshFakeActorDecoration",
		"ClearFakeActorDecoration",
	},
	players = {},
	IsLoaded = false,
}
DecorationSystem.__index = DecorationSystem

if IsServer then
	DecorationSystem.Client = setmetatable({}, DecorationSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	DecorationSystem.Server = setmetatable({}, DecorationSystem)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function DecorationSystem:Init()
	GetSystemMgr()

	if IsServer then
		self._playerDecorations = {}
		self._fakeActorDecorations = {}
		migrateWorkspaceTableDecoration()
		task.defer(function()
			self:RefreshAllDecorations(SENDER)
		end)
	end
end

function DecorationSystem:PlayerAdded(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	task.defer(function()
		if player:IsDescendantOf(Players) then
			self:RefreshPlayerDecoration(SENDER, player)
		end
	end)
end

function DecorationSystem:PlayerRemoving(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	self:ClearPlayerDecoration(SENDER, player)
end

function DecorationSystem:RefreshPlayerDecoration(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if not player or not player:IsDescendantOf(Players) then
		return
	end

	self._playerDecorations = self._playerDecorations or {}
	self:ClearPlayerDecoration(SENDER, player)

	local playerIns = PlayerServerClass.GetIns(player, false)
	if not playerIns then
		return
	end

	local assignment = GetSystemMgr().systems.TableSeatSystem:GetPlayerSeatAssignment(player)
	if not assignment then
		return
	end

	local runtimeFolder = getRuntimeFolder(assignment.tableModel)
	local record = {
		models = {},
		rawSeatId = assignment.rawSeatId,
		tableModel = assignment.tableModel,
	}

	local deskSetupId = playerIns:GetOneData(dataKey.equippedDeskSetup)
	local assetModel = getDecorationAsset(deskSetupId)
	if assetModel then
		local decorationName = `{assignment.rawSeatId}Decoration`
		local existingDecoration = runtimeFolder:FindFirstChild(decorationName)
		if existingDecoration then
			existingDecoration:Destroy()
		end

		local decorationModel = assetModel:Clone()
		decorationModel.Name = decorationName
		prepareDecorationModel(decorationModel)
		decorationModel:PivotTo(getDecorationCFrame(assignment))
		decorationModel:PivotTo(getSettledDecorationCFrame(decorationModel, decorationModel:GetPivot(), assignment.tableModel))
		decorationModel.Parent = runtimeFolder
		record.models.decoration = decorationModel
	else
		warn(`[DecorationSystem] Missing table decoration model asset for desk setup: {deskSetupId}`)
	end

	local chairId = playerIns:GetOneData(dataKey.equippedChair)
	local chairAsset = getChairAsset(chairId)
	if chairAsset then
		local chairName = `{assignment.rawSeatId}Chair`
		local existingChair = runtimeFolder:FindFirstChild(chairName)
		if existingChair then
			existingChair:Destroy()
		end

		local chairModel = chairAsset:Clone()
		chairModel.Name = chairName
		prepareDecorationModel(chairModel)
		chairModel:PivotTo(getChairCFrame(assignment))
		chairModel.Parent = runtimeFolder
		record.models.chair = chairModel
	else
		warn(`[DecorationSystem] Missing chair model asset for chair: {chairId}`)
	end

	self._playerDecorations[player.UserId] = record
end

function DecorationSystem:RefreshAllDecorations(sender)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		self:RefreshPlayerDecoration(SENDER, player)
	end
end

function DecorationSystem:TweenAllDecorations(sender)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	self._playerDecorations = self._playerDecorations or {}
	for userId, record in pairs(self._playerDecorations) do
		local player = Players:GetPlayerByUserId(userId)
		if not player or not player:IsDescendantOf(Players) then
			continue
		end

		local assignment = GetSystemMgr().systems.TableSeatSystem:GetPlayerSeatAssignment(player)
		if not assignment then
			continue
		end

		record.rawSeatId = assignment.rawSeatId
		record.tableModel = assignment.tableModel
		if record.models and record.models.decoration then
			tweenModelPivot(
				record.models.decoration,
				getSettledDecorationCFrame(record.models.decoration, getDecorationCFrame(assignment), assignment.tableModel)
			)
		end
		if record.models and record.models.chair then
			tweenModelPivot(record.models.chair, getChairCFrame(assignment))
		end
	end

	self._fakeActorDecorations = self._fakeActorDecorations or {}
	for fakeId, record in pairs(self._fakeActorDecorations) do
		local fakeActor = GetSystemMgr().systems.FakePlayerSystem:GetFakeActor(SENDER, fakeId)
		if not fakeActor or not fakeActor.isActive then
			continue
		end

		local assignment = GetSystemMgr().systems.TableSeatSystem:GetFakeActorSeatAssignment(fakeActor)
		if not assignment then
			continue
		end

		record.rawSeatId = assignment.rawSeatId
		record.tableModel = assignment.tableModel
		if record.models and record.models.decoration then
			tweenModelPivot(
				record.models.decoration,
				getSettledDecorationCFrame(record.models.decoration, getDecorationCFrame(assignment), assignment.tableModel)
			)
		end
		if record.models and record.models.chair then
			tweenModelPivot(record.models.chair, getChairCFrame(assignment))
		end
	end
end

function DecorationSystem:ClearPlayerDecoration(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	self._playerDecorations = self._playerDecorations or {}
	local record = player and self._playerDecorations[player.UserId]
	if not record then
		return
	end

	if record.model and record.model.Parent then
		record.model:Destroy()
	end
	for _, model in pairs(record.models or {}) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	self._playerDecorations[player.UserId] = nil
end

function DecorationSystem:RefreshFakeActorDecoration(sender, fakeActor)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if typeof(fakeActor) ~= "table" or fakeActor.isFake ~= true or not fakeActor.isActive then
		return
	end

	self._fakeActorDecorations = self._fakeActorDecorations or {}
	self:ClearFakeActorDecoration(SENDER, fakeActor)

	local assignment = GetSystemMgr().systems.TableSeatSystem:GetFakeActorSeatAssignment(fakeActor)
	if not assignment then
		return
	end

	local runtimeFolder = getRuntimeFolder(assignment.tableModel)
	local record = {
		models = {},
		rawSeatId = assignment.rawSeatId,
		tableModel = assignment.tableModel,
	}

	local deskSetupId = fakeActor.equippedDeskSetup or EcoPresets.LoadoutDefaults.equippedDeskSetup
	local assetModel = getDecorationAsset(deskSetupId)
	if assetModel then
		local decorationName = `{assignment.rawSeatId}FakeDecoration`
		local existingDecoration = runtimeFolder:FindFirstChild(decorationName)
		if existingDecoration then
			existingDecoration:Destroy()
		end

		local decorationModel = assetModel:Clone()
		decorationModel.Name = decorationName
		prepareDecorationModel(decorationModel)
		decorationModel:PivotTo(getDecorationCFrame(assignment))
		decorationModel:PivotTo(getSettledDecorationCFrame(decorationModel, decorationModel:GetPivot(), assignment.tableModel))
		decorationModel.Parent = runtimeFolder
		record.models.decoration = decorationModel
	else
		warn(`[DecorationSystem] Missing fake table decoration model asset for desk setup: {deskSetupId}`)
	end

	local chairId = fakeActor.equippedChair or EcoPresets.LoadoutDefaults.equippedChair
	local chairAsset = getChairAsset(chairId)
	if chairAsset then
		local chairName = `{assignment.rawSeatId}FakeChair`
		local existingChair = runtimeFolder:FindFirstChild(chairName)
		if existingChair then
			existingChair:Destroy()
		end

		local chairModel = chairAsset:Clone()
		chairModel.Name = chairName
		prepareDecorationModel(chairModel)
		chairModel:PivotTo(getChairCFrame(assignment))
		chairModel.Parent = runtimeFolder
		record.models.chair = chairModel
	else
		warn(`[DecorationSystem] Missing fake chair model asset for chair: {chairId}`)
	end

	self._fakeActorDecorations[fakeActor.fakeId] = record
end

function DecorationSystem:ClearFakeActorDecoration(sender, fakeActor)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	self._fakeActorDecorations = self._fakeActorDecorations or {}
	local fakeId = typeof(fakeActor) == "table" and fakeActor.fakeId or fakeActor
	local record = fakeId and self._fakeActorDecorations[fakeId]
	if not record then
		return
	end

	for _, model in pairs(record.models or {}) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	self._fakeActorDecorations[fakeId] = nil
end

---- [[ Server Only ]] ----
function getDecorationAsset(deskSetupId)
	if typeof(deskSetupId) ~= "string" then
		return nil
	end

	local assetFolder = getTableDecorationAssetFolder()
	local asset = assetFolder:FindFirstChild(deskSetupId)
	if asset and asset:IsA("Model") then
		return asset
	end

	local defaultAsset = assetFolder:FindFirstChild(DefaultTableDecorationAssetName)
		or assetFolder:FindFirstChild(WorkspaceTableDecorationName)
	if defaultAsset and defaultAsset:IsA("Model") then
		return defaultAsset
	end

	return nil
end

function getChairAsset(chairId)
	if typeof(chairId) ~= "string" then
		return nil
	end

	local assetFolder = getChairAssetFolder()
	local asset = assetFolder:FindFirstChild(chairId)
	if asset and asset:IsA("Model") then
		return asset
	end

	return nil
end

function getRuntimeFolder(tableModel)
	local assets = tableModel:FindFirstChild("Assets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = tableModel
	end

	local runtimeFolder = assets:FindFirstChild(RuntimeFolderName)
	if not runtimeFolder then
		runtimeFolder = Instance.new("Folder")
		runtimeFolder.Name = RuntimeFolderName
		runtimeFolder.Parent = assets
	end

	return runtimeFolder
end

function getDecorationCFrame(assignment)
	local dynamicSeatCFrame = getDynamicSeatCFrame(assignment)
	if dynamicSeatCFrame then
		return getDynamicDecorationCFrame(assignment, dynamicSeatCFrame)
	end

	local tableModel = assignment.tableModel
	local rawSeatId = assignment.rawSeatId
	local anchor = findDecorationAnchor(tableModel, rawSeatId)
	if anchor then
		return getAnchorCFrame(anchor)
	end

	local tableTop = tableModel:FindFirstChild("TableTop")
	local seat = assignment.seat
	if not tableTop or not seat then
		return tableModel:GetPivot()
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + tableNormal * halfThickness
	local outward = seat.Position - surfaceCenter
	outward = outward - tableNormal * outward:Dot(tableNormal)
	if outward.Magnitude < 0.001 then
		outward = tableTop.CFrame.LookVector
	else
		outward = outward.Unit
	end

	local position = surfaceCenter + outward * math.min(tableTop.Size.X, tableTop.Size.Z) * 0.22 + tableNormal * 0.03
	return CFrame.lookAt(position, position - outward, tableNormal)
end

function getChairCFrame(assignment)
	local dynamicSeatCFrame = getDynamicSeatCFrame(assignment)
	if dynamicSeatCFrame then
		return dynamicSeatCFrame * CFrame.new(0, -2.28, 0.51)
	end

	local tableModel = assignment.tableModel
	local rawSeatId = assignment.rawSeatId
	local anchor = findChairAnchor(tableModel, rawSeatId)
	if anchor then
		return getAnchorCFrame(anchor)
	end

	return assignment.seat.CFrame * CFrame.new(0, -2.28, 0.51)
end

function getDynamicSeatCFrame(assignment)
	return GetSystemMgr().systems.TableSeatSystem:GetSeatTargetCFrame(assignment.seatId)
end

function getDynamicDecorationCFrame(assignment, seatCFrame)
	local tableTop = assignment.tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return seatCFrame
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + tableNormal * halfThickness
	local inward = seatCFrame.LookVector - tableNormal * seatCFrame.LookVector:Dot(tableNormal)
	if inward.Magnitude < 0.001 then
		inward = (surfaceCenter - seatCFrame.Position) - tableNormal * (surfaceCenter - seatCFrame.Position):Dot(tableNormal)
	end
	if inward.Magnitude < 0.001 then
		inward = tableTop.CFrame.LookVector
	else
		inward = inward.Unit
	end
	local right = seatCFrame.RightVector - tableNormal * seatCFrame.RightVector:Dot(tableNormal)
	if right.Magnitude < 0.001 then
		right = inward:Cross(tableNormal).Unit
	else
		right = right.Unit
	end

	local rawPosition = seatCFrame.Position + inward * 2.25 - right * 0.85
	local surfacePosition = rawPosition - tableNormal * (rawPosition - surfaceCenter):Dot(tableNormal)
	local position = surfacePosition + tableNormal * 0.03
	return CFrame.lookAt(position, position - inward, tableNormal)
end

function findDecorationAnchor(tableModel, rawSeatId)
	local attachmentsFolder = tableModel:FindFirstChild("Attachments")
	if not attachmentsFolder then
		return nil
	end

	local candidateNames = {
		`{rawSeatId}Decoration`,
		`{rawSeatId}DecorationAnchor`,
		`{rawSeatId}DeskSetup`,
		`{rawSeatId}Marker`,
	}

	for _, candidateName in ipairs(candidateNames) do
		local candidate = attachmentsFolder:FindFirstChild(candidateName)
		if candidate then
			local attachment = candidate:IsA("Attachment") and candidate
				or candidate:FindFirstChildWhichIsA("Attachment")
			return attachment or candidate
		end
	end

	return nil
end

function findChairAnchor(tableModel, rawSeatId)
	local attachmentsFolder = tableModel:FindFirstChild("Attachments")
	if not attachmentsFolder then
		return nil
	end

	local candidateNames = {
		`{rawSeatId}Chair`,
		`{rawSeatId}ChairAnchor`,
		`{rawSeatId}Seat`,
	}

	for _, candidateName in ipairs(candidateNames) do
		local candidate = attachmentsFolder:FindFirstChild(candidateName)
		if candidate then
			local attachment = candidate:IsA("Attachment") and candidate
				or candidate:FindFirstChildWhichIsA("Attachment")
			return attachment or candidate
		end
	end

	return nil
end

function getAnchorCFrame(anchor)
	if anchor:IsA("Attachment") then
		return anchor.WorldCFrame
	end
	if anchor:IsA("BasePart") then
		return anchor.CFrame
	end
	if anchor:IsA("Model") then
		return anchor:GetPivot()
	end

	return CFrame.new()
end

function getTableSurfaceData(tableTop)
	local axisRecords = {
		{
			size = tableTop.Size.X,
			normal = tableTop.CFrame.RightVector,
		},
		{
			size = tableTop.Size.Y,
			normal = tableTop.CFrame.UpVector,
		},
		{
			size = tableTop.Size.Z,
			normal = -tableTop.CFrame.LookVector,
		},
	}

	table.sort(axisRecords, function(a, b)
		return a.size < b.size
	end)

	local normal = axisRecords[1].normal
	if normal:Dot(Vector3.yAxis) < 0 then
		normal = -normal
	end

	return normal, axisRecords[1].size * 0.5
end

function prepareDecorationModel(decorationModel)
	for _, descendant in ipairs(decorationModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

function settleDecorationOnTable(decorationModel, tableModel)
	decorationModel:PivotTo(getSettledDecorationCFrame(decorationModel, decorationModel:GetPivot(), tableModel))
end

function getSettledDecorationCFrame(decorationModel, targetCFrame, tableModel)
	local tableTop = tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return targetCFrame
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + tableNormal * halfThickness
	local surfaceAtPivot = targetCFrame.Position - tableNormal * (targetCFrame.Position - surfaceCenter):Dot(tableNormal)
	local lift = getDecorationSurfaceLift(decorationModel, targetCFrame, tableNormal) + TableDecorationSurfaceGap
	local correctedPosition = surfaceAtPivot + tableNormal * lift
	return targetCFrame + (correctedPosition - targetCFrame.Position)
end

function tweenModelPivot(model, targetCFrame)
	if not model or not model.Parent then
		return
	end

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = model:GetPivot()
	local connection = cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(cframeValue.Value)
		end
	end)

	local tween = TweenService:Create(
		cframeValue,
		TweenInfo.new(DecorationPresets.LayoutTweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Value = targetCFrame,
		}
	)
	tween:Play()
	tween.Completed:Once(function()
		connection:Disconnect()
		cframeValue:Destroy()
		if model.Parent then
			model:PivotTo(targetCFrame)
		end
	end)
end

function getDecorationSurfaceLift(decorationModel, modelCFrame, normal)
	local modelPivot = decorationModel:GetPivot()
	local minProjection = math.huge

	for _, descendant in ipairs(decorationModel:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end

		local relativeCFrame = modelPivot:ToObjectSpace(descendant.CFrame)
		local partCFrame = modelCFrame * relativeCFrame
		local halfSize = descendant.Size * 0.5
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local corner =
						partCFrame:PointToWorldSpace(Vector3.new(halfSize.X * x, halfSize.Y * y, halfSize.Z * z))
					minProjection = math.min(minProjection, corner:Dot(normal))
				end
			end
		end
	end

	if minProjection == math.huge then
		return 0
	end

	return modelCFrame.Position:Dot(normal) - minProjection
end

function getTableDecorationAssetFolder()
	return script.Assets:WaitForChild(TableDecorationAssetFolderName)
end

function getChairAssetFolder()
	return script.Assets:WaitForChild(ChairAssetFolderName)
end

function migrateWorkspaceTableDecoration()
	local workspaceAsset = Workspace:FindFirstChild(WorkspaceTableDecorationName)
	if not workspaceAsset then
		return
	end

	local assetFolder = getTableDecorationAssetFolder()
	local deskSetupIds = getDeskSetupIds()
	local movedExactAsset = false
	for _, child in ipairs(workspaceAsset:GetChildren()) do
		if child:IsA("Model") and deskSetupIds[child.Name] and not assetFolder:FindFirstChild(child.Name) then
			child.Parent = assetFolder
			movedExactAsset = true
		end
	end

	if movedExactAsset then
		if #workspaceAsset:GetChildren() == 0 then
			workspaceAsset:Destroy()
		end
		return
	end

	if assetFolder:FindFirstChild(DefaultTableDecorationAssetName) then
		workspaceAsset:Destroy()
		return
	end

	local defaultAsset
	if workspaceAsset:IsA("Model") then
		defaultAsset = workspaceAsset
		defaultAsset.Name = DefaultTableDecorationAssetName
	else
		defaultAsset = Instance.new("Model")
		defaultAsset.Name = DefaultTableDecorationAssetName
		for _, child in ipairs(workspaceAsset:GetChildren()) do
			child.Parent = defaultAsset
		end
		workspaceAsset:Destroy()
	end

	defaultAsset.Parent = assetFolder
end

function getDeskSetupIds()
	local deskSetupIds = {}
	for _, item in ipairs(EcoPresets.GrowthShopItems.desk) do
		deskSetupIds[item.id] = true
	end

	return deskSetupIds
end

return DecorationSystem
