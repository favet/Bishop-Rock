class_name LighthouseBeam
extends Node2D
## The rotating light cone. Left/Right arrows rotate manually (hold Down for
## precision speed); Q toggles between AUTO_SWEEP and MANUAL_HOLD. E is kept
## as a secondary clockwise binding. Other systems query is_point_illuminated();
## the beam owns no combat logic.

enum Mode { AUTO_SWEEP, MANUAL_HOLD }

@export var cone_half_angle_deg: float = 11.0
@export var beam_range: float = 335.0
@export var auto_speed_deg: float = 26.0
@export var manual_speed_deg: float = 100.0
@export var precision_speed_deg: float = 30.0
@export var auto_direction: float = 1.0  # 1 = clockwise on screen
@export var turn_speed_multiplier: float = 1.0

var beam_angle: float = -PI / 2.0  # start pointing up
var mode: Mode = Mode.AUTO_SWEEP
var is_overriding: bool = false  # true while Left/Right is actively rotating the beam this frame

func _ready() -> void:
	add_to_group("beam")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_auto_sweep"):
		mode = Mode.MANUAL_HOLD if mode == Mode.AUTO_SWEEP else Mode.AUTO_SWEEP

	var axis := Input.get_axis("beam_rotate_ccw", "beam_rotate_cw")
	is_overriding = not is_zero_approx(axis)
	if is_overriding:
		var speed := precision_speed_deg if Input.is_action_pressed("beam_precision") else manual_speed_deg
		beam_angle += deg_to_rad(speed) * turn_speed_multiplier * axis * delta
	elif mode == Mode.AUTO_SWEEP:
		beam_angle += deg_to_rad(auto_speed_deg) * turn_speed_multiplier * auto_direction * delta
	# MANUAL_HOLD with no input held: beam stays exactly where it is.
	beam_angle = wrapf(beam_angle, 0.0, TAU)
	queue_redraw()

func mode_name() -> String:
	return "AUTO_SWEEP" if mode == Mode.AUTO_SWEEP else "MANUAL_HOLD"

func is_point_illuminated(point: Vector2) -> bool:
	var local := point - global_position
	if local.length() > beam_range:
		return false
	return absf(angle_difference(beam_angle, local.angle())) <= deg_to_rad(cone_half_angle_deg)

func _draw() -> void:
	var half := deg_to_rad(cone_half_angle_deg)
	_draw_wedge(half, beam_range, Color(1.0, 0.95, 0.7, 0.10))
	_draw_wedge(half * 0.45, beam_range, Color(1.0, 0.97, 0.8, 0.10))

func _draw_wedge(half_angle: float, length: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 12
	for i in steps + 1:
		var a := beam_angle - half_angle + (half_angle * 2.0) * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * length)
	draw_colored_polygon(points, color)
