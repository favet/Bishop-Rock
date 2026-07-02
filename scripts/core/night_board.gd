class_name NightBoard
extends Node2D
## Simulation root for the night defense. Pure orchestration: wires spawner,
## boats, and lighthouse together and tracks run stats. All behavior lives in
## the child systems, so this file must stay small.
## TODO(day-loop): the day phase will wrap this board in a larger state
## machine (morning/day/dusk/night/dawn) — see Docs/DAY_LOOP_SPEC.md.

signal board_over

var kills: int = 0
var rammed: int = 0  ## boats that reached the lighthouse (not sunk by damage)
var elapsed: float = 0.0
var game_over: bool = false

@onready var lighthouse: Lighthouse = $Lighthouse
@onready var spawner: BoatSpawner = $BoatSpawner

func _ready() -> void:
	add_to_group("night_board")
	spawner.boat_spawned.connect(_on_boat_spawned)
	lighthouse.destroyed.connect(_on_lighthouse_destroyed)

func _physics_process(delta: float) -> void:
	if not game_over:
		elapsed += delta

## Boats no longer in play, one way or another — sunk or rammed home. With
## spawner.remaining_to_spawn(), (wave_size - resolved_count()) always equals
## the boats currently in the "boats" group, i.e. resolved + at-sea + incoming
## accounts for the whole wave.
func resolved_count() -> int:
	return kills + rammed

func _on_boat_spawned(boat: Boat) -> void:
	boat.died.connect(func(_boat: Boat) -> void: kills += 1)
	boat.reached_lighthouse.connect(func(rammer: Boat) -> void:
		rammed += 1
		lighthouse.take_damage(rammer.ram_damage))

func _on_lighthouse_destroyed() -> void:
	game_over = true
	spawner.active = false
	board_over.emit()
