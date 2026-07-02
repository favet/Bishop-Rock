# Bishop Rock — Control & Visibility Spec

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

## Control Model

Primary goal: laptop-friendly, keyboard-first. Avoid requiring precise mouse aiming. Mouse can be optional later for targeting, placement, or UI.

Candidate MVP controls:

| Input | Action |
|---|---|
| Q | Rotate beam counterclockwise while held |
| E | Rotate beam clockwise while held |
| Space | Fire main gun into current illuminated sector / selected target |
| Tab | Cycle target among illuminated targets |
| 1/2/3 | Select ammo/mode |
| Shift | Focus beam briefly (later upgrade) |
| Pause/slow key | Optional tactical pause/slowdown |

### Beam/Gun Recommendation

Start with **beam-as-reticle**:

- Beam direction is the effective main gun direction.
- Player controls one direction of attention rather than separate gun and light aim.
- Auto-fire can be an accessibility/upgrade setting.

## Visibility Model

Use both main-map memory and a small secondary radar/sonar-style display, but do not make the player stare only at the mini-map.

### Main Screen States

Enemies leave temporary afterimages/last-known silhouettes after illumination. These fade after a few seconds or become less accurate.

1. **Contact** — vague sector/horizon indication.
2. **Visible/Spotted** — exact-ish location, targetable by close defenses if near enough.
3. **Illuminated** — fully visible, main-gun-valid, higher accuracy/damage.
4. **Last known/Marked** — recently illuminated, fades over time.

### Sonar/Radar-Style Inset

A small circular inset can show:

- ring/sector overview
- fading dots from recently illuminated enemies
- buoy/scout contacts
- uncertainty/fade over time
- current beam direction
- tide/approach rings later

Tone: this should feel like a "lamp memory chart" or primitive keeper's instrument rather than modern radar, if the theme stays historical/supernatural.

### Recommendation

- **MVP**: main-map fading last-known silhouettes, plus a debug/player radar inset if easy.
- **Later**: make the inset a real upgradable instrument.

## Night Repair / Multitasking

The player should sometimes leave the gun/light controls during night.

When the player is not manning the light/gun:

- beam continues auto-rotating
- gun may auto-fire at reduced efficiency if enabled/upgraded
- turrets continue auto-firing
- player can spend emergency time repairing, reloading, boarding windows, pumping water, extinguishing fire, or fixing the engine/lens

This creates a strong tension:

> Do I stay at the lantern/gun to control the battle, or do I abandon perfect aim to keep the lighthouse from falling apart?

Add this after the basic loop works — see [DAY_LOOP_SPEC.md](./DAY_LOOP_SPEC.md) and [BACKLOG.md](./BACKLOG.md).
