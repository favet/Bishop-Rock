class_name Buoy
extends Node2D
## Marker that reveals nearby boats (VisibilitySystem promotes boats within
## reveal_radius to at least SPOTTED). Blinks so the player can find it at night.

@export var reveal_radius: float = 70.0

var _age: float = 0.0

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()

func _ready() -> void:
	add_to_group("buoys")

func _draw() -> void:
	var blink := 0.55 + 0.45 * sin(_age * 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0),
	]), Color(0.95, 0.6, 0.15, blink))
	draw_arc(Vector2.ZERO, reveal_radius, 0.0, TAU, 32, Color(0.95, 0.6, 0.15, 0.10), 1.0)
