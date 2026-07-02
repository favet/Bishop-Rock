# Bishop Rock — Backlog

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

This backlog covers only setup and preproduction follow-through. It does not include gameplay implementation (boat pathfinding, beam detection, combat architecture) — those are reserved for a later, explicitly-requested pass. See [FABLE_HANDOFF.md](./FABLE_HANDOFF.md) for why those are separated out.

## 1. Codex-Friendly Setup / Routine Tasks

Safe for routine agent work — scaffolding, docs, repo hygiene, no architecture decisions.

- [x] Confirm engine/framework choice — **Godot 4, GDScript**.
- [x] Once engine is confirmed, create a blank project structure only (no gameplay code) — `project.godot`, `scenes/`, `scripts/`, `resources/`, `data/`, `ui/`, `debug/`, `tests/`.
- [x] Set up a placeholder top-down scene: center island sprite, water background, camera — `scenes/main/Main.tscn`.
- [x] Add debug-overlay toggle scaffold (empty layer/hook, no drawing logic yet) — `debug/DebugOverlay.tscn` (not yet instanced in Main or bound to a toggle key).
- [x] Create placeholder primitives for lighthouse, boat, rock, mine, net/chain, buoy (simple shapes, no behavior) — `scenes/lighthouse/`, `scenes/boats/`, `scenes/hazards/` (none instanced in Main yet).
- [x] Set up an input map with Q/E beam rotation, fire, cycle target, pause/slow, and number-key modes, with no logic bound yet — see `project.godot` `[input]` section and README. (`Shift`/focus-beam intentionally deferred — it's flagged as a later upgrade in the design docs, not part of the requested control set.)
- [x] Add project README pointing to `/Docs`.
- [ ] Initialize version control (git repo, `.gitignore` for Godot) — not yet done, do when ready to start committing.
- [ ] Set up a lightweight test/run harness (e.g., GUT or gdUnit4 addon) — `tests/` exists with a note only; no addon installed yet.
- [ ] Add a basic day/night phase state machine skeleton (empty transitions: morning → day → dusk → night → dawn) with no gameplay inside each phase — explicitly deferred, not done in this scaffolding pass.

### Immediate Next Tasks (post-scaffold)

- [ ] Open the project in the actual Godot 4 editor once and confirm it imports/runs cleanly; let the editor rewrite `config/features` to match the installed version.
- [ ] Decide whether to `git init` now and commit the scaffold as a baseline.
- [ ] Wire `ui/HUD.tscn` and `debug/DebugOverlay.tscn` as child `CanvasLayer`s of `Main.tscn` (still no drawing/widget logic — just instancing).
- [ ] Decide on a placeholder art style/palette (the ColorRect primitives are intentionally ugly stand-ins).
- [ ] Pick and install a Godot test addon before any simulation logic lands, so tests exist from day one of that work.

## 2. Fable-Worthy Architecture / Simulation Tasks

Do not start these until explicitly requested. Logic-dense, cross-cutting, or hard to unwind if built wrong.

- [ ] Ocean coordinate/navigation architecture (ring/sector abstraction vs. continuous boat movement — see [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md)).
- [ ] Boat steering/pathfinding around rocks and hazards, including hard-blocked behavior (attack the blocker).
- [ ] Beam cone / visibility / last-known-state implementation (contact → visible → illuminated → marked, with fade timers).
- [ ] Main gun targeting tied to beam direction/illuminated sector.
- [ ] Shore turret auto-fire logic and range/accuracy scaling against illuminated targets.
- [ ] Hazard architecture: rocks (blocker + rule validation for "always leave a channel"), mines (trigger + explosion), chains/nets (slow/snare), buoys (reveal/mark).
- [ ] Rock placement validation (navigable-approach check, seabed/depth validity).
- [ ] Tide/depth/rock interaction rules (deferred until after baseline combat per [MVP_SPEC.md](./MVP_SPEC.md)).
- [ ] Day/night simulation state machine (real transitions, daylight pip economy wired to actions).
- [ ] Debug overlays for rings, sectors, beam cone, boat steering, visibility, and hazard areas.
- [ ] First hard playable vertical slice combining the above.

## 3. Later Content / Polish Tasks

Not needed for MVP acceptance. Sequence after the vertical slice proves the core loop is fun.

- [ ] Additional enemy behaviors: raiders that land, ranged boats, fog-making boats, mine-sweeping boats.
- [ ] Additional hazards: reefs, oil slicks, decoy lanterns, wrecks, currents, fog banks, explosive barrels, sandbars.
- [ ] Later ammo types: chain shot, flare shot, explosive shot, salt/anti-ghost shot, harpoon shot.
- [ ] Skiff/mobile agent and deepwater deployment upgrade.
- [ ] Real upgradable radar/sonar instrument (beyond MVP debug inset).
- [ ] Full night-repair/multitasking systems: boarding windows, pumping water, extinguishing fire, engine/lens repair minigames.
- [ ] Storm events that damage overbuilt breakwaters.
- [ ] Art pass: replace placeholder primitives with real sprites/animation, matching the "modular bones support later art upgrades" goal.
- [ ] Meta-progression / run structure beyond a single night-to-night loop (if desired).
