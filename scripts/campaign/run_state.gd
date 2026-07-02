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

func reset_campaign() -> void:
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
	if key == "energy_today":
		return "Daylight"
	return key.capitalize()

func perform_action(action_id: String) -> String:
	match action_id:
		"patch_hull":
			if not spend({"energy_today": 1, "gold": 3, "wood": 2}):
				return "Missing %s." % missing_text({"energy_today": 1, "gold": 3, "wood": 2})
			hull = mini(max_hull, hull + 10 + (2 if completed_projects.has("patch_frame") else 0))
			changed.emit()
			return "Patched hull."
		"full_repair":
			if not spend({"energy_today": 2, "gold": 6, "wood": 4}):
				return "Missing %s." % missing_text({"energy_today": 2, "gold": 6, "wood": 4})
			hull = mini(max_hull, hull + 22)
			changed.emit()
			return "Repairs completed."
		"clean_lens":
			if not spend({"energy_today": 1}):
				return "Need 1 Daylight."
			clean_lens_active = true
			changed.emit()
			return "Lens cleaned for tonight."
		"sort_scrap":
			if not spend({"energy_today": 1}):
				return "Need 1 Daylight."
			scrap += 2
			changed.emit()
			return "Sorted +2 scrap."
		"make_tool":
			if not spend({"energy_today": 1, "scrap": 5}):
				return "Missing %s." % missing_text({"energy_today": 1, "scrap": 5})
			tools += 1
			changed.emit()
			return "Made a tool."
		"craft_mines":
			if not spend({"energy_today": 1, "gold": 4, "scrap": 3}):
				return "Missing %s." % missing_text({"energy_today": 1, "gold": 4, "scrap": 3})
			mines += 2
			changed.emit()
			return "Crafted 2 mines."
		"build_barricade":
			if not spend({"energy_today": 1, "wood": 4}):
				return "Missing %s." % missing_text({"energy_today": 1, "wood": 4})
			barricades += 1
			changed.emit()
			return "Built a barricade."
		"gather_driftwood":
			if not spend({"energy_today": 1}):
				return "Need 1 Daylight."
			wood += 4
			changed.emit()
			return "Gathered +4 wood."
		"fish":
			if not spend({"energy_today": 1}):
				return "Need 1 Daylight."
			food += 2
			gold += 2
			changed.emit()
			return "Caught food and sold extra fish."
		"dive_wreckage":
			if daily_caps.get("dive_wreckage", false):
				return "Dive wreckage is done for today."
			if not spend({"energy_today": 2}):
				return "Need 2 Daylight."
			daily_caps["dive_wreckage"] = true
			wood += 2
			scrap += 3
			changed.emit()
			return "Recovered wood and scrap."
		"plant_potatoes":
			if _open_farm_plots() <= 0:
				return "No open farm plot."
			if not spend({"energy_today": 1, "food": 1}):
				return "Missing %s." % missing_text({"energy_today": 1, "food": 1})
			active_crops.append({"crop": "potatoes", "days_left": 3})
			changed.emit()
			return "Potatoes planted."
		"harvest_potatoes":
			for i in active_crops.size():
				if int(active_crops[i].get("days_left", 0)) <= 0:
					active_crops.remove_at(i)
					food += 5 + (1 if completed_projects.has("garden_bed_prep") else 0)
					changed.emit()
					return "Harvested potatoes."
			return "No mature potatoes."
		"rest":
			return _add_tomorrow_energy("rest", 1, {})
		"cook_meal":
			return _add_tomorrow_energy("cook_meal", 2, {"food": 2})
		"scout_raid":
			if daily_caps.get("scout_raid", false):
				return "Raid already scouted."
			if not spend({"energy_today": 1, "gold": 5}):
				return "Missing %s." % missing_text({"energy_today": 1, "gold": 5})
			daily_caps["scout_raid"] = true
			scouted_profile = raid_profile()
			changed.emit()
			return "Raid scouted: about %d boats." % int(scouted_profile.get("wave_size", 0))
	return "Unknown action."

func _add_tomorrow_energy(cap_id: String, amount: int, cost: Dictionary) -> String:
	if daily_caps.get(cap_id, false):
		return "%s is already done today." % cap_id.capitalize()
	var full_cost := cost.duplicate()
	full_cost["energy_today"] = 1
	if not spend(full_cost):
		return "Missing %s." % missing_text(full_cost)
	daily_caps[cap_id] = true
	tomorrow_energy_bonus = mini(tomorrow_energy_bonus + amount, 2)
	changed.emit()
	return "Tomorrow Daylight +%d." % amount

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
