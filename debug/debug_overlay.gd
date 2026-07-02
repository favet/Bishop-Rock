class_name DebugOverlay
extends Node2D
## World-space debug drawing: ocean rings/sectors, beam cone edges, boat
## steering vectors and states, and hazard radii. Toggle with F3. On by
## default while the prototype is schematic-first.

var enabled: bool = true

const RING_NAMES: Array[String] = ["shore", "shallows", "midwater", "deep", "horizon"]

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		enabled = not enabled
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	var font := ThemeDB.fallback_font
	var faint := Color(0.5, 0.7, 0.9, 0.16)

	# Rings with labels.
	for i in OceanGrid.RING_RADII.size():
		var radius: float = OceanGrid.RING_RADII[i]
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, faint, 1.0)
		draw_string(font, Vector2(4, -radius + 12), RING_NAMES[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.7, 0.9, 0.4))

	# Sector spokes.
	for s in OceanGrid.SECTOR_COUNT:
		var dir := Vector2.from_angle(TAU * float(s) / OceanGrid.SECTOR_COUNT)
		draw_line(dir * OceanGrid.ring_radius(OceanGrid.Ring.SHORE),
			dir * OceanGrid.ring_radius(OceanGrid.Ring.HORIZON), Color(0.5, 0.7, 0.9, 0.07), 1.0)

	# Beam cone edges + mode label.
	var beam := get_tree().get_first_node_in_group("beam") as LighthouseBeam
	if beam != null:
		var half := deg_to_rad(beam.cone_half_angle_deg)
		for sign_value in [-1.0, 1.0]:
			var edge := Vector2.from_angle(beam.beam_angle + half * sign_value) * beam.beam_range
			draw_line(Vector2.ZERO, edge, Color(1.0, 0.9, 0.4, 0.35), 1.0)
		var label := beam.mode_name() + (" +override" if beam.is_overriding else "")
		draw_string(font, Vector2(-20, 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.4, 0.6))

	# Boats: hull circle, steering vectors, visibility state letter.
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		var pos := boat.global_position
		draw_arc(pos, boat.hull_radius, 0.0, TAU, 12, Color(1, 1, 1, 0.25), 1.0)
		draw_line(pos, pos + boat.debug_desired * 30.0, Color(0.3, 1.0, 0.4, 0.6), 1.0)
		draw_line(pos, pos + boat.debug_avoid * 30.0, Color(1.0, 0.35, 0.3, 0.7), 1.0)
		var letters := ["C", "S", "I"]
		draw_string(font, pos + Vector2(-3, -12), letters[boat.vis_state],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.6))

	# Hazard radii.
	for node in get_tree().get_nodes_in_group("mines"):
		var mine := node as Mine
		draw_arc(mine.global_position, mine.trigger_radius, 0.0, TAU, 16, Color(1.0, 0.3, 0.2, 0.3), 1.0)
		draw_arc(mine.global_position, mine.blast_radius, 0.0, TAU, 24, Color(1.0, 0.5, 0.2, 0.15), 1.0)
	for node in get_tree().get_nodes_in_group("buoys"):
		var buoy := node as Buoy
		draw_arc(buoy.global_position, buoy.reveal_radius, 0.0, TAU, 24, Color(0.95, 0.6, 0.15, 0.25), 1.0)
	for node in get_tree().get_nodes_in_group("nets"):
		var net := node as NetChain
		draw_arc(net.global_position, net.slow_radius, 0.0, TAU, 16, Color(0.6, 0.62, 0.55, 0.3), 1.0)
	for node in get_tree().get_nodes_in_group("rocks"):
		var rock := node as Rock
		draw_arc(rock.global_position, rock.radius, 0.0, TAU, 16, Color(0.7, 0.7, 0.75, 0.3), 1.0)
	for node in get_tree().get_nodes_in_group("turrets"):
		var turret := node as ShoreTurret
		draw_arc(turret.global_position, turret.fire_range, 0.0, TAU, 32, Color(0.5, 0.75, 0.85, 0.2), 1.0)
