extends Boat
class_name FogMakerBoat

@export var fog_radius: float = 120.0
@export var fog_color: Color = Color(0.6, 0.7, 0.8, 0.4)

func _ready() -> void:
	super._ready()
	add_to_group("fog_makers")

func _draw() -> void:
	super._draw()
	# Draw the fog zone
	draw_circle(Vector2.ZERO, fog_radius, fog_color)
