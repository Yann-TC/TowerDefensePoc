# Tower Defense POC

A second game made with the Ampersand Engine, different from R-Type. The
engine is used as a library: the C++ is `src/main.cpp` (window, systems,
loop) and `src/GameBindings.cpp` (the `Props` component and the few Lua
functions the engine does not bind), and everything else is data and Lua
scripts.

## Build and run

From the root of the repository:

```sh
cmake -S . -B build
cmake --build build --parallel
./build/tower_defense
```

The game must be run from the root of the repository (`gameRoot` is `./`),
or given its configuration:
`tower_defense path/to/config.json`.

## Controls

| Input              | Action                                          |
| ------------------ | ----------------------------------------------- |
| Left click         | press a button, build the tower, select a tower |
| `1` `2` `3` `4`    | choose Gun, Cannon, Rocket, Missile             |
| `Q` / `E`          | previous / next tower to build                  |
| hold `Shift`       | keep building the same tower; release to stop   |
| Right click        | cancel                                          |
| `U` / `S`          | upgrade / sell the selected tower               |
| `Space`            | next wave (early = bonus gold)                  |
| `F`                | speed x1 / x2                                   |
| `Esc`              | cancel, or pause                                |
| `Tab`              | show / hide the metrics                         |
| `C`                | show / hide the colliders (red when touching)   |

## Content

| Kind     | What                                                                       |
| -------- | -------------------------------------------------------------------------- |
| Levels   | Green Valley (easy, 10 waves), Twin Rivers (hard, 15 waves), Stress Test   |
| Towers   | Gun (air + ground), Cannon (area, ground), Rocket (area), Missile (air), 3 levels each |
| Enemies  | soldier, scout, heavy robot, tank, desert tank (boss), plane, bomber       |
| Scenes   | menu (towers fighting in the background), 2 levels, result screen          |

## Stress Test

The third level pushes the engine: a 69-cell path, 20 towers already built
(level 3), 30000 gold, and 7 waves growing from 300 to 4000 enemies, which
pile up when they are called early (`Space`). The metrics (`Tab`, shown by
default there) come from the engine's `Stats` resource: the FPS, the frame
and update times, the entities alive and a graph of the last 120 frame times
(green at 60 FPS, yellow down to 30, red below), then the game's own values:
the enemies alive and their peak, the towers, and the spawns refused.

The game creates its World with room for 50000 entities (`kMaxEntities` in
`src/main.cpp`, the engine default is 10000); an enemy is 2 or 3 entities.
Past the limit, `spawn` fails: the scripts count it (`trySpawn`) instead of
stopping, so the wave goes on with fewer enemies. Only 4 explosions are heard
per frame, the others are silent.

### Measured limits

Release build, offscreen renderer, cost of one frame (60 FPS = 16.7 ms).
Soldiers spawned 200 per second on the Stress Test path:

| Enemies alive | Entities | No towers: scripts + render | Empty enemy script: scripts + render |
| ------------- | -------- | --------------------------- | ------------------------------------ |
| 1200          | 2800     | 0.8 + 1.3 = 2.1 ms          | 0.3 + 1.3 = 1.6 ms                   |
| 4800          | 10000    | 4.9 + 6.0 = 11.0 ms         | 1.0 + 5.7 = 6.7 ms                   |
| 7200          | 14800    | 7.7 + 9.1 = 17.0 ms         | 1.4 + 8.5 = 10.1 ms                  |
| 12000         | 24400    | 12.2 + 14.9 = 27.4 ms       | 2.4 + 14.8 = 17.5 ms                 |
| 14400         | 29200    | 15.1 + 18.3 = 33.7 ms       | 2.9 + 17.9 = 21.2 ms                 |

- **60 FPS holds up to about 7000 walking enemies** (15000 entities).
- **Rendering grows the most**: about 0.6 us per drawn entity, whatever it
  draws (one draw call per sprite, every draw sorted by layer, invisible
  ones included). Batching the sprites in the render module is where the
  engine would gain the most.
- **The ScriptingSystem itself costs about 0.2 us per scripted entity** (the
  empty script); the rest of the script time is the enemy logic.
- **In combat** (20 towers at level 3, 1000 spawns per second), about 3500
  enemies alive cost about 36 ms per frame: 28 ms of scripts, mostly the
  effects (explosion, popup, scorch mark kept 6 s), which are around 10000
  more scripted entities. Fewer or lighter effects would push this further.

In Debug everything is about 7 times slower: build in Release to test.

## Folder

```text
TowerDefensePoc
├── CMakeLists.txt     # the game, with the engine as a library
├── src/main.cpp       # C++: window, systems and loop
├── src/GameBindings.* # C++: Props and the Lua functions added by the game
├── assets/            # tilesheet (svg + png for SFML), font, sounds, music
├── scripts/           # behaviours (map, game, waves, enemy, tower...) and
│                      # modules (state, towerKinds, util, fx, units)
└── world/
    ├── config.json
    ├── prefabs/       # level, tiles, towers, enemies, projectiles, fx,
    │                  # ui (hud, button, pointer, stats, colliders)
    └── scenes/        # menu, level1, level2, level3, gameover
```

## Scripts and modules

A behaviour is listed in the `Scripts` of an entity and returns a table with
`start` / `update` / `onDestroy`. The code and state they share are modules,
loaded with Lua's `require`:

| Module       | Holds                                                                  |
| ------------ | ---------------------------------------------------------------------- |
| `state`      | the shared state (game, level, session, enemies, towers, shots, sounds), `message`, `playSound` |
| `towerKinds` | the stats of each tower and level, `sellRatio`                         |
| `util`       | math, entity and interface helpers on top of the engine bindings, `spawnAt` |
| `fx`         | `trySpawn` (survives a full World), popups, explosions                 |
| `units`      | the grid, and the enemies and towers on it                             |

```lua
local State = require("state")
local Units = require("units")
```

A module is loaded once: every script gets the same table, and it keeps its
values across the scenes.

## Adding content

- **A level**: copy `world/scenes/level1.json` and list it in `config.json`.
  It holds the prefabs `level.json` (scripts, sounds, cursor), `ui/hud.json`,
  `ui/pointer.json`, and the debug views `ui/stats.json` and
  `ui/colliders.json` (`"Props": {"shown": true}` to show them from the
  start). The `Props` of its `Level` entity hold the map and the waves:
  - `grid`: one string per row. `.` grass (buildable), `#` path, `S` start,
    `E` end, `T t p B r R o` decorations, `x` stone. The path is found from
    `S` to `E` by `map.lua`.
  - `waves`: `{ "groups": [{ "enemy", "count", "interval", "delay", "health" }], "bonus" }`.
  - `gold`, `lives`, `difficulty` (health multiplier of every enemy).
  - `towers` (optional): towers already built, `{ "kind", "col", "row", "level" }`.
- **An enemy**: a prefab in `world/prefabs/enemies/` with its stats in its
  `Props` (`health`, `speed`, `reward`, `damage`, `flying`).
- **A tower**: an entry in `scripts/towerKinds.lua` (stats of each level)
  and a prefab in `world/prefabs/towers/` (look and sound).

No recompilation is needed for any of these.

## What the game adds to the engine

The game runs on the systems of the engine only (`InputSystem`,
`ScriptingSystem`, `MovementSystem`, `AnimationSystem`, `AudioSystem`,
`RenderSystem`), and the scripts use its bindings and components wherever
they can:

| Engine feature                                   | Used for                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------------------ |
| scenes, prefabs (merged overrides), `children`   | every level (one `level.json`, one HUD), tower, enemy, projectile, effect and button |
| `instantiate`, `loadScene` (`SceneManager::bindScripting`) | every spawn (`Util.spawnAt`), every scene change                  |
| `Sprite` + `getSprite` (`source`, `color`, `layer`) | turret frames, hit flash, tinting the tower being placed, fading effects |
| `Rectangle`, `Circle` + `getRectangle`, `getCircle` | panels, buttons and their outline, health bars, path borders, range, pips, cursor |
| `Text` + `getText`                               | HUD, banner, popups, metrics                                             |
| `Animation`                                      | explosions                                                               |
| `AnimationStateMachine` + `animation.setFloat/setBool` | turrets: their sprite follows the params `level` (upgraded look) and `loaded` (rocket and missile empty while reloading) |
| `Gravity` + `GravityForce` (`MovementSystem`)    | debris thrown up by the explosions, falling back                         |
| `BoxCollider` + `CollisionSystem` + `Collisions` | the pointer: what it touches is hovered (buttons) or selected (towers)   |
| `getColliders` + `getBounds`                     | the colliders view (`C`): an outline per collider, red when it touches another one |
| `input.getButton` / `getButtonUp`                | hold `Shift` to keep building, release it to stop                        |
| `Stats` resource (filled by the `Scheduler`)     | the metrics (Tab): FPS, frame and update times, entities, frame-time graph, and the game's own metrics in its `values` |
| `Line`                                           | the frame-time graph of the metrics                                      |
| `Velocity` + `MovementSystem`                    | enemies, projectiles, popups                                             |
| `input.getButtonDown`, `getMousePosition`        | virtual buttons (keys and mouse) of `config.json`, the pointer |
| `AudioSource`, `SceneMusic`                      | shots, explosions, interface sounds, music of each scene                 |
| `children`, local `Transform`                    | parts that follow their entity: turret, health bar, button texts        |

The plain shapes (panels, buttons, health bars, range circle, level pips,
cursor frame, heart) are `Rectangle` and `Circle` components, sized in pixels
with a scale of 1: their children are not stretched with them.

The gameplay state (gold, lives, waves, enemies, towers, shots) is plain Lua
in the `state` module (`scripts/state.lua`).

The engine is used as it is: what the scripts need on top of it is added by
`src/GameBindings.cpp`, through the public API of the engine only
(`SceneManager::registerComponent`, `ScriptingSystem::lua`,
`Scheduler::addEventQueue`):

| Added by the game                 | What it does                                                              |
| --------------------------------- | ------------------------------------------------------------------------- |
| `Props` component                 | free JSON data of an entity (`"Props": {"health": 50}`), merged field by field over a prefab |
| `getProps(entity)`, `hasProps`    | the `Props` of the entity as Lua tables                                   |
| `getCurrentScene()`               | name of the scene running                                                 |
| `getClock()` (`dt`, `elapsed`, `timeScale`) | pause (0) and speed up (2): the loop multiplies the dt given to the `Scheduler` by `timeScale`, so the `Stats` keep the real times |
| `getStats()`                      | the `Stats` resource: `fps`, `frameMs`, `updateMs`, `entities`, `history()`, `value(name)`, `setValue(name, value)` |
| `getCollisions(entity)`           | the entities touching it in the `Collisions`                              |
| `require(name)`                   | the modules `gameRoot/scripts/<name>.lua` (Lua `package`, no native modules) |
| `ScriptErrorLog` system           | prints the errors of the scripts on the standard error                    |

`src/main.cpp` adds the resources it shows (`Stats`, `Collisions`) and the
systems.

Hiding an entity moves it far away (`Util.setShown`), and text is centered
with an estimate of its width (`Util.textWidth`): the engine has no
visibility flag and does not measure a `Text`.

The mouse is read in pixels of the window: the `Camera` of the game has the
size of its window, so they are also world coordinates.

Only the pointer, the buttons and the towers have a `BoxCollider`. The shots
hit by distance: the `CollisionSystem` tests every pair of colliders (no
broadphase), so colliders on the thousands of enemies of the Stress Test
would cost more than everything else. A broadphase (grid, sweep and prune)
in the physics module would let them use it.

The `Transform` of a child is relative to its parent, so `spawnAt` only moves
the root of a prefab. An enemy keeps a root that never turns, and its body is
a child: the health bar does not turn with it. A button is sized by its
`Rectangle`, and its `BoxCollider` is set to the same size by its script.
