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
local PlayerState = require(script.Parent.PlayerState)
local PowerService = require(script.Parent.PowerService)

local CHECK_INTERVAL = 0.25 -- how often a phase checks whether everyone was caught

local RoundService = {}

-- Announces a phase, then waits until it is over. With `canEndEarly`, it stops as soon as
-- every player has been caught and returns false.
local function runPhase(phase: string, cycle: number, canEndEarly: boolean?): boolean
	local duration = GameConfig.PhaseDurations[phase] * GameConfig.TimeScale
	ReplicatedStorage:SetAttribute("Cycle", cycle)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + duration)
	ReplicatedStorage:SetAttribute("Phase", phase) -- set last: scripts react to this one changing
	log(("Phase: %s (night %d, %.1fs)"):format(phase, cycle, duration))

	local endsAt = os.clock() + duration
	while os.clock() < endsAt do
		if canEndEarly and not PlayerState.anyoneLeft() then
			return false
		end
		task.wait(math.min(CHECK_INTERVAL, endsAt - os.clock()))
	end
	return true
end

-- Fresh mushrooms, scores back to 0, no powers, nobody caught, everyone back at the trailhead.
local function resetRound()
	MushroomService.spawnAll()
	for _, player in Players:GetPlayers() do
		Score.reset(player)
		PowerService.clear(player)
	end
	PlayerState.resetRound()
end

-- Gives every player who is still in the woods (not caught) a bonus.
-- `stat` (optional) also counts the event in that round stat.
local function rewardSurvivors(amount: number, stat: string?)
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute("Caught") then
			Score.addBonus(player, amount)
			if stat then
				Score.addStat(player, stat, 1)
			end
		end
	end
end

-- Plays every night of the round, stopping early if everyone is caught.
-- Survivors earn a bonus after each blackout and a bigger one at dawn.
local function runNights()
	for cycle = 1, GameConfig.CyclesPerRound do
		for _, phase in GameConfig.CyclePhases do
			if not runPhase(phase, cycle, true) then
				log("Everyone was caught - ending the round early")
				return
			end
			if phase == "Blackout" then
				rewardSurvivors(GameConfig.Bonus.PerBlackout, "RoundBlackouts")
			end
		end
	end
	rewardSurvivors(GameConfig.Bonus.Dawn)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("SurvivedDawn", not player:GetAttribute("Caught"))
	end
	log("Dawn: survivors rewarded")
end

local function runRound()
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end

	resetRound()
	runPhase("Lobby", 0)
	runNights()
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
