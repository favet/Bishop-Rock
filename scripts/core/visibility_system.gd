class_name VisibilitySystem
extends Node2D
## Assigns each boat a visibility state every physics tick and renders the
## "keeper's knowledge" layer: fading last-known ghosts and vague contact
## ticks at the sector where an unseen boat lurks.
##
## States (Docs/CONTROL_VISIBILITY_SPEC.md):
##   CONTACT     — vague sector indication only
##   SPOTTED     — close enough to see, or revealed by a buoy; turret-valid
##   ILLUMINATED — inside the beam cone; main-gun-valid
##   last-known  — ghost record left when illumination is lost (not a boat state)

@export var spotted_radius: float = 140.0
@export var ghost_lifetime: float = 4.0

class GhostRecord:
	var position: Vector2
	var heading: float
	var age: float = 0.0

var _ghosts: Array[GhostRecord] = []
var _beam: LighthouseBeam

static var GHOST_HULL := PackedVector2Array([Vector2(12, 0), Vector2(-8, 6), Vector2(-8, -6)])

func _physics_process(delta: float) -> void:
	if _beam == null:
		_beam = get_tree().get_first_node_in_group("beam") as LighthouseBeam
		if _beam == null:
			return

	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		var previous := boat.vis_state
		var next := _compute_state(boat)
		if previous == Boat.VisState.ILLUMINATED and next != Boat.VisState.ILLUMINATED:
			_add_ghost(boat)
		boat.vis_state = next

	for ghost in _ghosts:
		ghost.age += delta
	_ghosts = _ghosts.filter(func(g: GhostRecord) -> bool: return g.age < ghost_lifetime)
	queue_redraw()

func _compute_state(boat: Boat) -> Boat.VisState:
	if _beam.is_point_illuminated(boat.global_position):
		return Boat.VisState.ILLUMINATED
	if boat.global_position.length() <= spotted_radius:
		return Boat.VisState.SPOTTED
	for node in get_tree().get_nodes_in_group("buoys"):
		var buoy := node as Buoy
		if boat.global_position.distance_to(buoy.global_position) <= buoy.reveal_radius:
			return Boat.VisState.SPOTTED
	return Boat.VisState.CONTACT

func _add_ghost(boat: Boat) -> void:
	var ghost := GhostRecord.new()
	ghost.position = boat.global_position
	ghost.heading = boat.heading
	_ghosts.append(ghost)

func _draw() -> void:
	# Fading last-known silhouettes.
	for ghost in _ghosts:
		var alpha := 0.55 * (1.0 - ghost.age / ghost_lifetime)
		draw_set_transform(ghost.position, ghost.heading, Vector2.ONE)
		draw_colored_polygon(GHOST_HULL, Color(0.8, 0.85, 0.95, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Vague sector ticks for unseen contacts, at the deep-water boundary.
	var tick_radius := OceanGrid.ring_radius(OceanGrid.Ring.DEEP) + 12.0
	for node in get_tree().get_nodes_in_group("boats"):
		var boat := node as Boat
		if boat.vis_state == Boat.VisState.CONTACT:
			var angle := OceanGrid.sector_center_angle(OceanGrid.sector_at(boat.global_position))
			draw_arc(Vector2.ZERO, tick_radius, angle - 0.09, angle + 0.09, 6, Color(0.9, 0.9, 1.0, 0.25), 3.0)
