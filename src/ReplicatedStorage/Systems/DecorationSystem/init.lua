---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

---- requires ----
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Keys = require(Replicated.configs.Keys)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass

---- client variables ----

local RuntimeFolderName = "DecorationsRuntime"
local TableDecorationAssetFolderName = "TableDecoration"
local DefaultTableDecorationAssetName = "Default"
local WorkspaceTableDecorationName = "TableDecoration"
local TableDecorationSurfaceGap = 0.03

local DecorationSystem: Types.System = {
	whiteList = {
		"RefreshPlayerDecoration",
		"RefreshAllDecorations",
		"ClearPlayerDecoration",
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

	local deskSetupId = playerIns:GetOneData(dataKey.equippedDeskSetup)
	local assetModel = getDecorationAsset(deskSetupId)
	if not assetModel then
		warn(`[DecorationSystem] Missing table decoration model asset for desk setup: {deskSetupId}`)
		return
	end

	local runtimeFolder = getRuntimeFolder(assignment.tableModel)
	local decorationName = `{assignment.rawSeatId}Decoration`
	local existingDecoration = runtimeFolder:FindFirstChild(decorationName)
	if existingDecoration then
		existingDecoration:Destroy()
	end

	local decorationModel = assetModel:Clone()
	decorationModel.Name = decorationName
	prepareDecorationModel(decorationModel)
	decorationModel:PivotTo(getDecorationCFrame(assignment))
	settleDecorationOnTable(decorationModel, assignment.tableModel)
	decorationModel.Parent = runtimeFolder

	self._playerDecorations[player.UserId] = {
		model = decorationModel,
		rawSeatId = assignment.rawSeatId,
		tableModel = assignment.tableModel,
	}
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
	self._playerDecorations[player.UserId] = nil
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
			local attachment = candidate:IsA("Attachment") and candidate or candidate:FindFirstChildWhichIsA("Attachment")
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
	local tableTop = tableModel:FindFirstChild("TableTop")
	if not tableTop then
		return
	end

	local tableNormal, halfThickness = getTableSurfaceData(tableTop)
	local surfaceCenter = tableTop.Position + tableNormal * halfThickness
	local pivot = decorationModel:GetPivot()
	local surfaceAtPivot = pivot.Position - tableNormal * (pivot.Position - surfaceCenter):Dot(tableNormal)
	local lift = getDecorationSurfaceLift(decorationModel, pivot, tableNormal) + TableDecorationSurfaceGap
	local correctedPosition = surfaceAtPivot + tableNormal * lift
	decorationModel:PivotTo(pivot + (correctedPosition - pivot.Position))
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
