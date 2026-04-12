--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1 add cover
--Last Modified: 2024-05-23 7:34:00
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

---- requires ----
local MusicPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, sfxVolume

local MusicSystem: Types.System = {
	Remotes = {},
	whiteList = {},
	IsLoaded = false,
}
MusicSystem.__index = MusicSystem

if IsServer then
	MusicSystem.Client = setmetatable({}, MusicSystem)
	MusicSystem.AllClients = setmetatable({}, MusicSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	MusicSystem.Server = setmetatable({}, MusicSystem)
	LocalPlayer = Players.LocalPlayer
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end
local LoopedMusic = {}

local function GetGlobalSoundVolumeFactor()
	return 1
end

local function PlayBGMusic(musicData, fadeIn)
	fadeIn = fadeIn or 2
	local musicName = musicData.name
	local volume = musicData.volume or 1
	local resId = MusicPresets.Definition[musicName]
	if resId == nil then
		print(`music {musicName} is not exist`)
		return
	end
	local _name = "BGSound." .. musicName
	local music = workspace["BGSoundsFolder"]:FindFirstChild(_name) :: Sound
	if music == nil then
		music = Instance.new("Sound")
		music.Volume = 0
		music.Name = _name
		music.SoundId = resId
		music.Parent = workspace["BGSoundsFolder"]
		-- AllPlayedMusic[music] = volume
	end
	music.Looped = true
	music:Play()
	volume *= GetGlobalSoundVolumeFactor()
	local tweenTime = (math.max(volume - music.Volume, 0) / volume) * fadeIn
	if tweenTime == 0 then
		return
	end
	local tween = TweenService:Create(music, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {
		Volume = volume,
	})
	tween:Play()
end

local function StopBgMusic(musicData, fadeOut)
	fadeOut = fadeOut or 2
	local musicName = musicData.name
	local volume = musicData.volume or 1
	volume *= GetGlobalSoundVolumeFactor()
	local _name = "BGSound." .. musicName
	local music = workspace["BGSoundsFolder"]:FindFirstChild(_name) :: Sound
	if music ~= nil then
		local tweenTime = math.min((music.Volume / volume), 1.0) * fadeOut
		local tween = TweenService:Create(music, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {
			Volume = 0,
		})
		tween.Completed:Connect(function(playState)
			if playState == Enum.PlaybackState.Completed then
				music:Pause()
			end
		end)
		tween:Play()
	end
end

function MusicSystem:Init()
	GetSystemMgr()
end

function MusicSystem:PlayMusic(
	sender,
	player,
	args: {
		musicKey: string,
		musicName: string,
		part: Instance?,
		looped: boolean?,
		volume: number?,
	}
)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		if (not player) or (not player:IsA("Player")) then
			args.unreliable = true
			self.AllClients:PlayMusic(args)
		else
			self.Client:PlayMusic(player, args)
		end
	else
		local musicGroup = args.musicGroup or "SFX"
		local musicName = args.musicName
		local part = args.part or LocalPlayer.Character.HumanoidRootPart
		if not part then
			return
		end

		local volume = SoundService[musicGroup].Volume
		local oldMusic = part:FindFirstChild(`{musicGroup}_{musicName}`)
		if oldMusic then
			oldMusic.Volume = volume
			oldMusic:Play()
			return
		end
		local music = SoundService[musicGroup]:FindFirstChild(musicName):Clone()
		music.Name = `{musicGroup}_{musicName}`
		music.Parent = part
		music.Looped = args.looped or false
		music.Volume = volume
		music.PlaybackSpeed = args.playbackSpeed or 1
		music:Play()

		if music.Looped then
			table.insert(LoopedMusic, music)
		end
	end
end

function MusicSystem:Play2dMusic(sender, player, args: { musicName: string, cover: boolean, musicGroup: string })
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.Client:Play2dMusic(player, args)
	else
		local musicName = args.musicName
		local cover = args.cover or false
		local musicGroup = args.musicGroup or "SFX"
		local music = SoundService:FindFirstChild(musicGroup):FindFirstChild(musicName) :: Sound
		if music then
			if cover or not music.IsPlaying then
				music:Play()
			end
		else
			warn(`music {musicName} is not exist`)
		end
	end
end

function MusicSystem:Stop2dMusic(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.Client:Stop2dMusic(player, args)
	else
		local musicName = args.musicName
		local musicGroup = args.musicGroup or "SFX"
		local music = SoundService:FindFirstChild(musicGroup):FindFirstChild(musicName) :: Sound
		if music then
			music:Stop()
		end
	end
end

function MusicSystem:SetBgmVolume(volume)
	SoundService.bgm.Volume = volume * SoundService.bgm:GetAttribute("factor")
	for i = #LoopedMusic, 1, -1 do
		local music = LoopedMusic[i]
		if music.Parent then
			music.Volume = volume * music:GetAttribute("factor")
		else
			table.remove(LoopedMusic, i)
		end
	end
end

function MusicSystem:SetSfxVolume(volume)
	SoundService.SFX.Volume = volume * 0.5
	-- SoundService.pet.Volume = volume * 0.5
end

function MusicSystem:SetWeatherSfxVolume(volume)
	SoundService.weather.Volume = volume
end

return MusicSystem
