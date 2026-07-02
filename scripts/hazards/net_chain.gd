class_name NetChain
extends Node2D
## Area that slows boats passing through it (Boat checks the "nets" group).
## TODO(durability): nets should wear out or be cut by repeated crossings.

@export var slow_radius: float = 34.0
@export var slow_multiplier: float = 0.45

func _ready() -> void:
	add_to_group("nets")

func _draw() -> void:
	var color := Color(0.6, 0.62, 0.55, 0.35)
	draw_arc(Vector2.ZERO, slow_radius, 0.0, TAU, 24, color, 1.5)
	# Cross-hatch to read as netting.
	var step := slow_radius * 0.5
	for i in range(-1, 2):
		var offset := step * float(i)
		var half := sqrt(maxf(slow_radius * slow_radius - offset * offset, 0.0))
		draw_line(Vector2(-half, offset), Vector2(half, offset), color, 1.0)
		draw_line(Vector2(offset, -half), Vector2(offset, half), color, 1.0)
