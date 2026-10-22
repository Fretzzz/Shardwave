extends SceneTree
## Dev-only: renders the game scene into a fixed 720x1280 SubViewport and saves
## a PNG, independent of the host window size.
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --script res://tests/Shot.gd

const OUT := "C:/Projects/Shardwave/build/shot.png"


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

	for i in 30:
		await process_frame

	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var err := img.save_png(OUT)
	print("shot err=%d size=%s" % [err, str(img.get_size())])
	quit(0)
