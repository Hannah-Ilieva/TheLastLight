-- ClientMain: the starting point for code that runs on each player's computer
-- (HUD, sounds, visual effects). Gameplay decisions stay on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

if GameConfig.Debug then
	print("[TheLastLight] Client started")
end
