class_name Board
extends RefCounted
## Pure 8x8 board state. No nodes, no visuals, no input.
## Value encoding: 0 = empty, 1..4 = block color, 5 = prism (wildcard).

const SIZE := 8
const EMPTY := 0
const PRISM := 5
const COLORS := 4


var cells: PackedInt32Array


func _init() -> void:
	cells = PackedInt32Array()
	cells.resize(SIZE * SIZE)
	cells.fill(EMPTY)


func idx(p: Vector2i) -> int:
	return p.y * SIZE + p.x


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < SIZE and p.y >= 0 and p.y < SIZE


func get_cell(p: Vector2i) -> int:
	return cells[idx(p)]


func is_filled(p: Vector2i) -> bool:
	return cells[idx(p)] != EMPTY


func is_prism(p: Vector2i) -> bool:
	return cells[idx(p)] == PRISM


func clear() -> void:
	cells.fill(EMPTY)


func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	for c in shape:
		var p := origin + c
		if not in_bounds(p):
			return false
		if cells[idx(p)] != EMPTY:
			return false
	return true


## Returns the board positions filled, or an empty array if the placement is illegal.
func place(shape: Array[Vector2i], origin: Vector2i, value: int) -> Array[Vector2i]:
	if not can_place(shape, origin):
		return []
	var placed: Array[Vector2i] = []
	for c in shape:
		var p := origin + c
		cells[idx(p)] = value
		placed.append(p)
	return placed


func full_rows() -> Array[int]:
	var out: Array[int] = []
	for y in SIZE:
		var full := true
		for x in SIZE:
			if cells[y * SIZE + x] == EMPTY:
				full = false
				break
		if full:
			out.append(y)
	return out


func full_cols() -> Array[int]:
	var out: Array[int] = []
	for x in SIZE:
		var full := true
		for y in SIZE:
			if cells[y * SIZE + x] == EMPTY:
				full = false
				break
		if full:
			out.append(x)
	return out


func row_values(y: int) -> Array[int]:
	var out: Array[int] = []
	for x in SIZE:
		out.append(cells[y * SIZE + x])
	return out


func col_values(x: int) -> Array[int]:
	var out: Array[int] = []
	for y in SIZE:
		out.append(cells[y * SIZE + x])
	return out


func erase_indices(indices: Array) -> void:
	for i in indices:
		cells[i] = EMPTY


func filled_count() -> int:
	var n := 0
	for v in cells:
		if v != EMPTY:
			n += 1
	return n
