class_name Rock
extends Node2D
## Passive obstacle. Boats steer around it (see Boat._rock_avoidance).
## TODO(tide): high tide should make some rocks passable-but-damaging.
## TODO(rules): day-phase placement validation (navigable approach, depth
## limits, cost) lives outside this class — see Docs/OCEAN_MODEL_SPEC.md.
## TODO(enemies): hard-blocked boats attacking rocks is post-v0.

@export var radius: float = 18.0

func _ready() -> void:
	add_to_group("rocks")

func _draw() -> void:
	var points := PackedVector2Array()
	var corners := 7
	for i in corners:
		var a := TAU * float(i) / float(corners)
		var wobble := 0.75 + 0.25 * sin(float(i) * 12.9898 + position.x)
		points.append(Vector2.from_angle(a) * radius * wobble)
	draw_colored_polygon(points, Color(0.38, 0.4, 0.44, 1.0))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.55, 0.58, 0.62, 0.8), 1.5)
