extends Node
## Dev-only integration test for the scene shell:
##   Menu -> PLAY -> Game -> game over -> Results -> RUN AGAIN -> Game
##   -> Android back -> pause -> QUIT TO MENU -> Results -> back -> Menu
##
## Loaded as a root-level node by FlowBoot so scene changes can't free it.
##   godot --headless --path . res://tests/FlowTest.tscn

var failures: Array[String] = []
var checks := 0


func _ready() -> void:
	# if the flow wedges, fail loudly instead of hanging the build
	get_tree().create_timer(20.0).timeout.connect(func() -> void:
		printerr("TIMEOUT")
		get_tree().quit(2))
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _scene() -> Node:
	return get_tree().current_scene


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame


func _run() -> void:
	# 1) menu offers PLAY
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	await _settle()
	var menu := _scene()
	check(menu != null and menu.scene_file_path.ends_with("Menu.tscn"), "menu is the current scene")

	# 2) PLAY opens a run
	menu._tap(Vector2(360, 598))
	await _settle()
	var game := _scene()
	check(game != null and game.scene_file_path.ends_with("Game.tscn"), "PLAY opens Game")
	check(Session.mode == "classic", "session mode is classic")

	# 3) run ends -> results
	game._on_game_over()
	await get_tree().create_timer(1.4).timeout
	await _settle()
	var results := _scene()
	check(results != null and results.scene_file_path.ends_with("Results.tscn"),
		"game over opens Results")
	check(Session.last.has("score"), "session recorded the run")
	check(Session.last.get("mode", "") == "classic", "results carry the mode")

	# 4) RUN AGAIN starts a fresh run
	results._tap(Vector2(360, 938))
	await _settle()
	game = _scene()
	check(game != null and game.scene_file_path.ends_with("Game.tscn"), "RUN AGAIN reopens Game")
	check(game.state.score == 0 and not game.state.over, "new run is clean")

	# 5) the save file is versioned and on disk
	var cfg := ConfigFile.new()
	check(cfg.load(Save.PATH) == OK, "run wrote a save file")
	check(int(cfg.get_value("meta", "schema", -1)) == Save.SCHEMA, "save carries the schema version")
	check(Save.schema == Save.SCHEMA, "Save reports its schema")

	# 6) focus loss auto-pauses exactly once, resume works
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused, "focus loss pauses")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused, "focus loss does not toggle back")
	game._press(Vector2(360, 675))
	check(not game.paused, "resume clears the pause")

	# 7) back pauses, quit returns to menu
	game._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.paused, "back button pauses")
	game._press(Vector2(360, 808))
	await _settle()
	menu = _scene()
	check(menu != null and menu.scene_file_path.ends_with("Menu.tscn"), "QUIT TO MENU returns to menu")

	# 8) back from results returns to menu
	get_tree().change_scene_to_file("res://scenes/Results.tscn")
	await _settle()
	results = _scene()
	check(results.scene_file_path.ends_with("Results.tscn"), "Results loads standalone")
	results._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _settle()
	check(_scene().scene_file_path.ends_with("Menu.tscn"), "back from Results returns to menu")

	if failures.is_empty():
		print("PASS  %d checks" % checks)
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL  " + f)
		printerr("%d of %d checks failed" % [failures.size(), checks])
		get_tree().quit(1)
