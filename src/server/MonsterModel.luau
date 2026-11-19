-- MonsterModel: builds the Hollow Stag out of simple parts. A tall, thin, deer-like
-- shape with a pale skull for a head, dim glowing eyes and uneven antlers, so it reads
-- clearly as a silhouette in the fog. Not graphic: no gore, just wrong proportions.
--
-- The model faces -Z (forward). Its PrimaryPart "Root" is an invisible block at ground
-- level; MonsterService moves the model by moving that pivot.

local MonsterModel = {}

local BODY_COLOR = Color3.fromRGB(14, 14, 18)
local BONE_COLOR = Color3.fromRGB(196, 190, 174)
local EYE_COLOR = Color3.fromRGB(200, 255, 230)
local GROWL_SOUND_ID = "rbxassetid://9114628818" -- deep growl (Pro Sound Effects), pitched down

MonsterModel.ROOT_HEIGHT = 0.5 -- the Root part's centre above the ground

local function addPart(model: Model, name: string, props): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = BODY_COLOR
	if props.Shape then
		part.Shape = props.Shape -- before Size, so Size isn't adjusted afterwards
	end
	for key, value in props do
		if key ~= "Shape" then
			part[key] = value
		end
	end
	part.Parent = model
	return part
end

-- A cylinder between two points (legs, neck, antlers). Points are in model space.
local function addLimb(model: Model, name: string, from: Vector3, to: Vector3, thickness: number, color: Color3?): Part
	local middle = (from + to) / 2
	return addPart(model, name, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new((to - from).Magnitude, thickness, thickness),
		CFrame = CFrame.lookAt(middle, to) * CFrame.Angles(0, math.pi / 2, 0),
		Color = color or BODY_COLOR,
	})
end

-- A stretched sphere (the body), using a mesh so it can be longer than it is wide.
local function addOval(model: Model, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = addPart(model, name, { Size = size, CFrame = CFrame.new(position), Color = color })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Legs bend in the middle; back legs bend backwards like a deer's.
local function addLeg(model: Model, hip: Vector3, kneeShift: number)
	local knee = Vector3.new(hip.X, 3.8, hip.Z + kneeShift)
	local hoof = Vector3.new(hip.X, 0, hip.Z - kneeShift * 0.5)
	addLimb(model, "UpperLeg", hip, knee, 0.55)
	addLimb(model, "LowerLeg", knee, hoof, 0.4)
end

-- Each antler is a list of { from, to } branches; left and right differ on purpose.
local ANTLERS = {
	{ Vector3.new(-0.4, 13.3, -3.9), Vector3.new(-2.2, 16.5, -3.3) },
	{ Vector3.new(-2.2, 16.5, -3.3), Vector3.new(-3.7, 18.6, -2.6) },
	{ Vector3.new(-1.5, 15.3, -3.5), Vector3.new(-2.7, 16.3, -5.1) },
	{ Vector3.new(-3, 17.6, -2.9), Vector3.new(-2.7, 19.7, -3.7) },
	{ Vector3.new(0.4, 13.3, -3.9), Vector3.new(1.9, 15.8, -3.4) },
	{ Vector3.new(1.9, 15.8, -3.4), Vector3.new(3.3, 17.3, -2.7) },
	{ Vector3.new(1.3, 14.9, -3.6), Vector3.new(2.4, 15.5, -5.2) },
}

function MonsterModel.build(): Model
	local model = Instance.new("Model")
	model.Name = "Monster"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- visible from far away

	local root = addPart(model, "Root", { Size = Vector3.new(3, 1, 3), CFrame = CFrame.new(0, MonsterModel.ROOT_HEIGHT, 0), Transparency = 1 })
	model.PrimaryPart = root

	addOval(model, "Body", Vector3.new(2.4, 2.8, 6.2), Vector3.new(0, 8, 0.4), BODY_COLOR)
	for _, x in { -0.75, 0.75 } do
		addLeg(model, Vector3.new(x, 7.6, -2), -0.4) -- front
		addLeg(model, Vector3.new(x, 7.6, 2.8), 0.9) -- back
	end
	addLimb(model, "Neck", Vector3.new(0, 8.6, -2.2), Vector3.new(0, 12.2, -3.5), 1.1)

	-- The skull, tilted slightly down, with a narrower snout.
	local skullCFrame = CFrame.new(0, 12.7, -4.2) * CFrame.Angles(math.rad(-15), 0, 0)
	addPart(model, "Skull", { Size = Vector3.new(1.4, 1.4, 2), CFrame = skullCFrame, Color = BONE_COLOR })
	addPart(model, "Snout", { Size = Vector3.new(0.9, 0.8, 1.4), CFrame = skullCFrame * CFrame.new(0, -0.25, -1.5), Color = BONE_COLOR })
	for _, x in { -0.58, 0.58 } do
		addPart(model, "Eye", {
			Shape = Enum.PartType.Ball, Size = Vector3.one * 0.35, CFrame = skullCFrame * CFrame.new(x, 0.2, -0.55),
			Material = Enum.Material.Neon, Color = EYE_COLOR,
		})
	end
	for i, branch in ANTLERS do
		addLimb(model, "Antler" .. i, branch[1], branch[2], i % 4 == 1 and 0.32 or 0.22, BONE_COLOR)
	end

	-- A faint glow from the eyes so its shape shows in the dark, without lighting up the area.
	local glow = Instance.new("PointLight")
	glow.Color = EYE_COLOR
	glow.Range = 12
	glow.Brightness = 0.9
	glow.Parent = model:FindFirstChild("Skull")

	local growl = Instance.new("Sound")
	growl.Name = "Growl"
	growl.SoundId = GROWL_SOUND_ID
	growl.PlaybackSpeed = 0.7
	growl.Volume = 1
	growl.RollOffMinDistance = 10
	growl.RollOffMaxDistance = 110
	growl.Parent = model:FindFirstChild("Skull")
	return model
end

return MonsterModel
