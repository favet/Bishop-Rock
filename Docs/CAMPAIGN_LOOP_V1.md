# Campaign Loop v1

Campaign v1 wraps Night Board v0 with a perpetual survival loop — there is no final day; raid pressure ramps per day and currently plateaus after day 15 (endless scaling is a known gap):

Night raid -> dawn summary -> visual day hub -> spend Daylight/resources -> next night.

"Daylight" is the player-facing name for daily work energy (`energy_today` internally). The UI never says "energy."

Materials are rebranded in the UI only — internal keys are unchanged: gold -> Shillings, wood -> Timber, scrap -> Iron, food -> Rations, tools -> Parts. Rename in `_display_resource_name` (main.gd) and `_display_name` (run_state.gd) if these change again.

## State

Current pass notes (July 2026): Day 1 uses 4 Daylight. The live resource
set is Shillings, Timber, Iron, Rations, mines, and barricades; the older
tools/parts/farm notes below are legacy context only. Starter kill rewards
are Basic 2s, Swift 3s, Heavy 6s; perfect kill bonuses remain +2/+2/+4.

`CampaignState` is an autoload backed by `scripts/campaign/run_state.gd`. It tracks day, hull, Daylight (energy), gold, wood, scrap, food, tools, mines, barricades, farm plots, crops, projects, completed upgrades, turret unlock state, clean-lens state, and the last night summary.

Day 1 starts at 85/100 hull, 6 Daylight, 12 gold, 8 wood, 2 scrap, 3 food, 1 farm plot, and no turret.

## Nights

Starter campaign visibility is stricter than v0: no spawn pings, no free
contact ticks, and no ghost ships. The player sweeps the beam to find boats,
so early boats are slower. Boats are scheduled across a compact spawn window;
the night ends as soon as all spawned boats are resolved, with no empty wait
for a separate clock.

Campaign nights use `CampaignState.raid_profile()` instead of the original 24-boat v0 pressure.

- Days 1-3: 3-5 basic boats, max 1 simultaneous, 70% speed, no v0 hazards.
- Days 4-7: 5-7 boats, mostly basic, rare fast preview from day 6, max 1-2 simultaneous, no v0 hazards.
- Days 8-14 and 15+ are stubbed pressure ramps for later tuning.

The original high-pressure profile remains represented as later campaign pressure rather than Day 1.

## Rewards And Consequences

Kills award gold immediately with floating text:

- Basic: 3g
- Fast: 4g
- Heavy: 8g

Perfect nonlethal hits grant +1g once per boat. Perfect kills add +2g for basic/fast and +4g for heavy.

Campaign crash damage is lower than v0: basic 6, fast 4, heavy 13. Hull persists into the next day. Barricades auto-reduce the next crash by 75% and are consumed. Mines auto-fire once a boat reaches midwater, deal 6 damage, and are consumed.

## Dawn

When the wave is fully spawned and all boats are resolved, the dawn summary shows sunk boats, crashes, gold earned, perfect bonuses, hull damage, current hull, consumed defenses, and a neutral repair estimate.

## Day Hub

Current day hub: top core resources, focused tabs for Situation, Keep Light,
Provisions, and Workshop, and a fixed "Light the Lantern" button at the
bottom. No scrollbars at the current content level.

The day hub is a brass-on-iron card layout built in `scripts/main/main.gd`:

- Top bar: only the core resources — Hull (bar + label, fill always relative to current `max_hull`), Daylight (one brass token per point; spent tokens go dark), Gold, Wood, Scrap, Food, and the Day number. Every entry has a hover tooltip stating what the resource is for and how to gain it. Tools, mines, and barricades are deliberately NOT here.
- Left: four functional zone cards — Repairs (hull, lens, lighthouse work), Crafting (scrap, tools, mines, defenses), Supplies (wood, food, salvage, crops), Rest (meals, daylight, scouting).
- Right: detail panel listing the selected zone's action and project cards plus a feedback log.
- Bottom: "Tonight's Defenses" strip (mines, barricades, scout result) and a fixed, brass, always-in-the-same-place Start Night button showing the night number and raid forecast.

Card conventions:

- Actions show name, short effect, then one "X/N Material" row per cost (X = what you hold, N = what it needs; green when X >= N, red when short), then a REWARD section with green "+" rows. No prose like "Cost 3g 2 wood."
- The selected zone card carries a bright brass border and lighter fill so you always know which zone is open.
- Hovering an action that costs Daylight ghosts exactly that many tokens in the top-bar Daylight display (the "about to be spent" preview). Cards never print "Daylight after."
- Projects show effect first, then have/need requirement rows (green when met, red when short), work progress, and — when unaffordable — an explicit red Missing list with gain hints. Unaffordable projects remain clickable and inspectable.
- Tools are called out as inputs for Lens Crank I, Rifle Breech I, and Rusty Autoturret on the Make Tool card and in project tooltips.

Debug: the F3 world overlay is off by default; the normal night HUD shows only hull, night number, contacts, and rifle readiness.

Current night HUD: the top edge is a full-width deployment bar that drains
left-to-right as the spawn window passes. Boat shot/remaining counts are
intentionally omitted from normal play.

## Projects

Current starter projects: Lens Crank (20s, 6 Timber, 8 Iron, 2 work), Rifle
Breech (25s, 10 Iron, 3 work), Reinforced Hull (25s, 18 Timber, 4 Iron, 2
work), and Rusty Autoturret (50s, 12 Timber, 18 Iron, 6 work). The turret is
intended as a week-two milestone.

Projects pay a start cost, then consume Daylight over one or more days. Starter projects are reachable early: Greased Crank, Breech Cleaning Kit, Patch Frame, and Garden Bed Prep.

Applied effects:

- Greased Crank and Lens Crank I improve beam turn speed.
- Breech Cleaning Kit and Rifle Breech I reduce reload duration.
- Patch Frame improves patch repairs.
- Garden Bed Prep improves potato harvests.
- Reinforced Hull I raises and heals max hull.
- Rusty Autoturret enables the existing weak turret.

## Systems added since v1

- Seeded runs: `reset_campaign(seed)` — spawner RNG is `hash([run_seed, day])`, so nights replay deterministically and seeds are shareable (typed on the start screen, shown at death).
- Endless scaling: past day 15 pressure grows without bound; every run ends. Death screen shows nights held, kills, perfects, shillings, seed, and the persisted best (`user://records.cfg`; mercy runs on a separate ladder).
- Salvage economy: crashes wash up timber, perfect kills leave iron crates — both sweeten the day's single Dive Wreckage.
- Daily flavor: one seeded opportunity action from `OPPORTUNITIES` (shown in its zone + pointed at from the defenses strip) and weather (`WEATHERS`: clear/fog/swell) affecting beam cone and boat speed, forecast on Start Night.
- Audio: `Sfx` autoload + synthesized WAVs from `tools/gen_audio.py` (see DESIGN_REVIEW #8).
- Keeper's Mercy assist toggle; perfect-kill juice (hit-stop, zoom pulse, 30px float text); lit boats show their bounty; telemetry CSV per dawn/death (`user://runs.csv`); first three dawns carry keeper's-note hints.
- Balance guard: `tests/policy_sim_check.gd` asserts no single-action day policy keeps up with balanced play and that scaling ends every run.

- Save/load: runs checkpoint to `user://save.cfg` at dawn, after night results, and on Start Night; the start screen offers Continue Campaign; death deletes the save. Versioned (`SAVE_VERSION`) for future migration.

## Deferred

No trader, sector placement UI, breakwaters, decoys, ammo types, radar inset, advanced events, or art pass in this slice.

UI art: resources use `ui/resource_icon.gd`, a code-drawn brass icon set (coin, planks, riveted shard, fish, sun, lighthouse, hammer, naval mine, crossed planks, sunrise) sharing one plate/rim/palette treatment. Daylight tokens are the sun icon; ghost/spent states are modulate-based. Cohesive, no emoji, no external assets. A real texture/art pass can replace the class wholesale later.
