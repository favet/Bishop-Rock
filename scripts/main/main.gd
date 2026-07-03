extends Node2D
## App shell: night clear color, campaign overlays, global slow control, and
## camera screen-shake. Simulation logic lives under NightBoard.

const NIGHT_WATER := Color(0.04, 0.06, 0.10)
const SLOW_SCALE := 0.3
const SHAKE_PER_DAMAGE := 0.6
const SHAKE_MAX := 10.0
const SHAKE_DECAY := 6.0

const IRON := Color(0.045, 0.065, 0.085)
const PANEL := Color(0.10, 0.12, 0.13)
const PANEL_HOVER := Color(0.15, 0.14, 0.12)
const BRASS := Color(0.78, 0.58, 0.25)
const BRASS_DARK := Color(0.34, 0.24, 0.10)
const TEXT := Color(0.93, 0.88, 0.78)
const MUTED := Color(0.68, 0.64, 0.55)
const RED := Color(0.95, 0.34, 0.25)
const GREEN := Color(0.38, 0.86, 0.45)

var _slowed: bool = false
var _frozen: bool = false
var _shake_strength: float = 0.0

var _board: NightBoard
var _hud: CanvasLayer
var _campaign_layer: CanvasLayer
var _day_root: Control
var _top_bar: HBoxContainer
var _hull_fill: ColorRect
var _hull_label: Label
var _daylight_tokens: Array[Control] = []
var _daylight_preview_spend: int = 0
var _light_list: VBoxContainer
var _prov_list: VBoxContainer
var _project_list: VBoxContainer
var _tonight_holder: VBoxContainer
var _log_label: Label
var _start_night_label: Label

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
	_board.perfect_kill.connect(_on_perfect_kill)
	if CampaignState.day == 1 and CampaignState.last_night_stats.is_empty():
		_board.spawner.active = false
		_hud.visible = false
		_show_start_screen()
	else:
		Sfx.play("foghorn", -4.0)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		Engine.time_scale = 1.0
		# A lost run is over — R starts a fresh campaign at the title screen,
		# not a free retry of the failed night.
		if _board.game_over:
			CampaignState.reset_campaign()
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
	Sfx.play("hull_crunch")
	Sfx.duck_ambient()

## Hit-stop + zoom pulse on a perfect kill: freeze the world for a beat and
## punch the camera so the signature move lands physically.
func _on_perfect_kill() -> void:
	if _frozen:
		return
	Sfx.play("perfect_ding")
	Engine.time_scale = 0.05
	_camera.zoom = Vector2.ONE * 1.10
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(_camera, "zoom", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.07, true, false, true).timeout
	if not _frozen:
		Engine.time_scale = SLOW_SCALE if _slowed else 1.0

func _on_board_over() -> void:
	_frozen = true
	Engine.time_scale = 0.0

func _on_night_won(stats: Dictionary) -> void:
	_hud.visible = false
	_show_dawn(stats)

func _show_start_screen() -> void:
	_campaign_layer.add_child(_full_screen_dim())
	var center := _center_box(Vector2(440, 230))
	_campaign_layer.add_child(center)
	var box := center.get_child(0) as PanelContainer
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	box.add_child(list)
	_card_title(list, "Bishop Rock", "The sea never relents. Hold the light, night after night.")
	var seed_input := LineEdit.new()
	seed_input.placeholder_text = "Seed (optional - share a run)"
	list.add_child(seed_input)
	var mercy := CheckBox.new()
	mercy.text = "Keeper's Mercy - slower boats, wider beam, softer crashes"
	list.add_child(mercy)
	if CampaignState.has_save():
		var resume := Button.new()
		resume.text = "Continue Campaign"
		resume.custom_minimum_size = Vector2(0, 40)
		resume.pressed.connect(func() -> void:
			if CampaignState.load_run():
				Sfx.play("ui_click")
				_clear_campaign_layer()
				_show_day_hub()  # resume at dawn; Start Night reloads into the raid
		)
		list.add_child(resume)
	var start := Button.new()
	start.text = "Start New Campaign"
	start.custom_minimum_size = Vector2(0, 44)
	start.add_theme_stylebox_override("normal", _panel_style(BRASS, Color(0.92, 0.78, 0.42), 2))
	start.add_theme_color_override("font_color", Color(0.07, 0.05, 0.03))
	start.pressed.connect(func() -> void:
		CampaignState.reset_campaign(
			int(seed_input.text) if seed_input.text.strip_edges().is_valid_int() else -1,
			mercy.button_pressed)
		_clear_campaign_layer()
		_hud.visible = true
		_board.spawner.active = true
		Sfx.play("foghorn", -4.0)
	)
	list.add_child(start)

func _show_dawn(stats: Dictionary) -> void:
	_campaign_layer.add_child(_full_screen_dim())
	var center := _center_box(Vector2(540, 390))
	_campaign_layer.add_child(center)
	var box := center.get_child(0) as PanelContainer
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	box.add_child(list)
	_card_title(list, "Dawn after Night %d" % int(stats["night"]), "The sea quiets. The damage remains.")
	var consumed: Dictionary = stats["defenses_consumed"]
	for line in [
		"Boats sunk: %d (%d perfect)" % [int(stats["kills"]), int(stats.get("perfects", 0))],
		"Boats crashed: %d" % int(stats["crashed"]),
		"Shillings earned: %d" % int(stats["gold_earned"]),
		"Hull damage taken: %d" % int(stats["hull_damage_taken"]),
		"Hull: %d/%d" % [int(stats["hull"]), int(stats["max_hull"])],
		"Repair to full: about %s" % _repair_hint(),
	]:
		_small_label(list, line, TEXT)
	# Attribution: purchases must be seen paying off or they stop happening.
	if int(consumed.get("mines", 0)) > 0:
		_small_label(list, "Your mines fired %d time%s." % [int(consumed["mines"]),
			"s" if int(consumed["mines"]) > 1 else ""], BRASS)
	if int(consumed.get("barricades", 0)) > 0:
		_small_label(list, "A barricade ate most of a crash.", BRASS)
	var salvage: Dictionary = CampaignState.salvage_dive_bonus()
	if int(salvage["wood"]) > 0 or int(salvage["scrap"]) > 0:
		_small_label(list, "Wreckage litters the shallows - today's dive will be rich.", BRASS)
	# First three dawns teach, one line each. No tutorial system.
	var hints := {
		1: "Keeper's note: repair the hull before nightfall - crashes cost more than repairs.",
		2: "Keeper's note: check TONIGHT before spending - mines answer heavy hulls.",
		3: "Keeper's note: a hearty supper today means two extra Daylight tomorrow.",
	}
	if hints.has(int(stats["night"])):
		_small_label(list, hints[int(stats["night"])], MUTED)
	var button := Button.new()
	button.text = "Continue to Day %d" % (CampaignState.day + 1)
	button.custom_minimum_size = Vector2(0, 38)
	button.pressed.connect(func() -> void:
		_clear_campaign_layer()
		CampaignState.start_day()
		_show_day_hub()
	)
	list.add_child(button)

## One screen, no navigation: every card visible at once. Left column
## answers tonight, middle column funds tomorrow, right column shows what
## tonight actually is (the forecast is exact) plus the workshop.
func _show_day_hub() -> void:
	_day_root = Control.new()
	_day_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_campaign_layer.add_child(_day_root)
	var bg := ColorRect.new()
	bg.color = IRON
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_day_root.add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 16)
	_day_root.add_child(root)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	_top_bar = HBoxContainer.new()
	_top_bar.add_theme_constant_override("separation", 10)
	layout.add_child(_top_bar)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)

	_light_list = _card_column(body, "KEEP THE LIGHT")
	_prov_list = _card_column(body, "PROVISIONS")

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	_tonight_holder = VBoxContainer.new()
	right.add_child(_tonight_holder)
	var workshop := Label.new()
	workshop.text = "WORKSHOP"
	workshop.add_theme_font_size_override("font_size", 18)
	workshop.add_theme_color_override("font_color", BRASS)
	right.add_child(workshop)
	var project_scroll := ScrollContainer.new()
	project_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	project_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(project_scroll)
	_project_list = VBoxContainer.new()
	_project_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_project_list.add_theme_constant_override("separation", 8)
	project_scroll.add_child(_project_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)
	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_color_override("font_color", MUTED)
	footer.add_child(_log_label)
	var start := Button.new()
	start.name = "FixedStartNightButton"
	start.custom_minimum_size = Vector2(330, 64)
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start.add_theme_stylebox_override("normal", _panel_style(BRASS, Color(0.92, 0.78, 0.42), 2))
	start.add_theme_stylebox_override("hover", _panel_style(Color(0.92, 0.70, 0.30), Color(1.0, 0.88, 0.55), 2))
	start.add_theme_color_override("font_color", Color(0.07, 0.05, 0.03))
	_start_night_label = Label.new()
	_start_night_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_night_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_night_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_start_night_label.add_theme_font_size_override("font_size", 19)
	_start_night_label.add_theme_color_override("font_color", Color(0.07, 0.05, 0.03))
	start.add_child(_start_night_label)
	_start_night_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	start.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		CampaignState.save_run()  # crash mid-night resumes at this dusk
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	)
	footer.add_child(start)

	_refresh_day_ui()
	_rebuild_day_cards()

func _card_column(parent: HBoxContainer, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(370, 0)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", BRASS)
	column.add_child(header)
	# Scroll keeps tall card stacks from swallowing the footer — Start Night
	# must always be on screen.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list

func _rebuild_day_cards() -> void:
	for list in [_light_list, _prov_list, _project_list]:
		for child in list.get_children():
			child.queue_free()
	for action in _actions_for_group("light"):
		_light_list.add_child(_action_card(action))
	for action in _actions_for_group("provisions"):
		_prov_list.add_child(_action_card(action))
	# Completed projects collapse to one badge line; their card earned
	# retirement, not permanent Workshop space.
	var built: Array[String] = []
	for project_id in CampaignState.START_PROJECTS:
		if CampaignState.completed_projects.has(project_id):
			built.append(CampaignState.project_def(project_id)["display_name"])
		else:
			_project_list.add_child(_project_card(project_id))
	if not built.is_empty():
		_small_label(_project_list, "Built: %s" % ", ".join(built), GREEN)

func _action_card(action: Dictionary) -> Button:
	var button := _base_card_button()
	button.tooltip_text = action.get("tooltip", "")
	var cost: Dictionary = action.get("cost", {})
	var daylight_cost := _daylight_cost(cost)
	button.mouse_entered.connect(_set_daylight_preview.bind(daylight_cost))
	button.mouse_exited.connect(_set_daylight_preview.bind(0))
	# Unaffordable reads at a glance, before any text does.
	if not CampaignState.can_afford(cost):
		button.modulate = Color(1, 1, 1, 0.55)
	# Today's opportunity gets brass trim — the day's one novelty must pop.
	if action.get("opportunity", false):
		button.add_theme_stylebox_override("normal", _panel_style(Color(0.10, 0.09, 0.06), BRASS, 2))
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 3)
	rows.position = Vector2(12, 8)
	button.add_child(rows)
	_card_title(rows, action["name"], action["effect"], false)
	for key in cost.keys():
		_have_need_row(rows, key, int(CampaignState.get(key)), int(cost[key]))
	_trade_rows(rows, action.get("gain", {}), GREEN, "+")
	if action.has("note"):
		_small_label(rows, action["note"], MUTED, false)
	# A Button doesn't grow to fit manual children — size it to the content
	# or long cards bleed into their neighbours. Labels only know their size
	# once themed, i.e. inside the tree, so measure at ready.
	rows.ready.connect(func() -> void:
		button.custom_minimum_size.y = rows.get_combined_minimum_size().y + 16.0)
	button.pressed.connect(func() -> void:
		_log_label.text = CampaignState.perform_action(action["id"])
		_set_daylight_preview(0)
		_refresh_day_ui()
		_rebuild_day_cards()
	)
	return button

func _project_card(project_id: String) -> VBoxContainer:
	var project := CampaignState.project_def(project_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var wrap := PanelContainer.new()
	wrap.tooltip_text = _project_tooltip(project["start_cost"])
	wrap.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.085, 0.085), BRASS_DARK, 1))
	box.add_child(wrap)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	wrap.add_child(inner)
	_card_title(inner, project["display_name"], project["effect"])
	_small_label(inner, "Requirements", BRASS)
	var cost: Dictionary = project["start_cost"]
	for key in cost.keys():
		_have_need_row(inner, key, int(CampaignState.get(key)), int(cost[key]))
	# Work is progress, not a shortfall — "0/2 Daylight" in red read as "you
	# can't afford this" when it meant "no work done yet".
	var work_done := int(CampaignState.active_projects.get(project_id, {}).get("work_done", 0))
	var work_row := HBoxContainer.new()
	work_row.add_theme_constant_override("separation", 6)
	inner.add_child(work_row)
	work_row.add_child(ResourceIcon.new("daylight", 24))
	var work_label := Label.new()
	work_label.text = "Work done %d/%d (costs Daylight)" % [work_done, int(project["work_required"])]
	work_label.add_theme_font_size_override("font_size", 15)
	work_label.add_theme_color_override("font_color",
		GREEN if work_done >= int(project["work_required"]) else MUTED)
	work_row.add_child(work_label)
	if not CampaignState.can_afford(cost) and not CampaignState.active_projects.has(project_id) and not CampaignState.completed_projects.has(project_id):
		_small_label(inner, "Missing", RED)
		for key in cost.keys():
			var missing := int(cost[key]) - int(CampaignState.get(key))
			if missing > 0:
				_resource_row(inner, "-", key, missing, RED, _gain_hint(key))
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 30)
	button.pressed.connect(Sfx.play.bind("ui_click"))
	button.mouse_entered.connect(_set_daylight_preview.bind(1 if CampaignState.active_projects.has(project_id) else 0))
	button.mouse_exited.connect(_set_daylight_preview.bind(0))
	if CampaignState.completed_projects.has(project_id):
		button.text = "Completed"
	elif CampaignState.active_projects.has(project_id):
		button.text = "Work 1 Daylight"
	else:
		button.text = "Start Project" if CampaignState.can_afford(cost) else "Cannot Start"
	button.pressed.connect(func() -> void:
		if CampaignState.completed_projects.has(project_id):
			_log_label.text = "%s is complete." % project["display_name"]
		elif CampaignState.active_projects.has(project_id):
			_log_label.text = CampaignState.work_project(project_id)
		else:
			_log_label.text = CampaignState.start_project(project_id)
		_set_daylight_preview(0)
		_refresh_day_ui()
		_rebuild_day_cards()
	)
	box.add_child(button)
	return box

## Cards render straight from CampaignState.ACTIONS — one source of truth
## for both display and spend. Only presentation tweaks happen here.
func _actions_for_group(group: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in CampaignState.ACTIONS:
		var def: Dictionary = CampaignState.ACTIONS[id]
		if def["zone"] != group:
			continue
		var entry := {
			"id": id,
			"name": def["name"],
			"effect": def["effect"],
			"cost": def["cost"],
			"gain": CampaignState.action_gain(id),
		}
		if def.has("note"):
			entry["note"] = def["note"]
		if id == "dive_wreckage":
			var bonus: Dictionary = CampaignState.salvage_dive_bonus()
			if int(bonus["wood"]) > 0 or int(bonus["scrap"]) > 0:
				entry["note"] = "Once per day. Includes +%d timber from wrecks,\n+%d iron from crates." % [
					int(bonus["wood"]), int(bonus["scrap"])]
		out.append(entry)
	# Today's rotating opportunity: pinned first with brass trim — the day's
	# one novelty must never hide below a scroll fold.
	var opp_id: String = CampaignState.today_opportunity
	if not opp_id.is_empty() and not CampaignState.daily_caps.get("opportunity", false):
		var opp: Dictionary = CampaignState.OPPORTUNITIES[opp_id]
		if opp["zone"] == group:
			out.insert(0, {
				"id": opp_id, "name": opp["name"], "effect": opp["effect"],
				"cost": opp["cost"], "gain": CampaignState.action_gain(opp_id),
				"note": "Opportunity - today only.", "opportunity": true,
			})
	return out

func _refresh_day_ui() -> void:
	if _top_bar == null:
		return
	for child in _top_bar.get_children():
		child.queue_free()
	_daylight_tokens.clear()
	_top_bar.add_child(_hull_resource())
	_top_bar.add_child(_daylight_resource())
	for key in ["gold", "wood", "scrap", "food"]:
		_top_bar.add_child(_resource_badge(key, str(CampaignState.get(key))))
	_top_bar.add_child(_resource_badge("day", str(CampaignState.day)))
	if _start_night_label != null:
		_start_night_label.text = "START NIGHT %d\n%s" % [
			CampaignState.day, RunState.WEATHERS[CampaignState.weather]["label"]]
	if _tonight_holder != null:
		for child in _tonight_holder.get_children():
			child.queue_free()
		_tonight_holder.add_child(_tonight_panel())
	_update_daylight_tokens()

## The night's exact composition, weather, and your standing defenses — the
## question the day's spending is supposed to answer.
func _tonight_panel() -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.085, 0.095), BRASS, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	wrap.add_child(box)
	var title := Label.new()
	title.text = "TONIGHT"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BRASS)
	box.add_child(title)
	var profile := CampaignState.raid_profile()
	_small_label(box, CampaignState.forecast_text(), TEXT, false)
	_small_label(box, "%s - %s" % [profile["profile_name"],
		RunState.WEATHERS[CampaignState.weather]["label"]], MUTED, false)
	var defenses := HBoxContainer.new()
	defenses.add_theme_constant_override("separation", 8)
	box.add_child(defenses)
	defenses.add_child(ResourceIcon.new("mines", 24))
	_small_label(defenses, "Mines %d" % CampaignState.mines, TEXT, false)
	defenses.add_child(ResourceIcon.new("barricades", 24))
	_small_label(defenses, "Barricades %d" % CampaignState.barricades, TEXT, false)
	if CampaignState.night_plan().has("heavy") and CampaignState.mines == 0:
		_small_label(box, "Heavy hulls shrug off single shots - mines answer them.", RED)
	return wrap

func _hull_resource() -> PanelContainer:
	var wrap := _resource_shell("HULL", _resource_tooltip("hull"))
	wrap.custom_minimum_size = Vector2(190, 48)
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	wrap.add_child(box)
	box.add_child(ResourceIcon.new("hull", 34))
	var rows := VBoxContainer.new()
	box.add_child(rows)
	_hull_label = Label.new()
	_hull_label.text = "HULL %d/%d" % [CampaignState.hull, CampaignState.max_hull]
	_hull_label.add_theme_color_override("font_color", TEXT)
	rows.add_child(_hull_label)
	var bg := ColorRect.new()
	bg.custom_minimum_size = Vector2(140, 8)
	bg.color = Color(0.16, 0.17, 0.17)
	rows.add_child(bg)
	_hull_fill = ColorRect.new()
	_hull_fill.size = Vector2(140.0 * clampf(float(CampaignState.hull) / float(CampaignState.max_hull), 0.0, 1.0), 8)
	_hull_fill.color = GREEN if CampaignState.hull > CampaignState.max_hull * 0.35 else RED
	bg.add_child(_hull_fill)
	return wrap

func _daylight_resource() -> PanelContainer:
	var wrap := _resource_shell("DAYLIGHT", _resource_tooltip("energy_today"))
	wrap.name = "DaylightDisplay"
	wrap.custom_minimum_size = Vector2(190, 48)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(rows)
	var title := Label.new()
	title.text = "DAYLIGHT"
	title.add_theme_color_override("font_color", BRASS)
	rows.add_child(title)
	var tokens := HBoxContainer.new()
	tokens.name = "DaylightTokens"
	tokens.add_theme_constant_override("separation", 4)
	rows.add_child(tokens)
	for i in maxi(CampaignState.energy_max, CampaignState.energy_today):
		var token := ResourceIcon.new("daylight", 26)
		token.name = "DaylightToken%d" % i
		tokens.add_child(token)
		_daylight_tokens.append(token)
	return wrap

func _resource_badge(key: String, value: String) -> PanelContainer:
	var wrap := _resource_shell(_display_resource_name(key).to_upper(), _resource_tooltip(key))
	wrap.custom_minimum_size = Vector2(106, 48)
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	wrap.add_child(box)
	box.add_child(ResourceIcon.new(ResourceIcon.kind_for(key), 34))
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", TEXT)
	box.add_child(label)
	return wrap

func _resource_shell(_title: String, tooltip: String) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.tooltip_text = tooltip
	wrap.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.085, 0.095), BRASS_DARK, 1))
	return wrap

func _set_daylight_preview(amount: int) -> void:
	_daylight_preview_spend = max(amount, 0)
	_update_daylight_tokens()

func _update_daylight_tokens() -> void:
	for i in _daylight_tokens.size():
		var token := _daylight_tokens[i]
		var spent_preview := i >= CampaignState.energy_today - _daylight_preview_spend and i < CampaignState.energy_today
		if i < CampaignState.energy_today and not spent_preview:
			token.modulate = Color.WHITE
		elif spent_preview:
			token.modulate = Color(1, 1, 1, 0.28)
		else:
			token.modulate = Color(0.5, 0.48, 0.44, 0.7)

func _base_card_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 92)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.075, 0.085, 0.085), BRASS_DARK, 1))
	button.add_theme_stylebox_override("hover", _panel_style(PANEL_HOVER, BRASS, 2))
	button.pressed.connect(Sfx.play.bind("ui_click"))
	return button

func _card_title(parent: VBoxContainer, title_text: String, subtitle: String, wrap: bool = true) -> void:
	var title := Label.new()
	title.text = title_text.to_upper()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", TEXT)
	parent.add_child(title)
	_small_label(parent, subtitle, MUTED, wrap)

func _trade_rows(parent: VBoxContainer, values: Dictionary, color: Color, prefix: String) -> void:
	for key in values.keys():
		_resource_row(parent, prefix, key, int(values[key]), color, _gain_hint(key))

func _resource_row(parent: VBoxContainer, prefix: String, key: String, amount: int, color: Color, tooltip: String = "") -> void:
	var row := HBoxContainer.new()
	row.tooltip_text = tooltip
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var sign := Label.new()
	sign.text = prefix
	sign.custom_minimum_size = Vector2(16, 0)
	sign.add_theme_color_override("font_color", color)
	row.add_child(sign)
	var kind := ResourceIcon.kind_for(key)
	if not kind.is_empty():
		row.add_child(ResourceIcon.new(kind, 24))
	var label := Label.new()
	label.text = "%s %d" % [_display_resource_name(key), amount]
	label.add_theme_color_override("font_color", color)
	row.add_child(label)

## "X/N Material" — green once you meet the need, red while short.
func _have_need_row(parent: VBoxContainer, key: String, have: int, need: int) -> void:
	var color := GREEN if have >= need else RED
	var row := HBoxContainer.new()
	row.tooltip_text = _gain_hint(key)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var kind := ResourceIcon.kind_for(key)
	if not kind.is_empty():
		row.add_child(ResourceIcon.new(kind, 24))
	var label := Label.new()
	# Daylight's "have" already lives in the top-bar tokens (with hover
	# ghosting) — repeating it as X/N here was number soup.
	if key == "energy_today":
		label.text = "Daylight %d" % need
	else:
		label.text = "%d/%d %s" % [have, need, _display_resource_name(key)]
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	row.add_child(label)

func _small_label(parent: Control, text: String, color: Color, wrap: bool = true) -> void:
	var label := Label.new()
	label.text = text
	# Autowrap labels report a near-zero minimum width, so inside an HBox or a
	# manually laid-out card they collapse to one letter per line. Only wrap
	# where a container gives the label real width.
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _panel_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _daylight_cost(cost: Dictionary) -> int:
	return int(cost.get("energy_today", 0))

func _project_tooltip(cost: Dictionary) -> String:
	var lines: Array[String] = []
	for key in cost.keys():
		lines.append("%s: %s" % [_display_resource_name(key), _gain_hint(key)])
	return "\n".join(lines)

func _gain_hint(key: String) -> String:
	match key:
		"gold":
			return "Shillings. Gain from sinking boats and Fishing."
		"wood":
			return "Timber. Gain from Gather Driftwood or Dive Wreckage."
		"scrap":
			return "Iron. Gain from Dive Wreckage, crashes, and opportunities."
		"food":
			return "Rations. Gain from Fishing and opportunities."
		"tools":
			return "Machine parts in Crafting. Needed for Lens Crank I, Rifle Breech I, and Rusty Autoturret."
		"energy_today", "daylight_work":
			return "Daylight is your work time for the day."
	return ""

func _resource_tooltip(key: String) -> String:
	match key:
		"hull":
			return "Hull\nLighthouse durability. Boats that crash damage Hull. Repair it during the day."
		"energy_today":
			return "Daylight\nYour work time for the day. Most actions spend Daylight. A Hearty Supper adds two tomorrow."
		"gold":
			return "Shillings\nUsed for repairs, projects, crafting, and supplies. Earned by sinking boats and fishing."
		"wood":
			return "Timber\nUsed for repairs, barricades, and hull projects. Gain from Gather Driftwood or Dive Wreckage."
		"scrap":
			return "Iron\nUsed for mines, parts, and turret work. Gain from Dive Wreckage, crashes, and opportunities."
		"food":
			return "Rations\nUsed for the Hearty Supper. Gain from Fishing and opportunities."
		"day":
			return "Day\nSurvive nights, spend daylight, and keep the lighthouse standing."
	return ""

## Player-facing material names. Internal keys stay gold/wood/scrap/food/
## tools so save data and action definitions don't churn on a rename.
func _display_resource_name(key: String) -> String:
	match key:
		"energy_today", "tomorrow_daylight", "daylight_work":
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
		"mines":
			return "Mine"
		"barricades":
			return "Barricade"
		"hull":
			return "Hull"
		"day":
			return "Day"
	return key.capitalize()

func _repair_hint() -> String:
	var missing := CampaignState.max_hull - CampaignState.hull
	if missing <= 0:
		return "no repairs"
	return "%d Repair Hull action%s" % [ceili(missing / 12.0), "s" if missing > 12 else ""]

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
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, BRASS, 2))
	center.add_child(panel)
	return center
