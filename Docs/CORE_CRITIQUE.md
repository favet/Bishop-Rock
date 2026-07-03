# Core Critique — Day Cycle, Mechanics, UI/UX (July 2026)

Ruthless pass over the current build. Two lists: what to cut (extraneia)
and what to cement (the quality core). Every claim below was verified
against the code, not vibes.

## The quality core (protect these)

1. **The truthful forecast.** `night_plan()` -> TONIGHT panel -> spawner
   consuming the same list. This is the game's structural idea: the day is
   an answer to a visible question. Everything else should orbit it.
2. **4 Daylight vs 8 wants.** Scarcity works. Do not add actions back.
3. **The charge-shot perfect window** and its economy (crates, bounty).
4. **Token Daylight + ghost preview.** Best UI element in the game.
5. **Attribution** (dawn lines, mine/barricade floats, salvage bonus).

## Verified design faults

### F1. The mine's identity is dormant for 60% of a run
`raid_profile()`: heavy_weight is 0.0 until day 15. Balanced runs die
~day 25. So the "mines answer heavy hulls" warning, the TONIGHT
composition read, and the anti-heavy decision exist only in the last
third of a good run — and never in a bad one. The forecast currently asks
a question ("5 skiffs") whose answer is always "rifle."
**Fix: first fast boat ~day 3, first heavy ~day 5 (deterministic, one,
telegraphed). Compress the ramp; the tutorial pacing overstays.**

### F2. Mines dominate barricades
Mine kills route through `_on_boat_died` -> full shilling bounty. A mine
prevents a crash AND pays; a barricade only blunts one crash, and both
cost about one action. Barricade is a trap option.
**Fix: mine detonations award no bounty (nothing salvageable after the
blast). Mines = safety, rifle = income, barricade = cheap safety. Three
distinct identities.**

### F3. Hearty Supper is an always-correct closer
1 DL + 2 rations -> +2 DL tomorrow is a loan with guaranteed interest;
once food >= 2 the correct play is always "supper last." An always-correct
click is rote, not a decision.
**Fix options (pick one): (a) raise to 3 rations so Fish can't feed it
every day; (b) supper competes with a second rations sink; (c) accept it
as a tempo ritual and cut its DL cost + auto-apply at Start Night. (a) is
the smallest honest fix.**

### F4. Parts is a conveyor belt, not a currency
Parts have exactly one source (Machine a Part) and one sink (projects).
A currency with one source and one sink is a click-tax: it adds a step,
never a decision. It also costs an action slot, a top-bar-adjacent icon,
tooltips, and a card.
**Fix: delete Parts. Projects cost iron + shillings + work directly
(fold each part's 5 iron + 1 DL into the project). Actions drop 8 -> 7,
one currency gone, Workshop bottleneck becomes Daylight (work), which is
the resource the game is about.**

## UI/UX faults

### U1. REWARD headers are repeated noise
Eight cards x one 20px header that restates what the green "+" rows
already say. Cut the header; keep the green rows. Reclaims ~160px of
column height.

### U2. Action columns scroll
With U1 + F4 the columns are 3 cards each and fit without scrolling.
The bar to hit: the entire day readable in one glance, zero scroll on
actions. (Workshop may scroll; it's a menu, not a decision surface.)

### U3. Unaffordable cards look identical until read
Affordability is only visible in row colors. Dim the whole card
(modulate ~0.6) when the cost can't be paid — instant scan, zero text.

### U4. Daylight rows fight the token display
"4/1 Daylight" on a card duplicates the top-bar tokens (which already
ghost on hover). Materials keep X/N; Daylight rows should read as a plain
cost ("Daylight 1", colored by affordability). Less number soup.

### U5. Dawn is a stat wall
Eight lines + hint + button. Compress to: hull delta, earnings, the
attribution lines, one hint. Three seconds, then the day.

### U6. Completed projects keep full-size cards
"Completed" cards spend Workshop space forever. Collapse to one badge
row ("Built: Lens Crank, Rifle Breech").

### U7. TONIGHT states facts without stakes
"5 skiffs" means nothing to a new player. Add one line: "Each crash
costs ~6 hull." Weather likewise: "Fog - your beam reaches shorter,"
not just "Fog."

### U8. Opportunity card can hide below the fold
Pin it at the top of its column with a distinct trim; it is the day's
only novelty and must never be scrolled out of existence.

### U9. Start screen accretion
Seed input and mercy checkbox sit at the same visual rank as Start.
Demote both to a small single row under the Start button.

### U10. Dive card's bonus is invisible arithmetic
The salvage bonus quietly inflates REWARD numbers. Say it: "+2 timber
from last night's wrecks, +1 iron from crates" — exact numbers, on the
card, when active.

## Cut list (ranked, cheapest quality-per-line first)
1. U1 REWARD headers
2. U3 affordability dimming
3. F2 mine bounty removal
4. U4 Daylight-row simplification
5. U6 completed-project collapse
6. U5 dawn compression
7. F4 Parts deletion (touches actions, projects, icons, save v3)
8. F1 ramp compression (touches raid_profile + policy sim re-tune)
9. F3 supper cost 3 rations
10. U7/U8/U9/U10 panel polish

## Non-goals (do not add while cutting)
New actions, new currencies, new night systems, difficulty modes beyond
Mercy, meta-progression. The loop must prove itself lean before it earns
additions.
