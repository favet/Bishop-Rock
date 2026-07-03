# Day Phase Redesign — "Answer the Night"

## Diagnosis (July 2026 playtest feedback: "eyes glaze, no hard decisions")

1. **No scarcity.** 6 Daylight vs ~15 cheap actions — the player can do
   everything that matters every day. A decision is only interesting when
   options are mutually exclusive and the player feels the one they gave up.
2. **Sub-perceptual rewards.** "+5% beam turn" cannot be felt at night, so
   spending on it cannot be reinforced. Spreadsheet upgrades train apathy.
3. **Unknown threat = generic stockpiling.** Preparation is only engaging as
   an answer to a specific visible question (Into the Breach: perfect
   information makes every turn a puzzle).
4. **No attribution.** The dawn report doesn't say what mines/barricades did,
   so buying them never pays off emotionally.
5. **Choice overload, low stakes each.** 15 similar text cards across 4
   zones for ~8 real verbs. Hick's law -> paralysis -> apathy.

## Design principles applied

- Scarcity: 4 Daylight per day (Supper can push tomorrow to 6). Most days
  you take 4 of 8+ actions. Triage every day.
- Truthful forecast: the night's exact boat list is pre-rolled from the run
  seed (`night_plan()`); the day screen shows "6 boats: 4 skiffs, 1 swift,
  1 heavy" plus weather. The spawner consumes the same plan, so the
  forecast never lies. Scout action deleted — information is the game, not
  a tax.
- Perceptible upgrades only: projects cut to 4, each a visible power spike
  (beam +25%, reload -20%, +15 max hull, the autoturret). The +5% tier is
  deleted, not rebalanced.
- Attribution at dawn: report says what mines fired, what barricades ate,
  perfect kills.
- One screen: no zones, no navigation. All action cards visible at once in
  two groups (Keep the Light / Provisions), Tonight panel on the right,
  projects beside it, Start Night fixed.

## Action diet (15 -> 8 + daily opportunity)

Keep: Repair Hull (+12), Build Barricade, Craft Mines, Machine a Part,
Gather Driftwood, Dive Wreckage (once/day, salvage bonus), Fish,
Hearty Supper (2 rations -> +2 Daylight tomorrow, once/day).

Cut: Full Repair (merged into Repair Hull), Clean Lens (folded into lens
project), Sort Salvage (iron comes from diving, crashes, opportunities),
Plant/Harvest Potatoes (bookkeeping, tiny payoff), Rest + Cook Meal
(merged into Supper), Scout Raid (forecast is free now).

Projects cut: Greased Crank, Breech Cleaning Kit, Patch Frame, Garden Bed
Prep, Build Plot II (all sub-perceptual or farming). Kept: Lens Crank
(+25%), Rifle Breech (-20%), Reinforced Hull, Rusty Autoturret.

## Why hard-but-not-too-hard holds

Policy sim remains the guard: degenerate single-action play must die well
before balanced play, and endless scaling must end every run. Retuned after
the diet. Keeper's Mercy remains the relief valve.

## Deferred

Named hard nights ("Smugglers' Convoy"), per-boat sector forecast, action
count > 8. Add only after the reduced loop proves fun.
