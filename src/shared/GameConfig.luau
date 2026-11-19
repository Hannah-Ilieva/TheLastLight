-- GameConfig: one place for game settings that server and client scripts share.
-- Change values here instead of hunting for numbers inside scripts.

local GameConfig = {
	-- Set to false to hide the [TheLastLight] debug messages in the Output window.
	Debug = true,

	-- Folders you build in Workspace (in Studio). Scripts find map objects by these names.
	MapFolders = { "Map", "SafeZones", "MushroomSpawns", "PathLights", "MonsterSpawns" },

	-- Mushroom pickup
	PromptDistance = 8, -- how close (studs) the "Collect" prompt appears
	CollectDistance = 12, -- server-side limit; a bit larger than PromptDistance to allow for lag

	-- Round timing, in seconds. A round is Lobby, then CyclesPerRound cycles, then Results.
	TimeScale = 0.5, -- TEMPORARY for testing: halves every duration. Set to 1 for real rounds.
	PhaseDurations = {
		Lobby = 15,
		Exploring = 28,
		Warning = 7,
		Blackout = 12,
		Release = 3,
		Results = 10,
	},
	CyclePhases = { "Exploring", "Warning", "Blackout", "Release" }, -- order within one cycle
	CyclesPerRound = 4,

	-- Phases in which mushrooms can be collected.
	CollectPhases = { Exploring = true, Warning = true },

	-- Phases in which safe lights are SHOWN and PROTECT players. One setting for both,
	-- so what players see always matches what the server checks.
	SafeZonePhases = { Warning = true, Blackout = true },

	-- Survival bonus points: a little for every blackout survived, more for reaching dawn.
	-- Caught players keep the points and bonuses they already earned.
	Bonus = {
		PerBlackout = 1,
		Dawn = 5,
	},

	-- Phases in which players may change their look in the wardrobe (see SkinConfig).
	WardrobePhases = { Lobby = true, Results = true },

	-- Power mushrooms (see MushroomConfig). A player carries at most one unused power.
	Powers = {
		UsePhases = { Exploring = true, Warning = true, Blackout = true, Release = true },
		SpeedBoostWalkSpeed = 26, -- normal walking speed is 16
		SpeedBoostSeconds = 4,
		ShieldKnockback = 12, -- studs the monster is pushed back when a Guardian Cap blocks it
		ShieldStunSeconds = 2.5, -- how long the monster stands still after hitting a shield
	},

	-- The monster hunts only during Blackout.
	Monster = {
		SpeedByNight = { 11, 13, 14, 15 }, -- studs per second; players walk at 16, so running away works
		CatchDistance = 4, -- studs between the monster and a player for a catch
		MinSpawnDistance = 35, -- it never appears closer than this to any player
	},
}

return GameConfig
