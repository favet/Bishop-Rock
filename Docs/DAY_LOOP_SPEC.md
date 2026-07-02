# Bishop Rock — Day Loop Spec

Source of truth: [BISHOP_ROCK_PREPRODUCTION_HANDOFF.md](./BISHOP_ROCK_PREPRODUCTION_HANDOFF.md)

## Core Loop

### Morning: aftermath

- Review damage.
- Wreckage may wash ashore.
- Some traps may be spent or damaged.
- Garden/planter/dock/lighthouse systems may need repairs.

### Day: preparation

Use a limited action/energy/daylight economy (see Day Economy below).

Candidate actions:

- Scavenge beach/wreckage.
- Fish.
- Tend planters.
- Repair lighthouse or island nodes.
- Craft or queue ammo/traps.
- Place or maintain sea hazards.
- Upgrade lighthouse components.
- Send skiff/mobile agent (later).

### Dusk: forecast

Provide partial information:

- Tide state.
- Fog/weather hint.
- Likely attack sectors.
- Rough wave size or boat silhouettes.

### Night: defense

- Boats spawn from any angle.
- Lighthouse beam sweeps automatically unless overridden.
- Player rotates beam with Q/E.
- Main gun fires through or into illuminated sector.
- Short-range turrets auto-fire at nearby visible/illuminated boats.
- Sea hazards shape approach.

See [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md) for controls and visibility states, and [OCEAN_MODEL_SPEC.md](./OCEAN_MODEL_SPEC.md) for hazards and turret/gun rules.

### Dawn: resolution

- Survivors retreat or are resolved.
- Resources/damage are calculated.
- Wreckage and salvage appear.
- Next day begins.

## Day Economy

Three rigid actions feels too restrictive. Use a flexible daylight/energy system.

Suggested MVP:

- Each day gives **6 daylight pips**.
- Actions cost **1–4 pips**.
- Routine crafting can happen in an end-of-day workshop queue.

Example costs:

| Action | Cost |
|---|---|
| Quick scavenge | 1 |
| Fish | 1–2 |
| Tend planters | 1 |
| Minor repair | 1 |
| Major repair | 2–3 |
| Place mine/net/buoy | 1–2 |
| Place rock | 3+ (also tide/depth-limited) |
| Upgrade lighthouse component | 2–4 |
| Deepwater skiff mission (later) | 2–4 |

## Island Nodes

The Bishop Rock image implies a very small, vertical, harsh setting. Use nodes rather than a farm/base map.

| Node | Function |
|---|---|
| Lantern room | Beam range, width, focus, visibility |
| Gun ring | Main gun, ammo, reload |
| Engine room | Rotation speed, manual control, fuel/power |
| Store room | Resources, ammo, oil, supplies |
| Workshop/winch | Crafting, hazard deployment, repairs |
| Rock ledges | Planter crates, tiny work areas, shore turrets |
| Tide pool/dock | Fishing, salvage, future skiff/mobile agent |

"Garden" means small planter crates or hardy rock ledges, not a field.

## Night Repair / Multitasking

The player should sometimes leave the gun/light controls during night. Full behavior is documented in [CONTROL_VISIBILITY_SPEC.md](./CONTROL_VISIBILITY_SPEC.md#night-repair--multitasking). Summary:

- Beam continues auto-rotating; gun/turrets continue at reduced efficiency if the player steps away.
- The player can spend emergency time repairing, reloading, boarding windows, pumping water, extinguishing fire, or fixing the engine/lens.
- Add this after the basic day/night loop works — it is a tension layer on top of the MVP loop, not part of the first playable slice.
