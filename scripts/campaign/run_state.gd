class_name RunState
extends Node

signal changed

const START_PROJECTS := {
	"greased_crank": {
		"display_name": "Greased Crank",
		"zone": "Repairs",
		"effect": "Beam turn speed +5%",
		"start_cost": {"gold": 8, "scrap": 2},
		"work_required": 1,
	},
	"breech_cleaning_kit": {
		"display_name": "Breech Cleaning Kit",
		"zone": "Crafting",
		"effect": "Reload duration -5%",
		"start_cost": {"gold": 10, "scrap": 3},
		"work_required": 1,
	},
	"patch_frame": {
		"display_name": "Patch Frame",
		"zone": "Repairs",
		"effect": "Patch hull repairs +2",
		"start_cost": {"gold": 8, "wood": 4},
		"work_required": 1,
	},
	"garden_bed_prep": {
		"display_name": "Garden Bed Prep",
		"zone": "Supplies",
		"effect": "Potato harvest +1 food",
		"start_cost": {"gold": 6, "wood": 4},
		"work_required": 1,
	},
	"reinforced_hull_1": {
		"display_name": "Reinforced Hull I",
		"zone": "Repairs",
		"effect": "Max hull +15 and heal +15",
		"start_cost": {"gold": 30, "wood": 12, "scrap": 4},
		"work_required": 2,
	},
	"lens_crank_1": {
		"display_name": "Lens Crank I",
		"zone": "Repairs",
		"effect": "Beam turn speed +12%",
		"start_cost": {"gold": 25, "scrap": 6, "tools": 1},
		"work_required": 2,
	},
	"rifle_breech_1": {
		"display_name": "Rifle Breech I",
		"zone": "Crafting",
		"effect": "Reload duration -10%",
		"start_cost": {"gold": 35, "scrap": 8, "tools": 1},
		"work_required": 2,
	},
	"build_plot_2": {
		"display_name": "Build Plot II",
		"zone": "Supplies",
		"effect": "Farm plots +1",
		"start_cost": {"gold": 18, "wood": 8},
		"work_required": 2,
	},
	"rusty_autoturret": {
		"display_name": "Rusty Autoturret",
		"zone": "Crafting",
		"effect": "Unlocks the shore turret",
		"start_cost": {"gold": 55, "scrap": 14, "tools": 2},
		"work_required": 4,
	},
}

var run_seed: int
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
var tools: int
var mines: int
var barricades: int
var farm_plots: int
var active_crops: Array[Dictionary]
var active_projects: Dictionary
var completed_projects: Dictionary
var upgrades: Dictionary
var turret_unlocked: bool
var clean_lens_active: bool
var last_night_stats: Dictionary
var daily_caps: Dictionary
var scouted_profile: Dictionary

func _ready() -> void:
	reset_campaign()

func reset_campaign(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi() % 1000000
	day = 1
	hull = 85
	max_hull = 100
	energy_max = 6
	energy_today = 6
	tomorrow_energy_bonus = 0
	gold = 12
	wood = 8
	scrap = 2
	food = 3
	tools = 0
	mines = 0
	barricades = 0
	farm_plots = 1
	active_crops = []
	active_projects = {}
	completed_projects = {}
	upgrades = {}
	turret_unlocked = false
	clean_lens_active = false
	last_night_stats = {}
	daily_caps = {}
	scouted_profile = {}
	changed.emit()

func start_day() -> void:
	_advance_crops()
	daily_caps = {}
	energy_today = energy_max + tomorrow_energy_bonus
	tomorrow_energy_bonus = 0
	scouted_profile = {}
	day += 1
	changed.emit()

func set_night_result(stats: Dictionary) -> void:
	last_night_stats = stats.duplicate(true)
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
		"tools":
			return "Parts"
	return key.capitalize()

## Every action's definition lives here and only here — the day UI renders
## from this table and perform_action() executes from it, so a price can
## never drift between what's shown and what's charged.
const ACTIONS := {
	"patch_hull": {
		"name": "Patch Damage", "zone": "Repairs", "effect": "Repair lighthouse hull",
		"cost": {"energy_today": 1, "gold": 3, "wood": 2}, "gain": {"hull": 10},
		"log": "Patched hull.",
	},
	"full_repair": {
		"name": "Full Repair", "zone": "Repairs", "effect": "Major hull repair",
		"cost": {"energy_today": 2, "gold": 6, "wood": 4}, "gain": {"hull": 22},
		"log": "Repairs completed.",
	},
	"clean_lens": {
		"name": "Clean Lens", "zone": "Repairs", "effect": "Easier beam handling tonight",
		"cost": {"energy_today": 1}, "gain": {"handling": 1},
		"log": "Lens cleaned for tonight.",
	},
	"sort_scrap": {
		"name": "Sort Salvage", "zone": "Crafting", "effect": "Recover usable iron",
		"cost": {"energy_today": 1}, "gain": {"scrap": 2},
		"log": "Salvaged +2 iron.",
	},
	"make_tool": {
		"name": "Machine a Part", "zone": "Crafting", "effect": "Fabricate one precision part",
		"cost": {"energy_today": 1, "scrap": 5}, "gain": {"tools": 1},
		"log": "Machined a part.",
		"note": "Needed for Lens Crank I, Rifle Breech I,\nand Rusty Autoturret.",
	},
	"craft_mines": {
		"name": "Craft Mines", "zone": "Crafting", "effect": "Prepare automatic night mines",
		"cost": {"energy_today": 1, "gold": 4, "scrap": 3}, "gain": {"mines": 2},
		"log": "Crafted 2 mines.",
	},
	"build_barricade": {
		"name": "Build Barricade", "zone": "Crafting", "effect": "Reduce next crash damage",
		"cost": {"energy_today": 1, "wood": 4}, "gain": {"barricades": 1},
		"log": "Built a barricade.",
	},
	"gather_driftwood": {
		"name": "Gather Driftwood", "zone": "Supplies", "effect": "Comb the shore for timber",
		"cost": {"energy_today": 1}, "gain": {"wood": 4},
		"log": "Gathered +4 timber.",
	},
	"fish": {
		"name": "Fish", "zone": "Supplies", "effect": "Rations and a few shillings",
		"cost": {"energy_today": 1}, "gain": {"food": 2, "gold": 2},
		"log": "Caught rations and sold the extra fish.",
	},
	"dive_wreckage": {
		"name": "Dive Wreckage", "zone": "Supplies", "effect": "Salvage below the dock",
		"cost": {"energy_today": 2}, "gain": {"wood": 2, "scrap": 3},
		"log": "Recovered timber and iron.",
		"daily_cap": "dive_wreckage", "note": "Once per day.",
	},
	"plant_potatoes": {
		"name": "Plant Potatoes", "zone": "Supplies", "effect": "Matures after 3 days",
		"cost": {"energy_today": 1, "food": 1}, "gain": {"crop": 1},
		"log": "Potatoes planted.",
	},
	"harvest_potatoes": {
		"name": "Harvest Potatoes", "zone": "Supplies", "effect": "Free harvest from mature plots",
		"cost": {}, "gain": {"food": 5},
		"log": "Harvested potatoes.",
	},
	"rest": {
		"name": "Rest", "zone": "Rest", "effect": "Save strength for tomorrow",
		"cost": {"energy_today": 1}, "gain": {"tomorrow_daylight": 1},
		"log": "Tomorrow Daylight +1.",
		"daily_cap": "rest", "note": "Once per day.",
	},
	"cook_meal": {
		"name": "Cook Meal", "zone": "Rest", "effect": "Better tomorrow tempo",
		"cost": {"energy_today": 1, "food": 2}, "gain": {"tomorrow_daylight": 2},
		"log": "Tomorrow Daylight +2.",
		"daily_cap": "cook_meal", "note": "Once per day.",
	},
	"scout_raid": {
		"name": "Scout Raid", "zone": "Rest", "effect": "Preview tonight's threat",
		"cost": {"energy_today": 1, "gold": 5}, "gain": {"forecast": 1},
		"log": "Raid scouted.",
		"daily_cap": "scout_raid",
	},
}

## Gain with project modifiers applied — the UI shows this too, so a
## completed project's bonus is visible on the card, not a surprise.
func action_gain(action_id: String) -> Dictionary:
	var gain: Dictionary = ACTIONS[action_id]["gain"].duplicate()
	match action_id:
		"patch_hull":
			if completed_projects.has("patch_frame"):
				gain["hull"] += 2
		"harvest_potatoes":
			if completed_projects.has("garden_bed_prep"):
				gain["food"] += 1
	return gain

func perform_action(action_id: String) -> String:
	var action: Dictionary = ACTIONS.get(action_id, {})
	if action.is_empty():
		return "Unknown action."
	var cap: String = action.get("daily_cap", "")
	if not cap.is_empty() and daily_caps.get(cap, false):
		return "%s is done for today." % action["name"]
	match action_id:  # preconditions a cost dict can't express
		"plant_potatoes":
			if _open_farm_plots() <= 0:
				return "No open farm plot."
		"harvest_potatoes":
			if _mature_crop_index() < 0:
				return "No mature potatoes."
	var cost: Dictionary = action["cost"]
	if not spend(cost):
		return "Missing %s." % missing_text(cost)
	if not cap.is_empty():
		daily_caps[cap] = true
	if action_id == "harvest_potatoes":
		active_crops.remove_at(_mature_crop_index())
	var gain := action_gain(action_id)
	for key in gain.keys():
		_apply_gain(key, int(gain[key]))
	changed.emit()
	if action_id == "scout_raid":
		return "Raid scouted: about %d boats." % int(scouted_profile.get("wave_size", 0))
	return action["log"]

func _apply_gain(key: String, amount: int) -> void:
	match key:
		"hull":
			hull = mini(max_hull, hull + amount)
		"handling":
			clean_lens_active = true
		"crop":
			active_crops.append({"crop": "potatoes", "days_left": 3})
		"tomorrow_daylight":
			tomorrow_energy_bonus = mini(tomorrow_energy_bonus + amount, 2)
		"forecast":
			scouted_profile = raid_profile()
		_:
			set(key, int(get(key)) + amount)

func _mature_crop_index() -> int:
	for i in active_crops.size():
		if int(active_crops[i].get("days_left", 0)) <= 0:
			return i
	return -1

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

func projects_for_zone(zone: String) -> Array[String]:
	var ids: Array[String] = []
	for id in START_PROJECTS.keys():
		if START_PROJECTS[id]["zone"] == zone:
			ids.append(id)
	return ids

func _apply_project(project_id: String) -> void:
	upgrades[project_id] = true
	match project_id:
		"reinforced_hull_1":
			max_hull += 15
			hull = mini(max_hull, hull + 15)
		"build_plot_2":
			farm_plots += 1
		"rusty_autoturret":
			turret_unlocked = true
	changed.emit()

func _advance_crops() -> void:
	for crop in active_crops:
		crop["days_left"] = maxi(int(crop.get("days_left", 0)) - 1, 0)

func _open_farm_plots() -> int:
	return farm_plots - active_crops.size()

## Fresh RNG seeded from (run seed, day): the same night replays identically
## after a restart, and a typed seed reproduces a whole run.
func night_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, day])
	return rng

func raid_profile() -> Dictionary:
	if day <= 3:
		return {
			"profile_name": "Calm waters",
			"wave_size": 3 + mini(day - 1, 2),
			"fast_weight": 0.0,
			"heavy_weight": 0.0,
			"max_simultaneous": 1,
			"speed_scale": 0.7,
			"start_interval": 4.0,
			"min_interval": 3.0,
			"first_spawn_delay": 1.5,
			"use_v0_hazards": false,
		}
	if day <= 7:
		return {
			"profile_name": "Rising chop",
			"wave_size": 5 + int(day >= 6) + int(day >= 7),
			"fast_weight": 0.12 if day >= 6 else 0.0,
			"heavy_weight": 0.0,
			"max_simultaneous": 2 if day >= 6 else 1,
			"speed_scale": 0.75 + 0.03 * float(day - 4),
			"start_interval": 3.6,
			"min_interval": 2.4,
			"first_spawn_delay": 1.2,
			"use_v0_hazards": false,
		}
	if day <= 14:
		return {
			"profile_name": "Fast raiders",
			"wave_size": mini(7 + int((day - 8) / 2), 10),
			"fast_weight": 0.25,
			"heavy_weight": 0.0,
			"max_simultaneous": 2,
			"speed_scale": 0.9,
			"start_interval": 3.0,
			"min_interval": 1.9,
			"first_spawn_delay": 1.0,
			"use_v0_hazards": false,
		}
	return {
		"profile_name": "Night Board pressure",
		"wave_size": mini(9 + int((day - 15) / 2), 13),
		"fast_weight": 0.25,
		"heavy_weight": 0.12,
		"max_simultaneous": 3,
		"speed_scale": 1.0,
		"start_interval": 2.6,
		"min_interval": 1.5,
		"first_spawn_delay": 1.0,
		"use_v0_hazards": false,
	}

func beam_turn_multiplier() -> float:
	var value := 1.0
	if completed_projects.has("greased_crank"):
		value += 0.05
	if completed_projects.has("lens_crank_1"):
		value += 0.12
	if clean_lens_active:
		value += 0.05
	return value

func reload_multiplier() -> float:
	var value := 1.0
	if completed_projects.has("breech_cleaning_kit"):
		value -= 0.05
	if completed_projects.has("rifle_breech_1"):
		value -= 0.10
	return maxf(value, 0.65)

func perfect_zone_bonus() -> float:
	return 0.02 if clean_lens_active else 0.0
