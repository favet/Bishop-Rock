extends Node2D
## App shell: night clear color, global time-scale controls (pause/slow,
## game-over freeze), restart, and camera screen-shake on lighthouse hits.
## Simulation logic lives under NightBoard.

const NIGHT_WATER := Color(0.04, 0.06, 0.10)
const SLOW_SCALE := 0.3
const SHAKE_PER_DAMAGE := 0.6  ## px of shake strength added per point of damage taken
const SHAKE_MAX := 10.0  ## px, clamps a single hit's contribution
const SHAKE_DECAY := 6.0  ## px/sec the shake settles by

var _slowed: bool = false
var _frozen: bool = false
var _shake_strength: float = 0.0

@onready var _board: NightBoard = $NightBoard
@onready var _camera: Camera2D = $Camera2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(NIGHT_WATER)
	Engine.time_scale = 1.0
	_board.board_over.connect(_on_board_over)
	_board.lighthouse.damaged.connect(_on_lighthouse_damaged)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("pause_slow") and not _frozen:
		_slowed = not _slowed
		Engine.time_scale = SLOW_SCALE if _slowed else 1.0

	if _shake_strength > 0.0:
		_shake_strength = maxf(_shake_strength - SHAKE_DECAY * delta, 0.0)
		_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

func _on_lighthouse_damaged(amount: float) -> void:
	_shake_strength = minf(_shake_strength + amount * SHAKE_PER_DAMAGE, SHAKE_MAX)

func _on_board_over() -> void:
	_frozen = true
	Engine.time_scale = 0.0
