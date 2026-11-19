-- BuildMap: Studio tool that builds the whole map (The Hollow Pines).
-- Run it in edit mode (not during Play) by pasting this into the Command Bar:
--   require(game.ServerStorage.Tools.BuildMap:Clone())()
-- then save the place (Ctrl+S).
--
-- Safe to re-run: it deletes only the objects it built before (they carry a
-- "Generated" attribute) and builds them again. Objects you add are never touched,
-- EXCEPT terrain: the generator owns the terrain and repaints all of it.
-- To keep a hand-edited generated object, delete its "Generated" attribute.
--
-- The work is split into modules next to this one:
--   MapConfig  - all the numbers, positions and colours
--   MapKit     - small building helpers (parts, limbs, pyramids, discs)
--   MapNature  - terrain, trails, forest, rocks, area dressing
--   MapProps   - camp, landmarks, lamps, safe lights, markers, walls, lighting

local ServerStorage = game:GetService("ServerStorage")
local Tools = ServerStorage.Tools
-- Clone() each module so a re-run always uses the newest code (require caches results).
local MapConfig = require(Tools.MapConfig:Clone())
local MapKit = require(Tools.MapKit:Clone())
local MapNature = require(Tools.MapNature:Clone())
local MapProps = require(Tools.MapProps:Clone())

local FOLDER_NAMES = { "Map", "SafeZones", "MushroomSpawns", "PathLights", "MonsterSpawns" }

-- Studio's Baseplate template adds these. They would overlap the new ground and spawn.
local function removeTemplateObjects()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local item = workspace:FindFirstChild(name)
		if item and not item:GetAttribute(MapKit.GENERATED) then
			item:Destroy()
			print("[BuildMap] Removed template object:", name)
		end
	end
end

return function()
	local folders = {}
	for _, name in FOLDER_NAMES do
		folders[name] = MapKit.folder(workspace, name)
		MapKit.clearGenerated(folders[name])
	end
	removeTemplateObjects()

	local rng = Random.new(MapConfig.Forest.Seed)
	MapNature.buildTerrain(rng)
	MapProps.build(folders, rng)
	MapNature.dressAreas(folders.Map, rng)
	local treeCount = MapNature.buildForest(MapKit.folder(folders.Map, "Forest"), rng)

	print(("[BuildMap] Done: %d safe lights, %d mushroom spawns, %d monster dens, %d lamps, %d trees. Save the place with Ctrl+S."):format(
		#MapConfig.SafeZones, #MapConfig.MushroomSpawns, #MapConfig.MonsterDens, #folders.PathLights:GetChildren(), treeCount))
end
