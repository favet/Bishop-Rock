# Bishop Rock — Ocean Model Spec

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

This is a design document, not an implementation plan. The ocean coordinate/navigation architecture itself is reserved for a dedicated Fable pass — see [FABLE_HANDOFF.md](./FABLE_HANDOFF.md).

## Design Abstraction

Use a hybrid polar/continuous model.

The ocean is divided into **rings** and **sectors** for placement, balance, visibility, tides, and debug display. Boats can still move continuously in 2D so they feel alive — the ring/sector grid is a design and debug abstraction, not necessarily the movement representation.

### Candidate Rings

1. Shore / contact damage zone
2. Shallows
3. Midwater
4. Deep water
5. Horizon / spawn zone

### Candidate Sectors

- 16, 24, or 32 angular slices around the lighthouse.

### Why Rings Matter

Rings help define:

- spawn distance
- shore turret range
- main gun range
- trap placement costs
- rocks/depth limits
- tide effects
- mobile agent patrol range
- visibility falloff
- debug overlays

Example:

- Basic turret reaches only shore/shallows.
- Main gun can reach horizon, but only through illumination.
- Rocks are placeable only in shallows/midwater at first.
- Deepwater deployment requires a later skiff/winch upgrade.

## Sea Hazards

### MVP Hazards

| Hazard | Role |
|---|---|
| Rocks | Expensive semi-permanent blockers/obstacles |
| Mines | One-time explosive damage |
| Chains/Nets | Slow, snare, or delay boats |
| Buoys | Reveal contacts, mark sectors, or help targeting |

### Later Hazards

Reefs, oil slicks, decoy lanterns, wrecks, currents, fog banks, explosive barrels, sandbars.

Hazards should alter navigation, visibility, speed, steering, and approach decisions — not only deal damage.

## Rock Placement Rules

Need to prevent "why not make a full circle?"

Suggested rule stack:

1. The game validates that at least one navigable approach remains.
2. Rocks are only placeable on valid seabed/depth cells.
3. Rocks behave differently by tide and depth.
4. Rocks are expensive in resources and daylight.
5. Boats that are truly hard-blocked attack blocking rocks.
6. The lighthouse must maintain channels for fishing, supply, and skiff access.
7. Storms/tide can damage overbuilt breakwaters later.

Fictional explanation:

> Bishop Rock cannot be sealed completely because the lighthouse still needs navigable water, tide flow, and access for the keeper's skiff/winch.

## Tide System

Do not build complex tide simulation early. Use three states:

| Tide | Effect |
|---|---|
| Low tide | Rocks/reefs block more; beach scavenging better; channels narrower |
| Normal tide | Baseline |
| High tide | Some rocks become passable/damaging rather than blocking; boats can approach closer; shore defenses under more pressure |

Tide is a useful way to make rock defenses powerful but not absolute. Current lean: **not required for the first night prototype** — document now, wire in after baseline combat works (see [MVP_SPEC.md](./MVP_SPEC.md)).

## Automatic Turrets

Include short-range automatic turrets from early on.

Role:

- Last line of defense.
- Handles leaks near shore.
- Reduces need for perfect 360 manual attention.
- Supports laptop-friendly controls.

Limitations:

- Low range at start.
- Weaker than main gun.
- May require visibility.
- Stronger against illuminated targets.
- Cannot win alone.

Good MVP rule:

> Shore turrets auto-fire at close visible boats. They gain accuracy/range/damage against illuminated boats.

## Main Gun

Initial gun:

- Basic cannon.
- Fires into illuminated sector or at selected illuminated target.
- Long range compared with shore turrets.
- Reload-limited.
- Basic shot first.

Later ammo (not MVP): chain shot, flare shot, explosive shot, salt/anti-ghost shot, harpoon shot.
