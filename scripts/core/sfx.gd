extends Node
## Sfx autoload: fire-and-forget sound playback plus the looping shore
## ambience. All streams are synthesized originals from tools/gen_audio.py.
## Buses: Master <- SFX (one-shots), Ambient (wave loop, ducked on hull hits).

const STREAMS := {
	"foghorn": preload("res://assets/audio/foghorn.wav"),
	"rifle_crack": preload("res://assets/audio/rifle_crack.wav"),
	"perfect_ding": preload("res://assets/audio/perfect_ding.wav"),
	"hull_crunch": preload("res://assets/audio/hull_crunch.wav"),
	"mine_thump": preload("res://assets/audio/mine_thump.wav"),
	"ui_click": preload("res://assets/audio/ui_click.wav"),
}

var _ambient: AudioStreamPlayer

func _ready() -> void:
	for bus_name in ["SFX", "Ambient"]:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
	_ambient = AudioStreamPlayer.new()
	var loop := preload("res://assets/audio/wave_loop.wav") as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = loop.data.size() / 2  # 16-bit mono: samples = bytes/2
	_ambient.stream = loop
	_ambient.bus = "Ambient"
	_ambient.volume_db = -14.0
	add_child(_ambient)
	_ambient.play()

## One-shot on the SFX bus; the player frees itself when done.
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = STREAMS[sound]
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

## Dip the shore ambience briefly so a hull hit reads through the mix.
func duck_ambient() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), -10.0)
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_method(func(v: float) -> void:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), v),
		-10.0, 0.0, 0.5)
