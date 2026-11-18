-- GameConfig: one place for game settings that server and client scripts share.
-- Change values here instead of hunting for numbers inside scripts.

local GameConfig = {
	-- Set to false to hide the [TheLastLight] debug messages in the Output window.
	Debug = true,

	-- Folders you build in Workspace (in Studio). Scripts find map objects by these names.
	MapFolders = { "Map", "SafeZones", "MushroomSpawns" },

	-- Mushroom pickup
	PromptDistance = 8, -- how close (studs) the "Collect" prompt appears
	CollectDistance = 12, -- server-side limit; a bit larger than PromptDistance to allow for lag
}

return GameConfig
