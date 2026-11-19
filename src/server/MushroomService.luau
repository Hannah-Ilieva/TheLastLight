-- MushroomService: spawns mushrooms at the markers in Workspace.MushroomSpawns
-- (their look comes from MushroomModels) and handles collecting them.
-- Every check happens here on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MushroomConfig = require(ReplicatedStorage.Shared.MushroomConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)
local PowerService = require(script.Parent.PowerService)
local Remotes = require(script.Parent.Remotes)
local MushroomModels = require(script.Parent.MushroomModels)

local MushroomService = {}

local activeFolder: Folder -- holds this round's mushrooms

-- True during the phases listed in GameConfig.CollectPhases (RoundService sets the phase).
local function isCollectPhase(): boolean
	return GameConfig.CollectPhases[ReplicatedStorage:GetAttribute("Phase")] == true
end

-- True if the player is alive and standing close enough to the mushroom.
local function canReach(player: Player, position: Vector3): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then
		return false
	end
	return (root.Position - position).Magnitude <= GameConfig.CollectDistance
end

local function onCollect(player: Player, model: Model, kind: string)
	local config = MushroomConfig[kind]
	-- Already collected? (Destroyed models have no parent.) This stops double pickups.
	if not model.Parent then
		return
	end
	if not isCollectPhase() or not canReach(player, model.PrimaryPart.Position) then
		return
	end
	-- Only one unused power at a time; point-only mushrooms are always fine.
	if config.Power and not PowerService.canCarry(player) then
		local held = MushroomConfig[player:GetAttribute("Power")]
		Remotes.Notify:FireClient(player, "info", "Your hands are full", "Use your " .. held.DisplayName .. " first.")
		return
	end

	model:Destroy()
	Score.add(player, config.Points)
	Score.addStat(player, "RoundMushrooms", 1)
	if config.Power then
		PowerService.give(player, kind)
	end
	local style = config.Power and "rare" or "pickup"
	Remotes.Notify:FireClient(player, style, ("%s  +%d"):format(config.DisplayName, config.Points), config.Description)
	log(player.Name, "collected", config.DisplayName, "+" .. config.Points)
end

local function spawnAt(marker: BasePart)
	local kind = marker:GetAttribute("MushroomType")
	local config = MushroomConfig[kind]
	if not config then
		warn("[TheLastLight] Unknown MushroomType on " .. marker:GetFullName() .. ": " .. tostring(kind))
		return
	end

	local groundPosition = marker.Position - Vector3.new(0, marker.Size.Y / 2, 0)
	local model = MushroomModels.build(kind, config, groundPosition)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = config.DisplayName
	prompt.MaxActivationDistance = GameConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = isCollectPhase()
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onCollect(player, model, kind)
	end)

	model.Parent = activeFolder
end

-- Removes any leftover mushrooms and spawns a fresh one at every marker.
function MushroomService.spawnAll()
	if activeFolder then
		activeFolder:Destroy() -- also disconnects the old prompts' events
	end
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "Mushrooms"
	activeFolder.Parent = workspace

	local spawns = workspace:FindFirstChild("MushroomSpawns")
	if not spawns then
		return -- Main already warns about the missing folder
	end
	for _, marker in spawns:GetChildren() do
		spawnAt(marker)
	end
	log("Mushrooms spawned:", #activeFolder:GetChildren())
end

-- Show the "Collect" prompts only while collecting is allowed. This is just for
-- clarity on screen; onCollect still checks the phase, so it stays secure.
ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
	if not activeFolder then
		return
	end
	local enabled = isCollectPhase()
	for _, item in activeFolder:GetDescendants() do
		if item:IsA("ProximityPrompt") then
			item.Enabled = enabled
		end
	end
end)

return MushroomService
