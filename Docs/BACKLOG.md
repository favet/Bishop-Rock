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

### Immediate Next Tasks (post-Night-Board-v0, Codex-safe)

- [ ] Tuning pass: expose a difficulty knob (spawn ramp, boat hp/damage) and make an unattended lighthouse survive ~2 minutes. Now more urgent — hit-slowdown, focus-slowdown, and three boat variants interact in ways only a playtest will surface (see [NIGHT_BOARD_V0.md](./NIGHT_BOARD_V0.md#known-issues--deliberate-gaps)).
- [x] Boat variants: FastBoat (quick/weak) and HeavyBoat (slow/strong) as export presets of `boat.gd` with `hull_tint`/`hull_scale`. See [NIGHT_BOARD_V0.md](./NIGHT_BOARD_V0.md#enemy-variants-v03).
- [ ] Radar/sonar inset: corner display reading `VisibilitySystem` data (ghosts, states, beam angle).
- [ ] Win condition: now that `BoatSpawner.wave_size` is finite and HUD announces "All remaining ships are on the sea.", add an actual dawn/win screen once `at_sea == 0 and wave_complete()`.
- [ ] Pause vs slow: current P is slow-mo only; consider a true pause.
- [ ] Make the HUD hint bar and "LIGHTHOUSE HIT" label resolution-independent (anchors instead of fixed positions).
- [ ] Pick and install a Godot test addon (GUT/gdUnit4) and port the `tests/screenshot_runner.gd` smoke flow into it.
- [ ] Screenshot harness: promote to a proper CLI flag (custom output path) if used in CI.

## 2. Fable-Worthy Architecture / Simulation Tasks

Night Board v0 (2026-07-01) implemented the first slice of these — see [NIGHT_BOARD_V0.md](./NIGHT_BOARD_V0.md) for the architecture that now exists.

- [x] Ocean coordinate/navigation architecture v0 — `OceanGrid` polar rings/sectors + continuous boat movement, no physics engine.
- [x] Boat steering around rocks (seek + radial repulsion + hard separation). **Remaining:** real pathfinding for dense rock mazes; hard-blocked boats attacking blockers.
- [x] Beam cone / visibility / last-known-state — contact/spotted/illuminated on boats, fading ghosts + sector ticks in `VisibilitySystem`.
- [x] Main gun targeting tied to beam (beam-as-reticle, illuminated-only, Tab cycling).
- [x] Shore turret auto-fire with illuminated-damage bonus. **Rebalanced twice:** v0.2 dropped 6/9 dmg to 1/1.5 dmg so it can never one-shot alone; v0.3 further cut fire rate (0.6s→0.85s) and range (115→100) to offset hit-based slowdown making follow-up hits easier.
- [x] Hazard v0 behaviors: rocks block, mines explode, nets slow, buoys reveal. **Remaining:** modular hazard architecture review once hazard count grows; net durability; mine damage still needs retuning (see below).
- [x] Debug overlays (rings, sectors, beam edges, steering vectors, hazard radii, vis states — F3).
- [x] First playable vertical slice (night defense only).
- [x] Readability pass (v0.2): boat HP pips, lighthouse-hit feedback (flash/shake/pulse/text/health-lag), finite wave with enemy-status HUD line.
- [x] Focus-ring/misfire/world-slowdown pass (v0.3): charge and reload meters moved from the HUD corner to world-space rings around the lighthouse; overshooting the charge ring now forces a misfire (punishing reload + lighthouse backlash damage) instead of gracefully falling back; charging linearly slows boats/turret/spawner toward a stop; hit boats now slow down proportional to damage taken. See [NIGHT_BOARD_V0.md](./NIGHT_BOARD_V0.md#charge-shot--focus-ring-v03).
- [ ] Rock placement validation (navigable-approach check, seabed/depth validity) — needs the day phase.
- [ ] Tide/depth/rock interaction rules (hooks noted in `ocean_grid.gd`/`rock.gd`; still post-baseline).
- [ ] Day/night simulation state machine (real transitions, daylight pip economy wired to actions).
- [ ] Balance/tuning pass on night combat — now higher priority given how many systems interact (focus slowdown, hit slowdown, 3 boat variants, misfire risk).
- [ ] **Retune mine damage against the 4-hp basic boat** (60 dmg is still overkill). Turret has been rebalanced twice now; mines were out of scope both passes. See [NIGHT_BOARD_V0.md](./NIGHT_BOARD_V0.md#known-issues--deliberate-gaps).

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
