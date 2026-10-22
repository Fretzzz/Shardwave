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

const RESUME_RECT := Rect2(130, 620, 460, 110)
const QUIT_RECT := Rect2(130, 760, 460, 96)

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
@onready var fx: Control = $Fx

var drag_index := -1
var drag_pos := Vector2.ZERO
var shake := 0.0
var shake_offset := Vector2.ZERO
var flash := 0.0
var paused := false
var ending := false
var popups: Array = []

## Void Rush clock. Starts on the first placement, not on scene load.
var rush_time := 0.0
var rush_started := false
var rush_elapsed := 0.0
var time_up := false


func _ready() -> void:
	fx.bind(ORIGIN, CELL)
	state.cleared.connect(_on_cleared)
	state.game_over.connect(_on_game_over)
	state.start(Session.run_seed)
	if Session.mode == "rush":
		rush_time = ModeRules.RUSH_START
	set_process(true)


func _process(delta: float) -> void:
	if Session.mode == "rush" and rush_started and not state.over and not paused:
		rush_elapsed += delta
		rush_time -= delta
		if rush_time <= 0.0:
			rush_time = 0.0
			time_up = true
			state.timeout()

	shake = maxf(0.0, shake - delta * 42.0)
	flash = maxf(0.0, flash - delta * 1.8)
	shake_offset = Vector2.ZERO
	if shake > 0.5:
		shake_offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	fx.shake = shake_offset
	for p in popups:
		p.t += delta
	popups = popups.filter(func(p): return p.t < 0.9)
	queue_redraw()


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not ending:
			_toggle_pause()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release()
	elif event is InputEventScreenDrag and not paused and not ending:
		drag_pos = event.position


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if not ending:
				_toggle_pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# never lose a run to the notification shade or a phone call
			_pause()


func _pause() -> void:
	if paused or ending:
		return
	paused = true
	drag_index = -1
	queue_redraw()


func _toggle_pause() -> void:
	if paused:
		paused = false
		drag_index = -1
	else:
		_pause()
	queue_redraw()


func _press(pos: Vector2) -> void:
	if paused:
		if RESUME_RECT.has_point(pos):
			paused = false
			Audio.ui()
			Haptics.pulse(15, 0.5)
		elif QUIT_RECT.has_point(pos):
			Audio.ui()
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
			return
		queue_redraw()
		return

	if ending:
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
	if drag_index < 0 or paused or ending:
		return

	var piece: PieceLibrary.Piece = state.tray[drag_index]
	var origin := _ghost_origin(piece)

	if state.board.can_place(piece.cells, origin):
		if state.place(drag_index, origin) != null:
			Audio.place()
			Haptics.place()
			if Session.mode == "rush":
				rush_started = true

	drag_index = -1
	queue_redraw()


func _ghost_origin(piece: PieceLibrary.Piece) -> Vector2i:
	var bounds := _bounds(piece.cells)
	var local := drag_pos - ORIGIN - Vector2(bounds) * CELL * 0.5
	return Vector2i(roundi(local.x / CELL), roundi(local.y / CELL))


# ---------------------------------------------------------------- events

func _on_cleared(result: ClearResult) -> void:
	if Session.mode == "rush":
		rush_time = minf(rush_time + ModeRules.rush_bonus(result), ModeRules.RUSH_MAX)

	flash = 0.52 if result.prisms > 0 else 0.30
	shake = 6.0 + 3.0 * minf(float(result.lines), 3.0) + 2.5 * float(result.chain_depth)
	if result.prisms > 0:
		shake += 6.0
	fx.play(result)
	popups.append({
		"pos": ORIGIN + Vector2(Board.SIZE * CELL * 0.5, Board.SIZE * CELL * 0.5),
		"text": "+%d" % result.score,
		"t": 0.0,
		"prism": result.prisms > 0,
	})

	if result.prisms > 0:
		Audio.prism()
		Haptics.prism()
	elif result.lines > 1:
		Audio.multi(result.lines)
		Haptics.multi(result.lines)
	else:
		Audio.line()
		Haptics.line()


func _on_game_over() -> void:
	Audio.over()
	Haptics.multi(3)
	ending = true
	await get_tree().create_timer(0.9).timeout
	var extra := {}
	if Session.mode == "rush":
		extra["time"] = rush_elapsed
	Session.finish(state.score, state.lines_total, state.prisms_total, state.placements, extra)
	get_tree().change_scene_to_file("res://scenes/Results.tscn")


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
	# vertical gradient fill reads as a glass shard without a per-block material
	var top := col.lightened(0.18)
	top.a = col.a * alpha
	var bottom := col.darkened(0.26)
	bottom.a = col.a * alpha
	draw_polygon(
		PackedVector2Array([
			r.position,
			Vector2(r.end.x, r.position.y),
			r.end,
			Vector2(r.position.x, r.end.y),
		]),
		PackedColorArray([top, top, bottom, bottom]))
	# glass: top highlight + hairline edge
	draw_rect(Rect2(r.position, Vector2(r.size.x, maxf(2.0, cell * 0.07))),
		Color(1, 1, 1, 0.30 * alpha), true)
	draw_rect(r, Color(1, 1, 1, 0.10 * alpha), false, 1.0)


func _draw() -> void:
	draw_set_transform(shake_offset)

	# translucent veil: the aurora shader owns the background, this only
	# guarantees contrast behind the board.
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(C_BG, 0.45), true)

	# HUD
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(72, 118), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_DIM)
	draw_string(font, Vector2(72, 204), str(state.score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, C_TEXT)

	if Session.mode == "rush":
		var secs := ceili(rush_time)
		var hot := rush_started and secs <= 10
		var time_col := C_PINK if hot else C_TEXT
		draw_string(font, Vector2(500, 118), "TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_DIM)
		draw_string(font, Vector2(500, 186), "%d:%02d" % [secs / 60, secs % 60],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 52, time_col)
		draw_string(font, Vector2(500, 236), "BEST %s" % Ui.thousands(Save.best_rush),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_DIM)
		draw_string(font, Vector2(500, 274), "COMBO x%d" % maxi(state.combo, 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_MINT if state.combo > 1 else C_DIM)
		var ratio := clampf(rush_time / ModeRules.RUSH_START, 0.0, 1.0)
		draw_rect(Rect2(72, 276, 380, 5), Color(1, 1, 1, 0.08), true)
		draw_rect(Rect2(72, 276, 380 * ratio, 5), time_col, true)
	elif Session.mode == "daily":
		draw_string(font, Vector2(500, 118), "SHARD #%d" % Session.daily_shard,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_MINT)
		draw_string(font, Vector2(500, 186), "x%d" % maxi(state.combo, 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 52, C_MINT if state.combo > 1 else C_DIM)
		draw_string(font, Vector2(500, 236), "BEST %s" % Ui.thousands(Save.best_daily),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_DIM)
	else:
		draw_string(font, Vector2(500, 118), "COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_DIM)
		draw_string(font, Vector2(500, 186), "x%d" % maxi(state.combo, 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 52, C_MINT if state.combo > 1 else C_DIM)
		draw_string(font, Vector2(500, 236), "BEST %s" % Ui.thousands(Save.best_classic),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_DIM)

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
		var tint := C_MINT if p.get("prism", false) else Color(1, 1, 1, 1.0 - k)
		tint.a *= 1.0 - k
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, 320, 56, tint)

	# hit flash
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(1, 1, 1, flash * 0.22), true)

	# game over — the results scene takes over after the wind-down
	if state.over:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(0.07, 0.04, 0.16, 0.82), true)
		var headline := "TIME UP" if time_up else "NO MOVES"
		draw_string(font, Vector2(0, 560), headline, HORIZONTAL_ALIGNMENT_CENTER, 720, 64, C_TEXT)
		draw_string(font, Vector2(0, 640), "score  %s" % Ui.thousands(state.score),
			HORIZONTAL_ALIGNMENT_CENTER, 720, 34, C_DIM)

	draw_set_transform(Vector2.ZERO)

	if paused:
		_draw_pause(font)


func _draw_pause(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color(0.04, 0.02, 0.10, 0.86), true)
	draw_string(font, Vector2(0, 500), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 720, 56, C_TEXT)
	draw_string(font, Vector2(0, 556), "score  %s" % Ui.thousands(state.score),
		HORIZONTAL_ALIGNMENT_CENTER, 720, 24, C_DIM)
	if Session.mode == "rush":
		var secs := ceili(rush_time)
		draw_string(font, Vector2(0, 592), "time  %d:%02d" % [secs / 60, secs % 60],
			HORIZONTAL_ALIGNMENT_CENTER, 720, 24, C_MINT)
	elif Session.mode == "daily":
		draw_string(font, Vector2(0, 592), "shard #%d" % Session.daily_shard,
			HORIZONTAL_ALIGNMENT_CENTER, 720, 24, C_MINT)

	Ui.panel(self, RESUME_RECT, C_MINT, C_MINT.darkened(0.30), 2.0, false)
	Ui.label(self, Vector2(RESUME_RECT.position.x, RESUME_RECT.position.y + 70), "RESUME", 36,
		C_BG, HORIZONTAL_ALIGNMENT_CENTER, RESUME_RECT.size.x)

	Ui.panel(self, QUIT_RECT, Color(C_PANEL, 0.70), Color(1, 1, 1, 0.10), 2.0)
	Ui.label(self, Vector2(QUIT_RECT.position.x, QUIT_RECT.position.y + 62), "QUIT TO MENU", 28,
		C_DIM, HORIZONTAL_ALIGNMENT_CENTER, QUIT_RECT.size.x)
