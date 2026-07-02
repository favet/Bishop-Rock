# Bishop Rock — Product Brief

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

## High Concept

**Bishop Rock** is a 2D top-down, 360-degree lighthouse defense game. The player maintains a tiny rock-island lighthouse by day, then survives night attacks from boats approaching from any direction. The lighthouse beam reveals and enables long-range attacks, short-range automatic turrets protect the shore, and the player shapes the surrounding sea with rocks, mines, chains/nets, and buoys.

The fantasy is not a large island base. It is a small vertical lighthouse machine on a jagged rock, inspired by real isolated sea lighthouses.

> Prepare the rock. Shape the sea. Control the light. Survive the night.

## Target

- Offline Windows laptop game.
- Minimal 2D top-down placeholder visuals.
- Must run well on ordinary integrated-graphics laptops.
- Modular bones should support later art upgrades.
- Initial implementation favors clarity, debug overlays, and simple primitives over polish.

## Genre Frame

Not generic tower defense. Prefer:

- 360-degree lighthouse survival defense
- nautical perimeter defense
- light-guided sea defense

Most combat occurs at sea. The island is intentionally tiny.

## Design Pillars

1. **Lighthouse as main character** — the eye, weapon platform, warning system, and vulnerable core.
2. **Ocean as board** — the strategic space is the water around the lighthouse, not a sprawling base.
3. **Boats should feel like boats** — heading, steering limits, speed, preferred approach targets, and reactions to rocks/hazards/light.
4. **Light creates knowledge and targeting** — the beam reveals distant contacts, illuminates targets for the main gun, and leaves temporary last-known information.
5. **Day choices feed night survival** — fishing, scavenging, gardening/planters, repairs, crafting, and upgrades must support the night defense. Avoid a bloated cozy sim.
6. **Minimal first, modular forever** — start with a very small MVP but build systems that can accept more enemies, hazards, upgrades, tides, and visuals later.

## Current Strong Decisions

| Area | Decision |
|---|---|
| Working title | Bishop Rock |
| View | 2D top-down |
| Visuals | Minimal primitives/placeholders |
| Combat space | Mostly at sea |
| Island scale | Tiny lighthouse rock, node-based |
| Input priority | Keyboard-first, mouse optional |
| Beam | Auto-rotates by default; Q/E can manually rotate/override |
| Main gun | Fires into illuminated sector; likely tied to beam direction |
| Fire mode | Manual fire first, or optional auto-fire setting; no mouse precision required |
| Turrets | Short-range automatic shore defense |
| Visibility | Contact → visible/spotted → illuminated; optional marked/last-known state |
| Day economy | Daylight/energy pips, not just 3 rigid actions |
| Crafting | Consider end-of-day workshop queue for routine crafting |
| Tide | Simple low/normal/high tide states eventually |
| Rocks | Strong, expensive, depth/tide-limited, cannot fully seal island |
| MVP hazards | Rocks, mines, chains/nets, buoys |
| Enemy scope | Start with simple boats trying to damage the lighthouse |
| First milestone | Robust docs/scaffold, not full implementation |

## Related Docs

- [MVP_SPEC.md](./MVP_SPEC.md) — what the first playable slice must demonstrate
- [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md) — input model and visibility states
- [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md) — rings/sectors, hazards, tide, rock rules
- [DAY_LOOP_SPEC.md](./DAY_LOOP_SPEC.md) — core loop, day economy, island nodes
- [BACKLOG.md](./BACKLOG.md) — implementation task backlog
- [FABLE_HANDOFF.md](./FABLE_HANDOFF.md) — what to save for the hard-simulation pass
