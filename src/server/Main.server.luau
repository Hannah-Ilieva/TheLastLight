-- Main: the starting point for all server-side game code.
-- It checks the map, sets up each player's score and starts the round loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)
local RoundService = require(script.Parent.RoundService)

-- Warns about any missing map folder, then reports how many safe zones exist.
local function checkMap()
	for _, folderName in GameConfig.MapFolders do
		if not workspace:FindFirstChild(folderName) then
			warn("[TheLastLight] Missing folder in Workspace: " .. folderName)
		end
	end

	local safeZones = workspace:FindFirstChild("SafeZones")
	if safeZones then
		log("Safe zones found:", #safeZones:GetChildren())
	end
end

checkMap()

Players.PlayerAdded:Connect(Score.setup)
for _, player in Players:GetPlayers() do -- players who joined before this script ran
	Score.setup(player)
end

RoundService.start() -- also spawns the mushrooms at the start of each round
log("Server started")
