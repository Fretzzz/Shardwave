extends SceneTree
## Headless correctness tests for the pure core.
## Run: godot --headless --path . --script res://tests/CoreTests.gd

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_test_single_row()
	_test_simultaneous_cross()
	_test_prism_cross()
	_test_prism_chain()
	_test_no_clear()
	_test_purity()
	_test_placement_rules()
	_test_scoring()
	_test_deterministic_deal()
	_test_run_counters()
	_test_mode_rules()
	_test_timeout()

	if failures.is_empty():
		print("PASS  %d checks" % checks)
		quit(0)
	else:
		for f in failures:
			printerr("FAIL  " + f)
		printerr("%d of %d checks failed" % [failures.size(), checks])
		quit(1)


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func dot() -> Array[Vector2i]:
	return [Vector2i.ZERO]


func fill_row(board: Board, y: int, upto_x: int, value: int) -> void:
	for x in upto_x:
		board.place(dot(), Vector2i(x, y), value)


func fill_col(board: Board, x: int, upto_y: int, value: int) -> void:
	for y in upto_y:
		board.place(dot(), Vector2i(x, y), value)


func _test_single_row() -> void:
	var b := Board.new()
	fill_row(b, 0, 7, 1)
	b.place(dot(), Vector2i(7, 0), 2)
	var r := ClearResolver.resolve(b, 1)
	check(r.lines == 1, "single row: lines")
	check(r.cell_count == 8, "single row: 8 cells, got %d" % r.cell_count)
	check(b.filled_count() == 0, "single row: board emptied")
	check(r.score == 80, "single row: score 80, got %d" % r.score)
	check(r.chain_depth == 0, "single row: no chain")


func _test_simultaneous_cross() -> void:
	var b := Board.new()
	fill_row(b, 0, 8, 1)   # row 0 complete
	fill_col(b, 0, 8, 1)   # col 0 complete
	var r := ClearResolver.resolve(b, 1)
	check(r.lines == 2, "cross: 2 lines, got %d" % r.lines)
	check(r.cell_count == 15, "cross: 15 cells, got %d" % r.cell_count)
	check(r.score == 225, "cross: simultaneous bonus = 225, got %d" % r.score)
	check(b.filled_count() == 0, "cross: board emptied")


## A prism is a wildcard: it completes the row, then its beam clears the column.
func _test_prism_cross() -> void:
	var b := Board.new()
	fill_row(b, 0, 6, 1)
	b.place(dot(), Vector2i(6, 0), Board.PRISM)
	b.place(dot(), Vector2i(7, 0), 2)
	var r := ClearResolver.resolve(b, 1)
	check(r.lines == 1, "prism cross: 1 completed line")
	check(r.prisms == 1, "prism cross: 1 prism, got %d" % r.prisms)
	check(r.prisms_at == [Vector2i(6, 0)], "prism cross: detonation position, got %s" % str(r.prisms_at))
	check(r.chain_depth == 1, "prism cross: depth 1, got %d" % r.chain_depth)
	check(r.cell_count == 15, "prism cross: 15 cells, got %d" % r.cell_count)
	check(b.filled_count() == 0, "prism cross: board emptied")
	check(r.score == 225, "prism cross: 150 * 1.5 = 225, got %d" % r.score)


## Prism -> prism: the beam catches a second prism and detonates it too.
func _test_prism_chain() -> void:
	var b := Board.new()
	b.place(dot(), Vector2i(0, 0), Board.PRISM)
	b.place(dot(), Vector2i(0, 5), Board.PRISM)
	for x in range(1, 8):
		b.place(dot(), Vector2i(x, 0), 1)
	var r := ClearResolver.resolve(b, 1)
	check(r.prisms == 2, "chain: 2 prisms, got %d" % r.prisms)
	check(r.prisms_at.size() == 2 and r.prisms_at.has(Vector2i(0, 0)) and r.prisms_at.has(Vector2i(0, 5)),
		"chain: both detonation positions, got %s" % str(r.prisms_at))
	check(r.chain_depth == 2, "chain: depth 2, got %d" % r.chain_depth)
	check(r.cell_count == 22, "chain: 22 cells, got %d" % r.cell_count)
	check(r.waves.size() == 3, "chain: 3 waves, got %d" % r.waves.size())
	check(b.filled_count() == 0, "chain: board emptied")


func _test_no_clear() -> void:
	var b := Board.new()
	b.place(dot(), Vector2i(3, 3), 1)
	var r := ClearResolver.resolve(b, 1)
	check(r.lines == 0 and r.cell_count == 0 and r.score == 0, "no clear: empty result")
	check(b.filled_count() == 1, "no clear: block stays")


func _test_purity() -> void:
	var b := Board.new()
	for x in 6:
		b.place(dot(), Vector2i(x, 0), 1)
	b.place(dot(), Vector2i(6, 0), 2)
	b.place(dot(), Vector2i(7, 0), 3)
	var r := ClearResolver.resolve(b, 1)
	check(r.pure_lines == 1, "purity: 6/8 same color counts as pure")

	var b2 := Board.new()
	for x in 4:
		b2.place(dot(), Vector2i(x, 0), 1)
	for x in range(4, 8):
		b2.place(dot(), Vector2i(x, 0), 2)
	var r2 := ClearResolver.resolve(b2, 1)
	check(r2.pure_lines == 0, "purity: 4/4 split is not pure")


func _test_placement_rules() -> void:
	var b := Board.new()
	b.place(dot(), Vector2i(0, 0), 1)
	check(not b.can_place(dot(), Vector2i(0, 0)), "overlap rejected")
	check(not b.can_place(dot(), Vector2i(8, 0)), "out of bounds rejected")
	check(not b.can_place(dot(), Vector2i(-1, 0)), "negative rejected")
	check(b.can_place([Vector2i(0, 0), Vector2i(1, 0)], Vector2i(6, 7)), "valid shape accepted")
	check(not b.can_place([Vector2i(0, 0), Vector2i(1, 0)], Vector2i(7, 7)), "overflowing shape rejected")


func _test_scoring() -> void:
	check(Scorer.line_score(1, 8, 1, 0) == 80, "score: base")
	check(Scorer.line_score(1, 8, 2, 0) == 100, "score: combo 2 = 1.25x")
	check(Scorer.line_score(1, 8, 1, 1) == 120, "score: chain 1 = 1.5x")
	check(Scorer.line_score(3, 24, 4, 2) == 1890, "score: stacked multipliers, got %d" % Scorer.line_score(3, 24, 4, 2))


func _test_deterministic_deal() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 12345
	var b := RandomNumberGenerator.new()
	b.seed = 12345
	var tray_a := PieceLibrary.deal(a, 3)
	var tray_b := PieceLibrary.deal(b, 3)
	var same := true
	for i in 3:
		if tray_a[i].shape_name != tray_b[i].shape_name:
			same = false
	check(same, "deal: same seed gives same tray")
	check(tray_a.size() == 3, "deal: 3 pieces")


## RunState wiring: totals, score mirror, and tray refill after the last piece.
func _test_run_counters() -> void:
	var s := RunState.new()
	s.start(7)
	for x in 7:
		s.board.place(dot(), Vector2i(x, 0), 2)

	var piece := PieceLibrary.Piece.new()
	piece.shape_name = "dot"
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	piece.cells = cells
	piece.weight = 3
	var colors: Array[int] = [1]
	var used: Array[bool] = [false]
	s.tray = [piece]
	s.colors = colors
	s.used = used

	var r := s.place(0, Vector2i(7, 0))
	check(r != null and r.lines == 1, "run: single-line placement resolved")
	check(s.lines_total == 1, "run: lines_total, got %d" % s.lines_total)
	check(s.clears == 1, "run: clears, got %d" % s.clears)
	check(s.prisms_total == 0, "run: no prisms on a plain line")
	check(s.score == r.score and s.score > 0, "run: score mirrored")
	check(s.tray.size() == 3, "run: tray refilled, got %d" % s.tray.size())


## Mode rules: time bonus and the daily seed/calendar are pure math.
func _test_mode_rules() -> void:
	var r := ClearResult.new()
	r.lines = 2
	r.prisms = 1
	check(ModeRules.rush_bonus(r) == 7.0, "rules: 2 lines + 1 prism = 7s, got %s" % ModeRules.rush_bonus(r))

	var plain := ClearResult.new()
	plain.lines = 3
	check(ModeRules.rush_bonus(plain) == 4.5, "rules: 3 plain lines = 4.5s")

	var d := {"year": 2026, "month": 10, "day": 22}
	check(ModeRules.daily_seed(d) == 20261022, "rules: daily seed, got %d" % ModeRules.daily_seed(d))
	check(ModeRules.date_key(d) == "2026-10-22", "rules: date key, got %s" % ModeRules.date_key(d))
	check(ModeRules.shard_number(d) == 1022, "rules: shard number, got %d" % ModeRules.shard_number(d))
	check(ModeRules.previous_day_key("2026-10-22") == "2026-10-21", "rules: previous day")
	check(ModeRules.previous_day_key("2026-03-01") == "2026-02-28", "rules: previous day across a month")
	check(ModeRules.previous_day_key("2026-01-01") == "2025-12-31", "rules: previous day across a year")


## Void Rush ends when its clock hits zero, and only once.
func _test_timeout() -> void:
	var s := RunState.new()
	s.start(7)
	var fired := [0]
	s.game_over.connect(func(): fired[0] += 1)
	s.timeout()
	check(s.over, "timeout: run is over")
	check(fired[0] == 1, "timeout: game_over emitted once, got %d" % fired[0])
	s.timeout()
	check(fired[0] == 1, "timeout: second call is a no-op")
