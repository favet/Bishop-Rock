# Night Board v0 — Architecture Notes

Implemented 2026-07-01 (first Fable pass). This documents what exists so routine/Codex passes can extend it without re-deriving the design. Design source: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md).

## What v0 Is

A single schematic night: boats spawn from 360°, steer toward the lighthouse around rocks, get slowed by nets, blown up by mines, revealed by buoys and the sweeping beam, and shot by the player's gun and one auto turret. Lighthouse hull at 0 ends the run; R restarts. No day loop, no economy, no tide.

## Core Decisions

- **No physics engine.** Everything is distance checks against groups. Debuggable, cheap, and nothing to unwind later if we swap movement models.
- **Lighthouse at world origin.** All polar math (`OceanGrid`) assumes this; do not move the board.
- **Groups as the service locator**: `boats`, `rocks`, `mines`, `nets`, `buoys`, `beam`, `lighthouse`, `main_gun`, `turrets`, `night_board`. Systems find each other via `get_first_node_in_group` / `get_nodes_in_group`.
- **All rendering is `_draw()`** on the owning node. No sprites, no shaders.
- **Restart = scene reload** (`main.gd`), so no system needs reset logic.
- **VisibilitySystem is the single writer** of `Boat.vis_state`; boats only render their state. Ghost/last-known records live in the system, not on boats.

## File Map

| File | Owns |
|---|---|
| `scripts/core/ocean_grid.gd` | Ring radii, 16 sectors, polar helpers. Static, stateless. Tide TODO hooks. |
| `scripts/core/night_board.gd` | Orchestration only: wires spawner/boats/lighthouse, kills + rammed + elapsed, `resolved_count()`, game-over signal. Keep small. |
| `scripts/core/boat_spawner.gd` | Timed 360° horizon spawning, interval ramp 4s → 1.5s over 120s, stops after `wave_size` boats (v0.2); exposes `remaining_to_spawn()`/`wave_complete()`. |
| `scripts/core/visibility_system.gd` | Contact/spotted/illuminated assignment, ghost records, contact sector ticks. |
| `scripts/lighthouse/lighthouse.gd` | Hull health, island/tower drawing, hit-flash ring, `damaged`/`destroyed` signals. |
| `scripts/lighthouse/beam.gd` | Beam angle, AUTO_SWEEP/MANUAL_HOLD mode (Q toggles), Left/Right rotation with Down-modifier precision speed, `is_point_illuminated()`. |
| `scripts/lighthouse/main_gun.gd` | Hold-to-charge/release-to-fire on a real-time clock, misfire-on-overshoot, `world_time_scale()`, world-space reload+charge rings drawn around the lighthouse, cycle-target/mode input, illuminated-only targeting, tracers (v0.3 — see Charge Shot & Focus below). |
| `scripts/lighthouse/turret.gd` | Auto-fire at nearest ≥SPOTTED boat in range; chip damage, bonus vs illuminated, obeys `world_time_scale()`. |
| `scripts/boats/boat.gd` | Steering (seek + rock repulsion), net slow, ram, health, per-state drawing, world-upright HP pips, hit-based slowdown that recovers over time, obeys `world_time_scale()`, `hull_tint`/`hull_scale` for variants (v0.3). |
| `scripts/hazards/*.gd` | One class per hazard; self-registering, self-drawing. |
| `scripts/main/main.gd` | App shell: clear color, P slow-mo, game-over freeze, R restart, camera screen-shake on lighthouse hits. |
| `ui/hud.gd` | Polls sim each frame; builds controls in code. Health bar (with damage-chunk lag animation), enemy-wave status, lighthouse-hit screen pulse/text, game-over overlay. Reload/charge meters are NOT here (v0.3) — see MainGun. Deliberately dumb. |
| `debug/debug_overlay.gd` | F3 world-space overlay: rings, sectors, beam edges, steering vectors, hazard radii, vis letters. |
| `tests/screenshot_runner.gd` | Dev harness: runs Main, simulates two timed Space hold/release sequences (one PERFECT, one deliberate misfire), saves screenshots to `user://`, quits. |

Scenes mirror this: `Main.tscn` (shell) → `NightBoard.tscn` (sim root, hand-placed v0 hazards) → `Lighthouse.tscn` (beam/gun/turret children). `Boat.tscn`/`FastBoat.tscn`/`HeavyBoat.tscn` and hazard scenes are one node + script each, variants differing only in exported values.

## Tuning Values That Matter

All exported — tweak in the editor, not in code. Ring radii 55/115/190/265/335 (`OceanGrid`). Basic boat: 4 hp, 40 px/s, 15 ram damage. FastBoat: 2 hp, 65 px/s, 8 ram damage. HeavyBoat: 8 hp, 24 px/s, 26 ram damage. Spawn weights: 50% basic / 30% fast / 20% heavy (`BoatSpawner.fast_boat_weight`/`heavy_boat_weight`). Gun: 1 base dmg × 1/2/4 quality multiplier, 1.5s reload (`MainGun.reload_time`), illuminated-only. Turret: 1 dmg × 1.5 illuminated (chip damage), 0.85s interval, 100 range. Mine: 60 dmg (still overkill — see Known Issues). Beam: 22° cone, 26°/s auto, 100°/s manual, 30°/s precision (Down modifier). Spotted radius 140. Ghost lifetime 4s. Lighthouse 100 hp. Wave: 24 boats (`BoatSpawner.wave_size`).

## Charge Shot & Focus Ring (v0.3)

`MainGun` fires by holding Space; a ring drawn around the lighthouse (`CHARGE_RING_RADIUS`, radius 46) fills clockwise from the top as you hold, with the CHARGED (75–95%) and PERFECT (88–94%, nested inside) zones banded near the end of the ring — not a HUD corner widget, so it can't be missed.

- **Real-time clock, not engine delta.** `_charge_elapsed` accumulates via `_real_delta()` (wall-clock time from `Time.get_ticks_usec()`), never the scaled `delta` passed into `_process`. This is deliberate: see Focus Slowdown below for why using scaled delta would make the ring asymptotically approach 100% and never reach it.
- **No safe overshoot.** There is no fall-back-down grace period anymore. If the ring is still filling when elapsed time reaches `charge_up_time` (0.7s), the gun **misfires** automatically (`_misfire()`) — the player doesn't get to choose to release late. A misfire deals zero damage to any target, forces a punishing reload (`reload_time * misfire_reload_penalty`, default 1.6x), resets the ring, and deals `misfire_self_damage` (3 hp) backlash to the lighthouse via the *same* `Lighthouse.take_damage()`/`damaged` signal a boat ramming uses — so a misfire automatically gets the full existing hit-feedback treatment (screen shake, red flash, HUD pulse, "LIGHTHOUSE HIT" text) for free, plus its own purple "ring shatter" burst (`_draw_misfire_burst`).
- **Release before it fills** to fire at whatever quality (`ShotQuality`: NORMAL/CHARGED/PERFECT/MISFIRE) the ring shows; `quality_at()`/`multiplier_for()` are unchanged in spirit from v0.2, just no longer reachable via a falling meter.
- **Reload ring** (`RELOAD_RING_RADIUS`, radius 20, inside the charge ring) is drawn by the same `_draw()` call: fills clockwise as `cooldown_fraction()` progresses, flashes white→green on the not-ready→ready edge, with a "READY"/"RELOADING NN%" label centered below it. This replaced the old HUD corner reload bar entirely — `hud.gd` no longer owns any reload/charge UI.

## Focus Slowdown (v0.3)

While charging, `MainGun.world_time_scale()` returns `1.0 - charge_fraction` (floored at `world_slowdown_floor`, default 0.04) — full speed at 0% charge, nearly frozen at 100%, snapping back to 1.0 the instant you release or misfire. This is **not** `Engine.time_scale` (that stays reserved for the manual P slow-mo toggle) — instead, `Boat._physics_process`, `ShoreTurret._physics_process`, and `BoatSpawner._physics_process` each look up the gun via the `main_gun` group and multiply their own `delta` by `world_time_scale()` before using it. The player's own beam rotation and the charge ring's real-time clock are deliberately exempt, so the tension reads as "the world grinds down around you while your hand stays on real time" rather than everything (including your own aim) turning to molasses.

## Hit-Based Slowdown (v0.3)

`Boat.take_damage()` now also slows the boat: `target_factor = 1.0 - (amount / max_health) * hit_slow_strength`, floored at `hit_slow_floor` (0.2), and `_hit_slow_factor` takes the *stronger* of its current value and the new hit (so repeated hits stack/refresh rather than overriding upward). It eases back to 1.0 over `hit_slow_recovery_time` (1.5s) via `move_toward` each physics tick. This stacks with `_net_slow_factor()` and `world_time_scale()` multiplicatively. Because this makes landing a second/third shot meaningfully easier, the turret took an additional nerf this pass (0.6s → 0.85s interval, 115 → 100 range) on top of its v0.2 damage cut — see Tuning Values above.

## Enemy Variants (v0.3)

`FastBoat.tscn` and `HeavyBoat.tscn` reuse `boat.gd` with different exports plus `hull_tint`/`hull_scale` for a quick visual tell (cyan/small vs. orange/large; basic stays cream). `BoatSpawner._pick_scene()` rolls a weighted random choice each spawn. HP pip count follows `max_health` automatically (already capped at `MAX_HEALTH_PIPS`), no pip-drawing changes needed for the new health values.

## Readability & Balance Pass (v0.2, superseded in part by v0.3)

- **Boat HP pips.** `Boat._draw_health_pips()` draws one square per HP above the hull for SPOTTED/ILLUMINATED boats. Each corner is transformed individually through `to_local()` from a world-space anchor, so the row stays screen-upright regardless of hull heading instead of rotating with it — a reusable trick for any other "always-upright" indicator drawn from inside a rotated node's `_draw()`.
- **Lighthouse hit feedback.** `Lighthouse` gained a `damaged(amount)` signal and a local hit-flash ring in its own `_draw()`. `main.gd` subscribes for camera screen-shake (decaying `_shake_strength` applied to `Camera2D.offset`); `hud.gd` subscribes for a full-screen red pulse, a fading "LIGHTHOUSE HIT" label, and a health-bar "lag" layer that holds the pre-hit width and eases down over 0.4s so the lost chunk is visible for a moment instead of an instant snap. (v0.3 misfire backlash reuses this whole pipeline.)
- **Enemy wave status.** `BoatSpawner` has a finite `wave_size` (default 24) instead of spawning forever; exposes `spawned_count`, `remaining_to_spawn()`, `wave_complete()`. `NightBoard` has a `rammed` counter (boats that hit the lighthouse, as opposed to `kills` = boats sunk by damage) and `resolved_count()` = kills + rammed. HUD's enemy line always satisfies `remaining_total == at_sea + incoming` and switches to "All remaining ships are on the sea." once `incoming` hits 0.
- ~~Reload meter~~ / ~~charge meter~~ HUD widgets — **removed in v0.3**, replaced by the world-space rings described above.

## Extension Points (Codex-safe)

- More boat variants: another `.tscn` reusing `boat.gd` with different exports/`hull_tint`, plus a spawn weight in `BoatSpawner`.
- New hazards: new class in `scripts/hazards/`, register a group, draw yourself; VisibilitySystem/Boat only need touching if the hazard affects visibility or movement.
- Radar inset: read the same data VisibilitySystem already has (ghosts + states); render into a `SubViewport` or a corner `Control`.
- Day loop: wrap `NightBoard` in a phase state machine; `BoatSpawner.active` and scene reload are the existing hooks.
- Spawn-sector bias for the dusk forecast: `BoatSpawner._spawn()` is the single place angles are chosen.
- Anything else that should obey the focus slowdown: fetch `main_gun` from the group, multiply your own `delta` by `world_time_scale()` — that's the whole pattern, see Boat/ShoreTurret/BoatSpawner.

## Known Issues / Deliberate Gaps

- **Mines are still overkill** (60 dmg vs. 4 hp boats) — not addressed in v0.2 or v0.3. See [BACKLOG.md](./BACKLOG.md).
- **Balance is otherwise still rough** and now more volatile: hit-based slowdown + focus slowdown + three boat variants interact in ways only a real playtest pass will surface. Needs tuning, not just code correctness.
- Boats can jitter between closely-spaced rocks (radial repulsion, no real pathfinding). Hard-blocked boats do not attack rocks yet.
- `Boat`/`Mine`/`Turret`/`BoatSpawner` iterate full groups or do a group lookup every tick — O(boats × hazards). Fine at v0 scale; spatial partitioning only if profiling says so.
- **Wave is finite (24 boats) but there's still no win condition.** Once the wave is spawned and cleared, boats simply stop coming — the HUD says so, but nothing celebrates it or ends the run. Dawn/win screen is still a backlog item.
- Modes 1/2/3 are HUD-only placeholders (no ammo types).
- No radar/sonar inset yet (main-map ghosts + contact ticks fulfil the MVP lean).
- HUD hint bar and "LIGHTHOUSE HIT" label are positioned for 1280×720 only.
- No night-repair/multitasking layer yet (post-baseline per the handoff).
- Misfire self-damage (`MainGun.misfire_self_damage`, 3 hp, exported) is untested against a full night's attrition — could make an already-hard night harder if the player panics and over-holds repeatedly. Worth watching in playtest.
