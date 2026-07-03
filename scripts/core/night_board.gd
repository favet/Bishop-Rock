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
var night_duration: float = 65.0

@onready var lighthouse: Lighthouse = $Lighthouse
@onready var spawner: BoatSpawner = $BoatSpawner
@onready var _hazards: Node2D = $Hazards
@onready var _gun: MainGun = $Lighthouse/MainGun
@onready var _beam: LighthouseBeam = $Lighthouse/Beam
@onready var _turret: ShoreTurret = $Lighthouse/Turret
@onready var _visibility: VisibilitySystem = $VisibilitySystem

var _dawn_emitted: bool = false
var _floating_texts: Array[Dictionary] = []
var _pings: Array[Dictionary] = []
var _sea_speckle: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	add_to_group("night_board")
	if campaign_mode:
		_apply_campaign_profile()
	spawner.boat_spawned.connect(_on_boat_spawned)
	lighthouse.destroyed.connect(_on_lighthouse_destroyed)
	_gun.shot_hit.connect(_on_shot_hit)
	# Static sea speckle, rolled once per night so it doesn't shimmer.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([CampaignState.run_seed, CampaignState.day, "sea"])
	var horizon: float = OceanGrid.ring_radius(OceanGrid.Ring.HORIZON)
	for i in 170:
		var angle := rng.randf() * TAU
		var radius := sqrt(rng.randf()) * horizon
		_sea_speckle.append(Vector2.from_angle(angle) * radius)

func _physics_process(delta: float) -> void:
	if not game_over:
		elapsed += delta
		_auto_use_mines()
		_check_for_dawn()

func _process(delta: float) -> void:
	for text in _floating_texts:
		text["age"] = float(text["age"]) + delta
		text["position"] = text["position"] + Vector2(0, -22) * delta
	_floating_texts = _floating_texts.filter(func(t: Dictionary) -> bool:
		return float(t["age"]) < float(t.get("life", 1.0)))
	for ping in _pings:
		ping["age"] = float(ping["age"]) + delta
	_pings = _pings.filter(func(p: Dictionary) -> bool: return float(p["age"]) < 0.9)
	queue_redraw()  # floats, pings, and lit-boat bounties all move every frame

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
		# The cost of a crash lands as a number at the tower, not just a
		# shorter bar in the corner.
		_float_text(lighthouse.global_position + Vector2(0, -34), "-%d HULL" % damage,
			Color(0.95, 0.3, 0.25), 22)
		if campaign_mode:
			CampaignState.hull = int(lighthouse.health)
	)

func _on_boat_died(boat: Boat) -> void:
	kills += 1
	# Mine kills pay no bounty — nothing salvageable after the blast. Rifle
	# is income, mines are safety, barricades are cheap safety: three
	# identities instead of one dominant option.
	if boat.get_meta("mined", false):
		if campaign_mode:
			CampaignState.run_kills += 1
		_float_text(boat.global_position, "MINED", Color(1.0, 0.45, 0.2))
		return
	var reward := _base_reward(boat)
	var label := "+%ds" % reward
	var is_perfect := boat.killed_by_perfect
	if is_perfect:
		var bonus := _perfect_kill_bonus(boat)
		reward += bonus
		perfect_bonus_earned += bonus
		label = "PERFECT\n+%d" % reward
		perfect_kills += 1
		perfect_kill.emit()
	gold_earned += reward
	if campaign_mode:
		CampaignState.gold += reward
		CampaignState.run_kills += 1
		CampaignState.run_gold_earned += reward
		if boat.killed_by_perfect:
			CampaignState.run_perfects += 1
	_float_text(boat.global_position, label, Color(1.0, 0.85, 0.25), 30 if is_perfect else 16, is_perfect)

func _on_shot_hit(boat: Boat, quality: int, killed: bool) -> void:
	if killed or quality != MainGun.ShotQuality.PERFECT or boat.perfect_reward_claimed:
		return
	boat.perfect_reward_claimed = true
	perfect_bonus_earned += 1
	gold_earned += 1
	if campaign_mode:
		CampaignState.gold += 1
	_float_text(boat.global_position, "PERFECT\n+1", Color(1.0, 0.45, 0.3), 26, true)

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
	night_duration = float(profile.get("night_duration", 65.0))
	lighthouse.max_health = CampaignState.max_hull
	lighthouse.health = CampaignState.hull
	_beam.turn_speed_multiplier = CampaignState.beam_turn_multiplier()
	_beam.cone_half_angle_deg *= float(wx["cone"])
	if CampaignState.mercy:
		_beam.cone_half_angle_deg *= 1.25
	_gun.reload_time *= CampaignState.reload_multiplier()
	_turret.enabled = CampaignState.turret_unlocked
	if campaign_mode:
		_visibility.spotted_radius = 0.0
		_visibility.show_contact_ticks = false
		_visibility.show_ghosts = false
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
			# Flag only for the duration of the blast: a heavy that survives
			# the mine still pays full bounty to the rifle later.
			boat.set_meta("mined", true)
			boat.take_damage(6.0)
			if is_instance_valid(boat):
				boat.set_meta("mined", false)
			return

func _check_for_dawn() -> void:
	if _dawn_emitted or elapsed < night_duration or not spawner.wave_complete() or get_tree().get_nodes_in_group("boats").size() > 0:
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

## The sea as a watched instrument, not black debug space: faint range
## rings, compass ticks on the horizon, and a static speckle field. The F3
## overlay still owns labels, spokes, and vectors.
func _draw_ocean() -> void:
	var faint := Color(0.5, 0.7, 0.9, 0.05)
	for p in _sea_speckle:
		draw_circle(p, 1.0, faint)
	for radius in OceanGrid.RING_RADII:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.5, 0.7, 0.9, 0.07), 1.0)
	var horizon: float = OceanGrid.ring_radius(OceanGrid.Ring.HORIZON)
	for i in 16:
		var dir := Vector2.from_angle(TAU * float(i) / 16.0)
		var tick := 12.0 if i % 4 == 0 else 6.0
		draw_line(dir * (horizon - tick), dir * horizon, Color(0.5, 0.7, 0.9, 0.16), 1.0)

func _base_reward(boat: Boat) -> int:
	if boat.max_health >= 8.0:
		return 6
	if boat.max_health <= 2.0:
		return 3
	return 2

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

func time_remaining() -> float:
	return maxf(night_duration - elapsed, 0.0)

func _float_text(pos: Vector2, text: String, color: Color, size: int = 16, perfect: bool = false) -> void:
	_floating_texts.append({
		position = pos,
		text = text,
		color = color,
		age = 0.0,
		size = size,
		life = 1.55 if perfect else 1.0,
		perfect = perfect,
	})
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_ocean()
	for ping in _pings:
		var t := float(ping["age"]) / 0.9
		draw_arc(to_local(ping["position"]), 6.0 + 34.0 * t, 0.0, TAU, 24,
			Color(0.6, 0.85, 1.0, 0.5 * (1.0 - t)), 1.5)
	# Bounty on lit boats: target value is part of the aiming decision —
	# a heavy is worth leaving two skiffs alone for.
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.vis_state == Boat.VisState.ILLUMINATED:
			draw_string(font, to_local(boat.global_position) + Vector2(-10, -16),
				"%ds" % _base_reward(boat), HORIZONTAL_ALIGNMENT_CENTER, 40, 12,
				Color(1.0, 0.85, 0.25, 0.8))
	for item in _floating_texts:
		var life := float(item.get("life", 1.0))
		var t := float(item["age"]) / life
		var color: Color = item["color"]
		color.a = 1.0 - t
		var local := to_local(item["position"])
		if bool(item.get("perfect", false)):
			var origin := local + Vector2(-150, -48)
			draw_string(font, origin, "PERFECT", HORIZONTAL_ALIGNMENT_CENTER, 300, int(item.get("size", 30)), color)
			var reward := str(item["text"]).get_slice("\n", 1)
			var reward_color := Color(1.0, 0.95, 0.55, color.a)
			draw_string(font, origin + Vector2(0, 34), reward, HORIZONTAL_ALIGNMENT_CENTER, 300, 24, reward_color)
		else:
			draw_string(font, local + Vector2(-90, 0), item["text"], HORIZONTAL_ALIGNMENT_CENTER, 180, int(item.get("size", 16)), color)
