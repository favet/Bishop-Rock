class_name NightBoard
extends Node2D
## Simulation root for the night defense. Pure orchestration: wires spawner,
## boats, and lighthouse together and tracks run stats. All behavior lives in
## the child systems, so this file must stay small.
## TODO(day-loop): the day phase will wrap this board in a larger state
## machine (morning/day/dusk/night/dawn) — see Docs/DAY_LOOP_SPEC.md.

signal board_over
signal night_won(stats: Dictionary)
signal perfect_kill

var kills: int = 0
var rammed: int = 0  ## boats that reached the lighthouse (not sunk by damage)
var elapsed: float = 0.0
var game_over: bool = false
var campaign_mode: bool = true
var gold_earned: int = 0
var perfect_bonus_earned: int = 0
var perfect_kills: int = 0
var hull_damage_taken: int = 0
var defenses_consumed: Dictionary = {"mines": 0, "barricades": 0}

@onready var lighthouse: Lighthouse = $Lighthouse
@onready var spawner: BoatSpawner = $BoatSpawner
@onready var _hazards: Node2D = $Hazards
@onready var _gun: MainGun = $Lighthouse/MainGun
@onready var _beam: LighthouseBeam = $Lighthouse/Beam
@onready var _turret: ShoreTurret = $Lighthouse/Turret

var _dawn_emitted: bool = false
var _floating_texts: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("night_board")
	if campaign_mode:
		_apply_campaign_profile()
	spawner.boat_spawned.connect(_on_boat_spawned)
	lighthouse.destroyed.connect(_on_lighthouse_destroyed)
	_gun.shot_hit.connect(_on_shot_hit)

func _physics_process(delta: float) -> void:
	if not game_over:
		elapsed += delta
		_auto_use_mines()
		_check_for_dawn()

func _process(delta: float) -> void:
	for text in _floating_texts:
		text["age"] = float(text["age"]) + delta
		text["position"] = text["position"] + Vector2(0, -22) * delta
	_floating_texts = _floating_texts.filter(func(t: Dictionary) -> bool: return float(t["age"]) < 1.0)
	queue_redraw()  # floats + lit-boat bounties both move every frame

## Boats no longer in play, one way or another — sunk or rammed home. With
## spawner.remaining_to_spawn(), (wave_size - resolved_count()) always equals
## the boats currently in the "boats" group, i.e. resolved + at-sea + incoming
## accounts for the whole wave.
func resolved_count() -> int:
	return kills + rammed

func _on_boat_spawned(boat: Boat) -> void:
	boat.died.connect(_on_boat_died)
	boat.reached_lighthouse.connect(func(rammer: Boat) -> void:
		rammed += 1
		var damage := _crash_damage(rammer)
		if campaign_mode and CampaignState.barricades > 0:
			CampaignState.barricades -= 1
			defenses_consumed["barricades"] = int(defenses_consumed["barricades"]) + 1
			damage = ceili(float(damage) * 0.25)
			_float_text(rammer.global_position, "BARRICADE", Color(0.65, 0.9, 1.0))
		hull_damage_taken += damage
		lighthouse.take_damage(damage)
		if campaign_mode:
			CampaignState.hull = int(lighthouse.health)
	)

func _on_boat_died(boat: Boat) -> void:
	kills += 1
	var reward := _base_reward(boat)
	var label := "+%ds" % reward
	var is_perfect := boat.killed_by_perfect
	if is_perfect:
		var bonus := _perfect_kill_bonus(boat)
		reward += bonus
		perfect_bonus_earned += bonus
		label = "+%ds PERFECT" % reward
		perfect_kills += 1
		perfect_kill.emit()
	gold_earned += reward
	if campaign_mode:
		CampaignState.gold += reward
		CampaignState.run_kills += 1
		CampaignState.run_gold_earned += reward
		if boat.killed_by_perfect:
			CampaignState.run_perfects += 1
	_float_text(boat.global_position, label, Color(1.0, 0.85, 0.25), 30 if is_perfect else 16)

func _on_shot_hit(boat: Boat, quality: int, killed: bool) -> void:
	if killed or quality != MainGun.ShotQuality.PERFECT or boat.perfect_reward_claimed:
		return
	boat.perfect_reward_claimed = true
	perfect_bonus_earned += 1
	gold_earned += 1
	if campaign_mode:
		CampaignState.gold += 1
	_float_text(boat.global_position, "+1g PERFECT", Color(1.0, 0.45, 0.3))

func _on_lighthouse_destroyed() -> void:
	game_over = true
	spawner.active = false
	if campaign_mode:
		CampaignState.hull = 0
	board_over.emit()

func _apply_campaign_profile() -> void:
	var profile := CampaignState.raid_profile()
	spawner.wave_size = int(profile["wave_size"])
	spawner.fast_boat_weight = float(profile["fast_weight"])
	spawner.heavy_boat_weight = float(profile["heavy_weight"])
	spawner.max_simultaneous = int(profile["max_simultaneous"])
	var wx: Dictionary = RunState.WEATHERS[CampaignState.weather]
	spawner.speed_scale = float(profile["speed_scale"]) * float(wx["speed"]) \
		* (0.8 if CampaignState.mercy else 1.0)
	spawner.start_interval = float(profile["start_interval"])
	spawner.min_interval = float(profile["min_interval"])
	spawner.first_spawn_delay = float(profile["first_spawn_delay"])
	lighthouse.max_health = CampaignState.max_hull
	lighthouse.health = CampaignState.hull
	_beam.turn_speed_multiplier = CampaignState.beam_turn_multiplier()
	_beam.cone_half_angle_deg *= float(wx["cone"])
	if CampaignState.mercy:
		_beam.cone_half_angle_deg *= 1.25
	_gun.reload_time *= CampaignState.reload_multiplier()
	_turret.enabled = CampaignState.turret_unlocked
	if not bool(profile.get("use_v0_hazards", false)):
		for child in _hazards.get_children():
			child.queue_free()

func _auto_use_mines() -> void:
	if not campaign_mode or CampaignState.mines <= 0:
		return
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.global_position.length() <= OceanGrid.ring_radius(OceanGrid.Ring.MIDWATER):
			CampaignState.mines -= 1
			defenses_consumed["mines"] = int(defenses_consumed["mines"]) + 1
			_float_text(boat.global_position, "MINE -6", Color(1.0, 0.45, 0.2))
			Sfx.play("mine_thump")
			boat.take_damage(6.0)
			return

func _check_for_dawn() -> void:
	if _dawn_emitted or not spawner.wave_complete() or get_tree().get_nodes_in_group("boats").size() > 0:
		return
	_dawn_emitted = true
	spawner.active = false
	var stats := {
		"night": CampaignState.day if campaign_mode else 0,
		"kills": kills,
		"crashed": rammed,
		"perfects": perfect_kills,
		"gold_earned": gold_earned,
		"perfect_bonus_earned": perfect_bonus_earned,
		"hull_damage_taken": hull_damage_taken,
		"hull": int(lighthouse.health),
		"max_hull": int(lighthouse.max_health),
		"defenses_consumed": defenses_consumed.duplicate(),
	}
	if campaign_mode:
		CampaignState.hull = int(lighthouse.health)
		CampaignState.set_night_result(stats)
	night_won.emit(stats)

func _base_reward(boat: Boat) -> int:
	if boat.max_health >= 8.0:
		return 8
	if boat.max_health <= 2.0:
		return 4
	return 3

func _perfect_kill_bonus(boat: Boat) -> int:
	return 4 if boat.max_health >= 8.0 else 2

func _crash_damage(boat: Boat) -> int:
	if not campaign_mode:
		return int(boat.ram_damage)
	var damage := 6
	if boat.max_health >= 8.0:
		damage = 13
	elif boat.max_health <= 2.0:
		damage = 4
	return ceili(damage * 0.7) if CampaignState.mercy else damage

func _float_text(pos: Vector2, text: String, color: Color, size: int = 16) -> void:
	_floating_texts.append({position = pos, text = text, color = color, age = 0.0, size = size})
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Bounty on lit boats: target value is part of the aiming decision —
	# a heavy is worth leaving two skiffs alone for.
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.vis_state == Boat.VisState.ILLUMINATED:
			draw_string(font, to_local(boat.global_position) + Vector2(-10, -16),
				"%ds" % _base_reward(boat), HORIZONTAL_ALIGNMENT_CENTER, 40, 12,
				Color(1.0, 0.85, 0.25, 0.8))
	for item in _floating_texts:
		var t := float(item["age"])
		var color: Color = item["color"]
		color.a = 1.0 - t
		draw_string(font, to_local(item["position"]), item["text"], HORIZONTAL_ALIGNMENT_CENTER, 160, int(item.get("size", 16)), color)
