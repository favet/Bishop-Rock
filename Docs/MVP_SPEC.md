# Bishop Rock — MVP Spec

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

This spec defines what the first playable simulation must demonstrate. It is intentionally small. See [FABLE_HANDOFF.md](./FABLE_HANDOFF.md) for which of these systems are hard enough to require a dedicated architecture pass rather than routine implementation.

## MVP Enemy Scope

Start small. Do not overdesign enemy families yet.

- Simple boat
- Faster boat
- Tougher boat

All initially try to reach and damage the lighthouse. Later they can land raiders, sabotage, shoot from range, create fog, sweep mines, etc. (not MVP).

The first question to prove:

> Is scanning, illuminating, firing, and relying on shore turrets/traps fun against simple boats?

## MVP Hazards

| Hazard | Role |
|---|---|
| Rocks | Expensive semi-permanent blockers/obstacles |
| Mines | One-time explosive damage |
| Chains/Nets | Slow, snare, or delay boats |
| Buoys | Reveal contacts, mark sectors, or help targeting |

Later hazards (not MVP): reefs, oil slicks, decoy lanterns, wrecks, currents, fog banks, explosive barrels, sandbars.

## MVP Acceptance Criteria

A first playable simulation should demonstrate:

- Top-down lighthouse/island in center.
- Boats spawn from arbitrary angles around the horizon.
- Boats move toward the lighthouse.
- Boats steer around rocks if possible.
- If hard-blocked, boats can damage blockers.
- Lighthouse beam auto-rotates.
- Q/E manually rotate or override beam.
- Main gun fires into illuminated sector.
- Short-range turret auto-fires at close visible enemies.
- Rocks, mines, nets/chains, and buoys can be placed.
- Mines explode.
- Nets/chains slow.
- Buoys reveal or mark nearby contacts.
- Enemies have contact/visible/illuminated/last-known states.
- Last-known contacts fade on main map.
- Optional radar/sonar inset shows recent contacts.
- Day phase gives daylight pips and a few prep actions.
- Damage/loss condition exists.
- Debug overlays exist for rings, sectors, beam cone, boat steering, visibility, and hazard areas.

## Explicitly Out of Scope for MVP

- Tide simulation (design it now, wire it in after baseline combat works — see [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md)).
- Skiff/mobile agent, deepwater deployment.
- Later ammo types (chain shot, flare, explosive, salt/anti-ghost, harpoon).
- Later hazards beyond rocks/mines/chains-nets/buoys.
- Raiders, ranged boats, fog-making boats, mine-sweeping boats.
- Full night-repair minigame beyond the basic "leave the station" tension (see [DAY_LOOP_SPEC.md](./DAY_LOOP_SPEC.md)).

## Open Questions Affecting MVP Scope

1. **Main gun firing** — manual button press, auto-fire, or both? Current lean: both; manual default for feel, auto-fire as a setting/upgrade.
2. **Radar/sonar inset** — MVP or later? Current lean: main-map fading silhouettes are MVP; radar inset only if easy/debuggable.
3. **Night repair** — how much is allowed? Current lean: yes, but risky; leaving the gun/light station lets the lighthouse auto-run at lower efficiency.
4. **Rock collision** — physical collision or path-block only? Current lean: pathfinding/avoidance first, with simple collision/damage if hit.
5. **Tide in MVP?** — Current lean: probably not the first night prototype; document now, add after baseline combat.
