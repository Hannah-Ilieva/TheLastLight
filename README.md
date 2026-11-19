# The Last Light

A co-op Roblox horror game for 1–6 players. Gather glowing mushrooms in a night forest while the music plays. When the music stops, the lights die, so get to a safe light before the creature in the dark finds you.

<!-- Concept art: save the image to docs/images/forest-concept.png, then uncomment:
![Forest concept art for The Last Light](docs/images/forest-concept.png)
*Concept art showing the intended mood. Not an in-game screenshot.*
-->

## Core loop

1. **Gather (about 28 s):** explore the trails and collect mushrooms for points.
2. **Warning (about 7 s):** the beat speeds up, the lamps flicker, and the hidden safe lights appear. Run for one.
3. **Blackout (about 12 s):** the music cuts out. Only safe lights stay on, and the creature hunts anyone outside them.
4. **Release (about 3 s):** the lights return and the next cycle starts.

A round is 4 cycles. Every blackout you survive earns a bonus point, and reaching dawn earns 5 more. If you're caught, you spectate until the next round (and keep your points).

## Mushrooms

| Mushroom | Points | Power |
|---|---:|---|
| Mooncap | 1 | None, just points |
| Ember Morel | 2 | Press Q for a 4-second burst of speed |
| Guardian Cap | 3 | Blocks one catch automatically, then breaks |

You can carry one power mushroom at a time.

## Controls

| Action | Desktop | Mobile |
|---|---|---|
| Move | WASD | Thumbstick |
| Collect mushroom | Interact key on the prompt | Tap the prompt |
| Use Ember Morel | Q (Y on a controller) | Speed button |
| Change your look | Wardrobe buttons (lobby and results) | Tap a wardrobe button |

## Development setup

- [Roblox Studio](https://create.roblox.com/) with [Rojo](https://rojo.space/) 7.7.1
- Open `places/TheLastLight_Dev.rbxlx` in Studio, run `rojo serve` in this folder, and connect from the Rojo plugin.
- Rojo syncs the code: `src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.Server`, `src/client` → `StarterPlayer.StarterPlayerScripts.Client`.
- `src/tools` → `ServerStorage.Tools` holds the Studio-only map generator. To (re)build the map, run this in Studio's Command Bar in edit mode, then save the place:
  `require(game.ServerStorage.Tools.BuildMap:Clone())()`
  It rebuilds everything it made before (and all terrain); anything you add by hand is kept.
- The map, lighting and visuals are saved in the place file (`places/TheLastLight_Dev.rbxlx`), not synced by Rojo.

## Status

Playable prototype of the full round:

- **The Hollow Pines:** a generated forest map with terrain, dirt trails, pine trees, the ranger camp and four themed areas.
- **Round loop:** rounds run through every phase, with music, lighting and a HUD for each one.
- **Safe lights:** stone circles with a glowing beacon that light up from the Warning onward.
- **Mushrooms:** three types, two of them with powers.
- **The Hollow Stag:** stalks during the Warning and hunts during the Blackout.
- **Bonuses and results:** survival bonuses, a results screen at dawn, and a cosmetic wardrobe.

Everything that affects the game is checked on the server.

Round timers are halved for testing (`TimeScale` in `GameConfig`). Set it to 1 for real rounds.

Sounds come from Roblox's licensed libraries (APM Music and Pro Sound Effects); see `src/shared/SoundConfig.luau`.

## Roadmap

- [x] Map blockout (trails, camp, safe-light clearings)
- [x] First mushroom pickup with a server-side score
- [x] Round phases and HUD
- [x] Lighting that changes with each phase
- [x] Safe-zone detection
- [x] Placeholder monster
- [x] Speed and shield mushrooms
- [x] Art and sound pass
- [x] Cosmetic skins and results screen
- [ ] Playtesting and tuning

## License

[MIT](LICENSE)
