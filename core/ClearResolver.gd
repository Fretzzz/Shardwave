class_name ClearResolver
extends RefCounted
## Resolves one placement into a full clear event, including prism cascades.
##
## Determinism contract: rows are scanned ascending, then columns ascending,
## then prism waves in row-major order. Same board in => same result out.
## This is what makes seeded daily runs and bug repros possible.

const PURE_THRESHOLD := 6  ## cells of one color needed to call a line "pure"


static func resolve(board: Board, combo: int = 1) -> ClearResult:
	var result := ClearResult.new()

	var rows := board.full_rows()
	var cols := board.full_cols()
	if rows.is_empty() and cols.is_empty():
		return result

	# --- pure lines are measured before anything is erased ---
	for y in rows:
		if _is_pure(board.row_values(y)):
			result.pure_lines += 1
	for x in cols:
		if _is_pure(board.col_values(x)):
			result.pure_lines += 1
	result.lines = rows.size() + cols.size()

	# --- wave 0: the lines the player actually completed ---
	var cleared := {}
	var wave0: Array[Vector2i] = []
	for y in rows:
		for x in Board.SIZE:
			_collect(board, Vector2i(x, y), cleared, wave0)
	for x in cols:
		for y in Board.SIZE:
			_collect(board, Vector2i(x, y), cleared, wave0)
	result.waves.append(wave0)

	# --- prism cascade: beams can only ever remove cells, so new lines cannot
	# be completed. Chains come from prism -> prism along the same row/column. ---
	var detonated := {}
	var pending: Array[Vector2i] = []
	for p in wave0:
		if board.is_prism(p):
			pending.append(p)

	while not pending.is_empty():
		var wave: Array[Vector2i] = []
		var next: Array[Vector2i] = []

		for prism in pending:
			if detonated.has(prism):
				continue
			detonated[prism] = true
			result.prisms += 1
			result.prisms_at.append(prism)

			for x in Board.SIZE:
				var p := Vector2i(x, prism.y)
				_collect(board, p, cleared, wave)
			for y in Board.SIZE:
				var p := Vector2i(prism.x, y)
				_collect(board, p, cleared, wave)

		for p in wave:
			if board.is_prism(p) and not detonated.has(p):
				next.append(p)

		if not wave.is_empty():
			result.waves.append(wave)
			result.chain_depth += 1
		pending = next

	# --- commit ---
	for p in result.waves:
		result.cells.append_array(p)
	result.cell_count = result.cells.size()
	result.score = Scorer.line_score(result.lines, result.cell_count, combo, result.chain_depth)
	board.erase_indices(cleared.keys())
	return result


static func _collect(board: Board, p: Vector2i, cleared: Dictionary, wave: Array[Vector2i]) -> void:
	var i := board.idx(p)
	if cleared.has(i):
		return
	cleared[i] = true
	wave.append(p)


static func _is_pure(values: Array[int]) -> bool:
	var counts := {}
	var best := 0
	for v in values:
		if v == Board.EMPTY or v == Board.PRISM:
			continue
		counts[v] = counts.get(v, 0) + 1
		best = maxi(best, counts[v])
	return best >= PURE_THRESHOLD
