# Design Review — Pressure Test (July 2026)

Honest assessment of the concept as built, and prioritized recommendations.
Frame: perpetual fight — every run ends in a lost lighthouse; the score is
how long you held and what you sank.

## What already works

- Two-phase loop (tense night / planning day) is a proven spine — Kingdom,
  They Are Billions. Night tests hands, day tests judgment. Keep it sacred:
  never let day chores leak into night or vice versa.
- The charge-shot perfect window is real skill expression and the economy
  already pays it (perfect bonuses). This is the game's signature move.
- Small material web (5 currencies + Daylight) is the right size. Resist
  adding a sixth until two runs in a row feel identical.

## Biggest risks, in order

### 1. A perpetual game with a finite upgrade list goes stale or walls
Wave pressure plateaus at day ~15 (cap 13 boats); projects run out around
the same time. After that every day is the same day. Fixes, cheapest first:
- Past day 15, scale boat speed/HP/interval multiplicatively per day
  (unbounded, small increments). Every run now ends — that's the point.
- Score screen at death: days held, boats sunk, perfects, shillings earned.
  The score IS the retention mechanic in an endless game.
- Later: meta-unlocks between runs (alternate starting kits), not mid-run
  power creep.

### 2. Dominant day strategies make the day rote
If one action has the best value-per-Daylight every day, players find it by
day 3 and the day phase dies. Current smells: Fish (2 rations + 2 shillings,
uncapped) vs Gather Driftwood (4 timber, uncapped). Recommendations:
- Keep a balance sheet (one table, one doc): every action's yield per
  Daylight, normalized to shillings. Keep them within ~20% of each other,
  with situational swings deciding the winner.
- Add caps or diminishing returns to any uncapped generator (Fish twice/day,
  third cast yields half).
- Build a headless policy sim (extend the existing MainLoop checks): run 30
  days with "always fish", "always repair", "balanced" bots; assert no
  single-action policy survives longest. That turns balance into a test.

### 3. Failure spirals
Bad night -> hull repairs eat the whole day -> no growth -> worse night.
Spirals read as unfair. Counters that fit the fiction:
- Crashed boats leave wreckage; the morning after a bad night, Dive Wreckage
  yields more. Losses seed recovery.
- Never let repair costs scale with damage taken; flat costs are the
  catch-up mechanic.

### 4. Night decisions are thin after the aim/timing layer
One rifle, one beam. By night 10 the hands know the job. Cheap depth inside
existing systems (no new subsystems):
- Pre-night mine placement: choose ring (near = safer trigger, far = earlier
  intercept). One choice, big texture.
- Target-value tension already exists (heavy = 8s) — surface it: show boat
  bounty on the contact when lit.
- A risky overcharge: hold past perfect for +damage but bigger misfire
  backlash. Uses the mechanic you already have.

### 5. Runs open identically
Same actions, same projects, day 1 is a script. Variety levers, cheapest
first:
- Daily "opportunity" slot: one rotating bonus action from a small pool
  (passing merchant = trade rates, seal colony = rations, calm tide = second
  dive). One slot, ~6 entries, day texture forever.
- Offer projects 2-of-3 instead of the full list — forces builds, spurs
  replay ("the turret run", "the lens run").
- Weather flag rolled at dawn affecting the night (fog: shorter beam, slower
  boats). One enum, two knobs.

### 6. Skill should feed the economy more visibly
Perfect play currently earns small change. Make the loop explicit: perfect
kills drop crates -> tomorrow's dive is richer. Skill at night becomes
prosperity by day — that's the fantasy of a well-run lighthouse.

## Quality-of-life next

- Save/load. A perpetual run without persistence dies at the first quit.
  Highest-priority non-design item.
- 2x fast-forward for quiet early nights (slow-mo already exists).
- Dawn "keeper's log" flavor line (procedural, one sentence). Cheap charm,
  big personality.
- Hull damage forecast near Start Night ("4 boats, ~6 dmg per crash") so
  repair decisions are informed, not vibes.

## Process recommendations

- Tuning data (action yields, project costs, raid curves) should live in one
  data table (a Resource or a const dict in one file), not scattered through
  match arms — run_state.gd is already drifting toward scatter.
- Every balance change gets a policy-sim run before commit.
- Playtest cadence: one full run to death per change set; write the day you
  died and why in a log. Death reasons are the tuning backlog.

## What NOT to build yet

Trader economy, storms as a system, morale/starvation, new boat classes,
sector placement UI, breakwaters/decoys. Each is a good idea that costs a
month and dilutes the loop before the loop is proven. The loop is proven
when testers voluntarily start run #3.
