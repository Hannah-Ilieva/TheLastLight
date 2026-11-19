-- SkinConfig: the cosmetic looks players can pick in the lobby wardrobe.
-- Skins are pure decoration: small walk-through parts welded onto the character.
-- They never change speed, size, safety or how the monster finds you.
--
-- Each piece:
--   Attach    body part it sits on ("Head", "UpperTorso" or "LowerTorso"; R6 uses "Torso")
--   Offset    position from that part's centre, as a fraction of the part's size
--             (0.5 on Y = the top surface), so it fits any avatar size
--   Size      in studs for a standard-size avatar (scaled with the body part)
--   Shape     optional: "Ball" or "Cylinder" (cylinders lie along X; set Turn to stand them up)
--   Turn      optional rotation in degrees (X, Y, Z)

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local SkinConfig = {}

-- The order the wardrobe shows them in. "Default" means your own Roblox avatar.
SkinConfig.Order = { "Default", "Forager", "LanternKeeper", "MossWanderer" }

SkinConfig.Skins = {
	Default = {
		DisplayName = "Your Avatar",
		Description = "Just you, as you are.",
		Swatch = rgb(200, 200, 200),
		Pieces = {},
	},
	Forager = {
		DisplayName = "Forager",
		Description = "A wide-brimmed hat and a satchel for mushrooms.",
		Swatch = rgb(150, 112, 70),
		Pieces = {
			{ Name = "HatBrim", Attach = "Head", Shape = "Cylinder", Size = Vector3.new(0.12, 2.5, 2.5), Offset = Vector3.new(0, 0.42, 0), Turn = Vector3.new(0, 0, 90), Color = rgb(110, 80, 50), Material = Enum.Material.Fabric },
			{ Name = "HatCrown", Attach = "Head", Shape = "Cylinder", Size = Vector3.new(0.7, 1.35, 1.35), Offset = Vector3.new(0, 0.72, 0), Turn = Vector3.new(0, 0, 90), Color = rgb(96, 70, 44), Material = Enum.Material.Fabric },
			{ Name = "HatBand", Attach = "Head", Shape = "Cylinder", Size = Vector3.new(0.16, 1.4, 1.4), Offset = Vector3.new(0, 0.55, 0), Turn = Vector3.new(0, 0, 90), Color = rgb(170, 60, 45), Material = Enum.Material.Fabric },
			{ Name = "Satchel", Attach = "LowerTorso", Size = Vector3.new(0.4, 0.9, 1), Offset = Vector3.new(0.65, -0.6, 0), Color = rgb(125, 92, 58), Material = Enum.Material.Leather },
			{ Name = "Strap", Attach = "UpperTorso", Size = Vector3.new(0.25, 2.2, 0.06), Offset = Vector3.new(0, 0, -0.53), Turn = Vector3.new(0, 0, -38), Color = rgb(90, 64, 40), Material = Enum.Material.Leather },
		},
	},
	LanternKeeper = {
		DisplayName = "Lantern Keeper",
		Description = "A keeper's cap and a little brass lantern (just for show).",
		Swatch = rgb(230, 170, 80),
		Pieces = {
			{ Name = "Cap", Attach = "Head", Shape = "Ball", Size = Vector3.new(1.25, 1.25, 1.25), Offset = Vector3.new(0, 0.7, 0.05), Color = rgb(120, 40, 36), Material = Enum.Material.Fabric },
			{ Name = "Collar", Attach = "UpperTorso", Size = Vector3.new(2.1, 0.35, 1.15), Offset = Vector3.new(0, 0.5, 0), Color = rgb(40, 44, 52), Material = Enum.Material.Fabric },
			{ Name = "LanternFrame", Attach = "LowerTorso", Size = Vector3.new(0.5, 0.7, 0.5), Offset = Vector3.new(-0.75, -0.9, -0.1), Color = rgb(180, 140, 70), Material = Enum.Material.Glass, Transparency = 0.4 },
			{ Name = "LanternFlame", Attach = "LowerTorso", Size = Vector3.new(0.22, 0.35, 0.22), Offset = Vector3.new(-0.75, -0.9, -0.1), Color = rgb(255, 180, 90), Material = Enum.Material.Neon },
			{ Name = "LanternTop", Attach = "LowerTorso", Size = Vector3.new(0.55, 0.12, 0.55), Offset = Vector3.new(-0.75, -0.05, -0.1), Color = rgb(150, 115, 55), Material = Enum.Material.Metal },
		},
	},
	MossWanderer = {
		DisplayName = "Moss Wanderer",
		Description = "A mossy hooded cloak, grown in the deep woods.",
		Swatch = rgb(70, 110, 60),
		Pieces = {
			{ Name = "Hood", Attach = "Head", Shape = "Ball", Size = Vector3.new(1.55, 1.55, 1.55), Offset = Vector3.new(0, 0.2, 0.3), Color = rgb(56, 88, 50), Material = Enum.Material.Grass },
			{ Name = "Cloak", Attach = "UpperTorso", Size = Vector3.new(2.1, 2.9, 0.2), Offset = Vector3.new(0, -0.35, 0.62), Color = rgb(60, 92, 52), Material = Enum.Material.Grass },
			{ Name = "ShoulderL", Attach = "UpperTorso", Shape = "Ball", Size = Vector3.new(0.8, 0.8, 0.8), Offset = Vector3.new(-0.5, 0.45, 0.1), Color = rgb(72, 104, 58), Material = Enum.Material.Grass },
			{ Name = "ShoulderR", Attach = "UpperTorso", Shape = "Ball", Size = Vector3.new(0.7, 0.7, 0.7), Offset = Vector3.new(0.5, 0.42, 0.15), Color = rgb(66, 98, 56), Material = Enum.Material.Grass },
		},
	},
}

return SkinConfig
