-- HUDController: draws the round HUD (phase + countdown, night number, warning banner).
-- It only DISPLAYS the round state that RoundService publishes on ReplicatedStorage;
-- it never decides anything about the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PHASE_TEXT = {
	Lobby = "GET READY",
	Exploring = "GATHER",
	Warning = "FIND THE LIGHT",
	Blackout = "BLACKOUT",
	Release = "THE LIGHT RETURNS",
	Results = "DAWN",
}
local WARNING_MESSAGE = "The song is fading — find the light!"
local BANNER_SECONDS = 3
local TEXT_COLOR = Color3.fromRGB(235, 240, 230)
local WARNING_COLOR = Color3.fromRGB(255, 200, 110)

local HUDController = {}

-- Creates a transparent, auto-scaling text label. `props` sets position and size.
local function newLabel(name: string, props, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = TEXT_COLOR
	label.TextStrokeTransparency = 0.4 -- dark outline keeps text readable on bright areas
	label.TextScaled = true
	for key, value in props do
		label[key] = value
	end
	label.Parent = parent
	return label
end

local function formatTime(seconds: number): string
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

function HUDController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RoundHUD"
	gui.ResetOnSpawn = false -- keep the HUD when the character respawns
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local phaseLabel = newLabel("Phase", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 36),
	}, gui)
	local nightLabel = newLabel("Night", {
		Position = UDim2.new(0, 16, 0, 8),
		Size = UDim2.new(0.25, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, gui)
	local banner = newLabel("WarningBanner", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 0),
		Size = UDim2.new(0.8, 0, 0, 48),
		Text = WARNING_MESSAGE,
		TextColor3 = WARNING_COLOR,
		Visible = false,
	}, gui)

	-- Recalculates the text from the current attributes.
	local function refresh()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		if not phase then
			phaseLabel.Text = "Waiting for server..."
			return
		end
		local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
		local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		phaseLabel.Text = (PHASE_TEXT[phase] or phase) .. " — " .. formatTime(remaining)
		phaseLabel.TextColor3 = (phase == "Warning" or phase == "Blackout") and WARNING_COLOR or TEXT_COLOR

		local cycle = ReplicatedStorage:GetAttribute("Cycle") or 0
		nightLabel.Visible = cycle > 0
		nightLabel.Text = ("NIGHT %d / %d"):format(cycle, GameConfig.CyclesPerRound)
	end

	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		refresh()
		if ReplicatedStorage:GetAttribute("Phase") == "Warning" then
			banner.Visible = true
			task.delay(BANNER_SECONDS, function()
				banner.Visible = false
			end)
		end
	end)

	-- Update the countdown a few times per second.
	task.spawn(function()
		while true do
			refresh()
			task.wait(0.25)
		end
	end)
end

return HUDController
