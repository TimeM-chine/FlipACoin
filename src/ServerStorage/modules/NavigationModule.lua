---- ================================================================================
---- Navigation module, navigate a model to a part
---- ================================================================================

---- services ----
local PFS = game:GetService("PathfindingService")


local NavigationModule = {}
NavigationModule.__index = NavigationModule
NavigationModule.model = nil
NavigationModule.myRootPart = nil
NavigationModule.myHumanoid = nil
NavigationModule.moveCor = nil


function NavigationModule.new(model)
    local ins = setmetatable({}, NavigationModule)
    ins.model = model
    ins.myRootPart = model:WaitForChild("HumanoidRootPart")
    ins.myHumanoid = model:WaitForChild("Humanoid")
    return ins
end


function NavigationModule:MoveToPart(part:Part)
    print(part)
    local path = PFS:FindPathAsync(self.myRootPart.CFrame.Position, part.CFrame.Position)
    local wayPoints = path:GetWaypoints()
    path:
    print(path, wayPoints)
    if self.moveCor then
        coroutine.close(self.moveCor)
    end
    self.moveCor = coroutine.create(function()
        for _, wayPoint in ipairs(wayPoints) do
            if wayPoint.Action == Enum.PathWaypointAction.Walk then
                self.myHumanoid:MoveTo(wayPoint.Position)
            elseif wayPoint.Action == Enum.PathWaypointAction.Jump then
                self.myHumanoid.Jump = true
                self.myHumanoid:MoveTo(wayPoint.Position)
            end
        end
    end)

    coroutine.resume(self.moveCor)

end


function NavigationModule:ChasingPlayer(player:Player)
    local targetPart = player.Character.HumanoidRootPart
    self:MoveToPart(targetPart)
end




return NavigationModule
