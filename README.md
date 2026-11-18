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

A round is 4 cycles. Survive until dawn to earn a bonus. If you're caught, you spectate until the next round.

## Controls

| Action | Desktop | Mobile |
|---|---|---|
| Move | WASD | Thumbstick |
| Collect mushroom | Interact key on the prompt | Tap the prompt |
| Use mushroom ability | Ability key (planned) | Ability button (planned) |

## Development setup

- [Roblox Studio](https://create.roblox.com/) with [Rojo](https://rojo.space/) 7.7.1
- Open `places/TheLastLight_Dev.rbxlx` in Studio, run `rojo serve` in this folder, and connect from the Rojo plugin.
- Rojo syncs the code: `src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.Server`, `src/client` → `StarterPlayer.StarterPlayerScripts.Client`.
- `src/tools` → `ServerStorage.Tools` holds Studio-only tools. To (re)build the map blockout, run this in Studio's Command Bar in edit mode, then save the place:
  `require(game.ServerStorage.Tools.BuildBlockout:Clone())()`
- The map, lighting and visuals are saved in the place file (`places/TheLastLight_Dev.rbxlx`), not synced by Rojo.

## Status

Prototype. The map blockout is generated, rounds loop through all phases with an on-screen countdown, and players can collect Mooncaps during Gather and Warning (checked by the server). The scene is night with fog; path lamps flicker in Warning, go dark in Blackout and return on Release. Safe lights are hidden during Gather and appear only for Warning and Blackout. Safe-zone detection comes next. Round timers are halved for testing (`TimeScale` in `GameConfig`).

## Roadmap

- [x] Map blockout (trails, camp, safe-light clearings)
- [x] First mushroom pickup with a server-side score
- [x] Round phases and HUD
- [x] Lighting that changes with each phase
- [ ] Safe-zone detection
- [ ] Placeholder monster
- [ ] Speed and shield mushrooms
- [ ] Art and sound pass
- [ ] Cosmetic skins and results screen
- [ ] Playtesting and tuning

## License

[MIT](LICENSE)
