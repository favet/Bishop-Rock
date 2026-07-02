# Bishop Rock — Fable Handoff

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

This doc defines what to hand to Fable (or another dedicated architecture pass) once preproduction docs and scaffolding are in place, and explicitly what not to hand it.

## Why This Split Exists

Codex/routine agent work is trusted for scaffolding, docs, repo setup, and routine implementation. It should not be asked to invent the architecture of the hardest systems. Fable is reserved for the logic-dense core that is expensive to redo if the wrong structure is chosen early.

## What Fable Should Be Saved For

- Final ocean coordinate/navigation architecture (ring/sector abstraction reconciled with continuous boat movement — see [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md)).
- Boat steering/pathfinding around rocks and hazards.
- Beam cone / visibility / last-known-state implementation (see [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md)).
- Tide/depth/rock rules.
- Modular hazard architecture (rocks, mines, chains/nets, buoys, and room for later hazard types).
- Simulation state machine (day/night phases, daylight economy wiring).
- Debug overlays for rings, sectors, beam cone, boat steering, visibility, and hazard areas.
- First hard playable vertical slice.

## What Fable Should Not Be Spent On

- Broad brainstorming or concept iteration — design decisions are already captured in the handoff and specs.
- File scaffolding or repo setup — routine/Codex work.
- Routine markdown/docs cleanup.

## Inputs Fable Will Need

- [PRODUCT_BRIEF.md](./PRODUCT_BRIEF.md) — pillars and framing, so architecture choices don't drift into generic tower defense.
- [MVP_SPEC.md](./MVP_SPEC.md) — the acceptance bar for the first slice; do not build beyond it.
- [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md) — ring/sector model, hazard roles, rock placement rules, tide states, turret/gun rules.
- [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md) — control scheme and the four-stage visibility model (contact/visible/illuminated/last-known).
- [DAY_LOOP_SPEC.md](./DAY_LOOP_SPEC.md) — phase structure and daylight pip economy the simulation state machine must support.
- Whatever project scaffold Codex has produced by that point (engine project, placeholder scenes/primitives, input map skeleton — see [BACKLOG.md](./BACKLOG.md) section 1).

## Open Design Questions Fable Should Resolve Concretely

These are currently leans, not locked decisions. Fable's architecture should either implement the lean or surface why it doesn't work:

1. Main gun firing: manual, auto-fire, or both (lean: both, manual default).
2. Radar/sonar inset: MVP or later (lean: main-map fading silhouettes are MVP; inset if easy).
3. Night repair scope: how much is allowed (lean: yes, risky, reduced-efficiency auto-run — see [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md#night-repair--multitasking)).
4. Rock collision: path-block vs. physical collision (lean: pathfinding/avoidance first, simple collision/damage if hit).
5. Tide in MVP: (lean: no, add after baseline combat).

## Explicit Guardrail

Do not begin boat pathfinding, beam detection, or combat architecture until explicitly asked. This handoff exists so that when that request comes, Fable can start from a complete picture instead of re-deriving the design.
