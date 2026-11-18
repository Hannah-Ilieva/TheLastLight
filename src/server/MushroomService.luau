-- MushroomService: spawns mushrooms at the markers in Workspace.MushroomSpawns
-- and handles collecting them. Every check happens here on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MushroomConfig = require(ReplicatedStorage.Shared.MushroomConfig)
local log = require(ReplicatedStorage.Shared.Log)
local Score = require(script.Parent.Score)

local STEM_SIZE = Vector3.new(0.7, 1.6, 0.7)
local CAP_SIZE = Vector3.new(2.6, 1.2, 2.6)

local MushroomService = {}

local activeFolder: Folder -- holds this round's mushrooms

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false -- players walk through it instead of tripping on it
	part.CastShadow = false
	part.Parent = parent
	return part
end

-- Builds a simple mushroom: a stem plus a squashed-sphere cap with a soft light.
local function buildMushroom(config, groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = config.DisplayName

	local stemCFrame = CFrame.new(groundPosition + Vector3.new(0, STEM_SIZE.Y / 2, 0))
	local stem = newPart("Stem", STEM_SIZE, stemCFrame, config.StemColor, model)
	model.PrimaryPart = stem

	local capCFrame = CFrame.new(groundPosition + Vector3.new(0, STEM_SIZE.Y + CAP_SIZE.Y / 4, 0))
	local cap = newPart("Cap", CAP_SIZE, capCFrame, config.CapColor, model)
	local mesh = Instance.new("SpecialMesh") -- turns the block into a smooth dome shape
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = cap

	local light = Instance.new("PointLight")
	light.Color = config.GlowColor
	light.Brightness = 1
	light.Range = 8
	light.Parent = cap

	return model
end

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

local function onCollect(player: Player, model: Model, config)
	-- Already collected? (Destroyed models have no parent.) This stops double pickups.
	if not model.Parent then
		return
	end
	if not isCollectPhase() or not canReach(player, model.PrimaryPart.Position) then
		return
	end

	model:Destroy()
	Score.add(player, config.Points)
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
	local model = buildMushroom(config, groundPosition)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = config.DisplayName
	prompt.MaxActivationDistance = GameConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = isCollectPhase()
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onCollect(player, model, config)
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
