extends CanvasLayer
## Normal-play HUD: hull, contact count, rifle readiness, and hit feedback.
## Debug detail stays in the F3 overlay.

var _board: NightBoard
var _lighthouse: Lighthouse
var _gun: MainGun
var _lighthouse_signal_connected: bool = false

var _health_bar_bg: ColorRect
var _health_lag_fill: ColorRect
var _health_fill: ColorRect
var _status: Label
var _enemy_status: Label
var _game_over: Control
var _game_over_label: Label

var _damage_overlay: ColorRect
var _hit_label: Label
var _damage_pulse_age: float = -1.0
var _hit_text_age: float = -1.0

var _health_lag_from: float = 0.0
var _health_lag_t: float = 1.0

const HEALTH_BAR_WIDTH := 180.0
const HEALTH_BAR_HEIGHT := 10.0
const HEALTH_LAG_TIME := 0.4
const DAMAGE_PULSE_TIME := 0.5
const DAMAGE_PULSE_PEAK_ALPHA := 0.28
const HIT_TEXT_TIME := 1.0

func _ready() -> void:
	_build_ui()

func _process(delta: float) -> void:
	if _board == null:
		_board = get_tree().get_first_node_in_group("night_board") as NightBoard
		_lighthouse = get_tree().get_first_node_in_group("lighthouse") as Lighthouse
		_gun = get_tree().get_first_node_in_group("main_gun") as MainGun
		if _board == null or _lighthouse == null or _gun == null:
			return
	if not _lighthouse_signal_connected:
		_lighthouse.damaged.connect(_on_lighthouse_damaged)
		_lighthouse_signal_connected = true

	_update_health(delta)
	_update_enemy_status()
	_update_damage_feedback(delta)

	if _board.game_over and not _game_over.visible:
		_game_over_label.text = "LIGHTHOUSE LOST\n\nSurvived %ds - %d boats sunk\n\nPress R to restart" % [
			int(_board.elapsed), _board.kills]
		_game_over.visible = true

func _update_health(delta: float) -> void:
	var frac := clampf(_lighthouse.health / _lighthouse.max_health, 0.0, 1.0)
	_health_fill.size.x = HEALTH_BAR_WIDTH * frac
	_health_fill.color = Color(0.9, 0.25, 0.2) if frac < 0.35 else Color(0.4, 0.85, 0.5)

	_health_lag_t = minf(_health_lag_t + delta / HEALTH_LAG_TIME, 1.0)
	var lag_width := lerpf(_health_lag_from, _health_fill.size.x, _health_lag_t)
	lag_width = maxf(lag_width, _health_fill.size.x)
	_health_lag_fill.size.x = lag_width

	var rifle := "READY" if _gun.cooldown_fraction() >= 1.0 else "RELOADING %d%%" % int(_gun.cooldown_fraction() * 100.0)
	_status.text = "Hull %d/%d   Night %d   Rifle %s%s" % [
		int(_lighthouse.health), int(_lighthouse.max_health), CampaignState.day,
		rifle, "   TARGET" if _gun.has_target() else "",
	]

func _update_enemy_status() -> void:
	var spawner := _board.spawner
	var at_sea := get_tree().get_nodes_in_group("boats").size()
	var incoming := spawner.remaining_to_spawn()
	var remaining_total := maxi(spawner.wave_size - _board.resolved_count(), 0)
	if incoming > 0:
		_enemy_status.text = "Contacts: %d remaining   Sunk %d" % [remaining_total, _board.kills]
	else:
		_enemy_status.text = "Contacts: %d on the water   Sunk %d" % [at_sea, _board.kills]

func _update_damage_feedback(delta: float) -> void:
	if _damage_pulse_age >= 0.0:
		_damage_pulse_age += delta
		var t := _damage_pulse_age / DAMAGE_PULSE_TIME
		if t >= 1.0:
			_damage_pulse_age = -1.0
			_damage_overlay.color.a = 0.0
		else:
			_damage_overlay.color.a = lerpf(DAMAGE_PULSE_PEAK_ALPHA, 0.0, t)

	if _hit_text_age >= 0.0:
		_hit_text_age += delta
		var t := _hit_text_age / HIT_TEXT_TIME
		if t >= 1.0:
			_hit_text_age = -1.0
			_hit_label.visible = false
		else:
			_hit_label.visible = true
			_hit_label.modulate.a = 1.0 - t

func _on_lighthouse_damaged(_amount: float) -> void:
	_damage_pulse_age = 0.0
	_hit_text_age = 0.0
	_health_lag_from = _health_lag_fill.size.x
	_health_lag_t = 0.0

func _build_ui() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(12, 10)
	add_child(panel)
	_build_health_bar(panel)
	_status = Label.new()
	panel.add_child(_status)
	_enemy_status = Label.new()
	panel.add_child(_enemy_status)

	var hint := Label.new()
	hint.text = "Hold Space to charge   Release to fire   Arrow keys aim   F3 debug"
	hint.modulate = Color(1, 1, 1, 0.38)
	hint.position = Vector2(12, 694)
	add_child(hint)

	_build_damage_feedback()
	_game_over = Control.new()
	_game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.visible = false
	add_child(_game_over)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.add_child(center)
	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_game_over_label)

func _build_health_bar(panel: VBoxContainer) -> void:
	_health_bar_bg = ColorRect.new()
	_health_bar_bg.custom_minimum_size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	_health_bar_bg.color = Color(0.15, 0.17, 0.22)
	panel.add_child(_health_bar_bg)

	_health_lag_fill = ColorRect.new()
	_health_lag_fill.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	_health_lag_fill.color = Color(0.85, 0.3, 0.2, 0.9)
	_health_bar_bg.add_child(_health_lag_fill)

	_health_fill = ColorRect.new()
	_health_fill.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	_health_fill.color = Color(0.4, 0.85, 0.5)
	_health_bar_bg.add_child(_health_fill)

func _build_damage_feedback() -> void:
	_damage_overlay = ColorRect.new()
	_damage_overlay.color = Color(0.9, 0.15, 0.1, 0.0)
	_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_damage_overlay)

	_hit_label = Label.new()
	_hit_label.text = "LIGHTHOUSE HIT"
	_hit_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	_hit_label.add_theme_font_size_override("font_size", 22)
	_hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hit_label.custom_minimum_size = Vector2(240, 30)
	_hit_label.position = Vector2(520, 90)
	_hit_label.visible = false
	add_child(_hit_label)
