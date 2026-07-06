# Bishop Rock

A minimal 2D top-down, 360-degree lighthouse survival defense game. Engine: **Godot 4** (GDScript).

Design docs live in [Docs/](Docs/) — start with [Docs/PRODUCT_BRIEF.md](Docs/PRODUCT_BRIEF.md). Source of truth for the design is [Docs/BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](Docs/BISHOP_ROCK_PREPRODUCTION_HANDOFF.md).

## Opening the Project

1. Install [Godot 4](https://godotengine.org/download) (this project was scaffolded assuming ~4.3; any 4.x editor should open it — Godot will just update the `config/features` tag on first save if your version differs).
2. Launch the Godot 4 editor.
3. Click **Import**, browse to this folder, and select `project.godot`.
4. Once imported, click **Open**.

## Running the Project

- Press **F5** (or the Play button in the top-right) to run the main scene.
- The main scene (`scenes/main/Main.tscn`) currently shows a placeholder blue water background with a small placeholder island square in the center — this confirms the project runs. No gameplay is implemented yet.

## Project Structure

| Folder | Purpose |
|---|---|
| `scenes/` | Scene files, organized by feature (`main/`, `lighthouse/`, `boats/`, `hazards/`) |
| `scripts/` | GDScript files, mirroring the `scenes/` layout |
| `resources/` | Typed Godot `Resource`/`.tres` data (empty for now) |
| `data/` | Non-Resource game data such as JSON tuning tables (empty for now) |
| `ui/` | HUD and other UI scenes/scripts, self-contained |
| `debug/` | Debug overlay scenes/scripts (rings, sectors, beam cone, etc.), self-contained |
| `tests/` | Reserved for a future Godot test addon (GUT or gdUnit4) |
| `Docs/` | Design docs and preproduction handoff |

## Current State — Campaign Loop v1

The game is currently in the **Campaign Loop v1** phase. It features a seven-day survival loop that wraps the original Night Board v0 defense phase:

- **Night Raid**: Boats — basic, fast/weak, and slow/tough variants — spawn and steer toward the lighthouse. The campaign logic curates wave composition and size based on the day. The main gun's hold-to-charge shot is the main killer, slowing down time while charging. Overshoot the charge and it misfires, hurting the lighthouse. The shore turret, mines, barricades, and other hazards help shape the sea.
- **Dawn Summary**: Once the wave is cleared, a dawn summary displays boats sunk, gold earned, perfect hit bonuses, damage taken, and the state of your hull and defenses.
- **Day Hub**: A visual day hub lets you spend limited energy and resources (gold, wood, scrap, food) on actions across four zones (Lighthouse, Workshop, Shore / Dock / Farm, Quarters). You can repair the lighthouse, craft defenses, start long-term upgrade projects, and prepare for the next night.
- **Next Night**: Defenses are consumed or persisted based on their type, and you survive another night. Lighthouse hull at 0 ends the run.

Architecture notes for the original night board: [Docs/NIGHT_BOARD_V0.md](Docs/NIGHT_BOARD_V0.md).
Campaign loop design and specs: [Docs/CAMPAIGN_LOOP_V1.md](Docs/CAMPAIGN_LOOP_V1.md).
Task list: [Docs/BACKLOG.md](Docs/BACKLOG.md).

Not in yet: trader, sector placement UI, breakwaters, decoys, storms, advanced ammo types, radar inset.

## Controls

| Key | Action |
|---|---|
| ← / → | Rotate beam counterclockwise/clockwise (primary) |
| Hold ↓ + ← / → | Rotate beam at slower, precise speed |
| Q | Toggle beam mode: AUTO_SWEEP ↔ MANUAL_HOLD |
| E | Rotate beam clockwise (secondary binding, same as →) |
| Hold Space, release | Charge and fire the main gun (see Charge Shot below) |
| Tab | Cycle target among illuminated boats |
| 1 / 2 / 3 | Select gun mode (placeholder — no gameplay effect yet) |
| P | Toggle slow motion |
| F3 | Toggle debug overlay (rings, sectors, steering, hazard radii) |
| R | Restart the night |

### Beam Modes

- **AUTO_SWEEP** (default): the beam rotates on its own. Holding ←/→ temporarily overrides it; releasing resumes the sweep from wherever the beam ended up.
- **MANUAL_HOLD**: the beam only moves when you rotate it with ←/→, and stays exactly where you leave it otherwise.
- Q toggles between the two modes at any time. Manual rotation with ←/→ works in both modes.

### Charge Shot & Focus Ring

Space is hold-to-charge, not tap-to-fire. You can only start charging when the gun is off cooldown — this is a fragile, overloaded weapon, not a turret you can lean on.

- Holding Space fills a **ring around the lighthouse itself**, clockwise from the top, over ~0.7s. **75–95%** is the CHARGED zone (2x damage, gold band); **88–94%** (nested inside it) is the PERFECT zone (4x damage, red band) — both banded near the end of the ring, so you can see the target coming.
- **There is no safe overshoot.** If the ring fills all the way while you're still holding, the gun **misfires** — no damage, a punishing reload, the ring resets, and the lighthouse itself takes a jolt of backlash damage (same screen-shake/flash/"LIGHTHOUSE HIT" feedback as a ram). Release *before* it fills, every time.
- **The world slows down as you charge.** Boats, the shore turret, and incoming spawns all gradually grind toward a near-stop as the ring approaches full — and snap back to normal speed the instant you release or misfire. Your own beam control and the charge timer itself stay on real time, so the tension is real: everything else seems to freeze while your hand is still on the clock.
- A reload ring sits just inside the charge ring, filling clockwise with a "READY"/"RELOADING NN%" label, flashing white the instant it completes — also drawn at the lighthouse, not the corner.
- Targeting is unchanged: a released (non-misfired) shot resolves against the selected/nearest illuminated boat, or a wasted blind shot if nothing is illuminated. A hit also visibly slows the boat down for a moment, proportional to how hard it was hit.

## Dev Harness

`tests/ScreenshotRunner.tscn` boots the game, drives two charge/release sequences (one PERFECT, one deliberate misfire), and saves a spread of screenshots to `user://` (`%APPDATA%/Godot/app_userdata/Bishop Rock/`) before quitting:

```
godot --path . res://tests/ScreenshotRunner.tscn
```

Headless smoke test (no window, catches script errors):

```
godot --headless --path . --quit-after 600
```
