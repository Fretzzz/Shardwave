extends Control
## Prism Resonance presentation. Beams, detonation rings, sparks, line flashes.
##
## The rules live in core/. This node only choreographs what ClearResult reports:
## wave 0 flashes the completed lines, every recording prism fires a cross-beam,
## and each detonation is staggered so a chain reads as a chain.

const BEAM_GROW := 0.14
const BEAM_HOLD := 0.04
const BEAM_FADE := 0.34
const DETONATE_STAGGER := 0.10
const BAND_LIFE := 0.34
const RING_LIFE := 0.50
const MAX_SPARKS := 260

var origin := Vector2.ZERO
var cell := 72.0
var shake := Vector2.ZERO

var _t := 0.0
var _beams: Array = []
var _rings: Array = []
var _sparks: Array = []
var _bands: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func bind(board_origin: Vector2, cell_size: float) -> void:
	origin = board_origin
	cell = cell_size


func clear_all() -> void:
	_beams.clear()
	_rings.clear()
	_sparks.clear()
	_bands.clear()
	_t = 0.0
	set_process(false)
	queue_redraw()


func play(result: ClearResult) -> void:
	if not result.waves.is_empty():
		_add_bands(result.waves[0])

	for i in result.prisms_at.size():
		var p: Vector2i = result.prisms_at[i]
		_beams.append({"p": p, "t0": i * DETONATE_STAGGER, "seen": false})
		_rings.append({"p": p, "t0": i * DETONATE_STAGGER})

	var budget := MAX_SPARKS - _sparks.size()
	for p in result.cells:
		if budget <= 0:
			break
		for k in 2:
			_spark(_center(p), 90.0)
			budget -= 1

	set_process(true)


# ---------------------------------------------------------------- simulation

func _process(delta: float) -> void:
	_t += delta

	for s in _sparks:
		s["pos"] = s["pos"] + s["vel"] * delta
		s["vel"] = s["vel"] * 0.90
		s["t"] = s["t"] + delta
	_sparks = _sparks.filter(func(s): return s["t"] < s["life"])

	for b in _beams:
		if not b["seen"] and _t >= b["t0"]:
			b["seen"] = true
			_beam_sparks(b["p"])

	_beams = _beams.filter(func(b): return _t < b["t0"] + BEAM_GROW + BEAM_HOLD + BEAM_FADE)
	_rings = _rings.filter(func(r): return _t < r["t0"] + RING_LIFE)
	_bands = _bands.filter(func(b): return _t < b["t0"] + BAND_LIFE)

	if _beams.is_empty() and _rings.is_empty() and _sparks.is_empty() and _bands.is_empty():
		set_process(false)
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	for b in _bands:
		var e: float = _t - b["t0"]
		if e < 0.0:
			continue
		var a: float = (1.0 - clampf(e / BAND_LIFE, 0.0, 1.0)) * 0.20
		var r: Rect2 = b["rect"]
		draw_rect(Rect2(r.position + shake, r.size), Color(0.36, 0.95, 0.75, a), true)

	for b in _beams:
		var e: float = _t - b["t0"]
		if e >= 0.0:
			_draw_beam(b["p"], e)

	for r in _rings:
		var e: float = _t - r["t0"]
		if e < 0.0:
			continue
		var k: float = clampf(e / RING_LIFE, 0.0, 1.0)
		var c: Vector2 = _center(r["p"]) + shake
		draw_arc(c, cell * (0.28 + 1.10 * k), 0.0, TAU, 40,
			Color(1, 1, 1, (1.0 - k) * 0.80), 6.0 * (1.0 - k) + 1.0, true)
		draw_arc(c, cell * (0.18 + 0.80 * k), 0.0, TAU, 40,
			Color(0.36, 0.95, 0.75, (1.0 - k) * 0.45), 12.0 * (1.0 - k) + 1.0, true)

	for s in _sparks:
		var a: float = 1.0 - float(s["t"]) / float(s["life"])
		draw_circle(s["pos"] + shake, float(s["size"]) * a, Color(s["col"], a))


func _draw_beam(p: Vector2i, e: float) -> void:
	var grow: float = clampf(e / BEAM_GROW, 0.0, 1.0)
	var fade := 1.0
	if e > BEAM_GROW + BEAM_HOLD:
		fade = clampf(1.0 - (e - BEAM_GROW - BEAM_HOLD) / BEAM_FADE, 0.0, 1.0)
	if fade <= 0.0:
		return

	var c: Vector2 = _center(p) + shake
	var left := origin.x + shake.x
	var right := origin.x + Board.SIZE * cell + shake.x
	var top := origin.y + shake.y
	var bottom := origin.y + Board.SIZE * cell + shake.y

	var lx: float = lerpf(c.x, left, grow)
	var rx: float = lerpf(c.x, right, grow)
	var ty: float = lerpf(c.y, top, grow)
	var by: float = lerpf(c.y, bottom, grow)

	_beam_line(Vector2(lx, c.y), Vector2(rx, c.y), fade)
	_beam_line(Vector2(c.x, ty), Vector2(c.x, by), fade)
	draw_circle(c, 7.0 * fade, Color(1, 1, 1, fade))


func _beam_line(a: Vector2, b: Vector2, fade: float) -> void:
	draw_line(a, b, Color(0.36, 0.95, 0.75, 0.20 * fade), 26.0, true)
	draw_line(a, b, Color(0.55, 0.98, 0.85, 0.55 * fade), 9.0, true)
	draw_line(a, b, Color(1, 1, 1, 0.95 * fade), 3.0, true)


# ---------------------------------------------------------------- emitters

func _add_bands(wave: Array[Vector2i]) -> void:
	var rows := {}
	var cols := {}
	for p in wave:
		rows[p.y] = rows.get(p.y, 0) + 1
		cols[p.x] = cols.get(p.x, 0) + 1

	for y in rows:
		if rows[y] >= Board.SIZE:
			_bands.append({
				"rect": Rect2(origin.x, origin.y + y * cell, Board.SIZE * cell, cell),
				"t0": 0.0,
			})
	for x in cols:
		if cols[x] >= Board.SIZE:
			_bands.append({
				"rect": Rect2(origin.x + x * cell, origin.y, cell, Board.SIZE * cell),
				"t0": 0.0,
			})


func _beam_sparks(p: Vector2i) -> void:
	var c := _center(p)
	for i in 14:
		var along := randf_range(0.0, Board.SIZE * cell)
		if i % 2 == 0:
			_spark(Vector2(origin.x + along, c.y), 210.0)
		else:
			_spark(Vector2(c.x, origin.y + along), 210.0)


func _spark(pos: Vector2, speed: float) -> void:
	if _sparks.size() >= MAX_SPARKS:
		return
	var ang := randf() * TAU
	var col := Color(0.36, 0.95, 0.75) if randf() < 0.72 else Color(1, 1, 1)
	_sparks.append({
		"pos": pos,
		"vel": Vector2(cos(ang), sin(ang)) * randf_range(speed * 0.20, speed),
		"t": 0.0,
		"life": randf_range(0.25, 0.55),
		"size": randf_range(1.5, 3.6),
		"col": col,
	})


func _center(p: Vector2i) -> Vector2:
	return origin + (Vector2(p) + Vector2(0.5, 0.5)) * cell
