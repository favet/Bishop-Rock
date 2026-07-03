class_name RunState
extends Node

signal changed

## Four projects, each a power spike the player can SEE working at night.
## The +5% tier was deleted, not rebalanced — sub-perceptual upgrades train
## apathy (see Docs/DAY_REDESIGN.md).
## Parts (the old "tools" currency) had one source and one sink — a click
## tax, not a decision. Each part's cost (5 iron + 1 Daylight of machining)
## is folded directly into the projects that needed it.
const START_PROJECTS := {
	"lens_crank_1": {
		"display_name": "Lens Crank",
		"effect": "Beam turns 25% faster",
		"start_cost": {"gold": 18, "scrap": 9},
		"work_required": 2,
	},
	"rifle_breech_1": {
		"display_name": "Rifle Breech",
		"effect": "Reload 20% faster",
		"start_cost": {"gold": 24, "scrap": 11},
		"work_required": 3,
	},
	"reinforced_hull_1": {
		"display_name": "Reinforced Hull",
		"effect": "Max hull +15 and heal +15",
		"start_cost": {"gold": 24, "wood": 10, "scrap": 3},
		"work_required": 2,
	},
	"rusty_autoturret": {
		"display_name": "Rusty Autoturret",
		"effect": "A second gun fires on its own",
		"start_cost": {"gold": 40, "scrap": 20},
		"work_required": 4,
	},
}

var run_seed: int
var mercy: bool  # Keeper's Mercy: slower boats, wider beam, softer crashes
var day: int
var hull: int
var max_hull: int
var energy_max: int
var energy_today: int
var tomorrow_energy_bonus: int
var gold: int
var wood: int
var scrap: int
var food: int
var mines: int
var barricades: int
var active_projects: Dictionary
var completed_projects: Dictionary
var upgrades: Dictionary
var turret_unlocked: bool
var last_night_stats: Dictionary
var daily_caps: Dictionary
# Whole-run tallies for the death score screen.
var run_kills: int
var run_gold_earned: int
var run_perfects: int

func _ready() -> void:
	reset_campaign()

func reset_campaign(seed_value: int = -1, mercy_enabled: bool = false) -> void:
	run_seed = seed_value if seed_value >= 0 else randi() % 1000000
	mercy = mercy_enabled
	day = 1
	hull = 85
	max_hull = 100
	# 4 Daylight against 8+ actions: most days you take half of what you
	# want. Scarcity is where the decisions live.
	energy_max = 4
	energy_today = 4
	tomorrow_energy_bonus = 0
	gold = 12
	wood = 8
	scrap = 2
	food = 3
	mines = 0
	barricades = 0
	active_projects = {}
	completed_projects = {}
	upgrades = {}
	turret_unlocked = false
	last_night_stats = {}
	daily_caps = {}
	run_kills = 0
	run_gold_earned = 0
	run_perfects = 0
	_roll_day_flavor()
	changed.emit()

func start_day() -> void:
	daily_caps = {}
	energy_today = energy_max + tomorrow_energy_bonus
	tomorrow_energy_bonus = 0
	day += 1
	_roll_day_flavor()
	_log_telemetry("dawn")
	save_run()
	changed.emit()

const TELEMETRY_PATH := "user://runs.csv"
var telemetry_enabled: bool = true  # policy sims turn this off

## One CSV row per dawn and per death: resource snapshot + last night's
## result. After a handful of runs this answers "which action dominates"
## and "which day kills people" with data instead of debate.
## ponytail: per-zone Daylight spend not tracked; add a per-action counter
## if resource deltas alone can't explain a dominant strategy.
func _log_telemetry(event: String) -> void:
	if not telemetry_enabled:
		return
	var file: FileAccess
	if FileAccess.file_exists(TELEMETRY_PATH):
		file = FileAccess.open(TELEMETRY_PATH, FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open(TELEMETRY_PATH, FileAccess.WRITE)
		file.store_line("seed,day,event,hull,max_hull,gold,wood,scrap,food,mines,barricades,night_kills,night_crashed,night_gold")
	if file == null:
		return
	file.store_line("%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
		run_seed, day, event, hull, max_hull, gold, wood, scrap, food,
		mines, barricades, int(last_night_stats.get("kills", 0)),
		int(last_night_stats.get("crashed", 0)), int(last_night_stats.get("gold_earned", 0))])
	file.close()

func set_night_result(stats: Dictionary) -> void:
	last_night_stats = stats.duplicate(true)
	save_run()
	changed.emit()

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for key in cost.keys():
		set(key, int(get(key)) - int(cost[key]))
	changed.emit()
	return true

func can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		if int(get(key)) < int(cost[key]):
			return false
	return true

func missing_text(cost: Dictionary) -> String:
	var missing: Array[String] = []
	for key in cost.keys():
		var need := int(cost[key])
		var have := int(get(key))
		if have < need:
			missing.append("%s %d" % [_display_name(key), need - have])
	return ", ".join(missing)

func _display_name(key: String) -> String:
	match key:
		"energy_today":
			return "Daylight"
		"gold":
			return "Shillings"
		"wood":
			return "Timber"
		"scrap":
			return "Iron"
		"food":
			return "Rations"
	return key.capitalize()

## Every action's definition lives here and only here — the day UI renders
## from this table and perform_action() executes from it, so a price can
## never drift between what's shown and what's charged.
## Eight actions in two groups ("light" = answer tonight, "provisions" =
## fund tomorrow); the fifteen-action list glazed eyes — see DAY_REDESIGN.md.
const ACTIONS := {
	"patch_hull": {
		"name": "Repair Hull", "zone": "light", "effect": "Mend the lighthouse",
		"cost": {"energy_today": 1, "gold": 3, "wood": 2}, "gain": {"hull": 12},
		"log": "Repaired the hull.",
	},
	"craft_mines": {
		"name": "Craft Mines", "zone": "light", "effect": "Two mines fire on their own tonight",
		"cost": {"energy_today": 1, "gold": 4, "scrap": 3}, "gain": {"mines": 2},
		"log": "Crafted 2 mines.",
	},
	"build_barricade": {
		"name": "Build Barricade", "zone": "light", "effect": "Eats most of the next crash",
		"cost": {"energy_today": 1, "wood": 4}, "gain": {"barricades": 1},
		"log": "Built a barricade.",
	},
	"gather_driftwood": {
		"name": "Gather Driftwood", "zone": "provisions", "effect": "Comb the shore for timber",
		"cost": {"energy_today": 1}, "gain": {"wood": 4},
		"log": "Gathered +4 timber.",
	},
	"dive_wreckage": {
		"name": "Dive Wreckage", "zone": "provisions", "effect": "Salvage below the dock",
		"cost": {"energy_today": 2}, "gain": {"wood": 2, "scrap": 3},
		"log": "Recovered timber and iron.",
		"daily_cap": "dive_wreckage", "note": "Once per day.",
	},
	"fish": {
		"name": "Fish", "zone": "provisions", "effect": "Rations and a few shillings",
		"cost": {"energy_today": 1}, "gain": {"food": 2, "gold": 2},
		"log": "Caught rations and sold the extra fish.",
	},
	"hearty_supper": {
		# 3 rations, not 2: one Fish can't feed it daily, so supper is a
		# choice you build toward instead of an always-correct closer.
		"name": "Hearty Supper", "zone": "provisions", "effect": "Work longer tomorrow",
		"cost": {"energy_today": 1, "food": 3}, "gain": {"tomorrow_daylight": 2},
		"log": "A proper meal. Tomorrow: +2 Daylight.",
		"daily_cap": "hearty_supper", "note": "Once per day.",
	},
}

## One rotating bonus action per day, drawn from this pool by the run seed.
## Same card machinery as ACTIONS; "zone" is where it shows up.
const OPPORTUNITIES := {
	"passing_merchant": {
		"name": "Passing Merchant", "zone": "provisions", "effect": "Sell timber at a good rate",
		"cost": {"energy_today": 1, "wood": 4}, "gain": {"gold": 7},
		"log": "Sold timber to the merchant sloop.",
	},
	"seal_colony": {
		"name": "Seal Colony", "zone": "provisions", "effect": "Easy hunting on the north rocks",
		"cost": {"energy_today": 1}, "gain": {"food": 4},
		"log": "Came back heavy with meat.",
	},
	"calm_tide": {
		"name": "Calm Tide", "zone": "provisions", "effect": "The shallows give up their secrets",
		"cost": {"energy_today": 2}, "gain": {"wood": 3, "scrap": 3},
		"log": "Calm water made for easy salvage.",
	},
	"iron_barge": {
		"name": "Iron Barge Wreck", "zone": "light", "effect": "A barge broke up on the reef",
		"cost": {"energy_today": 2}, "gain": {"scrap": 5},
		"log": "Stripped the barge to its ribs.",
	},
	"quiet_morning": {
		"name": "Quiet Morning", "zone": "provisions", "effect": "The sea is kind, for once",
		"cost": {"energy_today": 1}, "gain": {"tomorrow_daylight": 1},
		"log": "A rare unhurried morning.",
	},
	"travelling_smith": {
		"name": "Travelling Smith", "zone": "light", "effect": "Buy off-cut iron cheap",
		"cost": {"energy_today": 1, "gold": 6}, "gain": {"scrap": 5},
		"log": "Bought the smith's off-cuts.",
	},
}

## Weather rolled per day: one enum, two knobs on the night.
const WEATHERS := {
	"clear": {"label": "Clear", "speed": 1.0, "cone": 1.0},
	"fog": {"label": "Fog", "speed": 0.9, "cone": 0.8},
	"swell": {"label": "Heavy swell", "speed": 1.1, "cone": 1.0},
}
var today_opportunity: String
var weather: String

func _roll_day_flavor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, day, "flavor"])
	today_opportunity = OPPORTUNITIES.keys()[rng.randi() % OPPORTUNITIES.size()]
	var roll := rng.randf()
	weather = "clear" if roll < 0.5 else ("fog" if roll < 0.75 else "swell")

## Gain with project modifiers applied — the UI shows this too, so a
## completed project's bonus is visible on the card, not a surprise.
func action_def(action_id: String) -> Dictionary:
	return ACTIONS.get(action_id, OPPORTUNITIES.get(action_id, {}))

func action_gain(action_id: String) -> Dictionary:
	var gain: Dictionary = action_def(action_id)["gain"].duplicate()
	if action_id == "dive_wreckage":
		var bonus := salvage_dive_bonus()
		gain["wood"] += int(bonus["wood"])
		gain["scrap"] += int(bonus["scrap"])
	return gain

## Last night's chaos seeds today's recovery: crashed boats wash up timber,
## perfect kills leave intact cargo crates of iron. Both sweeten the first
## dive of the day (dive is once per day), so a bad night funds its own
## repairs and good shooting pays visibly by day.
func salvage_dive_bonus() -> Dictionary:
	return {
		"wood": mini(int(last_night_stats.get("crashed", 0)), 3),
		"scrap": mini(int(last_night_stats.get("perfects", 0)), 3),
	}

func perform_action(action_id: String) -> String:
	var action: Dictionary = ACTIONS.get(action_id, {})
	var cap: String = action.get("daily_cap", "")
	if action.is_empty():
		if action_id != today_opportunity:
			return "Unknown action."
		action = OPPORTUNITIES[action_id]
		cap = "opportunity"  # each opportunity is once, today only
	if action.is_empty():
		return "Unknown action."
	if not cap.is_empty() and daily_caps.get(cap, false):
		return "%s is done for today." % action["name"]
	var cost: Dictionary = action["cost"]
	if not spend(cost):
		return "Missing %s." % missing_text(cost)
	if not cap.is_empty():
		daily_caps[cap] = true
	var gain := action_gain(action_id)
	for key in gain.keys():
		_apply_gain(key, int(gain[key]))
	changed.emit()
	return action["log"]

func _apply_gain(key: String, amount: int) -> void:
	match key:
		"hull":
			hull = mini(max_hull, hull + amount)
		"tomorrow_daylight":
			tomorrow_energy_bonus = mini(tomorrow_energy_bonus + amount, 2)
		_:
			set(key, int(get(key)) + amount)

func start_project(project_id: String) -> String:
	if completed_projects.has(project_id):
		return "Project already completed."
	if active_projects.has(project_id):
		return "Project already started."
	var project := project_def(project_id)
	if project.is_empty():
		return "Unknown project."
	var cost: Dictionary = project["start_cost"]
	if not spend(cost):
		return "Missing %s." % missing_text(cost)
	active_projects[project_id] = {"work_done": 0}
	changed.emit()
	return "Started %s." % project["display_name"]

func work_project(project_id: String) -> String:
	if not active_projects.has(project_id):
		return "Start this project first."
	if not spend({"energy_today": 1}):
		return "Need 1 Daylight."
	active_projects[project_id]["work_done"] = int(active_projects[project_id]["work_done"]) + 1
	var project := project_def(project_id)
	if int(active_projects[project_id]["work_done"]) >= int(project["work_required"]):
		active_projects.erase(project_id)
		completed_projects[project_id] = true
		_apply_project(project_id)
		return "Completed %s." % project["display_name"]
	changed.emit()
	return "Worked on %s." % project["display_name"]

func project_def(project_id: String) -> Dictionary:
	return START_PROJECTS.get(project_id, {})

func _apply_project(project_id: String) -> void:
	upgrades[project_id] = true
	match project_id:
		"reinforced_hull_1":
			max_hull += 15
			hull = mini(max_hull, hull + 15)
		"rusty_autoturret":
			turret_unlocked = true
	changed.emit()

const SAVE_PATH := "user://save.cfg"
const SAVE_VERSION := 3  # v2 saves (Parts era) are discarded
## Everything a run needs to resume at dawn. today_opportunity/weather are
## derived from (run_seed, day) on load, so they aren't stored.
const SAVE_FIELDS: Array[String] = [
	"run_seed", "mercy", "day", "hull", "max_hull", "energy_max",
	"energy_today", "tomorrow_energy_bonus", "gold", "wood", "scrap", "food",
	"mines", "barricades",
	"active_projects", "completed_projects", "upgrades", "turret_unlocked",
	"last_night_stats", "daily_caps",
	"run_kills", "run_gold_earned", "run_perfects",
]

## Checkpoints: every dawn, after each night result, and when Start Night is
## pressed. ponytail: quitting mid-day rolls back to the latest checkpoint —
## add per-action saves if playtesters complain about lost afternoons.
func save_run() -> void:
	if not is_inside_tree():
		return  # bare RunState instances (policy sims, checks) never persist
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", SAVE_VERSION)
	for field in SAVE_FIELDS:
		cfg.set_value("save", field, get(field))
	cfg.save(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_run() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK or int(cfg.get_value("save", "version", 0)) != SAVE_VERSION:
		return false
	for field in SAVE_FIELDS:
		set(field, cfg.get_value("save", field, get(field)))
	_roll_day_flavor()
	changed.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

const RECORDS_PATH := "user://records.cfg"

## Persist the run's result; returns {best_nights, new_record, total_runs}
## for the death screen. Call exactly once per lost run.
func record_death() -> Dictionary:
	var nights_held := day - 1
	var cfg := ConfigFile.new()
	cfg.load(RECORDS_PATH)  # missing file on first run is fine
	# Mercy runs keep their own ladder so full-difficulty records stay honest.
	var best_key := "best_nights_mercy" if mercy else "best_nights"
	var best: int = cfg.get_value("records", best_key, 0)
	var total_runs: int = cfg.get_value("records", "total_runs", 0) + 1
	var new_record := nights_held > best
	if new_record:
		best = nights_held
	cfg.set_value("records", best_key, best)
	cfg.set_value("records", "total_runs", total_runs)
	cfg.save(RECORDS_PATH)
	_log_telemetry("death")
	delete_save()  # the run is over; no Continue back into a lost lighthouse
	return {"best_nights": best, "new_record": new_record, "total_runs": total_runs}

## Fresh RNG seeded from (run seed, day): the same night replays identically
## after a restart, and a typed seed reproduces a whole run.
func night_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, day])
	return rng

## Compressed ramp: the old one kept heavies out until day 15 — most runs
## ended around day 25, so the mine-vs-heavy decision (the reason the
## forecast exists) was dormant for two-thirds of the game. Now: fast
## boats from day 3, first heavy guaranteed on night 5 (see night_plan).
func raid_profile() -> Dictionary:
	if day <= 2:
		return {
			"profile_name": "Calm waters",
			"wave_size": 2 + day,
			"fast_weight": 0.0,
			"heavy_weight": 0.0,
			"max_simultaneous": 1,
			"speed_scale": 0.7,
			"start_interval": 3.6,
			"min_interval": 2.8,
			"first_spawn_delay": 1.5,
			"use_v0_hazards": false,
		}
	if day <= 4:
		return {
			"profile_name": "Rising chop",
			"wave_size": 3 + day - 2,
			"fast_weight": 0.15,
			"heavy_weight": 0.0,
			"max_simultaneous": 1 if day == 3 else 2,
			"speed_scale": 0.75,
			"start_interval": 3.4,
			"min_interval": 2.4,
			"first_spawn_delay": 1.2,
			"use_v0_hazards": false,
		}
	if day <= 9:
		return {
			"profile_name": "Heavy weather",
			"wave_size": 5 + (day - 5) / 2,
			"fast_weight": 0.2,
			"heavy_weight": 0.08,
			"max_simultaneous": 2,
			"speed_scale": 0.8 + 0.02 * float(day - 5),
			"start_interval": 3.2,
			"min_interval": 2.2,
			"first_spawn_delay": 1.2,
			"use_v0_hazards": false,
		}
	if day <= 14:
		return {
			"profile_name": "Fast raiders",
			"wave_size": mini(7 + (day - 10) / 2, 10),
			"fast_weight": 0.25,
			"heavy_weight": 0.12,
			"max_simultaneous": 2,
			"speed_scale": 0.9,
			"start_interval": 3.0,
			"min_interval": 1.9,
			"first_spawn_delay": 1.0,
			"use_v0_hazards": false,
		}
	# Day 15+: unbounded multiplicative growth. There is no final day — the
	# sea always wins eventually; the score is how long you held it off.
	var over := day - 15
	return {
		"profile_name": "The sea rising" if over < 10 else "The sea furious",
		"wave_size": 9 + over / 2,
		"fast_weight": minf(0.25 + 0.012 * over, 0.5),
		"heavy_weight": minf(0.12 + 0.010 * over, 0.4),
		"max_simultaneous": 3 + over / 6,
		"speed_scale": pow(1.02, over),
		"start_interval": maxf(2.6 * pow(0.985, over), 1.2),
		"min_interval": maxf(1.5 * pow(0.985, over), 0.7),
		"first_spawn_delay": 1.0,
		"use_v0_hazards": false,
	}

func beam_turn_multiplier() -> float:
	return 1.25 if completed_projects.has("lens_crank_1") else 1.0

func reload_multiplier() -> float:
	return 0.8 if completed_projects.has("rifle_breech_1") else 1.0

## Tonight's exact boat list, rolled from the night RNG. The forecast shows
## this and the spawner consumes it, so the forecast is true by construction.
func night_plan() -> Array[String]:
	var profile := raid_profile()
	var rng := night_rng()
	var plan: Array[String] = []
	for i in int(profile["wave_size"]):
		var roll := rng.randf()
		if roll < float(profile["heavy_weight"]):
			plan.append("heavy")
		elif roll < float(profile["heavy_weight"]) + float(profile["fast_weight"]):
			plan.append("fast")
		else:
			plan.append("basic")
	# Night 5 always ends with a heavy: one telegraphed teaching moment —
	# the forecast warns, mines answer, the lesson sticks.
	if day == 5 and not plan.has("heavy"):
		plan[plan.size() - 1] = "heavy"
	return plan

## "5 boats: 4 skiffs, 1 heavy hull" — the day is an answer to this line.
func forecast_text() -> String:
	var plan := night_plan()
	var counts := {"basic": 0, "fast": 0, "heavy": 0}
	for kind in plan:
		counts[kind] += 1
	var parts: Array[String] = []
	if counts["basic"] > 0:
		parts.append("%d skiff%s" % [counts["basic"], "s" if counts["basic"] > 1 else ""])
	if counts["fast"] > 0:
		parts.append("%d swift" % counts["fast"])
	if counts["heavy"] > 0:
		parts.append("%d heavy hull%s" % [counts["heavy"], "s" if counts["heavy"] > 1 else ""])
	return "%d boats: %s" % [plan.size(), ", ".join(parts)]
