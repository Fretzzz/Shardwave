class_name RunState
extends RefCounted
## One run of Classic mode. Owns the board, tray, score and Core charges.
## Knows nothing about how any of it looks.

signal cleared(result: ClearResult)
signal refilled
signal game_over

const TRAY_SIZE := 3
const CHARGE_REQUIRED := 3

var board := Board.new()
var rng := RandomNumberGenerator.new()

var tray: Array = []          ## Array[PieceLibrary.Piece]
var colors: Array[int] = []   ## parallel to tray; Board.PRISM for the prism
var used: Array[bool] = []

var score := 0
var combo := 0
var charges := 0
var placements := 0
var over := false

## Run totals for the results screen; reset with start().
var lines_total := 0
var prisms_total := 0
var clears := 0


func start(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	board.clear()
	score = 0
	combo = 0
	charges = 0
	placements = 0
	lines_total = 0
	prisms_total = 0
	clears = 0
	over = false
	tray.clear()
	colors.clear()
	used.clear()
	_refill()


## Returns the clear result, or null if the placement was illegal / piece unusable.
func place(index: int, origin: Vector2i) -> ClearResult:
	if over or index < 0 or index >= tray.size() or used[index]:
		return null

	var piece: PieceLibrary.Piece = tray[index]
	var filled := board.place(piece.cells, origin, colors[index])
	if filled.is_empty():
		return null

	used[index] = true
	placements += 1

	var result := ClearResolver.resolve(board, combo + 1)

	if result.lines > 0:
		combo += 1
		charges += result.lines + result.pure_lines
		score += result.score
		lines_total += result.lines
		prisms_total += result.prisms
		clears += 1
		cleared.emit(result)
	else:
		combo = 0

	if used.count(true) == used.size():
		_refill()

	_check_over()
	return result


func fits_somewhere(piece: PieceLibrary.Piece) -> bool:
	for y in Board.SIZE:
		for x in Board.SIZE:
			if board.can_place(piece.cells, Vector2i(x, y)):
				return true
	return false


func remaining() -> Array[int]:
	var out: Array[int] = []
	for i in tray.size():
		if not used[i]:
			out.append(i)
	return out


func _refill() -> void:
	tray = PieceLibrary.deal(rng, TRAY_SIZE)
	colors.clear()
	used.clear()
	for i in tray.size():
		colors.append(PieceLibrary.color_for(rng))
		used.append(false)

	# Core payout: the prism is dealt as a fourth, optional piece.
	if charges >= CHARGE_REQUIRED:
		var prism := PieceLibrary.Piece.new()
		prism.shape_name = "prism"
		var prism_cells: Array[Vector2i] = [Vector2i.ZERO]
		prism.cells = prism_cells
		prism.weight = 0
		tray.append(prism)
		colors.append(Board.PRISM)
		used.append(false)
		charges -= CHARGE_REQUIRED

	refilled.emit()


func _check_over() -> void:
	for i in tray.size():
		if used[i]:
			continue
		if fits_somewhere(tray[i]):
			return
	over = true
	game_over.emit()
