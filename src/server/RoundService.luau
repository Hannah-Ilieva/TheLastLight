-- RoundService: owns the round timer. It is the ONLY script that changes the phase.
-- It publishes the round state as attributes on ReplicatedStorage, which every
-- client can read (including players who join mid-round):
--   Phase        current phase name, e.g. "Exploring"
--   Cycle        current night (1-4), or 0 during Lobby and Results
--   PhaseEndsAt  server time when the phase ends (compare with workspace:GetServerTimeNow())

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)
local MushroomService = require(script.Parent.MushroomService)

local RoundService = {}

-- Announces a phase, then waits until it is over.
local function runPhase(phase: string, cycle: number)
	local duration = GameConfig.PhaseDurations[phase] * GameConfig.TimeScale
	ReplicatedStorage:SetAttribute("Cycle", cycle)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + duration)
	ReplicatedStorage:SetAttribute("Phase", phase) -- set last: scripts react to this one changing
	log(("Phase: %s (night %d, %.1fs)"):format(phase, cycle, duration))
	task.wait(duration)
end

-- Fresh mushrooms, scores back to 0, and everyone respawns at the trailhead.
local function resetRound()
	MushroomService.spawnAll()
	for _, player in Players:GetPlayers() do
		Score.reset(player)
		player:LoadCharacter()
	end
end

local function runRound()
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end

	resetRound()
	runPhase("Lobby", 0)
	for cycle = 1, GameConfig.CyclesPerRound do
		for _, phase in GameConfig.CyclePhases do
			runPhase(phase, cycle)
		end
	end
	runPhase("Results", 0)
end

-- Starts the endless round loop in the background.
function RoundService.start()
	task.spawn(function()
		while true do
			runRound()
		end
	end)
end

return RoundService
