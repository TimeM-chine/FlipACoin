local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Teams = game:GetService("Teams")

---- services ----
local Replicated = game.ReplicatedStorage

local BindableEvents = Replicated.BindableEvents
local RemoteEvents = Replicated.RemoteEvents
---- requires -----
local CreateModule = require(Replicated.modules.CreateModule)
local GameConfig = require(Replicated.configs.GameConfig)

local playerStatus = GameConfig.playerStatus

local DamageModule = {}


function DamageModule.AHurtB(A:Player, B:Player, damage, cause)
    if not B or not B:IsA("Player") then
        warn(`Victim {B} is not a Player.`)
        return
    end

    if A:IsA("Player") then

        if A.Team == B.Team then
            return
        end

        local victimChar = B.Character
        victimChar.Murderer.Value = A.UserId

        local isAssist = true
        for _, nv in victimChar.Damager:GetChildren() do
            if nv.Value == A.UserId then
                isAssist = false
                break
            end
        end
        if isAssist then
            CreateModule.CreateValue("NumberValue", "UserId", A.UserId, victimChar.Damager)
        end
    else

    end

    if table.find(GameConfig.bladeWeapons, cause) then
        local sound = SoundService.bladeHit:Clone()
        sound.Parent = A.Character.HumanoidRootPart
        sound:Play()
    elseif table.find(GameConfig.bluntWeapons, cause) then
        local sound = SoundService.bluntHit:Clone()
        sound.Parent = A.Character.HumanoidRootPart
        sound:Play()
    elseif cause == "tennisRacket" then
        local sound = SoundService.tennisHit:Clone()
        sound.Parent = A.Character.HumanoidRootPart
        sound:Play()
    end

    B.Character.Humanoid:TakeDamage(damage)
    local animator = B.Character.Humanoid:FindFirstChild("Animator")
    local anim = B.Character:FindFirstChild("hitAnim")
    if animator and anim then
        local track = animator:LoadAnimation(anim)
        track:Play()
    end

    if B.Character.Humanoid.Health <= 0 and B.Character.Status.Value ~= playerStatus.died then
        B.Character.Status.Value = playerStatus.died
        BindableEvents.AKilledB:Fire(A, B, cause)
        RemoteEvents.AKillB:FireAllClients(A.Name, A.TeamColor.Color, B.Name, B.TeamColor.Color, cause)
        RemoteEvents.BeKilled:FireClient(B, A)
    end
end



return DamageModule