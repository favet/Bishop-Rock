extends Node
## Dev harness: boots Main, drives two Space hold/release sequences (one
## landing a PERFECT shot, one deliberately overshooting into a misfire),
## captures screenshots to user://, then quits. Timing is elapsed-time based
## (not frame-count based) so it's correct regardless of headless FPS. Run
## with:
##   godot --path . res://tests/ScreenshotRunner.tscn
## Screenshots land in %APPDATA%/Godot/app_userdata/Bishop Rock/.

const MAIN := preload("res://scenes/main/Main.tscn")

## MainGun's default charge_up_time is 0.7s and its perfect zone is
## 0.88-0.94; holding for 0.62s lands comfortably inside it (~0.886).
const PRESS_1 := 1.0
const HOLD_1 := 0.62
const RELEASE_1 := PRESS_1 + HOLD_1

## Second hold starts after the 1.5s reload clears, and is held well past
## charge_up_time (0.7s) without releasing, forcing a misfire.
const PRESS_2 := RELEASE_1 + 1.7
const RELEASE_2 := PRESS_2 + 0.9

const CAPTURE_TIMES: Array[float] = [
	PRESS_1 + 0.35,   # 0: mid-charge ring, first hold
	RELEASE_1 + 0.05, # 1: PERFECT result flash
	PRESS_2 + 0.35,   # 2: mid-charge ring, second hold
	PRESS_2 + 0.72,   # 3: just past the misfire threshold — burst + backlash
	8.0,              # 4: general gameplay, boat variety
	10.0, 10.5, 11.0, 11.5,  # 5-8: spread to catch a lighthouse-ram feedback window
]
const QUIT_TIME := 12.0

var _elapsed: float = 0.0
var _pressed_1: bool = false
var _released_1: bool = false
var _pressed_2: bool = false
var _released_2: bool = false
var _captured: Array[bool] = []

func _init() -> void:
	_captured.resize(CAPTURE_TIMES.size())
	_captured.fill(false)

func _ready() -> void:
	# Skip the title screen: a fresh day-1 campaign shows it, and this
	# harness wants the night sim running immediately.
	CampaignState.reset_campaign(42)
	CampaignState.last_night_stats = {"night": 0}
	add_child(MAIN.instantiate())

func _process(delta: float) -> void:
	_elapsed += delta

	if not _pressed_1 and _elapsed >= PRESS_1:
		Input.action_press("fire")
		_pressed_1 = true
	if not _released_1 and _elapsed >= RELEASE_1:
		Input.action_release("fire")
		_released_1 = true
	if not _pressed_2 and _elapsed >= PRESS_2:
		Input.action_press("fire")
		_pressed_2 = true
	if not _released_2 and _elapsed >= RELEASE_2:
		Input.action_release("fire")  # inert by now — the gun already misfired on its own
		_released_2 = true

	for i in CAPTURE_TIMES.size():
		if not _captured[i] and _elapsed >= CAPTURE_TIMES[i]:
			_captured[i] = true
			var image := get_viewport().get_texture().get_image()
			image.save_png("user://night_board_t%d.png" % i)

	if _elapsed >= QUIT_TIME:
		get_tree().quit()
