class_name Mine
extends Node2D
## One-shot proximity explosive. Triggers on the nearest boat, damages all
## boats in blast radius, plays a brief expanding-ring flash, then frees.

@export var trigger_radius: float = 16.0
@export var blast_radius: float = 42.0
@export var damage: float = 60.0

const FLASH_TIME := 0.35

var _armed: bool = true
var _flash_age: float = 0.0

func _ready() -> void:
	add_to_group("mines")

func _physics_process(delta: float) -> void:
	if _armed:
		for node in get_tree().get_nodes_in_group("boats"):
			var boat := node as Boat
			if global_position.distance_to(boat.global_position) <= trigger_radius + boat.hull_radius:
				_explode()
				break
	else:
		_flash_age += delta
		queue_redraw()
		if _flash_age >= FLASH_TIME:
			queue_free()

func _explode() -> void:
	_armed = false
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if global_position.distance_to(boat.global_position) <= blast_radius:
			boat.take_damage(damage)
	queue_redraw()

func _draw() -> void:
	if _armed:
		draw_circle(Vector2.ZERO, 5.0, Color(0.7, 0.2, 0.15, 0.9))
		for i in 4:
			var a := TAU * float(i) / 4.0 + PI / 4.0
			draw_line(Vector2.from_angle(a) * 5.0, Vector2.from_angle(a) * 8.0, Color(0.7, 0.2, 0.15, 0.9), 1.5)
	else:
		var t := _flash_age / FLASH_TIME
		draw_arc(Vector2.ZERO, blast_radius * t, 0.0, TAU, 24, Color(1.0, 0.7, 0.3, 1.0 - t), 3.0)
