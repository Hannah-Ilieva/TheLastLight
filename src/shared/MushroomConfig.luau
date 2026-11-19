-- MushroomConfig: the stats and look of every mushroom type, keyed by type name.
-- A spawn marker's "MushroomType" attribute must match one of these keys.
--   Points       round points, added the moment it is collected
--   Power        nil (points only), "Speed" (used by pressing the ability key) or
--                "Shield" (works automatically when the monster catches you)
--   Description  shown on screen when you pick it up

return {
	Mooncap = {
		DisplayName = "Mooncap",
		Points = 1,
		Description = "A reliable point.",
		CapColor = Color3.fromRGB(235, 225, 200), -- cream
		StemColor = Color3.fromRGB(215, 210, 195),
		GlowColor = Color3.fromRGB(120, 190, 255), -- soft blue
	},
	EmberMorel = {
		DisplayName = "Ember Morel",
		Points = 2,
		Power = "Speed",
		Description = "Use it for a burst of speed.",
		CapColor = Color3.fromRGB(215, 85, 40), -- orange-red
		StemColor = Color3.fromRGB(225, 200, 165),
		GlowColor = Color3.fromRGB(255, 130, 60), -- warm ember
	},
	GuardianCap = {
		DisplayName = "Guardian Cap",
		Points = 3,
		Power = "Shield",
		Description = "Blocks one catch. Works automatically.",
		CapColor = Color3.fromRGB(125, 70, 200), -- violet
		StemColor = Color3.fromRGB(205, 195, 225),
		GlowColor = Color3.fromRGB(185, 130, 255), -- bright violet
	},
}
