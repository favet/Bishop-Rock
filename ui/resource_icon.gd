class_name ResourceIcon
extends Control
## Code-drawn brass resource icon: every icon shares the same iron plate,
## brass rim, and brass/dark palette so the set reads as one family.
## Placeholder for a real art pass, but deliberately not emoji or clip art.

const BRASS := Color(0.80, 0.60, 0.26)
const BRASS_LIGHT := Color(0.94, 0.80, 0.45)
const BRASS_DEEP := Color(0.52, 0.38, 0.15)
const PLATE := Color(0.11, 0.115, 0.11)
const DARK := Color(0.07, 0.06, 0.045)

var kind: String

func _init(resource_kind: String = "gold", size_px: float = 24.0) -> void:
	kind = resource_kind
	custom_minimum_size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	draw_circle(c, s * 0.50, PLATE)
	draw_arc(c, s * 0.46, 0.0, TAU, 32, BRASS_DEEP, maxf(s * 0.07, 1.5), true)
	match kind:
		"gold":
			draw_circle(c, s * 0.28, BRASS)
			draw_arc(c, s * 0.28, 0.0, TAU, 24, BRASS_LIGHT, 1.5, true)
			draw_arc(c, s * 0.17, 0.0, TAU, 20, BRASS_DEEP, 1.2, true)
		"wood":
			_bar(c + Vector2(0, -s * 0.14), s * 0.56, s * 0.14, deg_to_rad(-8), BRASS)
			_bar(c + Vector2(0, s * 0.06), s * 0.60, s * 0.14, deg_to_rad(4), BRASS_LIGHT)
			_bar(c + Vector2(0, s * 0.25), s * 0.52, s * 0.14, deg_to_rad(-3), BRASS_DEEP)
		"scrap":
			var pts := PackedVector2Array([
				c + Vector2(-s * 0.28, s * 0.18), c + Vector2(-s * 0.10, -s * 0.30),
				c + Vector2(s * 0.16, -s * 0.20), c + Vector2(s * 0.30, s * 0.06),
				c + Vector2(s * 0.06, s * 0.30),
			])
			draw_colored_polygon(pts, BRASS)
			draw_circle(c + Vector2(-s * 0.08, -s * 0.02), s * 0.06, DARK)
			draw_circle(c + Vector2(s * 0.12, s * 0.10), s * 0.05, DARK)
		"food":
			var body := PackedVector2Array([
				c + Vector2(-s * 0.30, 0), c + Vector2(-s * 0.08, -s * 0.16),
				c + Vector2(s * 0.14, -s * 0.10), c + Vector2(s * 0.14, s * 0.10),
				c + Vector2(-s * 0.08, s * 0.16),
			])
			draw_colored_polygon(body, BRASS)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(s * 0.12, 0), c + Vector2(s * 0.30, -s * 0.16),
				c + Vector2(s * 0.30, s * 0.16),
			]), BRASS_DEEP)
			draw_circle(c + Vector2(-s * 0.18, -s * 0.04), s * 0.045, DARK)
		"daylight":
			draw_circle(c, s * 0.20, BRASS_LIGHT)
			for i in 8:
				var dir := Vector2.from_angle(TAU * float(i) / 8.0)
				draw_line(c + dir * s * 0.27, c + dir * s * 0.40, BRASS, maxf(s * 0.07, 1.5))
		"hull":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 0.13, s * 0.30), c + Vector2(-s * 0.08, -s * 0.14),
				c + Vector2(s * 0.08, -s * 0.14), c + Vector2(s * 0.13, s * 0.30),
			]), BRASS)
			draw_rect(Rect2(c + Vector2(-s * 0.11, -s * 0.26), Vector2(s * 0.22, s * 0.10)), BRASS_LIGHT)
			draw_circle(c + Vector2(0, -s * 0.30), s * 0.07, BRASS_LIGHT)
		"mines":
			draw_circle(c, s * 0.22, BRASS)
			draw_circle(c, s * 0.10, BRASS_DEEP)
			for i in 6:
				var dir := Vector2.from_angle(TAU * float(i) / 6.0 + 0.4)
				draw_line(c + dir * s * 0.22, c + dir * s * 0.36, BRASS, maxf(s * 0.08, 1.5))
		"barricades":
			_bar(c, s * 0.62, s * 0.13, deg_to_rad(38), BRASS)
			_bar(c, s * 0.62, s * 0.13, deg_to_rad(-38), BRASS_DEEP)
		"day":
			draw_line(c + Vector2(-s * 0.30, s * 0.14), c + Vector2(s * 0.30, s * 0.14), BRASS_DEEP, maxf(s * 0.07, 1.5))
			draw_circle(c + Vector2(0, s * 0.02), s * 0.16, BRASS_LIGHT)
			for i in 3:
				var dir := Vector2.from_angle(PI + PI * float(i + 1) / 4.0)
				draw_line(c + dir * s * 0.22, c + dir * s * 0.34, BRASS, maxf(s * 0.06, 1.2))
		_:
			draw_circle(c, s * 0.22, BRASS)

func _bar(center: Vector2, length: float, width: float, angle: float, color: Color) -> void:
	var dir := Vector2.from_angle(angle)
	var n := dir.orthogonal() * width * 0.5
	var a := center - dir * length * 0.5
	var b := center + dir * length * 0.5
	draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), color)

static func kind_for(resource_key: String) -> String:
	match resource_key:
		"energy_today", "tomorrow_daylight", "daylight_work":
			return "daylight"
		"gold", "wood", "scrap", "food", "hull", "mines", "barricades", "day":
			return resource_key
	return ""
