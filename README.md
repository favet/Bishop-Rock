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

## Current State

This is scaffolding only. Placeholder scenes exist for the lighthouse, a boat, and the four MVP hazards (rock, mine, chain/net, buoy), but none of them have behavior yet, and none are instanced into the main scene. The input map (Q/E beam rotation, fire, cycle target, pause/slow, number-key modes) is wired in Project Settings but not bound to any logic.

See [Docs/BACKLOG.md](Docs/BACKLOG.md) for what's next, and [Docs/FABLE_HANDOFF.md](Docs/FABLE_HANDOFF.md) for which systems are reserved for a dedicated architecture pass rather than routine work.

## Input Map

| Action | Key |
|---|---|
| `beam_rotate_ccw` | Q |
| `beam_rotate_cw` | E |
| `fire` | Space |
| `cycle_target` | Tab |
| `pause_slow` | P |
| `mode_1` | 1 |
| `mode_2` | 2 |
| `mode_3` | 3 |

Verify these under **Project > Project Settings > Input Map** after opening in the editor.
