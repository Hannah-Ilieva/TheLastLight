-- Main: the starting point for all server-side game code.
-- It checks the map, sets up each player's score and starts the game systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)
local RoundService = require(script.Parent.RoundService)
local SafeZoneService = require(script.Parent.SafeZoneService)

-- Warns about any map folder that is missing from Workspace.
local function checkMap()
	for _, folderName in GameConfig.MapFolders do
		if not workspace:FindFirstChild(folderName) then
			warn("[TheLastLight] Missing folder in Workspace: " .. folderName)
		end
	end
end

checkMap()

Players.PlayerAdded:Connect(Score.setup)
for _, player in Players:GetPlayers() do -- players who joined before this script ran
	Score.setup(player)
end

SafeZoneService.start()
RoundService.start() -- also spawns the mushrooms at the start of each round
log("Server started")
