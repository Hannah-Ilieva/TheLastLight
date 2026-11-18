-- ClientMain: the starting point for code that runs on each player's computer
-- (HUD, sounds, visual effects). Gameplay decisions stay on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local log = require(ReplicatedStorage.Shared.Log)

log("Client started")
