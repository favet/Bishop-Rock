class_name Boat
extends Node2D
## A simple attacker: steers toward the lighthouse (world origin), avoids rocks,
## is slowed by nets, and rams the island for damage. Visibility state is set
## externally by VisibilitySystem; this script only renders per-state.
## Also slows down (proportional to damage taken, recovering over time) and
## obeys MainGun.world_time_scale() — the whole world grinds down while the
## player charges a shot, boats included.
## Variants (FastBoat/HeavyBoat) reuse this scene with different exports plus
## hull_tint/hull_scale for a quick visual tell — see Docs/NIGHT_BOARD_V0.md.

signal died(boat: Boat)
signal reached_lighthouse(boat: Boat)

enum VisState { CONTACT, SPOTTED, ILLUMINATED }

@export var max_health: float = 4.0  ## tuned so a PERFECT (4x) main-gun shot one-shots the basic boat
@export var speed: float = 30.0
@export var turn_rate: float = 2.5  # rad/s
@export var ram_damage: float = 15.0
@export var hull_radius: float = 8.0
@export var avoid_lookahead: float = 48.0
@export var hull_tint: Color = Color(1.0, 1.0, 1.0, 1.0)  ## multiplied into hull colors; distinguishes variants
@export var hull_scale: float = 1.0  ## visual only, doesn't affect hull_radius/collision

@export_group("Hit Reaction")
@export var hit_slow_strength: float = 1.0  ## 1.0 = losing X% of max HP in one hit slows speed by X%
@export var hit_slow_floor: float = 0.2  ## minimum speed multiplier even from a devastating hit
@export var hit_slow_recovery_time: float = 1.5  ## seconds to ease back to full speed

var health: float
var heading: float = 0.0
var vis_state: VisState = VisState.CONTACT
var perfect_reward_claimed: bool = false
var killed_by_perfect: bool = false

# Exposed for DebugOverlay steering vectors.
var debug_desired := Vector2.ZERO
var debug_avoid := Vector2.ZERO

var _hard_blocked: bool = false
var _attack_target: Rock = null
var _attack_timer: float = 0.0

var _hit_slow_factor: float = 1.0
var _gun: MainGun

static var HULL := PackedVector2Array([Vector2(12, 0), Vector2(-8, 6), Vector2(-8, -6)])
const RAM_DISTANCE := 42.0  # island edge + hull

const HEALTH_PIP_SIZE := Vector2(4.0, 4.0)
const HEALTH_PIP_GAP := 2.0
const HEALTH_PIP_OFFSET_Y := -16.0  # world-space, above the hull
const MAX_HEALTH_PIPS := 8

func _ready() -> void:
	add_to_group("boats")
	health = max_health
	heading = (-global_position).angle()
	rotation = heading

func _physics_process(delta: float) -> void:
	if _gun == null:
		_gun = get_tree().get_first_node_in_group("main_gun") as MainGun
	var world_scale := _gun.world_time_scale() if _gun != null else 1.0
	if vis_state == VisState.CONTACT:
		world_scale *= 0.7
	var scaled_delta := delta * world_scale

	if _hit_slow_factor < 1.0:
		_hit_slow_factor = move_toward(_hit_slow_factor, 1.0, delta / hit_slow_recovery_time)

	# If attacking a rock because we are hard blocked
	if _hard_blocked and is_instance_valid(_attack_target):
		_attack_timer -= scaled_delta
		var to_rock = _attack_target.global_position - global_position
		heading = rotate_toward(heading, to_rock.angle(), turn_rate * scaled_delta)
		rotation = heading
		if _attack_timer <= 0.0:
			# "Attack" the rock by instantly destroying it but taking self damage
			_attack_target.queue_free()
			_attack_target = null
			_hard_blocked = false
			take_damage(max_health * 0.5) # Take 50% damage when destroying a rock
		return

	var desired := (-global_position).normalized()
	var avoid := _rock_avoidance()
	debug_desired = desired
	debug_avoid = avoid
	var steer := desired + avoid

	# Detect if we are stuck (repulsion perfectly equals desired)
	if steer.length_squared() < 0.01 and avoid.length_squared() > 0.1:
		_hard_blocked = true
		_attack_target = _find_closest_rock()
		_attack_timer = 3.0 # Takes 3 seconds of grinding against it to break it
		return

	if steer.length_squared() > 0.0001:
		heading = rotate_toward(heading, steer.angle(), turn_rate * scaled_delta)
	rotation = heading
	global_position += Vector2.from_angle(heading) * speed * _net_slow_factor() * _hit_slow_factor * scaled_delta
	_resolve_rock_overlap()

	if global_position.length() <= RAM_DISTANCE:
		reached_lighthouse.emit(self)
		queue_free()

func _process(_delta: float) -> void:
	queue_redraw()

func take_damage(amount: float, quality: int = -1) -> bool:
	health -= amount
	if health <= 0.0:
		killed_by_perfect = quality == MainGun.ShotQuality.PERFECT
		died.emit(self)
		queue_free()
		return true
	var relative := clampf(amount / max_health, 0.0, 1.0)
	var target := clampf(1.0 - relative * hit_slow_strength, hit_slow_floor, 1.0)
	_hit_slow_factor = minf(_hit_slow_factor, target)
	return false

## Radial repulsion from rocks within lookahead range.
func _find_closest_rock() -> Rock:
	var closest: Rock = null
	var closest_dist := 99999.0
	for node in get_tree().get_nodes_in_group("rocks"):
		var rock := node as Rock
		var dist := global_position.distance_to(rock.global_position)
		if dist < closest_dist:
			closest = rock
			closest_dist = dist
	return closest

func _rock_avoidance() -> Vector2:
	var avoid := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("rocks"):
		var rock := node as Rock
		var to_rock := rock.global_position - global_position
		var reach := avoid_lookahead + rock.radius
		var dist := to_rock.length()
		if dist < reach and dist > 0.001:
			avoid -= to_rock.normalized() * (1.0 - dist / reach) * 1.8
	return avoid

## Hard separation so boats never sit inside a rock.
func _resolve_rock_overlap() -> void:
	for node in get_tree().get_nodes_in_group("rocks"):
		var rock := node as Rock
		var offset := global_position - rock.global_position
		var min_dist := rock.radius + hull_radius
		var dist := offset.length()
		if dist < min_dist and dist > 0.001:
			global_position = rock.global_position + offset / dist * min_dist

func _net_slow_factor() -> float:
	var factor := 1.0
	for node in get_tree().get_nodes_in_group("nets"):
		var net := node as NetChain
		if global_position.distance_to(net.global_position) <= net.slow_radius:
			factor = minf(factor, net.slow_multiplier)
	return factor

func _draw() -> void:
	match vis_state:
		VisState.CONTACT:
			pass  # truly invisible on the main map until illuminated or spotted
		VisState.SPOTTED:
			var outline := _scaled_hull()
			outline.append(outline[0])
			draw_polyline(outline, Color(0.75, 0.8, 0.85, 0.5) * hull_tint, 1.5)
			_draw_health_pips()
		VisState.ILLUMINATED:
			draw_colored_polygon(_scaled_hull(), Color(1.0, 0.95, 0.8, 0.95) * hull_tint)
			_draw_health_pips()

func _scaled_hull() -> PackedVector2Array:
	if is_equal_approx(hull_scale, 1.0):
		return HULL.duplicate()
	var scaled := PackedVector2Array()
	for p in HULL:
		scaled.append(p * hull_scale)
	return scaled

## HP pips anchored above the hull. Readable at a glance and doesn't rely on
## color alone (filled vs. empty squares, counted at a glance) — see
## Docs/NIGHT_BOARD_V0.md. Positions are computed in world space and passed
## through to_local() per corner so the row stays screen-upright regardless
## of hull heading, instead of drawing (and rotating) in the local frame.
func _draw_health_pips() -> void:
	var pip_count := clampi(int(round(max_health)), 1, MAX_HEALTH_PIPS)
	var hp_per_pip := max_health / float(pip_count)
	var filled := clampi(int(ceil(health / hp_per_pip)), 0, pip_count)
	var total_width := pip_count * HEALTH_PIP_SIZE.x + (pip_count - 1) * HEALTH_PIP_GAP
	var start_x := -total_width * 0.5
	for i in pip_count:
		var top_left := global_position + Vector2(start_x + i * (HEALTH_PIP_SIZE.x + HEALTH_PIP_GAP), HEALTH_PIP_OFFSET_Y)
		var bottom_right := top_left + HEALTH_PIP_SIZE
		var a := to_local(top_left)
		var b := to_local(Vector2(bottom_right.x, top_left.y))
		var c := to_local(bottom_right)
		var d := to_local(Vector2(top_left.x, bottom_right.y))
		var corners := PackedVector2Array([a, b, c, d])
		var filled_pip := i < filled
		draw_colored_polygon(corners, Color(0.4, 1.0, 0.5, 0.95) if filled_pip else Color(0.15, 0.18, 0.16, 0.85))
		draw_polyline(PackedVector2Array([a, b, c, d, a]), Color(0.05, 0.06, 0.05, 0.9), 1.0)
