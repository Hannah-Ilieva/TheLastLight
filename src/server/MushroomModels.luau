-- MushroomModels: builds the look of each mushroom type out of simple parts.
--   Mooncap      a small cluster of cream caps with softly glowing blue gills
--   EmberMorel   a tall, ridged orange-red cap with glowing ember flecks and sparks
--   GuardianCap  a wide violet dome with a bright glowing ring and pale spots
-- Every model's PrimaryPart is its main stem: the collect prompt sits there and the
-- server measures pickup distance from it. Colours come from MushroomConfig.

local MushroomModels = {}

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds" -- built into Roblox

-- A decorative part: anchored, walk-through, no shadow.
local function piece(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material, parent: Instance, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

-- A squashed dome made with a sphere mesh (lets the cap be wider than it is tall).
local function dome(name: string, size: Vector3, position: Vector3, color: Color3, parent: Instance): Part
	local cap = piece(name, size, position, color, Enum.Material.SmoothPlastic, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = cap
	return cap
end

-- A thin flat disc (cylinder lying down), used for glowing gills and rings.
local function flatDisc(name: string, diameter: number, position: Vector3, color: Color3, parent: Instance): Part
	local disc = piece(name, Vector3.new(0.1, diameter, diameter), position, color, Enum.Material.Neon, parent, Enum.PartType.Cylinder)
	disc.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	return disc
end

local function addGlow(part: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
end

local function addParticles(part: BasePart, color: Color3, rate: number, upward: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.3, 0.8)
	emitter.Acceleration = Vector3.new(0, upward, 0)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Parent = part
end

-- One stem + cap + glowing gills; `scale` makes the smaller ones in a cluster.
local function mooncapStalk(ground: Vector3, scale: number, config, parent: Instance): Part
	local stemHeight = 1.4 * scale
	local stem = piece("Stem", Vector3.new(0.6, stemHeight, 0.6) * scale, ground + Vector3.new(0, stemHeight / 2, 0), config.StemColor, Enum.Material.SmoothPlastic, parent)
	dome("Cap", Vector3.new(2.4, 1.1, 2.4) * scale, ground + Vector3.new(0, stemHeight + 0.25 * scale, 0), config.CapColor, parent)
	flatDisc("Gills", 2 * scale, ground + Vector3.new(0, stemHeight - 0.05, 0), config.GlowColor, parent)
	return stem
end

local function buildMooncap(model: Model, ground: Vector3, config)
	model.PrimaryPart = mooncapStalk(ground, 1, config, model)
	mooncapStalk(ground + Vector3.new(0.95, 0, 0.6), 0.55, config, model)
	mooncapStalk(ground + Vector3.new(-0.7, 0, 0.85), 0.4, config, model)
	addGlow(model.PrimaryPart, config.GlowColor, 9, 1.2)
	addParticles(model.PrimaryPart, config.GlowColor, 1.5, 0.3)
end

local function buildEmberMorel(model: Model, ground: Vector3, config)
	local stem = piece("Stem", Vector3.new(0.7, 1.2, 0.7), ground + Vector3.new(0, 0.6, 0), config.StemColor, Enum.Material.SmoothPlastic, model)
	model.PrimaryPart = stem
	-- Stacked balls with a bumpy texture read as a tall, ridged morel cap.
	local layers = { { 1.7, 1.7 }, { 1.35, 2.6 }, { 0.95, 3.35 } } -- { diameter, height }
	for i, layer in layers do
		piece("Cap" .. i, Vector3.one * layer[1], ground + Vector3.new(0, layer[2], 0), config.CapColor, Enum.Material.Cobblestone, model, Enum.PartType.Ball)
	end
	local flecks = { Vector3.new(0.75, 1.9, 0.3), Vector3.new(-0.6, 2.3, -0.45), Vector3.new(0.2, 2.9, -0.6), Vector3.new(-0.35, 3.4, 0.35), Vector3.new(0.55, 2.7, 0.55) }
	for i, offset in flecks do
		piece("Ember" .. i, Vector3.one * 0.28, ground + offset, config.GlowColor, Enum.Material.Neon, model, Enum.PartType.Ball)
	end
	addGlow(stem, config.GlowColor, 9, 1.4)
	addParticles(stem, config.GlowColor, 4, 2)
end

local function buildGuardianCap(model: Model, ground: Vector3, config)
	local stem = piece("Stem", Vector3.new(0.9, 1.7, 0.9), ground + Vector3.new(0, 0.85, 0), config.StemColor, Enum.Material.SmoothPlastic, model)
	model.PrimaryPart = stem
	local capCenter = ground + Vector3.new(0, 1.95, 0)
	dome("Cap", Vector3.new(3.4, 1.5, 3.4), capCenter, config.CapColor, model)
	flatDisc("Ring", 3.65, capCenter - Vector3.new(0, 0.1, 0), config.GlowColor, model) -- the bright ring around the rim
	local spots = { Vector3.new(0, 0.7, 0), Vector3.new(0.85, 0.5, 0.3), Vector3.new(-0.7, 0.5, 0.55), Vector3.new(0.1, 0.5, -0.9), Vector3.new(-0.6, 0.45, -0.55) }
	for i, offset in spots do
		piece("Spot" .. i, Vector3.one * 0.32, capCenter + offset, Color3.fromRGB(245, 235, 255), Enum.Material.Neon, model, Enum.PartType.Ball)
	end
	addGlow(stem, config.GlowColor, 11, 1.6)
	addParticles(stem, config.GlowColor, 3, 0.6)
end

local BUILDERS = {
	Mooncap = buildMooncap,
	EmberMorel = buildEmberMorel,
	GuardianCap = buildGuardianCap,
}

-- Builds a mushroom of type `kind` standing on `ground`. Returns the Model (not parented).
function MushroomModels.build(kind: string, config, ground: Vector3): Model
	local model = Instance.new("Model")
	model.Name = config.DisplayName
	model:SetAttribute("MushroomType", kind)
	local builder = BUILDERS[kind] or buildMooncap
	builder(model, ground, config)
	return model
end

return MushroomModels
