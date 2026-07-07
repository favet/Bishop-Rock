extends Control
class_name RadarUI

@export var radar_radius: float = 60.0
@export var radar_color: Color = Color(0.1, 0.4, 0.2, 0.6)
@export var sweep_color: Color = Color(0.3, 0.9, 0.4, 0.4)
@export var contact_color: Color = Color(0.8, 0.3, 0.2, 0.9)
@export var blip_size: float = 3.0

var _beam: LighthouseBeam
var _vis_system: VisibilitySystem

func _ready() -> void:
	custom_minimum_size = Vector2(radar_radius * 2, radar_radius * 2)

func _process(delta: float) -> void:
	if _beam == null:
		_beam = get_tree().get_first_node_in_group("beam") as LighthouseBeam
	if _vis_system == null:
		_vis_system = get_tree().get_first_node_in_group("visibility_system") as VisibilitySystem
	queue_redraw()

func _draw() -> void:
	var center = size / 2.0

	# Draw radar bg
	draw_circle(center, radar_radius, radar_color)
	draw_arc(center, radar_radius, 0, TAU, 32, Color(0.2, 0.8, 0.3, 0.8), 2.0)
	draw_arc(center, radar_radius * 0.5, 0, TAU, 32, Color(0.2, 0.8, 0.3, 0.3), 1.0)

	# Draw crosshairs
	draw_line(center - Vector2(radar_radius, 0), center + Vector2(radar_radius, 0), Color(0.2, 0.8, 0.3, 0.3), 1.0)
	draw_line(center - Vector2(0, radar_radius), center + Vector2(0, radar_radius), Color(0.2, 0.8, 0.3, 0.3), 1.0)

	if _beam != null:
		var beam_dir = Vector2.from_angle(_beam.beam_angle)
		var p1 = center
		var p2 = center + Vector2.from_angle(_beam.beam_angle - _beam.beam_width/2) * radar_radius
		var p3 = center + Vector2.from_angle(_beam.beam_angle + _beam.beam_width/2) * radar_radius
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), sweep_color)

	if _vis_system != null:
		var scale_factor = radar_radius / OceanGrid.ring_radius(OceanGrid.Ring.HORIZON)

		# Draw ghosts (fading dots)
		for ghost in _vis_system._ghosts:
			var alpha = 0.8 * (1.0 - ghost.age / _vis_system.ghost_lifetime)
			var pos = center + ghost.position * scale_factor
			draw_circle(pos, blip_size, Color(0.8, 0.8, 0.2, alpha))

		# Draw active contacts/spotted
		for node in get_tree().get_nodes_in_group("boats"):
			var boat = node as Boat
			# Everything spotted, contacted, or illuminated
				var pos = center + boat.global_position * scale_factor
				if boat.vis_state == Boat.VisState.ILLUMINATED:
					draw_circle(pos, blip_size * 1.5, Color(0.9, 0.1, 0.1, 1.0))
				elif boat.vis_state == Boat.VisState.SPOTTED:
					draw_circle(pos, blip_size, Color(0.9, 0.5, 0.1, 0.8))
				if boat.vis_state == Boat.VisState.CONTACT:
					# Just a vague sector edge blip for contacts
					var angle = boat.global_position.angle()
					var edge_pos = center + Vector2.from_angle(angle) * radar_radius
					draw_circle(edge_pos, blip_size, Color(0.4, 0.6, 0.8, 0.5))
