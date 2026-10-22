extends Node
## Dev-only: renders the Play Store phone screenshots at a clean 720x1280.
## Runs as a scene so autoloads exist.
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
##     res://tests/StoreShots.tscn

const OUT := "C:/Projects/Shardwave/store"

const BOARD_LAYOUT := [
	"00000000",
	"11022000",
	"41123300",
	"44112230",
	"24415220",
	"02241130",
	"00332244",
	"00000330",
]


func _ready() -> void:
	_shoot.call_deferred()


func _viewport() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp


func _save(vp: SubViewport, name: String) -> void:
	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT)
	var err := img.save_png(OUT.path_join(name))
	print("shot %s err=%d size=%s" % [name, err, str(img.get_size())])


func _settle(frames: int = 20) -> void:
	for i in frames:
		await get_tree().process_frame


func _paint(game: Node) -> void:
	game.state.start(4242)
	var board = game.state.board
	var cells: PackedInt32Array = board.cells
	for y in Board.SIZE:
		var row: String = BOARD_LAYOUT[y]
		for x in Board.SIZE:
			cells[board.idx(Vector2i(x, y))] = int(row[x])
	board.cells = cells
	game.state.score = 4280
	game.state.charges = 2
	game.state.combo = 3
	game.state.lines_total = 37
	game.state.prisms_total = 4
	game.state.placements = 44


func _prism_result() -> ClearResult:
	var r := ClearResult.new()
	r.lines = 2
	r.pure_lines = 1
	r.prisms = 1
	r.chain_depth = 1
	r.score = 1240
	r.prisms_at = [Vector2i(4, 3)] as Array[Vector2i]
	var wave0: Array[Vector2i] = []
	for x in Board.SIZE:
		wave0.append(Vector2i(x, 3))
	r.waves.append(wave0)
	var wave1: Array[Vector2i] = []
	for i in Board.SIZE:
		wave1.append(Vector2i(4, i))
		if i != 3:
			wave1.append(Vector2i(i, 3))
	r.waves.append(wave1)
	r.cells = wave0.duplicate()
	r.cells.append_array(wave1)
	r.cell_count = r.cells.size()
	return r


func _shoot() -> void:
	Save.best_classic = 18420
	Save.best_rush = 12480
	Save.best_daily = 9210
	Save.daily_date = ""

	# 1) menu
	var vp := _viewport()
	vp.add_child(load("res://scenes/Menu.tscn").instantiate())
	await _settle()
	_save(vp, "phone-01-menu.png")
	vp.queue_free()
	await _settle(3)

	# 2) results
	Session.last = {
		"mode": "classic",
		"score": 18420,
		"lines": 61,
		"prisms": 7,
		"placements": 88,
		"best": 18420,
		"new_best": true,
	}
	vp = _viewport()
	vp.add_child(load("res://scenes/Results.tscn").instantiate())
	await _settle()
	_save(vp, "phone-02-results.png")
	vp.queue_free()
	await _settle(3)

	# 3) board mid-run
	Session.begin("classic")
	vp = _viewport()
	var game: Node = load("res://scenes/Game.tscn").instantiate()
	vp.add_child(game)
	await _settle()
	_paint(game)
	await _settle()
	_save(vp, "phone-03-board.png")
	vp.queue_free()
	await _settle(3)

	# 4) prism cascade, captured a few frames into the blast
	Session.begin("classic")
	vp = _viewport()
	game = load("res://scenes/Game.tscn").instantiate()
	vp.add_child(game)
	await _settle()
	_paint(game)
	game._on_cleared(_prism_result())
	await _settle(9)
	_save(vp, "phone-04-prism.png")
	vp.queue_free()
	await _settle(3)

	# 5) Void Rush, clock running
	Session.begin("rush")
	vp = _viewport()
	game = load("res://scenes/Game.tscn").instantiate()
	vp.add_child(game)
	await _settle()
	_paint(game)
	game.rush_started = true
	game.rush_elapsed = 31.0
	game.rush_time = 63.0
	await _settle()
	_save(vp, "phone-05-rush.png")
	vp.queue_free()

	get_tree().quit(0)
