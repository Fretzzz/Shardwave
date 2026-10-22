extends Node
## Dev-only: renders a shell scene at 720x1280 for eyeballing layout.
## Runs as a scene (not --script) so autoloads exist.
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
##     res://tests/ShotScene.tscn -- menu|results|game

const OUT := "C:/Projects/Shardwave/build/shot-%s.png"


func _ready() -> void:
	_shoot.call_deferred()


func _shoot() -> void:
	var which := "menu"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		which = args[0]

	var path := "res://scenes/Menu.tscn"
	if which == "results":
		path = "res://scenes/Results.tscn"
	elif which == "game":
		path = "res://scenes/Game.tscn"

	Save.best_classic = 12480
	if which == "results":
		Session.last = {
			"mode": "classic",
			"score": 12480,
			"lines": 42,
			"prisms": 5,
			"placements": 61,
			"best": 12480,
			"new_best": true,
		}

	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var scene: Node = load(path).instantiate()
	vp.add_child(scene)

	for i in 20:
		await get_tree().process_frame

	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("C:/Projects/Shardwave/build")
	var out := OUT % which
	var err := img.save_png(out)
	print("shot %s err=%d size=%s" % [which, err, str(img.get_size())])
	get_tree().quit(0)
