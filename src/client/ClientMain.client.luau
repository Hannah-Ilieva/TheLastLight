-- ClientMain: the starting point for code that runs on each player's computer
-- (HUD, sounds, visual effects). Gameplay decisions stay on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local log = require(ReplicatedStorage.Shared.Log)
local HUDController = require(script.Parent.HUDController)
local LightingController = require(script.Parent.LightingController)

HUDController.start()
LightingController.start()
log("Client started")
