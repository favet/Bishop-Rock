class_name BoatSpawner
extends Node
## Spawns boats at random angles on the horizon ring, ramping the interval
## down over the night, until wave_size boats have been spawned. Picks among
## the basic boat and two variants (fast_boat_scene/heavy_boat_scene) by
## weighted roll — see Boat.tscn/FastBoat.tscn/HeavyBoat.tscn. Exposes
## spawned/remaining counts so the HUD can show enemies-left/at-sea/incoming
## without duplicating spawn bookkeeping. Also obeys MainGun.world_time_scale()
## so the pace of incoming boats slows along with everything else while the
## player is charging a shot.
## TODO(waves): dusk forecast should later bias spawn sectors so "likely
## attack sectors" information is honest.
## TODO(win-condition): once the wave is fully spawned and cleared, that's a
## natural dawn/win trigger — not implemented yet, see Docs/BACKLOG.md.

signal boat_spawned(boat: Boat)

@export var boat_scene: PackedScene
@export var fast_boat_scene: PackedScene
@export var heavy_boat_scene: PackedScene
@export var fog_boat_scene: PackedScene = preload("res://scenes/boats/FogMakerBoat.tscn")
@export var fog_boat_weight: float = 0.05
@export var fast_boat_weight: float = 0.3
@export var heavy_boat_weight: float = 0.2
@export var boats_container: NodePath
@export var start_interval: float = 4.0
@export var min_interval: float = 1.5
@export var ramp_duration: float = 120.0
@export var first_spawn_delay: float = 1.5
@export var wave_size: int = 24  ## total boats for the night; spawning stops once reached
@export var max_simultaneous: int = 99
@export var speed_scale: float = 1.0

var active: bool = true
var spawned_count: int = 0

var _elapsed: float = 0.0
var _timer: float = 0.0
var _gun: MainGun

func _ready() -> void:
	_timer = first_spawn_delay

func _physics_process(delta: float) -> void:
	if not active or wave_complete():
		return
	if get_tree().get_nodes_in_group("boats").size() >= max_simultaneous:
		return
	if _gun == null:
		_gun = get_tree().get_first_node_in_group("main_gun") as MainGun
	var scaled_delta := delta * (_gun.world_time_scale() if _gun != null else 1.0)

	_elapsed += scaled_delta
	_timer -= scaled_delta
	if _timer <= 0.0:
		_timer = current_interval()
		_spawn()

func current_interval() -> float:
	var t := clampf(_elapsed / ramp_duration, 0.0, 1.0)
	return lerpf(start_interval, min_interval, t)

func remaining_to_spawn() -> int:
	return maxi(wave_size - spawned_count, 0)

func wave_complete() -> bool:
	return spawned_count >= wave_size

func _pick_scene() -> PackedScene:
	var roll := randf()
	if roll < fog_boat_weight and fog_boat_scene != null:
		return fog_boat_scene
	if roll < fog_boat_weight + heavy_boat_weight and heavy_boat_scene != null:
		return heavy_boat_scene
	if roll < fog_boat_weight + heavy_boat_weight + fast_boat_weight and fast_boat_scene != null:
		return fast_boat_scene
	return boat_scene

func _spawn() -> void:
	var boat := _pick_scene().instantiate() as Boat
	var angle := randf() * TAU
	boat.position = OceanGrid.polar(angle, OceanGrid.ring_radius(OceanGrid.Ring.HORIZON))
	# Slight speed variation so waves don't arrive as a single line.
	boat.speed *= randf_range(0.85, 1.15) * speed_scale
	get_node(boats_container).add_child(boat)
	spawned_count += 1
	boat_spawned.emit(boat)
