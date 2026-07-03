# Design Review — Pressure Test (July 2026)

Honest assessment of the concept as built, and prioritized recommendations.
Frame: perpetual fight — every run ends in a lost lighthouse; the score is
how long you held and what you sank.

**Implementation status (July 2026):** all items below are DONE except —
2-of-3 project offering (deferred: playtest the current project list first),
overcharge shot and mine ring placement (skipped: the existing
NORMAL/CHARGED/PERFECT/misfire bands already carry the risk curve, and mine
rings add a knob without tension). Save/load is DONE (checkpoint saves,
Continue button, delete on death). Balance numbers from the policy sim:
all-fish dies night 11, balanced play holds ~26.

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

## Round 2 — further recommendations (actionable)

### 7. Kill the duplicated cost tables (do this first, it's a live bug farm)
Action costs are declared twice: once in `main.gd _actions_for_zone` (what
the UI shows) and again in `run_state.gd perform_action` (what spend()
charges). The moment one is tuned and the other isn't, the UI lies about
prices — the exact class of bug this whole pass existed to kill.
Action: move every action into one `const ACTIONS := {...}` table in
run_state.gd (id, name, effect, cost, gain, zone, daily_cap). UI reads it;
`perform_action` becomes one generic ~15-line function that spends cost and
applies gain. Deletes ~100 lines of match arms; tuning becomes editing one
table. Projects already work this way (`START_PROJECTS`) — mirror it.

### 8. Audio: the game is currently silent — biggest feel-per-hour lever
Zero AudioStream nodes in the repo. Even placeholder audio transforms
perceived quality. Action, in one sitting:
- Buses: Master -> Music, SFX, UI (AudioServer, godot-audio setup).
- Eight sounds cover the whole game: wave loop (ambient), foghorn (night
  start), rifle crack, charge hum (pitch rises with charge), PERFECT ding,
  hull crunch, mine thump, brass click (UI press).
- Source CC0 only: Kenney audio packs / freesound CC0 filter — matches the
  no-license-risk rule already in this pass.
- Duck Music -6 dB for 0.4 s on hull hit (one tween on bus volume).

### 9. Make PERFECT feel perfect (numbers, not vibes)
There's screen shake; the signature move deserves the full stack:
- Hit-stop: `Engine.time_scale = 0.05` for 70 ms on perfect kill (timer must
  be `ignore_time_scale`), then restore.
- One-frame white flash on the boat sprite, 1.15x camera zoom pulse easing
  back over 0.25 s.
- Float text already exists — make PERFECT text 2x size, gold.
Budget: ~30 lines in night_board / main_gun, no new systems.

### 10. Persist a best-run record and show it at death
"LIGHTHOUSE LOST ... Press R" wastes the most emotional moment. Action:
- One ConfigFile at `user://records.cfg`: best_day, best_kills, total_runs.
- Death screen: this run's line vs best line; stamp "NEW RECORD" when beaten.
- ~25 lines in hud.gd game-over path. This is the cheapest possible version
  of the score-screen retention loop from item 1.

### 11. Run telemetry for tuning (data beats debate)
Append one CSV row per day to `user://runs.csv`: run_id, day, hull at dawn,
daylight spent per zone, shillings earned, boats crashed. ~20 lines in
`start_day`/game-over. After ten playtests you'll *know* whether Fish
dominates and which day kills people, instead of guessing. Balance items
2, 3, and the raid curve all become chart-reading.

### 12. First three dawns teach, one line each (no tutorial system)
Contextual drip via the existing log label / dawn screen:
- Dawn 1: "Patch the hull before nightfall — crashes hurt more than repairs cost."
- Dawn 2: "Salvage and parts unlock the workshop projects."
- Dawn 3: "Rest today improves tomorrow's Daylight."
`if day <= 3` + three strings. Delete when real onboarding exists.

### 13. Assist toggles broaden the audience for free
One settings dict + three checkboxes on the start screen ("Keeper's Mercy"):
boat speed -20%, beam cone +25%, crash damage -30%. Each toggle multiplies
final score by 0.85 so records stay honest. Roguelites live and die on
letting weaker players see day 10.

### 14. Seed the run, show the seed
Give each run a seed (`randi()` at campaign start, seed all raid/loot rolls
from one `RandomNumberGenerator`). Show it on the death screen; accept a
typed seed on the start screen. Costs ~15 lines now, enables shareable runs
("try seed 4471") and a daily-challenge mode later. Retrofitting seeded RNG
after more systems land is 10x the work.

### 15. Make bought defenses visible doing their job at night
A mine that fires while the player is aiming elsewhere is a purchase they
never see pay off. Float "MINE -6" at the blast, brief flash on the
barricade when it eats a crash. If a purchase never visibly works, players
stop buying it. ~10 lines where those effects already resolve.
