-- Main: the starting point for all server-side game code.
-- For now it only checks that the Workspace map is set up the way later scripts expect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local function debugPrint(...)
	if GameConfig.Debug then
		print("[TheLastLight]", ...)
	end
end

-- Warns about any missing map folder, then reports how many safe zones exist.
local function checkMap()
	for _, folderName in GameConfig.MapFolders do
		if not workspace:FindFirstChild(folderName) then
			warn("[TheLastLight] Missing folder in Workspace: " .. folderName)
		end
	end

	local safeZones = workspace:FindFirstChild("SafeZones")
	if safeZones then
		debugPrint("Safe zones found:", #safeZones:GetChildren())
	end
end

checkMap()
debugPrint("Server started")
