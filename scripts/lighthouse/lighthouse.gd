class_name Lighthouse
extends Node2D
## The vulnerable core: island + tower rendering and structure health.
## Weapons and the beam are child nodes; this class owns only hit points.
## Emits `damaged` (in addition to `health_changed`) so other systems — HUD
## damage-pulse/text, main.gd screen shake — can react to a hit without
## polling; this class itself only handles the local flash visual.
## TODO(nodes): later split health across island nodes (lantern, engine, etc.)
## per Docs/DAY_LOOP_SPEC.md.

signal health_changed(current: float, max_value: float)
signal damaged(amount: float)
signal destroyed

@export var max_health: float = 100.0

const FLASH_TIME := 0.25

var health: float

var _flash_age: float = -1.0  # negative = not flashing

func _ready() -> void:
	add_to_group("lighthouse")
	health = max_health

func _process(delta: float) -> void:
	if _flash_age >= 0.0:
		_flash_age += delta
		if _flash_age > FLASH_TIME:
			_flash_age = -1.0
		queue_redraw()

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	damaged.emit(amount)
	_flash_age = 0.0
	queue_redraw()
	if health <= 0.0:
		destroyed.emit()

func _draw() -> void:
	# Island rock.
	var points := PackedVector2Array()
	var corners := 9
	for i in corners:
		var a := TAU * float(i) / float(corners)
		var wobble := 0.8 + 0.2 * sin(float(i) * 7.3)
		points.append(Vector2.from_angle(a) * OceanGrid.ISLAND_RADIUS * wobble)
	draw_colored_polygon(points, Color(0.3, 0.29, 0.27, 1.0))
	# Tower + lamp, tinted toward red as health drops.
	var hurt := 1.0 - clampf(health / max_health, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 10.0, Color(0.9, 0.88 - 0.5 * hurt, 0.8 - 0.6 * hurt, 1.0))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.95, 0.7, 1.0))
	# Brief red flash ring on hit, unmistakable even mid-combat.
	if _flash_age >= 0.0:
		var t := 1.0 - _flash_age / FLASH_TIME
		draw_circle(Vector2.ZERO, 12.0 + 10.0 * t, Color(1.0, 0.25, 0.15, 0.55 * t))
