extends CanvasLayer
## Schematic HUD: lighthouse health (with damage-chunk animation), live
## enemy-wave counters, beam/gun status text, lighthouse-hit feedback (screen
## pulse + text), and the game-over overlay. Builds its controls in code and
## polls the sim each frame — deliberately dumb so simulation stays UI-free.
## Reload and charge meters are NOT here — they're drawn as rings around the
## lighthouse by MainGun itself (world-space, central, hard to miss). This
## HUD only carries corner status text and full-screen hit feedback.

var _board: NightBoard
var _lighthouse: Lighthouse
var _beam: LighthouseBeam
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
		_beam = get_tree().get_first_node_in_group("beam") as LighthouseBeam
		_gun = get_tree().get_first_node_in_group("main_gun") as MainGun
		if _board == null:
			return
	if not _lighthouse_signal_connected and _lighthouse != null:
		_lighthouse.damaged.connect(_on_lighthouse_damaged)
		_lighthouse_signal_connected = true

	_update_health(delta)
	_update_enemy_status()
	_update_damage_feedback(delta)

	if _board.game_over and not _game_over.visible:
		_game_over_label.text = "LIGHTHOUSE LOST\n\nSurvived %ds — %d boats sunk\n\nPress R to restart" % [
			int(_board.elapsed), _board.kills]
		_game_over.visible = true

func _update_health(delta: float) -> void:
	var frac := clampf(_lighthouse.health / _lighthouse.max_health, 0.0, 1.0)
	_health_fill.size.x = HEALTH_BAR_WIDTH * frac
	_health_fill.color = Color(0.9, 0.25, 0.2) if frac < 0.35 else Color(0.4, 0.85, 0.5)

	# Lag bar: holds the pre-hit width and eases down to the new (lower)
	# width so a chunk of "lost" health is visibly visible for a moment
	# rather than the bar just snapping — see NIGHT_BOARD_V0.md.
	_health_lag_t = minf(_health_lag_t + delta / HEALTH_LAG_TIME, 1.0)
	var lag_width := lerpf(_health_lag_from, _health_fill.size.x, _health_lag_t)
	lag_width = maxf(lag_width, _health_fill.size.x)
	_health_lag_fill.size.x = lag_width

	_status.text = "Hull %d/%d   Night %ds\nBeam %s%s   Mode %d%s" % [
		int(_lighthouse.health), int(_lighthouse.max_health), int(_board.elapsed),
		_beam.mode_name(), " (override)" if _beam.is_overriding else "",
		_gun.current_mode, "   [TARGET LOCK]" if _gun.has_target() else "",
	]

func _update_enemy_status() -> void:
	var spawner := _board.spawner
	var at_sea := get_tree().get_nodes_in_group("boats").size()
	var incoming := spawner.remaining_to_spawn()
	var remaining_total := maxi(spawner.wave_size - _board.resolved_count(), 0)
	if incoming > 0:
		_enemy_status.text = "Enemies: %d left  (%d at sea, %d incoming)   Sunk %d" % [
			remaining_total, at_sea, incoming, _board.kills]
	else:
		_enemy_status.text = "Enemies: %d left  (%d at sea) — All remaining ships are on the sea.   Sunk %d" % [
			remaining_total, at_sea, _board.kills]

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
	hint.text = "←/→ beam (hold ↓ precision) · Q auto-sweep on/off · Hold Space to charge, release to fire · Tab target · 1-3 mode · P pause · F3 debug · R restart"
	hint.modulate = Color(1, 1, 1, 0.45)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	hint.offset_top = -30
	add_child(hint)

	_build_damage_feedback()

	var radar_scene = load("res://ui/Radar.tscn")
	if radar_scene:
		var radar = radar_scene.instantiate()
		add_child(radar)

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

## Health bar with a trailing "lag" layer behind the live fill: on a hit the
## live fill snaps down immediately (current health stays unmistakable) while
## the lag layer holds the old width and eases down over HEALTH_LAG_TIME,
## visibly showing the chunk that was just lost.
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

## Full-screen red pulse + "LIGHTHOUSE HIT" text, both triggered by
## Lighthouse.damaged (this fires for both ram damage and MainGun misfire
## backlash — same feedback either way). Screen shake lives in main.gd (it
## drives the Camera2D, which this CanvasLayer doesn't touch).
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
	_hit_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	_hit_label.offset_top = 90
	_hit_label.visible = false
	add_child(_hit_label)
