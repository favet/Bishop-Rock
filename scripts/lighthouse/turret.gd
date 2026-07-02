class_name ShoreTurret
extends Node2D
## Short-range automatic shore defense. Fires at the nearest boat that is at
## least SPOTTED within range; hits harder against ILLUMINATED boats
## ("turrets gain accuracy/damage against illuminated targets" — handoff).
## Deliberately weak: base_damage * illuminated_multiplier must stay below a
## basic boat's max_health (4.0) so the turret can never one-shot on its
## own — that's reserved for a PERFECT (4x) main-gun shot. The turret chips
## damage and finishes off already-weakened boats; it's a leak-plugger, not
## the primary killer. Also obeys MainGun.world_time_scale() (fires slower
## while the player is charging, same as boats slow down).

@export var fire_range: float = 100.0
@export var fire_interval: float = 0.85
@export var base_damage: float = 1.0
@export var illuminated_multiplier: float = 1.5
@export var enabled: bool = true

var _fire_timer: float = 0.0
var _tracers: Array[Dictionary] = []  # {to: Vector2, age: float}
var _gun: MainGun

const TRACER_TIME := 0.18

func _ready() -> void:
	add_to_group("turrets")

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if _gun == null:
		_gun = get_tree().get_first_node_in_group("main_gun") as MainGun
	var scaled_delta := delta * (_gun.world_time_scale() if _gun != null else 1.0)

	_fire_timer -= scaled_delta
	if _fire_timer <= 0.0:
		var target := _pick_target()
		if target != null:
			_fire_timer = fire_interval
			var dmg := base_damage
			if target.vis_state == Boat.VisState.ILLUMINATED:
				dmg *= illuminated_multiplier
			_tracers.append({to = to_local(target.global_position), age = 0.0})
			target.take_damage(dmg)

	for tracer in _tracers:
		tracer.age += scaled_delta
	_tracers = _tracers.filter(func(t: Dictionary) -> bool: return t.age < TRACER_TIME)
	queue_redraw()

func _pick_target() -> Boat:
	var best: Boat = null
	var best_dist := fire_range
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.vis_state == Boat.VisState.CONTACT:
			continue  # turret needs visibility
		var dist := global_position.distance_to(boat.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = boat
	return best

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.5, 0.75, 0.85, 1.0))
	for tracer in _tracers:
		var fade: float = 1.0 - tracer.age / TRACER_TIME
		draw_line(Vector2.ZERO, tracer.to, Color(0.6, 0.9, 1.0, 0.7 * fade), 1.0)
