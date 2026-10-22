extends Control
## M1 gray-box: fully playable Classic loop, no art. Every number here is a
## placeholder that M2's FeelConfig will own. The point is to feel the twist
## with your thumb before spending a minute on polish.

const CELL := 72.0
const ORIGIN := Vector2(72, 300)
const SLOT_W := 208.0
const SLOT_H := 168.0
const SLOT_GAP := 24.0
const TRAY_Y := 1010.0

const C_BG := Color("120A2A")
const C_PANEL := Color("1E1140")
const C_EMPTY := Color("241652")
const C_MINT := Color("5CF2C0")
const C_PINK := Color("FF5FA2")
const C_BUTTER := Color("FFD166")
const C_SKY := Color("5AC8FA")
const C_PRISM := Color("F4F0FF")
const C_TEXT := Color("F4F0FF")
const C_DIM := Color("8A7AB8")

var state := RunState.new()

var drag_index := -1
var drag_pos := Vector2.ZERO
var shake := 0.0
var flash := 0.0
var popups: Array = []


func _ready() -> void:
	state.cleared.connect(_on_cleared)
	state.game_over.connect(_on_game_over)
	state.start(0)
	set_process(true)


func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta * 42.0)
	flash = maxf(0.0, flash - delta * 1.8)
	for p in popups:
		p.t += delta
	popups = popups.filter(func(p): return p.t < 0.9)
	queue_redraw()


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release()
	elif event is InputEventScreenDrag:
		drag_pos = event.position


func _press(pos: Vector2) -> void:
	if state.over:
		state.start(0)
		shake = 6.0
		return

	for i in state.tray.size():
		if state.used[i]:
			continue
		if _slot_rect(i).has_point(pos):
			drag_index = i
			drag_pos = pos
			Haptics.place()
			return


func _release() -> void:
	if drag_index < 0:
		return

	var piece: PieceLibrary.Piece = state.tray[drag_index]
	var origin := _ghost_origin(piece)

	if state.board.can_place(piece.cells, origin):
		state.place(drag_index, origin)
		Haptics.place()

	drag_index = -1
	queue_redraw()


func _ghost_origin(piece: PieceLibrary.Piece) -> Vector2i:
	var bounds := _bounds(piece.cells)
	var local := drag_pos - ORIGIN - Vector2(bounds) * CELL * 0.5
	return Vector2i(roundi(local.x / CELL), roundi(local.y / CELL))


# ---------------------------------------------------------------- events

func _on_cleared(result: ClearResult) -> void:
	flash = 0.45
	shake = 7.0 + 3.5 * minf(float(result.lines), 3.0)
	popups.append({
		"pos": ORIGIN + Vector2(Board.SIZE * CELL * 0.5, Board.SIZE * CELL * 0.5),
		"text": "+%d" % result.score,
		"t": 0.0,
	})

	if result.prisms > 0:
		Haptics.prism()
	elif result.lines > 1:
		Haptics.multi(result.lines)
	else:
		Haptics.line()


func _on_game_over() -> void:
	Haptics.multi(3)


# ---------------------------------------------------------------- drawing

func _slot_rect(i: int) -> Rect2:
	var n := state.tray.size()
	var total := n * SLOT_W + maxf(0.0, float(n - 1)) * SLOT_GAP
	var start_x := (720.0 - total) * 0.5
	return Rect2(Vector2(start_x + i * (SLOT_W + SLOT_GAP), TRAY_Y), Vector2(SLOT_W, SLOT_H))


func _bounds(cells: Array[Vector2i]) -> Vector2i:
	var w := 1
	var h := 1
	for c in cells:
		w = maxi(w, c.x + 1)
		h = maxi(h, c.y + 1)
	return Vector2i(w, h)


func _color(value: int) -> Color:
	match value:
		1: return C_MINT
		2: return C_PINK
		3: return C_BUTTER
		4: return C_SKY
		Board.PRISM: return C_PRISM
		_: return C_EMPTY


func _draw_block(pos: Vector2, cell: float, col: Color, alpha: float = 1.0, inset: float = 3.0) -> void:
	var r := Rect2(pos + Vector2(inset, inset), Vector2(cell - inset * 2.0, cell - inset * 2.0))
	var c := col
	c.a *= alpha
	draw_rect(r, c, true)
	# fake bevel highlight — cheap, but it already reads as "solid"
	draw_rect(Rect2(r.position, Vector2(r.size.x, maxf(2.0, cell * 0.06))), Color(1, 1, 1, 0.28 * alpha), true)


func _draw() -> void:
	var offset := Vector2.ZERO
	if shake > 0.5:
		offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))

	draw_set_transform(offset)

	# background
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), C_BG, true)

	# HUD
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(72, 118), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_DIM)
	draw_string(font, Vector2(72, 204), str(state.score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, C_TEXT)
	draw_string(font, Vector2(500, 118), "COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_DIM)
	draw_string(font, Vector2(500, 186), "x%d" % maxi(state.combo, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 52,
		C_MINT if state.combo > 1 else C_DIM)

	# core charge pips
	for i in RunState.CHARGE_REQUIRED:
		var pip := Vector2(72 + i * 40, 236)
		draw_circle(pip, 12.0, C_PRISM if i < state.charges else Color(1, 1, 1, 0.12))

	# board panel
	draw_rect(Rect2(ORIGIN - Vector2(16, 16), Vector2(Board.SIZE * CELL + 32, Board.SIZE * CELL + 32)), C_PANEL, true)

	for y in Board.SIZE:
		for x in Board.SIZE:
			var p := Vector2i(x, y)
			var pos := ORIGIN + Vector2(x, y) * CELL
			var value := state.board.get_cell(p)
			if value == Board.EMPTY:
				_draw_block(pos, CELL, C_EMPTY, 0.55, 4.0)
			elif value == Board.PRISM:
				_draw_block(pos, CELL, C_PRISM, 1.0, 3.0)
				draw_rect(Rect2(pos + Vector2(10, 10), Vector2(CELL - 20, CELL - 20)), Color(0.36, 0.95, 0.75, 0.9), false, 3.0)
			else:
				_draw_block(pos, CELL, _color(value))

	# ghost
	if drag_index >= 0:
		var piece: PieceLibrary.Piece = state.tray[drag_index]
		var origin := _ghost_origin(piece)
		var ok := state.board.can_place(piece.cells, origin)
		var tint := Color(0.36, 0.95, 0.75, 0.4) if ok else Color(1.0, 0.3, 0.35, 0.4)
		for c in piece.cells:
			var p := Vector2i(origin + c)
			if state.board.in_bounds(p):
				_draw_block(ORIGIN + Vector2(p) * CELL, CELL, tint, 1.0, 4.0)

	# tray
	for i in state.tray.size():
		var rect := _slot_rect(i)
		draw_rect(rect, Color(1, 1, 1, 0.04), true)
		if state.used[i]:
			continue
		var piece: PieceLibrary.Piece = state.tray[i]
		if i == drag_index:
			continue
		var bounds := _bounds(piece.cells)
		var cell := minf(52.0, minf((SLOT_W - 48.0) / bounds.x, (SLOT_H - 36.0) / bounds.y))
		var center := rect.get_center()
		var top_left := center - Vector2(bounds) * cell * 0.5
		for c in piece.cells:
			_draw_block(top_left + Vector2(c) * cell, cell, _color(state.colors[i]))

	# dragged piece follows the finger
	if drag_index >= 0:
		var piece: PieceLibrary.Piece = state.tray[drag_index]
		var bounds := _bounds(piece.cells)
		var cell := CELL
		var top_left := drag_pos - Vector2(bounds) * cell * 0.5
		for c in piece.cells:
			_draw_block(top_left + Vector2(c) * cell, cell, _color(state.colors[drag_index]), 0.95)

	# score popups
	for p in popups:
		var k: float = p.t / 0.9
		var pos: Vector2 = p.pos + Vector2(-160.0, -70.0 * k)
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, 320, 56, Color(1, 1, 1, 1.0 - k))

	# hit flash
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(1, 1, 1, flash * 0.22), true)

	# game over
	if state.over:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(0.07, 0.04, 0.16, 0.82), true)
		draw_string(font, Vector2(0, 560), "NO MOVES", HORIZONTAL_ALIGNMENT_CENTER, 720, 64, C_TEXT)
		draw_string(font, Vector2(0, 640), "score  %d" % state.score, HORIZONTAL_ALIGNMENT_CENTER, 720, 34, C_DIM)
		draw_string(font, Vector2(0, 760), "tap to run again", HORIZONTAL_ALIGNMENT_CENTER, 720, 28, C_MINT)

	draw_set_transform(Vector2.ZERO)
