class_name OceanGrid
extends RefCounted
## Polar ring/sector abstraction for the ocean board (Docs/OCEAN_MODEL_SPEC.md).
## Boats move continuously in 2D; rings and sectors are the design/debug layer
## used for spawn distance, weapon ranges, visibility falloff, and overlays.
## The lighthouse is always at world origin.

enum Ring { SHORE, SHALLOWS, MIDWATER, DEEP, HORIZON }

const SECTOR_COUNT: int = 16

## Outer radius of each ring, in world pixels, indexed by Ring.
## Sized so the whole board fits a 1280x720 window with an unzoomed camera.
## TODO(tide): tide state should later shift effective depth per ring
## (rock passability, boat approach limits) without moving these radii.
const RING_RADII: Array[float] = [55.0, 115.0, 190.0, 265.0, 335.0]

const ISLAND_RADIUS: float = 35.0

static func ring_radius(ring: Ring) -> float:
	return RING_RADII[ring]

## Ring index containing a world position (HORIZON also covers beyond-board).
static func ring_at(pos: Vector2) -> int:
	var dist := pos.length()
	for i in RING_RADII.size():
		if dist <= RING_RADII[i]:
			return i
	return Ring.HORIZON

static func sector_at(pos: Vector2) -> int:
	var angle := wrapf(pos.angle(), 0.0, TAU)
	return int(angle / (TAU / SECTOR_COUNT)) % SECTOR_COUNT

static func sector_center_angle(sector: int) -> float:
	return (float(sector) + 0.5) * TAU / SECTOR_COUNT

static func polar(angle: float, radius: float) -> Vector2:
	return Vector2.from_angle(angle) * radius
