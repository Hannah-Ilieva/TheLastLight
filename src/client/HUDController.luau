-- HUDController: draws the round HUD:
--   top centre   phase name + countdown, and "SAFE IN THE LIGHT" under it while safe
--   upper left   night number, with one moon per night
--   upper right  your points
--   centre       the warning banner when the song fades
--   bottom       the caught message (with a short fade from black)
-- It only DISPLAYS what the server publishes (attributes and leaderstats); it never
-- decides anything about the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local UIStyle = require(script.Parent.UIStyle)

local PHASE_TEXT = {
	Lobby = "Get Ready",
	Exploring = "Gather",
	Warning = "Find the Light",
	Blackout = "Blackout",
	Release = "The Light Returns",
	Results = "Dawn",
}
local DANGER_PHASES = { Warning = true, Blackout = true } -- phase text turns warm/orange
local WARNING_MESSAGE = "The song is fading — find the light!"
local BANNER_SECONDS = 3
local SAFE_TEXT = "SAFE IN THE LIGHT"
local CAUGHT_TEXT = "Caught in the dark — spectating until next round"
local CAUGHT_FLASH_SECONDS = 0.8 -- a short fade from black, played once per catch
local MOON_ON = Color3.fromRGB(220, 230, 255)
local MOON_OFF = Color3.fromRGB(50, 60, 70)

local HUDController = {}

local player = Players.LocalPlayer

local function formatTime(seconds: number): string
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

local function fade(item: GuiObject, property: string, value: number, seconds: number)
	TweenService:Create(item, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { [property] = value }):Play()
end

-- Top centre: phase name on the left, countdown on the right.
local function buildPhasePanel(gui: ScreenGui)
	local panel = UIStyle.panel("PhasePanel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(340, 50),
	}, gui)
	local phase = UIStyle.label("Phase", {
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -110, 1, -12),
		Font = UIStyle.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local timer = UIStyle.label("Timer", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 10),
		Size = UDim2.new(0, 80, 1, -20),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, panel)
	return panel, phase, timer
end

-- Upper left: "NIGHT 2" and one moon per night (filled = reached).
local function buildNightPanel(gui: ScreenGui)
	local panel = UIStyle.panel("NightPanel", {
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(150, 50),
	}, gui)
	local label = UIStyle.label("Night", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local moons = {}
	for i = 1, GameConfig.CyclesPerRound do
		local moon = Instance.new("Frame")
		moon.Name = "Moon" .. i
		moon.Size = UDim2.fromOffset(12, 12)
		moon.Position = UDim2.fromOffset(12 + (i - 1) * 20, 30)
		moon.BorderSizePixel = 0
		moon.BackgroundColor3 = MOON_OFF
		Instance.new("UICorner", moon).CornerRadius = UDim.new(1, 0)
		moon.Parent = panel
		moons[i] = moon
	end
	return panel, label, moons
end

-- Upper right: points from leaderstats (set by the server).
local function buildPointsPanel(gui: ScreenGui)
	local panel = UIStyle.panel("PointsPanel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 10),
		Size = UDim2.fromOffset(130, 50),
	}, gui)
	UIStyle.label("Caption", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 14),
		Text = "POINTS",
		TextColor3 = UIStyle.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)
	local value = UIStyle.label("Value", {
		Position = UDim2.fromOffset(12, 20),
		Size = UDim2.new(1, -24, 0, 24),
		Text = "0",
		TextColor3 = UIStyle.Warm,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, panel)

	task.spawn(function()
		local points = player:WaitForChild("leaderstats"):WaitForChild("Points")
		local function refresh()
			value.Text = tostring(points.Value)
		end
		points.Changed:Connect(refresh)
		refresh()
	end)
end

function HUDController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RoundHUD"
	gui.ResetOnSpawn = false -- keep the HUD when the character respawns
	gui.Parent = player:WaitForChild("PlayerGui")

	local _, phaseLabel, timerLabel = buildPhasePanel(gui)
	local nightPanel, nightLabel, moons = buildNightPanel(gui)
	buildPointsPanel(gui)

	local banner = UIStyle.label("WarningBanner", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 0),
		Size = UDim2.new(0.8, 0, 0, 54),
		Font = UIStyle.TitleFont,
		Text = WARNING_MESSAGE,
		TextColor3 = UIStyle.Warm,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}, gui)
	local safeLabel = UIStyle.label("Safe", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 66),
		Size = UDim2.fromOffset(260, 22),
		Text = SAFE_TEXT,
		TextColor3 = UIStyle.Warm,
		Visible = false,
	}, gui)
	local caughtLabel = UIStyle.label("Caught", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.new(0.8, 0, 0, 30),
		Text = CAUGHT_TEXT,
		Visible = false,
	}, gui)
	local flash = Instance.new("Frame")
	flash.Name = "CaughtFlash"
	flash.Position = UDim2.fromOffset(0, -80) -- also covers Roblox's top bar
	flash.Size = UDim2.new(1, 0, 1, 80)
	flash.BackgroundColor3 = Color3.new(0, 0, 0)
	flash.BackgroundTransparency = 1
	flash.ZIndex = 0 -- behind the text
	flash.Parent = gui

	-- The server sets "Safe" and "Caught" attributes on our Player; we only show them.
	local function refreshSafe()
		safeLabel.Visible = player:GetAttribute("Safe") == true
	end
	local function refreshCaught()
		local caught = player:GetAttribute("Caught") == true
		if caught and not caughtLabel.Visible then
			flash.BackgroundTransparency = 0
			fade(flash, "BackgroundTransparency", 1, CAUGHT_FLASH_SECONDS)
		end
		caughtLabel.Visible = caught
	end
	player:GetAttributeChangedSignal("Safe"):Connect(refreshSafe)
	player:GetAttributeChangedSignal("Caught"):Connect(refreshCaught)
	refreshSafe()
	refreshCaught()

	-- Recalculates the text from the current round attributes.
	local function refresh()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		if not phase then
			phaseLabel.Text = "Waiting..."
			timerLabel.Text = ""
			return
		end
		local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
		local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		local color = DANGER_PHASES[phase] and UIStyle.Warm or UIStyle.Text
		phaseLabel.Text = PHASE_TEXT[phase] or phase
		phaseLabel.TextColor3 = color
		timerLabel.Text = formatTime(remaining)
		timerLabel.TextColor3 = color

		local cycle = ReplicatedStorage:GetAttribute("Cycle") or 0
		nightPanel.Visible = cycle > 0
		nightLabel.Text = ("NIGHT %d / %d"):format(cycle, GameConfig.CyclesPerRound)
		for i, moon in moons do
			moon.BackgroundColor3 = i <= cycle and MOON_ON or MOON_OFF
		end
	end

	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		refresh()
		if ReplicatedStorage:GetAttribute("Phase") == "Warning" then
			fade(banner, "TextTransparency", 0, 0.3)
			fade(banner, "TextStrokeTransparency", 0.5, 0.3)
			task.delay(BANNER_SECONDS, function()
				fade(banner, "TextTransparency", 1, 0.6)
				fade(banner, "TextStrokeTransparency", 1, 0.6)
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
