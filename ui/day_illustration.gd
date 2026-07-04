class_name DayIllustration
extends Control
## Small code-drawn day-phase illustrations. These are not final art, but they
## give each zone a different visual language without adding asset dependencies.

const INK := Color(0.055, 0.065, 0.07)
const PAPER := Color(0.70, 0.61, 0.42)
const PAPER_DARK := Color(0.44, 0.35, 0.20)
const BRASS := Color(0.82, 0.62, 0.26)
const BRASS_LIGHT := Color(0.98, 0.82, 0.42)
const SEA := Color(0.08, 0.18, 0.22)
const SEA_LINE := Color(0.33, 0.55, 0.58)
const WOOD := Color(0.42, 0.25, 0.12)
const RED := Color(0.82, 0.22, 0.16)

var kind: String = "chart"

func _init(visual_kind: String = "chart", min_size: Vector2 = Vector2(96, 82)) -> void:
	kind = visual_kind
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match kind:
		"situation", "chart":
			_draw_chart(r)
		"light", "lantern", "repair", "barricade":
			_draw_lighthouse(r)
		"provisions", "fish", "driftwood", "dive", "supper":
			_draw_shore(r)
		"workshop", "blueprint", "project", "mine":
			_draw_blueprint(r)
		_:
			_draw_chart(r)

func _draw_chart(r: Rect2) -> void:
	var pad := minf(r.size.x, r.size.y) * 0.10
	var paper := Rect2(r.position + Vector2(pad, pad), r.size - Vector2(pad * 2.0, pad * 2.0))
	draw_rect(paper, PAPER)
	draw_rect(paper, PAPER_DARK, false, 2.0)
	for i in 3:
		var y := paper.position.y + paper.size.y * (0.28 + float(i) * 0.18)
		draw_line(Vector2(paper.position.x + 8, y), Vector2(paper.end.x - 8, y - 8), SEA_LINE, 1.4)
	var c := paper.get_center()
	for radius in [paper.size.y * 0.18, paper.size.y * 0.30, paper.size.y * 0.42]:
		draw_arc(c, radius, -0.2, TAU - 0.2, 42, Color(0.12, 0.16, 0.14, 0.45), 1.1)
	draw_line(c, c + Vector2.from_angle(-0.8) * paper.size.y * 0.42, RED, 2.0)
	draw_circle(c + Vector2.from_angle(-0.8) * paper.size.y * 0.30, 4.0, RED)

func _draw_lighthouse(r: Rect2) -> void:
	var c := r.get_center()
	var h := r.size.y * 0.70
	var base_y := c.y + h * 0.42
	var top_y := c.y - h * 0.43
	var body := PackedVector2Array([
		Vector2(c.x - r.size.x * 0.13, base_y),
		Vector2(c.x + r.size.x * 0.13, base_y),
		Vector2(c.x + r.size.x * 0.08, top_y),
		Vector2(c.x - r.size.x * 0.08, top_y),
	])
	draw_colored_polygon(body, Color(0.58, 0.57, 0.50))
	draw_polyline(body + PackedVector2Array([body[0]]), INK, 1.5)
	var room := Rect2(Vector2(c.x - r.size.x * 0.18, top_y - 10), Vector2(r.size.x * 0.36, 20))
	draw_rect(room, BRASS)
	draw_rect(room, INK, false, 1.5)
	draw_line(Vector2(room.position.x - 20, room.get_center().y), Vector2(room.position.x, room.get_center().y), BRASS_LIGHT, 3.0)
	draw_line(Vector2(room.end.x, room.get_center().y), Vector2(room.end.x + 20, room.get_center().y), BRASS_LIGHT, 3.0)
	for i in 3:
		var y := top_y + 20 + i * h * 0.18
		draw_line(Vector2(c.x - r.size.x * 0.09, y), Vector2(c.x + r.size.x * 0.09, y), INK, 1.0)
	draw_rect(Rect2(Vector2(c.x - r.size.x * 0.28, base_y), Vector2(r.size.x * 0.56, 7)), WOOD)

func _draw_shore(r: Rect2) -> void:
	var water := Rect2(Vector2(0, r.size.y * 0.48), Vector2(r.size.x, r.size.y * 0.52))
	draw_rect(water, SEA)
	for i in 4:
		var y := water.position.y + 8.0 + float(i) * 10.0
		draw_arc(Vector2(r.size.x * (0.18 + 0.18 * i), y), 16.0, 0.1, PI - 0.1, 18, SEA_LINE, 1.3)
	var dock_y := r.size.y * 0.48
	draw_line(Vector2(r.size.x * 0.15, dock_y), Vector2(r.size.x * 0.78, dock_y + 18), WOOD, 8.0)
	for i in 4:
		var x := r.size.x * (0.18 + 0.13 * i)
		draw_line(Vector2(x, dock_y - 5), Vector2(x, dock_y + 24), Color(0.22, 0.13, 0.07), 2.0)
	var crate := Rect2(Vector2(r.size.x * 0.58, r.size.y * 0.22), Vector2(r.size.x * 0.22, r.size.y * 0.18))
	draw_rect(crate, WOOD)
	draw_rect(crate, BRASS, false, 1.4)
	draw_circle(Vector2(r.size.x * 0.33, r.size.y * 0.72), 7.0, BRASS_LIGHT)
	draw_line(Vector2(r.size.x * 0.28, r.size.y * 0.72), Vector2(r.size.x * 0.38, r.size.y * 0.72), INK, 1.2)

func _draw_blueprint(r: Rect2) -> void:
	var pad := minf(r.size.x, r.size.y) * 0.08
	var sheet := Rect2(r.position + Vector2(pad, pad), r.size - Vector2(pad * 2.0, pad * 2.0))
	draw_rect(sheet, Color(0.055, 0.12, 0.16))
	draw_rect(sheet, BRASS, false, 1.6)
	for i in 1: # draw a few steady construction lines without crowding.
		pass
	for i in 4:
		var x := sheet.position.x + sheet.size.x * float(i + 1) / 5.0
		draw_line(Vector2(x, sheet.position.y + 5), Vector2(x, sheet.end.y - 5), Color(0.20, 0.36, 0.42, 0.75), 1.0)
	for i in 3:
		var y := sheet.position.y + sheet.size.y * float(i + 1) / 4.0
		draw_line(Vector2(sheet.position.x + 5, y), Vector2(sheet.end.x - 5, y), Color(0.20, 0.36, 0.42, 0.75), 1.0)
	var c := sheet.get_center()
	draw_arc(c, sheet.size.y * 0.24, 0.0, TAU, 36, BRASS_LIGHT, 1.6)
	draw_line(c + Vector2(-sheet.size.x * 0.20, sheet.size.y * 0.18), c + Vector2(sheet.size.x * 0.20, -sheet.size.y * 0.18), BRASS_LIGHT, 2.0)
	draw_rect(Rect2(c + Vector2(-12, -7), Vector2(24, 14)), Color(0.09, 0.18, 0.22), false, 1.4)
