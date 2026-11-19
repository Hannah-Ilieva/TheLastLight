-- AudioController: the game's soundtrack, following the round phase.
--   Gather    the music-box song plays over night insects
--   Warning   the song speeds up and a heartbeat joins, faster and faster
--   Blackout  the song cuts out; a moment of near silence, then a low drone
--   Release   the drone fades and the song starts again
--   Dawn      birds sing
-- It also plays short effects for pickups, powers and being caught. Sounds are created
-- on this computer only; nothing here affects gameplay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SoundConfig = require(ReplicatedStorage.Shared.SoundConfig)
local NotifyController = require(script.Parent.NotifyController)

local SONG_WARNING_SPEED = 1.3 -- how fast the song gets by the end of the Warning
local HEARTBEAT_START_SPEED = 0.9
local HEARTBEAT_END_SPEED = 1.7
local SILENCE_BEFORE_DRONE = 0.8 -- seconds of near silence when the lights die
local STYLE_SOUND = { -- Notify style -> effect
	pickup = "Pickup",
	rare = "RarePickup",
	power = "SpeedBoost",
	shield = "ShieldBreak",
}

local AudioController = {}

local sounds: { [string]: Sound } = {}
local currentPhase: string? = nil

local function makeSound(name: string, looped: boolean): Sound
	local entry = SoundConfig[name]
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. entry.Id
	sound.Volume = 0
	sound.Looped = looped
	sound.Parent = SoundService
	sounds[name] = sound
	return sound
end

-- Fades a looping sound to `level` (0-1 of its configured volume), starting or
-- stopping it as needed.
local function fadeTo(name: string, level: number, seconds: number)
	local sound = sounds[name]
	local target = SoundConfig[name].Volume * level
	if level > 0 and not sound.IsPlaying then
		sound:Play()
	end
	local tween = TweenService:Create(sound, TweenInfo.new(seconds), { Volume = target })
	tween:Play()
	if level == 0 then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and sound.Volume == 0 then
				sound:Stop()
			end
		end)
	end
end

local function playOnce(name: string)
	local sound = sounds[name]
	sound.Volume = SoundConfig[name].Volume
	sound.TimePosition = 0
	sound:Play()
end

local function setSpeed(name: string, speed: number, seconds: number)
	TweenService:Create(sounds[name], TweenInfo.new(seconds, Enum.EasingStyle.Linear), { PlaybackSpeed = speed }):Play()
end

local function onPhase(phase: string)
	currentPhase = phase
	local warningSeconds = GameConfig.PhaseDurations.Warning * GameConfig.TimeScale

	if phase == "Lobby" or phase == "Exploring" then
		fadeTo("Dawn", 0, 1.5)
		fadeTo("Ambience", 1, 2)
		fadeTo("Song", phase == "Lobby" and 0.6 or 1, 2)
		setSpeed("Song", 1, 1)
		fadeTo("Heartbeat", 0, 0.5)
	elseif phase == "Warning" then
		setSpeed("Song", SONG_WARNING_SPEED, warningSeconds)
		sounds.Heartbeat.PlaybackSpeed = HEARTBEAT_START_SPEED
		fadeTo("Heartbeat", 1, 1)
		setSpeed("Heartbeat", HEARTBEAT_END_SPEED, warningSeconds)
	elseif phase == "Blackout" then
		-- The music stops sharply. Silence is part of the scare.
		for _, name in { "Song", "Heartbeat" } do
			sounds[name].Volume = 0
			sounds[name]:Stop()
		end
		fadeTo("Ambience", 0.25, 0.3)
		task.delay(SILENCE_BEFORE_DRONE, function()
			if currentPhase == "Blackout" then
				fadeTo("BlackoutDrone", 1, 1.5)
			end
		end)
	elseif phase == "Release" then
		fadeTo("BlackoutDrone", 0, 1.5)
		fadeTo("Ambience", 1, 2)
		sounds.Song.TimePosition = 0
		sounds.Song.PlaybackSpeed = 1
		fadeTo("Song", 1, 2.5)
	elseif phase == "Results" then
		for _, name in { "Song", "Heartbeat", "BlackoutDrone", "Ambience" } do
			fadeTo(name, 0, 2)
		end
		fadeTo("Dawn", 1, 3)
	end
end

function AudioController.start()
	for _, name in { "Song", "Ambience", "Heartbeat", "BlackoutDrone", "Dawn" } do
		makeSound(name, true)
	end
	for _, name in { "Pickup", "RarePickup", "SpeedBoost", "ShieldBreak", "Caught" } do
		makeSound(name, false)
	end

	NotifyController.shown:Connect(function(style)
		local name = STYLE_SOUND[style]
		if name then
			playOnce(name)
		end
	end)
	local player = Players.LocalPlayer
	player:GetAttributeChangedSignal("Caught"):Connect(function()
		if player:GetAttribute("Caught") then
			playOnce("Caught")
		end
	end)

	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		onPhase(ReplicatedStorage:GetAttribute("Phase"))
	end)
	onPhase(ReplicatedStorage:GetAttribute("Phase") or "Lobby")
end

return AudioController
