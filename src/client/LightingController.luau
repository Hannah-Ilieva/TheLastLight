-- LightingController: changes the sky, fog, colour grading, path lamps and safe lights
-- to match the round phase. It runs on each player's computer because lighting is purely
-- visual: it reacts to the Phase attribute that RoundService sets, and never decides
-- anything. (Safety in the dark is checked by the server's safe-zone code.)
--
-- Safe lights stay hidden until the Warning, so players can't just wait beside them;
-- they must remember where the refuges are and run when the song fades. Every piece of
-- a safe light that glows (floor circle, runes, beacon flame, fireflies, hum) is tagged
-- "SafeGlow" by the map generator.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Looks for each phase. "Lighting" values go on the Lighting service, "Atmosphere" on
-- its Atmosphere (the fog) and "Grade" on the colour correction effect.
local PRESETS = {
	Night = {
		Lighting = { ClockTime = 0, Brightness = 1, Ambient = rgb(30, 40, 45), OutdoorAmbient = rgb(60, 88, 92), ExposureCompensation = 0 },
		Atmosphere = { Density = 0.4, Offset = 0.1, Color = rgb(60, 105, 105), Decay = rgb(25, 45, 50), Haze = 1 },
		Grade = { Brightness = 0, Contrast = 0.12, Saturation = -0.1, TintColor = rgb(220, 235, 240) },
	},
	-- Dark, but trees still stand out as silhouettes against slightly lighter fog.
	Blackout = {
		Lighting = { ClockTime = 0, Brightness = 0.3, Ambient = rgb(16, 20, 26), OutdoorAmbient = rgb(30, 40, 48), ExposureCompensation = -0.2 },
		Atmosphere = { Density = 0.45, Offset = 0.1, Color = rgb(30, 46, 54), Decay = rgb(12, 20, 24), Haze = 1 },
		Grade = { Brightness = -0.02, Contrast = 0.22, Saturation = -0.35, TintColor = rgb(195, 210, 230) },
	},
	Dawn = {
		Lighting = { ClockTime = 6.4, Brightness = 2, Ambient = rgb(90, 85, 80), OutdoorAmbient = rgb(150, 140, 125), ExposureCompensation = 0 },
		Atmosphere = { Density = 0.3, Offset = 0.2, Color = rgb(200, 190, 170), Decay = rgb(150, 130, 110), Haze = 0.5 },
		Grade = { Brightness = 0.02, Contrast = 0.05, Saturation = 0, TintColor = rgb(255, 240, 220) },
	},
}
local PHASE_PRESET = {
	Lobby = "Night",
	Exploring = "Night",
	Warning = "Night",
	Blackout = "Blackout",
	Release = "Night",
	Results = "Dawn",
}
-- How long (seconds) the change into each phase takes. Blackout is a sharp cut.
local FADE_SECONDS = {
	Blackout = 0.3,
	Release = GameConfig.PhaseDurations.Release * GameConfig.TimeScale, -- fade up over the whole phase
	Results = 3,
}
local DEFAULT_FADE = 1.5

-- Safe lights are shown in GameConfig.SafeZonePhases (the same phases in which the
-- server protects players).
local SAFE_ZONE_PHASES = GameConfig.SafeZonePhases
local SAFE_GLOW_TAG = "SafeGlow"
local SAFE_GLOW_REVEAL_SECONDS = 0.5

-- Warning flicker: each tick, every lamp has a chance to blink off. The chance grows
-- from MIN to MAX as the warning runs out, so flicker gets faster (but never strobes).
local FLICKER_TICK = 0.1
local FLICKER_MIN_CHANCE = 0.03
local FLICKER_MAX_CHANCE = 0.3

local LightingController = {}

local currentPhase: string? = nil
local pathLights: Folder
local rng = Random.new()

local function tweenTo(target: Instance, properties, seconds: number)
	TweenService:Create(target, TweenInfo.new(seconds, Enum.EasingStyle.Sine), properties):Play()
end

local function setLamp(lamp: Instance, on: boolean)
	local lantern = lamp:FindFirstChild("Lantern")
	if not lantern then
		return
	end
	lantern.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local light = lantern:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = on
	end
end

local function setAllLamps(on: boolean)
	for _, lamp in pathLights:GetChildren() do
		setLamp(lamp, on)
	end
end

-- Shows or hides one glowing piece of a safe light: the part fades to its
-- "GlowTransparency", and its lights, particles and sounds switch with it.
local function setGlow(item: Instance, visible: boolean, fade: number)
	if item:IsA("BasePart") then
		local shown = item:GetAttribute("GlowTransparency") or 0
		tweenTo(item, { Transparency = visible and shown or 1 }, fade)
	end
	for _, child in item:GetDescendants() do
		if child:IsA("Light") or child:IsA("ParticleEmitter") then
			child.Enabled = visible
		elseif child:IsA("Sound") then
			if visible and not child.IsPlaying then
				child:Play()
			elseif not visible then
				child:Stop()
			end
		end
	end
end

local function setAllSafeGlow(visible: boolean, fade: number)
	for _, item in CollectionService:GetTagged(SAFE_GLOW_TAG) do
		setGlow(item, visible, fade)
	end
end

-- Runs while the phase is Warning; stops by itself when the phase changes.
local function flicker()
	local duration = GameConfig.PhaseDurations.Warning * GameConfig.TimeScale
	while currentPhase == "Warning" do
		local remaining = (ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow()
		local progress = math.clamp(1 - remaining / duration, 0, 1)
		local chance = FLICKER_MIN_CHANCE + (FLICKER_MAX_CHANCE - FLICKER_MIN_CHANCE) * progress
		for _, lamp in pathLights:GetChildren() do
			setLamp(lamp, rng:NextNumber() > chance)
		end
		task.wait(FLICKER_TICK)
	end
end

-- Moves the scene to the look for `phase`. `instant` skips the fade (used on join).
local function applyPhase(phase: string, instant: boolean)
	currentPhase = phase
	local preset = PRESETS[PHASE_PRESET[phase] or "Night"]
	local fade = instant and 0 or (FADE_SECONDS[phase] or DEFAULT_FADE)

	tweenTo(Lighting, preset.Lighting, fade)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		tweenTo(atmosphere, preset.Atmosphere, fade)
	end
	local grade = Lighting:FindFirstChild("Grade")
	if grade then
		tweenTo(grade, preset.Grade, fade)
	end

	setAllLamps(phase ~= "Blackout")
	local showSafeLights = SAFE_ZONE_PHASES[phase] == true
	local glowFade = fade -- hide at the same speed as the lighting change...
	if showSafeLights and not instant then
		glowFade = SAFE_GLOW_REVEAL_SECONDS -- ...but reveal quickly, so players can react
	end
	setAllSafeGlow(showSafeLights, glowFade)
	if phase == "Warning" then
		task.spawn(flicker)
	end
end

function LightingController.start()
	pathLights = workspace:WaitForChild("PathLights")
	-- Anything that loads in late (streaming) should match the current phase.
	pathLights.ChildAdded:Connect(function(lamp)
		setLamp(lamp, currentPhase ~= "Blackout")
	end)
	CollectionService:GetInstanceAddedSignal(SAFE_GLOW_TAG):Connect(function(item)
		setGlow(item, SAFE_ZONE_PHASES[currentPhase] == true, 0)
	end)

	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		applyPhase(ReplicatedStorage:GetAttribute("Phase"), false)
	end)
	applyPhase(ReplicatedStorage:GetAttribute("Phase") or "Lobby", true)
end

return LightingController
