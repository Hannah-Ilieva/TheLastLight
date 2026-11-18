-- GameConfig: one place for game settings that server and client scripts share.
-- Change values here instead of hunting for numbers inside scripts.

local GameConfig = {
	-- Set to false to hide the [TheLastLight] debug messages in the Output window.
	Debug = true,

	-- Folders you build in Workspace (in Studio). Scripts find map objects by these names.
	MapFolders = { "Map", "SafeZones", "MushroomSpawns", "PathLights" },

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
}

return GameConfig
