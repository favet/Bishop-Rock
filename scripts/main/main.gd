extends Node2D
## App shell: night clear color, global time-scale controls (pause/slow,
## game-over freeze), restart, and camera screen-shake on lighthouse hits.
## Simulation logic lives under NightBoard.

const NIGHT_WATER := Color(0.04, 0.06, 0.10)
const SLOW_SCALE := 0.3
const SHAKE_PER_DAMAGE := 0.6  ## px of shake strength added per point of damage taken
const SHAKE_MAX := 10.0  ## px, clamps a single hit's contribution
const SHAKE_DECAY := 6.0  ## px/sec the shake settles by
const NIGHT_BOARD_SCENE := preload("res://scenes/main/NightBoard.tscn")
const HUD_SCENE := preload("res://ui/HUD.tscn")

var _slowed: bool = false
var _frozen: bool = false
var _shake_strength: float = 0.0

var _board: NightBoard
var _hud: CanvasLayer
var _campaign_layer: CanvasLayer
var _day_root: Control
var _top_bar: Label
var _zone_title: Label
var _action_list: VBoxContainer
var _log_label: Label
var _selected_zone: String = "Lighthouse"

@onready var _camera: Camera2D = $Camera2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(NIGHT_WATER)
	Engine.time_scale = 1.0
	_board = $NightBoard
	_hud = $HUD
	_campaign_layer = CanvasLayer.new()
	add_child(_campaign_layer)
	_board.board_over.connect(_on_board_over)
	_board.night_won.connect(_on_night_won)
	_board.lighthouse.damaged.connect(_on_lighthouse_damaged)
	if CampaignState.day == 1 and CampaignState.last_night_stats.is_empty():
		_board.spawner.active = false
		_hud.visible = false
		_show_start_screen()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("pause_slow") and not _frozen:
		_slowed = not _slowed
		Engine.time_scale = SLOW_SCALE if _slowed else 1.0

	if _shake_strength > 0.0:
		_shake_strength = maxf(_shake_strength - SHAKE_DECAY * delta, 0.0)
		_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

func _on_lighthouse_damaged(amount: float) -> void:
	_shake_strength = minf(_shake_strength + amount * SHAKE_PER_DAMAGE, SHAKE_MAX)

func _on_board_over() -> void:
	_frozen = true
	Engine.time_scale = 0.0

func _on_night_won(stats: Dictionary) -> void:
	_hud.visible = false
	_show_dawn(stats)

func _show_start_screen() -> void:
	_campaign_layer.add_child(_full_screen_dim())
	var center := _center_box(Vector2(420, 220))
	_campaign_layer.add_child(center)
	var box := center.get_child(0) as PanelContainer
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	box.add_child(list)
	var title := Label.new()
	title.text = "Bishop Rock"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	var summary := Label.new()
	summary.text = "Seven days of raids, repairs, food, and hard choices."
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(summary)
	var start := Button.new()
	start.text = "Start New Campaign"
	start.pressed.connect(func() -> void:
		CampaignState.reset_campaign()
		_clear_campaign_layer()
		_hud.visible = true
		_board.spawner.active = true
	)
	list.add_child(start)

func _show_dawn(stats: Dictionary) -> void:
	_campaign_layer.add_child(_full_screen_dim())
	var center := _center_box(Vector2(520, 380))
	_campaign_layer.add_child(center)
	var box := center.get_child(0) as PanelContainer
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	box.add_child(list)
	var title := Label.new()
	title.text = "Dawn after Night %d" % int(stats["night"])
	title.add_theme_font_size_override("font_size", 24)
	list.add_child(title)
	var consumed: Dictionary = stats["defenses_consumed"]
	var full_repair := _repair_hint()
	var lines := [
		"Boats sunk: %d" % int(stats["kills"]),
		"Boats crashed: %d" % int(stats["crashed"]),
		"Gold earned: %dg" % int(stats["gold_earned"]),
		"Perfect bonuses: %dg" % int(stats["perfect_bonus_earned"]),
		"Hull damage taken: %d" % int(stats["hull_damage_taken"]),
		"Hull: %d/%d" % [int(stats["hull"]), int(stats["max_hull"])],
		"Defenses consumed: %d mines, %d barricades" % [int(consumed.get("mines", 0)), int(consumed.get("barricades", 0))],
		"Repair to full would require approximately: %s" % full_repair,
	]
	for line in lines:
		var label := Label.new()
		label.text = line
		list.add_child(label)
	var button := Button.new()
	button.text = "Continue to Day %d" % (CampaignState.day + 1)
	button.pressed.connect(func() -> void:
		_clear_campaign_layer()
		CampaignState.start_day()
		_show_day_hub()
	)
	list.add_child(button)

func _show_day_hub() -> void:
	_day_root = Control.new()
	_day_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_campaign_layer.add_child(_day_root)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.10, 0.11, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_day_root.add_child(bg)

	var layout := VBoxContainer.new()
	layout.position = Vector2(18, 14)
	layout.size = Vector2(1244, 690)
	layout.add_theme_constant_override("separation", 10)
	_day_root.add_child(layout)

	_top_bar = Label.new()
	_top_bar.add_theme_font_size_override("font_size", 16)
	layout.add_child(_top_bar)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)

	var zones := GridContainer.new()
	zones.columns = 2
	zones.custom_minimum_size = Vector2(520, 470)
	zones.add_theme_constant_override("h_separation", 10)
	zones.add_theme_constant_override("v_separation", 10)
	body.add_child(zones)
	for zone in ["Lighthouse", "Workshop", "Shore / Dock / Farm", "Quarters"]:
		var card := Button.new()
		card.text = _zone_label(zone)
		card.custom_minimum_size = Vector2(250, 220)
		card.focus_mode = Control.FOCUS_ALL
		card.pressed.connect(_select_zone.bind(zone))
		zones.add_child(card)

	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	body.add_child(panel)
	_zone_title = Label.new()
	_zone_title.add_theme_font_size_override("font_size", 22)
	panel.add_child(_zone_title)
	_action_list = VBoxContainer.new()
	_action_list.add_theme_constant_override("separation", 5)
	panel.add_child(_action_list)
	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.custom_minimum_size = Vector2(0, 42)
	panel.add_child(_log_label)
	var start := Button.new()
	start.text = "Start Night %d" % CampaignState.day
	start.pressed.connect(func() -> void:
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	)
	panel.add_child(start)

	_refresh_day_ui()
	_select_zone(_selected_zone)

func _select_zone(zone: String) -> void:
	_selected_zone = zone
	_zone_title.text = zone
	for child in _action_list.get_children():
		child.queue_free()
	for action in _actions_for_zone(zone):
		_action_list.add_child(_action_button(action))
	for project_id in CampaignState.projects_for_zone(zone):
		_action_list.add_child(_project_card(project_id))

func _action_button(action: Dictionary) -> Button:
	var button := Button.new()
	button.text = action["label"]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void:
		_log_label.text = CampaignState.perform_action(action["id"])
		_refresh_day_ui()
		_select_zone(_selected_zone)
	)
	return button

func _project_card(project_id: String) -> VBoxContainer:
	var project := CampaignState.project_def(project_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = "%s: %s" % [project["display_name"], project["effect"]]
	box.add_child(title)
	var cost := Label.new()
	cost.modulate = Color(1, 1, 1, 0.72)
	cost.text = "Cost %s   Work %d/%d%s" % [
		_cost_text(project["start_cost"]),
		int(CampaignState.active_projects.get(project_id, {}).get("work_done", 0)),
		int(project["work_required"]),
		"   Missing " + CampaignState.missing_text(project["start_cost"]) if not CampaignState.can_afford(project["start_cost"]) and not CampaignState.active_projects.has(project_id) and not CampaignState.completed_projects.has(project_id) else "",
	]
	box.add_child(cost)
	var button := Button.new()
	if CampaignState.completed_projects.has(project_id):
		button.text = "Completed"
	elif CampaignState.active_projects.has(project_id):
		button.text = "Work  E1"
	else:
		button.text = "Start"
	button.pressed.connect(func() -> void:
		if CampaignState.completed_projects.has(project_id):
			_log_label.text = "%s is complete." % project["display_name"]
		elif CampaignState.active_projects.has(project_id):
			_log_label.text = CampaignState.work_project(project_id)
		else:
			_log_label.text = CampaignState.start_project(project_id)
		_refresh_day_ui()
		_select_zone(_selected_zone)
	)
	box.add_child(button)
	return box

func _actions_for_zone(zone: String) -> Array[Dictionary]:
	match zone:
		"Lighthouse":
			return [
				{"id": "patch_hull", "label": "Patch hull   E1 -> +10 hull   Cost 3g 2 wood"},
				{"id": "full_repair", "label": "Full repair   E2 -> +22 hull   Cost 6g 4 wood"},
				{"id": "clean_lens", "label": "Clean lens   E1 -> easier handling tonight"},
			]
		"Workshop":
			return [
				{"id": "sort_scrap", "label": "Sort scrap   E1 -> scrap +2"},
				{"id": "make_tool", "label": "Make tool   E1 scrap5 -> tool +1   Used for Lens Crank I, Rifle Breech I, Rusty Autoturret"},
				{"id": "craft_mines", "label": "Craft mines   E1 4g scrap3 -> mines +2"},
				{"id": "build_barricade", "label": "Build barricade   E1 wood4 -> barricade +1"},
			]
		"Shore / Dock / Farm":
			return [
				{"id": "gather_driftwood", "label": "Gather driftwood   E1 -> wood +4"},
				{"id": "fish", "label": "Fish   E1 -> food +2, gold +2"},
				{"id": "dive_wreckage", "label": "Dive wreckage   E2 -> wood +2, scrap +3   Once/day"},
				{"id": "plant_potatoes", "label": "Plant potatoes   E1 food1 -> crop in 3 days"},
				{"id": "harvest_potatoes", "label": "Harvest potatoes   E0 -> food +5"},
			]
		"Quarters":
			var scout := "Scout raid   E1 5g -> preview tonight"
			if not CampaignState.scouted_profile.is_empty():
				scout = "Scout raid   %s, about %d boats" % [CampaignState.scouted_profile["profile_name"], int(CampaignState.scouted_profile["wave_size"])]
			return [
				{"id": "rest", "label": "Rest   E1 -> tomorrow energy +1   Once/day"},
				{"id": "cook_meal", "label": "Cook meal   E1 food2 -> tomorrow energy +2   Once/day"},
				{"id": "scout_raid", "label": scout},
			]
	return []

func _refresh_day_ui() -> void:
	if _top_bar == null:
		return
	_top_bar.text = "♥ %d/%d   ⚡ %d/%d   🪙 %d   🪵 %d   ⚙ %d   🍲 %d   🔧 %d   💣 %d   🛡 %d   Day %d" % [
		CampaignState.hull, CampaignState.max_hull, CampaignState.energy_today, CampaignState.energy_max,
		CampaignState.gold, CampaignState.wood, CampaignState.scrap, CampaignState.food,
		CampaignState.tools, CampaignState.mines, CampaignState.barricades, CampaignState.day,
	]

func _zone_label(zone: String) -> String:
	match zone:
		"Lighthouse":
			return "LIGHTHOUSE\nHull, lens, repairs"
		"Workshop":
			return "WORKSHOP\nScrap, tools, defenses"
		"Shore / Dock / Farm":
			return "SHORE / DOCK / FARM\nWood, food, wreckage"
		"Quarters":
			return "QUARTERS\nRest, meals, scouting"
	return zone

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost.keys():
		parts.append("%s %d" % [key, int(cost[key])])
	return ", ".join(parts)

func _repair_hint() -> String:
	var missing := CampaignState.max_hull - CampaignState.hull
	if missing <= 0:
		return "no repairs"
	var full := missing / 22
	var patch := int(ceil(float(missing % 22) / 10.0))
	var parts: Array[String] = []
	if full > 0:
		parts.append("%d Full Repair" % full)
	if patch > 0:
		parts.append("%d Patch" % patch)
	return " + ".join(parts)

func _clear_campaign_layer() -> void:
	for child in _campaign_layer.get_children():
		child.queue_free()

func _full_screen_dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	return dim

func _center_box(min_size: Vector2) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	return center
