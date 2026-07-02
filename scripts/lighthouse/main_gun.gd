class_name MainGun
extends Node2D
## Long-range cannon slaved to the beam (beam-as-reticle). Hold Space to
## charge a shot: a ring around the lighthouse fills clockwise from 0% to
## 100% in real time (see below), with the CHARGED/PERFECT zones banded near
## the end. Releasing before the ring fills fires at whatever value it shows.
## There is no "safe" overshoot — if the ring fills completely while still
## held, the gun MISFIRES automatically: no damage, a punishing reload, the
## meter resets, and the lighthouse itself takes a small jolt of backlash
## damage (this is a fragile, overloaded weapon, not a turret you can lean on).
##
## The charge clock runs on real (unscaled) time via _real_delta(), NOT the
## engine delta — because charging also linearly slows the rest of the world
## (see world_time_scale()), and if the charge timer used scaled delta it
## would asymptotically approach 100% and never reach it. This is deliberate:
## the world grinds toward a stop while your hand stays on the real-time
## clock, which is the whole tension of the hold.
##
## Only illuminated boats are valid targets. Tab cycles among them; 1/2/3
## select a mode (placeholder).
## TODO(ammo): modes will become real ammo types (chain/flare/explosive...).
## TODO(auto-fire): optional auto-fire setting/upgrade per the handoff.
## TODO(no-target): a released charge with no illuminated target still fires
## a blind, damageless tracer and still consumes the reload, matching the
## v0 pattern where every input resolves immediately (mines/turret do the
## same). A future pass could refund the charge instead; out of scope here.

@export var base_damage: float = 1.0
@export var bonus_multiplier: float = 2.0
@export var perfect_multiplier: float = 4.0
@export var reload_time: float = 1.5  ## seconds between shots
@export var fire_range: float = 335.0  ## blind-shot tracer length when no target is illuminated

@export_group("Charge Timing")
@export var charge_up_time: float = 0.7  ## real seconds for the ring to fill 0% -> 100%
@export var world_slowdown_floor: float = 0.04  ## minimum world_time_scale() while charging (never fully 0)

@export_group("Charge Zones")  # fractions of the 0..1 ring
@export var bonus_zone_min: float = 0.75
@export var bonus_zone_max: float = 0.95
@export var perfect_zone_min: float = 0.88
@export var perfect_zone_max: float = 0.94

@export_group("Misfire")
@export var misfire_reload_penalty: float = 1.6  ## reload_time multiplier after a misfire
@export var misfire_self_damage: float = 3.0  ## backlash damage to the lighthouse on misfire

enum ShotQuality { NORMAL, CHARGED, PERFECT, MISFIRE }

signal shot_hit(boat: Boat, quality: int, killed: bool)

const QUALITY_LABELS: Array[String] = ["NORMAL", "CHARGED 2x", "PERFECT 4x", "MISFIRE"]
const TRACER_TIME := 0.3
const RESULT_FLASH_TIME := 0.9
const RELOAD_READY_FLASH_TIME := 0.35
const MISFIRE_BURST_TIME := 0.5
const MUZZLE_FLASH_TIME := 0.15
const RELOAD_RING_RADIUS := 20.0
const CHARGE_RING_RADIUS := 46.0
const RING_THICKNESS := 5.0

var current_mode: int = 1

var _cooldown_left: float = 0.0
var _selected: Boat = null
var _tracers: Array[Dictionary] = []  # {from, to, age, hit, quality}
var _beam: LighthouseBeam
var _lighthouse: Lighthouse

var _charging: bool = false
var _charge_elapsed: float = 0.0
var _charge: float = 0.0  # current ring value, 0..1

var _last_quality: ShotQuality = ShotQuality.NORMAL
var _result_flash_age: float = -1.0  # negative = no recent result to show
var _gun_was_ready: bool = true
var _reload_flash_age: float = -1.0
var _misfire_flash_age: float = -1.0
var _muzzle_flash_age: float = -1.0
var _muzzle_flash_quality: ShotQuality = ShotQuality.NORMAL

var _last_ticks_usec: int = -1

func _ready() -> void:
	add_to_group("main_gun")

func _process(_delta: float) -> void:
	if _beam == null:
		_beam = get_tree().get_first_node_in_group("beam") as LighthouseBeam
	if _lighthouse == null:
		_lighthouse = get_tree().get_first_node_in_group("lighthouse") as Lighthouse
	if _beam == null or _lighthouse == null:
		return

	var real_delta := _real_delta()
	_cooldown_left = maxf(_cooldown_left - real_delta, 0.0)

	var ready := _cooldown_left <= 0.0
	if ready and not _gun_was_ready:
		_reload_flash_age = 0.0  # edge trigger: reload just completed
	_gun_was_ready = ready

	for i in 3:
		if Input.is_action_just_pressed("mode_%d" % (i + 1)):
			current_mode = i + 1

	if is_instance_valid(_selected) and _selected.vis_state != Boat.VisState.ILLUMINATED:
		_selected = null

	if Input.is_action_just_pressed("cycle_target"):
		_cycle_target()

	_update_charge(real_delta)

	if _result_flash_age >= 0.0:
		_result_flash_age += real_delta
		if _result_flash_age > RESULT_FLASH_TIME:
			_result_flash_age = -1.0
	if _reload_flash_age >= 0.0:
		_reload_flash_age += real_delta
		if _reload_flash_age > RELOAD_READY_FLASH_TIME:
			_reload_flash_age = -1.0
	if _misfire_flash_age >= 0.0:
		_misfire_flash_age += real_delta
		if _misfire_flash_age > MISFIRE_BURST_TIME:
			_misfire_flash_age = -1.0
	if _muzzle_flash_age >= 0.0:
		_muzzle_flash_age += real_delta
		if _muzzle_flash_age > MUZZLE_FLASH_TIME:
			_muzzle_flash_age = -1.0

	for tracer in _tracers:
		tracer.age += real_delta
	_tracers = _tracers.filter(func(t: Dictionary) -> bool: return t.age < TRACER_TIME)
	queue_redraw()

## Wall-clock delta, immune to Engine.time_scale and to world_time_scale()'s
## own slowdown (which this gun causes) — see class doc for why.
func _real_delta() -> float:
	var now := Time.get_ticks_usec()
	if _last_ticks_usec < 0:
		_last_ticks_usec = now
		return 0.0
	var d := (now - _last_ticks_usec) / 1_000_000.0
	_last_ticks_usec = now
	return d

func _update_charge(real_delta: float) -> void:
	var held := Input.is_action_pressed("fire")
	if _charging:
		_charge_elapsed += real_delta
		if _charge_elapsed >= charge_up_time:
			_misfire()
			return
		_charge = _charge_elapsed / charge_up_time
		if not held:
			_release_shot()
	elif held and _cooldown_left <= 0.0:
		_charging = true
		_charge_elapsed = 0.0
		_charge = 0.0

func quality_at(charge: float) -> ShotQuality:
	if charge >= perfect_zone_min and charge <= perfect_zone_max:
		return ShotQuality.PERFECT
	if charge >= bonus_zone_min and charge <= bonus_zone_max:
		return ShotQuality.CHARGED
	return ShotQuality.NORMAL

func multiplier_for(quality: ShotQuality) -> float:
	match quality:
		ShotQuality.PERFECT:
			return perfect_multiplier
		ShotQuality.CHARGED:
			return bonus_multiplier
		ShotQuality.MISFIRE:
			return 0.0
		_:
			return 1.0

## Global slowdown this gun imposes on the rest of the world while charging:
## 1.0 (full speed) at 0% charge, linearly down to world_slowdown_floor at
## 100%, snapping back to 1.0 immediately on release/misfire. Boat, ShoreTurret,
## and BoatSpawner each multiply their own delta by this — nothing here
## touches Engine.time_scale (that stays reserved for the manual P slow-mo).
func world_time_scale() -> float:
	if _charging:
		return clampf(1.0 - _charge, world_slowdown_floor, 1.0)
	return 1.0

## -- Read-only state for HUD/debug --

func is_charging() -> bool:
	return _charging

func charge_fraction() -> float:
	return _charge

func preview_quality() -> ShotQuality:
	return quality_at(_charge)

func cooldown_fraction() -> float:
	return 1.0 - _cooldown_left / reload_time if reload_time > 0.0 else 1.0

func has_target() -> bool:
	return is_instance_valid(_selected)

## Illuminated boats sorted by angular closeness to the beam center.
func _illuminated_boats() -> Array[Boat]:
	var result: Array[Boat] = []
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.vis_state == Boat.VisState.ILLUMINATED:
			result.append(boat)
	result.sort_custom(func(a: Boat, b: Boat) -> bool:
		var da := absf(angle_difference(_beam.beam_angle, a.global_position.angle()))
		var db := absf(angle_difference(_beam.beam_angle, b.global_position.angle()))
		return da < db)
	return result

func _cycle_target() -> void:
	var lit := _illuminated_boats()
	if lit.is_empty():
		_selected = null
		return
	var idx := lit.find(_selected)
	_selected = lit[(idx + 1) % lit.size()]

func _release_shot() -> void:
	_charging = false
	var quality := quality_at(_charge)
	_resolve_shot(quality)
	_charge = 0.0

## Ring overfilled while still held: forced bad outcome, not a player choice.
func _misfire() -> void:
	_charging = false
	_charge = 0.0
	_resolve_shot(ShotQuality.MISFIRE)
	_cooldown_left = reload_time * misfire_reload_penalty
	_misfire_flash_age = 0.0
	_lighthouse.take_damage(misfire_self_damage)

func _resolve_shot(quality: ShotQuality) -> void:
	_last_quality = quality
	_result_flash_age = 0.0
	_muzzle_flash_age = 0.0
	_muzzle_flash_quality = quality
	if quality != ShotQuality.MISFIRE:
		_cooldown_left = reload_time

	if quality == ShotQuality.MISFIRE:
		return  # no shot leaves the barrel — see class doc

	var target := _selected
	if target == null:
		var lit := _illuminated_boats()
		if not lit.is_empty():
			target = lit[0]

	if target != null:
		_tracers.append({from = Vector2.ZERO, to = to_local(target.global_position), age = 0.0, hit = true, quality = quality})
		var killed := target.take_damage(base_damage * multiplier_for(quality), quality)
		shot_hit.emit(target, quality, killed)
	else:
		# No illuminated target: still resolves as a wasted blind shot (see TODO above).
		_tracers.append({from = Vector2.ZERO, to = Vector2.from_angle(_beam.beam_angle) * fire_range, age = 0.0, hit = false, quality = quality})

func _draw() -> void:
	_draw_reload_ring()
	_draw_charge_ring()
	_draw_misfire_burst()
	_draw_muzzle_flash()
	_draw_tracers()

	if is_instance_valid(_selected):
		draw_arc(to_local(_selected.global_position), 14.0, 0.0, TAU, 16, Color(1.0, 0.4, 0.3, 0.9), 1.5)

## Central, unmissable reload readout: a ring just outside the tower that
## fills clockwise and flashes white the instant it completes, plus a text
## label. Deliberately drawn in world-space at the lighthouse, not tucked in
## a HUD corner.
func _draw_reload_ring() -> void:
	var font := ThemeDB.fallback_font
	var frac := clampf(cooldown_fraction(), 0.0, 1.0)
	draw_arc(Vector2.ZERO, RELOAD_RING_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.12), RING_THICKNESS)

	var fill_color := Color(0.35, 0.6, 0.9)
	if frac > 0.0:
		if frac >= 1.0:
			var flash_t := clampf(_reload_flash_age / RELOAD_READY_FLASH_TIME, 0.0, 1.0) if _reload_flash_age >= 0.0 else 1.0
			fill_color = Color(1.0, 1.0, 1.0).lerp(Color(0.4, 0.9, 0.55), flash_t)
		var end_angle := -PI / 2.0 + TAU * frac
		draw_arc(Vector2.ZERO, RELOAD_RING_RADIUS, -PI / 2.0, end_angle, 48, fill_color, RING_THICKNESS)

	var label := "READY" if frac >= 1.0 else "RELOADING %d%%" % int(frac * 100.0)
	draw_string(font, Vector2(-60, 58), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 13,
		Color(0.4, 0.9, 0.55) if frac >= 1.0 else Color(0.7, 0.8, 0.95))

## The primary, hard-to-miss focus meter: a ring around the lighthouse that
## fills clockwise as the player holds Space, with the CHARGED/PERFECT zones
## banded near the end (see class doc for the misfire behavior past 100%).
func _draw_charge_ring() -> void:
	var font := ThemeDB.fallback_font
	draw_arc(Vector2.ZERO, CHARGE_RING_RADIUS, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.10), RING_THICKNESS)
	_draw_ring_zone(bonus_zone_min, bonus_zone_max, Color(1.0, 0.75, 0.25, 0.55))
	_draw_ring_zone(perfect_zone_min, perfect_zone_max, Color(1.0, 0.3, 0.25, 0.7))

	if _charging:
		var start_angle := -PI / 2.0
		var end_angle := start_angle + TAU * _charge
		var q := preview_quality()
		var fill_color := _ring_quality_color(q)
		draw_arc(Vector2.ZERO, CHARGE_RING_RADIUS, start_angle, end_angle, 64, fill_color, RING_THICKNESS + 1.0)
		var tip := Vector2.from_angle(end_angle) * CHARGE_RING_RADIUS
		draw_circle(tip, RING_THICKNESS * 0.9, Color(1.0, 1.0, 1.0, 0.95))
		# Tension glow that brightens as the charge nears full — the weapon
		# straining under its own overload.
		draw_circle(Vector2.ZERO, 14.0 + 6.0 * _charge, Color(1.0, 0.85, 0.5, 0.10 + 0.2 * _charge))
		var label := "%d%%   x%d" % [int(_charge * 100.0), int(multiplier_for(q))]
		draw_string(font, Vector2(-60, -62), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 15, fill_color)
	elif _result_flash_age >= 0.0:
		var label := QUALITY_LABELS[_last_quality]
		draw_string(font, Vector2(-70, -62), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 17, _ring_quality_color(_last_quality))

func _draw_ring_zone(zone_min: float, zone_max: float, color: Color) -> void:
	var start_angle := -PI / 2.0 + TAU * zone_min
	var end_angle := -PI / 2.0 + TAU * zone_max
	draw_arc(Vector2.ZERO, CHARGE_RING_RADIUS, start_angle, end_angle, 24, color, RING_THICKNESS)

func _ring_quality_color(quality: ShotQuality) -> Color:
	match quality:
		ShotQuality.PERFECT:
			return Color(1.0, 0.45, 0.3)
		ShotQuality.CHARGED:
			return Color(1.0, 0.8, 0.35)
		ShotQuality.MISFIRE:
			return Color(0.85, 0.25, 0.95)
		_:
			return Color(0.85, 0.9, 1.0)

## Overload backfire: the ring shatters outward instead of a clean release.
func _draw_misfire_burst() -> void:
	if _misfire_flash_age < 0.0:
		return
	var t := _misfire_flash_age / MISFIRE_BURST_TIME
	var alpha := 1.0 - t
	draw_arc(Vector2.ZERO, CHARGE_RING_RADIUS * (1.0 + t * 0.6), 0.0, TAU, 48, Color(0.85, 0.2, 0.9, alpha * 0.8), 3.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var inner := CHARGE_RING_RADIUS * 0.6
		var outer := CHARGE_RING_RADIUS * (1.2 + t * 0.8)
		draw_line(Vector2.from_angle(a) * inner, Vector2.from_angle(a) * outer, Color(0.9, 0.3, 1.0, alpha), 2.0)

func _draw_muzzle_flash() -> void:
	if _muzzle_flash_age < 0.0 or _muzzle_flash_quality == ShotQuality.MISFIRE:
		return
	var t := _muzzle_flash_age / MUZZLE_FLASH_TIME
	var radius := 10.0 if _muzzle_flash_quality == ShotQuality.NORMAL else (16.0 if _muzzle_flash_quality == ShotQuality.CHARGED else 24.0)
	draw_circle(Vector2.ZERO, radius * (1.0 - t), Color(1.0, 0.95, 0.8, (1.0 - t) * 0.9))

func _draw_tracers() -> void:
	for tracer in _tracers:
		var fade: float = 1.0 - tracer.age / TRACER_TIME
		var quality: ShotQuality = tracer.quality
		var color := Color(1.0, 0.9, 0.6, 0.8 * fade)
		var thickness := 2.0
		if quality == ShotQuality.CHARGED:
			color = Color(1.0, 0.75, 0.25, 0.85 * fade)
			thickness = 3.0
		elif quality == ShotQuality.PERFECT:
			color = Color(1.0, 0.35, 0.25, 0.95 * fade)
			thickness = 4.0
		draw_line(tracer.from, tracer.to, color, thickness)
		if tracer.hit:
			var base_radius := 6.0 if quality == ShotQuality.NORMAL else (9.0 if quality == ShotQuality.CHARGED else 14.0)
			draw_circle(tracer.to, base_radius * (1.0 - fade * 0.5), color)
			if quality == ShotQuality.PERFECT:
				# Stronger primitive flash for a perfect hit: expanding ring.
				draw_arc(tracer.to, base_radius * 1.6 * (1.0 - fade) + 4.0, 0.0, TAU, 20, Color(1.0, 1.0, 0.8, fade), 2.0)
