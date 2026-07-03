extends Control
## Fishing minigame: the needle sweeps, release the strike in the band.
## Three casts; quality = strikes landed (0 poor / 1 normal / 2 good /
## 3 perfect). The day-side mirror of the night's charge shot — the same
## timing muscle, without the threat. Spot picks the difficulty before the
## first cast: shallows steady, reef tighter, deep water fast and narrow.

signal finished(quality: String)

const QUALITIES: Array[String] = ["poor", "normal", "good", "perfect"]
const BAR := Rect2(390, 380, 500, 26)

var spot: String
var band_center := 0.65
var band_width := 0.16
var needle_speed := 0.75
var casts_left := 3
var hits := 0
var _needle := 0.0
var _direction := 1.0
var _flash := -1.0
var _last_hit := false

func _init(fishing_spot: String, calm: bool = false) -> void:
	spot = fishing_spot
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # modal: eat clicks under it
	match spot:
		"shallows":
			needle_speed = 0.7
			band_width = 0.20
		"reef":
			needle_speed = 1.0
			band_width = 0.15
		"deep":
			needle_speed = 1.4
			band_width = 0.11
	if calm:
		band_width *= 1.5  # calm tide: the sea cooperates
	band_center = randf_range(0.35, 0.8)

func _process(delta: float) -> void:
	if _flash >= 0.0:
		_flash += delta
		if _flash > 0.55:
			_flash = -1.0
			if casts_left <= 0:
				finished.emit(QUALITIES[hits])
				queue_free()
				return
			band_center = randf_range(0.3, 0.85)
			_needle = 0.0
			_direction = 1.0
	else:
		_needle += needle_speed * delta * _direction
		if _needle >= 1.0:
			_needle = 1.0
			_direction = -1.0
		elif _needle <= 0.0:
			_needle = 0.0
			_direction = 1.0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _flash < 0.0 and event.is_action_pressed("fire"):
		casts_left -= 1
		_last_hit = absf(_needle - band_center) <= band_width * 0.5
		if _last_hit:
			hits += 1
			Sfx.play("perfect_ding", -8.0, 1.5)
		else:
			Sfx.play("ui_click", -4.0, 0.7)
		_flash = 0.0
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	var panel := Rect2(BAR.position - Vector2(40, 120), Vector2(BAR.size.x + 80, 240))
	draw_rect(panel, Color(0.07, 0.085, 0.095))
	draw_rect(panel, Color(0.78, 0.58, 0.25), false, 2.0)
	draw_string(font, panel.position + Vector2(20, 34), "FISHING - %s" % spot.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.78, 0.58, 0.25))
	draw_string(font, panel.position + Vector2(20, 62),
		"Press SPACE when the needle crosses the band. Casts left: %d   Strikes: %d" % [casts_left, hits],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.93, 0.88, 0.78))
	# Meter: dark bar, brass band, white needle.
	draw_rect(BAR, Color(0.14, 0.15, 0.16))
	var band_x := BAR.position.x + (band_center - band_width * 0.5) * BAR.size.x
	draw_rect(Rect2(band_x, BAR.position.y, band_width * BAR.size.x, BAR.size.y),
		Color(0.38, 0.86, 0.45, 0.55))
	var needle_x := BAR.position.x + _needle * BAR.size.x
	draw_line(Vector2(needle_x, BAR.position.y - 6), Vector2(needle_x, BAR.end.y + 6),
		Color.WHITE, 2.0)
	if _flash >= 0.0:
		draw_string(font, panel.position + Vector2(20, 200),
			"STRIKE!" if _last_hit else "The line slips...",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(0.38, 0.86, 0.45) if _last_hit else Color(0.95, 0.34, 0.25))
