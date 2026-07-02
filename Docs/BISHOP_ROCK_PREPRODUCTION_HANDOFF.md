# Bishop Rock — Preproduction Handoff v0.2

## Purpose

This document captures the current strong design decisions for **Bishop Rock**, a minimal 2D top-down lighthouse survival defense game. The goal is to give a coding agent enough context to set up project scaffolding and documentation without spending time re-litigating the concept.

Do not overbuild. The first milestone is not a complete game. It is a clean project structure and a robust design/technical foundation for a later Fable/Claude Code pass to implement the hard simulation core.

---

## High Concept

**Bishop Rock** is a 2D top-down 360-degree lighthouse defense game. The player maintains a tiny rock-island lighthouse by day, then survives night attacks from boats approaching from any direction. The lighthouse beam reveals and enables long-range attacks, short-range automatic turrets protect the shore, and the player shapes the surrounding sea with rocks, mines, chains/nets, and buoys.

The fantasy is not a large island base. It is a small vertical lighthouse machine on a jagged rock, inspired by real isolated sea lighthouses.

Core phrase:

> Prepare the rock. Shape the sea. Control the light. Survive the night.

---

## Target

- Offline Windows laptop game.
- Minimal 2D top-down placeholder visuals.
- Must run well on ordinary integrated-graphics laptops.
- Modular bones should support later art upgrades.
- Initial implementation should favor clarity, debug overlays, and simple primitives over polish.

---

## Genre Frame

Do not describe this primarily as generic tower defense.

Better framing:

- 360-degree lighthouse survival defense
- nautical perimeter defense
- light-guided sea defense

Most combat occurs at sea. The island is intentionally tiny.

---

## Design Pillars

### 1. Lighthouse as main character

The lighthouse is the eye, weapon platform, warning system, and vulnerable core.

### 2. Ocean as board

The strategic space is the water around the lighthouse, not a sprawling base.

### 3. Boats should feel like boats

Enemies should have heading, steering limits, speed, preferred approach targets, and reactions to rocks/hazards/light.

### 4. Light creates knowledge and targeting

The beam should reveal distant contacts, illuminate targets for the main gun, and leave temporary last-known information.

### 5. Day choices feed night survival

Fishing, scavenging, gardening/planters, repairs, crafting, and upgrades must support the night defense. Avoid a bloated cozy sim.

### 6. Minimal first, modular forever

Start with a very small MVP but build systems that can accept more enemies, hazards, upgrades, tides, and visuals later.

---

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
| Fire mode | Manual fire first or optional auto-fire setting; do not require mouse precision |
| Turrets | Short-range automatic shore defense |
| Visibility | Contact → visible/spotted → illuminated; optional marked/last-known state |
| Day economy | Daylight/energy pips, not just 3 rigid actions |
| Crafting | Consider end-of-day workshop queue for routine crafting |
| Tide | Simple low/normal/high tide states eventually |
| Rocks | Strong, expensive, depth/tide-limited, cannot fully seal island |
| MVP hazards | Rocks, mines, chains/nets, buoys |
| Enemy scope | Start with simple boats trying to damage the lighthouse |
| First milestone | Robust docs/scaffold, not full implementation |

---

## Core Loop

### Morning: aftermath

- Review damage.
- Wreckage may wash ashore.
- Some traps may be spent or damaged.
- Garden/planter/dock/lighthouse systems may need repairs.

### Day: preparation

Use a limited action/energy/daylight economy.

Candidate actions:
- Scavenge beach/wreckage.
- Fish.
- Tend planters.
- Repair lighthouse or island nodes.
- Craft or queue ammo/traps.
- Place or maintain sea hazards.
- Upgrade lighthouse components.
- Send skiff/mobile agent later.

### Dusk: forecast

Provide partial information:
- tide state
- fog/weather hint
- likely attack sectors
- rough wave size or boat silhouettes

### Night: defense

- Boats spawn from any angle.
- Lighthouse beam sweeps automatically unless overridden.
- Player rotates beam with Q/E.
- Main gun fires through or into illuminated sector.
- Short-range turrets auto-fire at nearby visible/illuminated boats.
- Sea hazards shape approach.

### Dawn: resolution

- Survivors retreat or are resolved.
- Resources/damage are calculated.
- Wreckage and salvage appear.
- Next day begins.

---

## Control Model

Primary goal: laptop-friendly, keyboard-first.

Candidate MVP controls:

| Input | Action |
|---|---|
| Q | Rotate beam counterclockwise while held |
| E | Rotate beam clockwise while held |
| Space | Fire main gun into current illuminated sector / selected target |
| Tab | Cycle target among illuminated targets |
| 1/2/3 | Select ammo/mode |
| Shift | Focus beam briefly, later upgrade |
| Pause/slow key | Optional tactical pause/slowdown |

Avoid requiring precise mouse aiming. Mouse can be optional later for targeting, placement, or UI.

### Beam/Gun Recommendation

Start with **beam-as-reticle**:
- Beam direction is the effective main gun direction.
- Player controls one direction of attention rather than separate gun and light aim.
- Auto-fire can be an accessibility/upgrade setting.

---

## Visibility and Sonar/Radar Recommendation

Use both main-map memory and a small secondary radar/sonar-style display, but do not make the player stare only at the mini-map.

### Main screen

Enemies should leave temporary afterimages/last-known silhouettes after illumination. These fade after a few seconds or become less accurate.

Main screen states:
1. **Contact** — vague sector/horizon indication.
2. **Visible/Spotted** — exact-ish location, targetable by close defenses if near enough.
3. **Illuminated** — fully visible, main-gun-valid, higher accuracy/damage.
4. **Last known/Marked** — recently illuminated, fades over time.

### Sonar/radar-style inset

A small circular inset can show:
- ring/sector overview
- fading dots from recently illuminated enemies
- buoy/scout contacts
- uncertainty/fade over time
- current beam direction
- tide/approach rings later

This should feel like a “lamp memory chart” or primitive keeper’s instrument rather than modern radar if the theme stays historical/supernatural.

Recommendation:
- MVP: implement main-map fading last-known silhouettes plus a debug/player radar inset if easy.
- Later: make the inset a real upgradable instrument.

---

## Ocean Model

Use a hybrid polar/continuous model.

### Design abstraction

The ocean is divided into rings and sectors for placement, balance, visibility, tides, and debug display.

Boats can still move continuously in 2D so they feel alive.

Candidate rings:
1. Shore / contact damage zone
2. Shallows
3. Midwater
4. Deep water
5. Horizon / spawn zone

Candidate sectors:
- 16, 24, or 32 angular slices around the lighthouse.

### Why rings matter

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
- basic turret reaches only shore/shallows
- main gun can reach horizon but only through illumination
- rocks start placeable only in shallows/midwater
- deepwater deployment requires a later skiff/winch upgrade

---

## Sea Hazards

MVP hazards:

| Hazard | Role |
|---|---|
| Rocks | Expensive semi-permanent blockers/obstacles |
| Mines | One-time explosive damage |
| Chains/Nets | Slow, snare, or delay boats |
| Buoys | Reveal contacts, mark sectors, or help targeting |

Later hazards:
- reefs
- oil slicks
- decoy lanterns
- wrecks
- currents
- fog banks
- explosive barrels
- sandbars

Hazards should alter navigation, visibility, speed, steering, and approach decisions, not only deal damage.

---

## Rock Placement Rules

Need to prevent “why not make a full circle?”

Suggested stack of rules:
1. The game validates that at least one navigable approach remains.
2. Rocks are only placeable on valid seabed/depth cells.
3. Rocks behave differently by tide and depth.
4. Rocks are expensive in resources and daylight.
5. Boats that are truly hard-blocked attack blocking rocks.
6. The lighthouse must maintain channels for fishing, supply, and skiff access.
7. Storms/tide can damage overbuilt breakwaters later.

Fictional explanation:
> Bishop Rock cannot be sealed completely because the lighthouse still needs navigable water, tide flow, and access for the keeper’s skiff/winch.

---

## Tide System

Do not build complex tide simulation early. Use three states:

| Tide | Effect |
|---|---|
| Low tide | rocks/reefs block more; beach scavenging better; channels narrower |
| Normal tide | baseline |
| High tide | some rocks become passable/damaging rather than blocking; boats can approach closer; shore defenses under more pressure |

Tide is a useful way to make rock defenses powerful but not absolute.

---

## Island Nodes

The Bishop Rock image implies a very small, vertical, harsh setting. Use nodes rather than a farm/base map.

Candidate nodes:

| Node | Function |
|---|---|
| Lantern room | beam range, width, focus, visibility |
| Gun ring | main gun, ammo, reload |
| Engine room | rotation speed, manual control, fuel/power |
| Store room | resources, ammo, oil, supplies |
| Workshop/winch | crafting, hazard deployment, repairs |
| Rock ledges | planter crates, tiny work areas, shore turrets |
| Tide pool/dock | fishing, salvage, future skiff/mobile agent |

“Garden” means small planter crates or hardy rock ledges, not a field.

---

## Day Economy

Three actions feels too restrictive. Use a flexible daylight/energy system.

Suggested MVP:
- Each day gives 6 daylight pips.
- Actions cost 1–4 pips.
- Routine crafting can happen in an end-of-day workshop queue.

Example costs:
- quick scavenge: 1
- fish: 1–2
- tend planters: 1
- minor repair: 1
- major repair: 2–3
- place mine/net/buoy: 1–2
- place rock: 3+ and tide/depth-limited
- upgrade lighthouse component: 2–4
- deepwater skiff mission later: 2–4

---

## Automatic Turrets

Include short-range automatic turrets from early on.

Role:
- last line of defense
- handles leaks near shore
- reduces need for perfect 360 manual attention
- supports laptop-friendly controls

Limitations:
- low range at start
- weaker than main gun
- may require visibility
- stronger against illuminated targets
- cannot win alone

Good MVP rule:
> Shore turrets auto-fire at close visible boats. They gain accuracy/range/damage against illuminated boats.

---

## Main Gun

Initial gun:
- basic cannon
- fires into illuminated sector or at selected illuminated target
- long range compared with shore turrets
- reload-limited
- can use basic shot first

Later ammo:
- chain shot
- flare shot
- explosive shot
- salt/anti-ghost shot
- harpoon shot

---

## MVP Enemy Scope

Start small. Do not overdesign enemy families yet.

MVP enemies:
- simple boat
- faster boat
- tougher boat

All initially try to reach and damage the lighthouse. Later they can land raiders, sabotage, shoot from range, create fog, sweep mines, etc.

The first question to prove:
> Is scanning, illuminating, firing, and relying on shore turrets/traps fun against simple boats?

---

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

---

## What Codex Should Do First

Codex is trusted for scaffolding, docs, repo setup, and routine implementation. Do not ask it to invent the architecture of the hardest systems yet unless needed.

Suggested first Codex task:

1. Create/prepare the project repository.
2. Add a `/docs` folder.
3. Add this handoff as `/docs/BISHOP_ROCK_PREPRODUCTION_HANDOFF.md`.
4. Create separate docs:
   - `/docs/PRODUCT_BRIEF.md`
   - `/docs/MVP_SPEC.md`
   - `/docs/CONTROL_VISIBILITY_SPEC.md`
   - `/docs/OCEAN_MODEL_SPEC.md`
   - `/docs/DAY_LOOP_SPEC.md`
   - `/docs/BACKLOG.md`
5. If using Godot, create a blank Godot 4 project structure only after confirming engine choice.
6. Do not implement core pathfinding/beam architecture yet unless explicitly asked.
7. Create a backlog of small tasks for future Fable/Codex passes.

---

## What Fable Should Be Saved For

Use Fable for the logic-dense core:

- final ocean coordinate/navigation architecture
- boat steering/pathfinding around rocks and hazards
- beam cone/visibility/last-known-state implementation
- tide/depth/rock rules
- modular hazard architecture
- simulation state machine
- debug overlays
- first hard playable vertical slice

Fable should not be spent on broad brainstorming, file scaffolding, or routine markdown/docs cleanup.

---

## Immediate Open Questions

1. Should main gun firing be manual button press, auto-fire, or both?
   - Current lean: both; manual default for feel, auto-fire as setting/upgrade.

2. Should radar/sonar inset be MVP or later?
   - Current lean: main-map fading silhouettes in MVP; radar inset if easy/debuggable.

3. How much night repair is allowed?
   - Current lean: yes, but risky. Leaving the gun/light station should let the lighthouse auto-run at lower efficiency.

4. Should rocks physically collide or path-block?
   - Current lean: pathfinding/avoidance first, with simple collision/damage if hit.

5. Should tide be in MVP?
   - Current lean: maybe not first night prototype; include in docs and add after baseline combat.

---

## Night Repair / Multitasking Design Note

The player should sometimes leave the gun/light controls during night.

When the player is not manning the light/gun:
- beam continues auto-rotating
- gun may auto-fire at reduced efficiency if enabled/upgraded
- turrets continue auto-firing
- player can spend emergency time repairing, reloading, boarding windows, pumping water, extinguishing fire, or fixing the engine/lens

This creates a strong tension:
> Do I stay at the lantern/gun to control the battle, or do I abandon perfect aim to keep the lighthouse from falling apart?

This should be included after the basic loop works.
