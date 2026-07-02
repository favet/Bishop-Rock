# Campaign Loop v1

Campaign v1 wraps Night Board v0 with a seven-day survival loop:

Night raid -> dawn summary -> visual day hub -> spend energy/resources -> next night.

## State

`CampaignState` is an autoload backed by `scripts/campaign/run_state.gd`. It tracks day, hull, energy, gold, wood, scrap, food, tools, mines, barricades, farm plots, crops, projects, completed upgrades, turret unlock state, clean-lens state, and the last night summary.

Day 1 starts at 85/100 hull, 6 energy, 12 gold, 8 wood, 2 scrap, 3 food, 1 farm plot, and no turret.

## Nights

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

The day hub has four visual zones:

- Lighthouse: patch, full repair, clean lens, lighthouse projects.
- Workshop: scrap, tools, mines, barricades, workshop projects.
- Shore / Dock / Farm: wood, fish, wreckage, potatoes, farm projects.
- Quarters: rest, cook, scout.

Actions are compact buttons with a feedback log. Unaffordable projects remain clickable and show missing resources. Tools are called out as inputs for Lens Crank I, Rifle Breech I, and Rusty Autoturret.

## Projects

Projects pay a start cost, then consume energy over one or more days. Starter projects are reachable early: Greased Crank, Breech Cleaning Kit, Patch Frame, and Garden Bed Prep.

Applied effects:

- Greased Crank and Lens Crank I improve beam turn speed.
- Breech Cleaning Kit and Rifle Breech I reduce reload duration.
- Patch Frame improves patch repairs.
- Garden Bed Prep improves potato harvests.
- Reinforced Hull I raises and heals max hull.
- Rusty Autoturret enables the existing weak turret.

## Deferred

No trader, sector placement UI, breakwaters, decoys, storms, ammo types, radar inset, advanced events, or art pass in this slice.
