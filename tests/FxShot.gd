extends SceneTree
## Dev-only: fires a synthetic prism clear so the beam/chain FX can be captured
## without playing into one. Not part of the game.
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --script res://tests/FxShot.gd

const OUT := "C:/Projects/Shardwave/build/fx.png"


func _initialize() -> void:
	_shoot.call_deferred()


func _shoot() -> void:
	await process_frame

	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var game: Node = load("res://scenes/Game.tscn").instantiate()
	vp.add_child(game)
	await process_frame

	var r := ClearResult.new()
	r.lines = 1
	r.pure_lines = 1
	r.prisms = 1
	r.chain_depth = 1
	r.score = 225
	r.prisms_at = [Vector2i(3, 3)] as Array[Vector2i]

	var wave0: Array[Vector2i] = []
	for x in Board.SIZE:
		wave0.append(Vector2i(x, 3))
	r.waves.append(wave0)

	var wave1: Array[Vector2i] = []
	for i in Board.SIZE:
		wave1.append(Vector2i(3, i))
		if i != 3:
			wave1.append(Vector2i(i, 3))
	r.waves.append(wave1)

	r.cells = wave0.duplicate()
	r.cells.append_array(wave1)
	r.cell_count = r.cells.size()

	game.fx.play(r)
	game.shake = 9.0

	for i in 9:
		await process_frame

	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var err := img.save_png(OUT)
	print("fx shot err=%d size=%s" % [err, str(img.get_size())])
	quit(0)
