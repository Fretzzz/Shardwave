class_name PieceLibrary
extends RefCounted
## The shape pool. Weights decide how often a shape is dealt.
## Deliberately excludes anything wider than 5 cells: on an 8x8 board,
## giant shapes are where "unfair" lives.

class Piece:
	var shape_name: String
	var cells: Array[Vector2i]
	var weight: int


static var _pool: Array = []


static func pool() -> Array:
	if _pool.is_empty():
		_build()
	return _pool


static func _build() -> void:
	_add("dot", [[0, 0]], 3)
	_add("i2h", [[0, 0], [1, 0]], 3)
	_add("i2v", [[0, 0], [0, 1]], 3)
	_add("i3h", [[0, 0], [1, 0], [2, 0]], 3)
	_add("i3v", [[0, 0], [0, 1], [0, 2]], 3)
	_add("i4h", [[0, 0], [1, 0], [2, 0], [3, 0]], 2)
	_add("i4v", [[0, 0], [0, 1], [0, 2], [0, 3]], 2)
	_add("i5h", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], 1)
	_add("i5v", [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], 1)
	_add("o2", [[0, 0], [1, 0], [0, 1], [1, 1]], 3)
	_add("o3", _rect(3, 3), 1)

	# 3-cell corners (the workhorses)
	_add("corner_a", [[0, 0], [1, 0], [0, 1]], 2)
	_add("corner_b", [[0, 0], [1, 0], [1, 1]], 2)
	_add("corner_c", [[0, 0], [0, 1], [1, 1]], 2)
	_add("corner_d", [[1, 0], [0, 1], [1, 1]], 2)

	# 4-cell L
	_add("ell_a", [[0, 0], [0, 1], [0, 2], [1, 2]], 1)
	_add("ell_b", [[0, 0], [1, 0], [2, 0], [0, 1]], 1)
	_add("ell_c", [[0, 0], [1, 0], [1, 1], [1, 2]], 1)
	_add("ell_d", [[2, 0], [0, 1], [1, 1], [2, 1]], 1)

	# 4-cell T
	_add("tee_a", [[0, 0], [1, 0], [2, 0], [1, 1]], 1)
	_add("tee_b", [[1, 0], [0, 1], [1, 1], [1, 2]], 1)
	_add("tee_c", [[1, 0], [0, 1], [1, 1], [2, 1]], 1)
	_add("tee_d", [[0, 0], [0, 1], [1, 1], [0, 2]], 1)

	# 4-cell S/Z
	_add("ess_a", [[0, 0], [1, 0], [1, 1], [2, 1]], 1)
	_add("ess_b", [[1, 0], [0, 1], [1, 1], [0, 2]], 1)

	# 5-cell 3x3 corners
	_add("big_a", [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]], 1)
	_add("big_b", [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]], 1)
	_add("big_c", [[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]], 1)
	_add("big_d", [[2, 0], [2, 1], [0, 2], [1, 2], [2, 2]], 1)


static func _rect(w: int, h: int) -> Array:
	var out := []
	for y in h:
		for x in w:
			out.append([x, y])
	return out


static func _add(shape_name: String, coords: Array, weight: int) -> void:
	var piece := Piece.new()
	piece.shape_name = shape_name
	piece.weight = weight
	var cells: Array[Vector2i] = []
	for c in coords:
		cells.append(Vector2i(c[0], c[1]))
	piece.cells = cells
	_pool.append(piece)


static func total_weight() -> int:
	var total := 0
	for p in pool():
		total += p.weight
	return total


## Deals a tray. Never deals three identical shapes in a row: that is the
## single most common "the game cheated me" complaint in this genre.
static func deal(rng: RandomNumberGenerator, count: int = 3) -> Array:
	var tray: Array = []
	var total := total_weight()
	var guard := 0
	while tray.size() < count:
		guard += 1
		if guard > 200:
			break
		var roll := rng.randi_range(0, total - 1)
		var chosen: Piece = null
		for p in pool():
			roll -= p.weight
			if roll < 0:
				chosen = p
				break
		if tray.size() == count - 1 and tray.size() >= 2:
			if tray[0].shape_name == chosen.shape_name and tray[1].shape_name == chosen.shape_name:
				continue
		tray.append(chosen)
	return tray


static func color_for(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, Board.COLORS)
