-- Main: the starting point for all server-side game code.
-- It checks the map, sets up each player and starts the game systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)
local PlayerState = require(script.Parent.PlayerState)
local SafeZoneService = require(script.Parent.SafeZoneService)
local MonsterService = require(script.Parent.MonsterService)
local RoundService = require(script.Parent.RoundService)

-- Warns about any map folder that is missing from Workspace.
local function checkMap()
	for _, folderName in GameConfig.MapFolders do
		if not workspace:FindFirstChild(folderName) then
			warn("[TheLastLight] Missing folder in Workspace: " .. folderName)
		end
	end
end

local function onPlayerAdded(player: Player)
	Score.setup(player)
	PlayerState.setup(player) -- also spawns their character
end

checkMap()

Players.CharacterAutoLoads = false -- PlayerState decides when characters spawn
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- players who joined before this script ran
	onPlayerAdded(player)
end

SafeZoneService.start()
MonsterService.start()
RoundService.start() -- also spawns the mushrooms at the start of each round
log("Server started")
