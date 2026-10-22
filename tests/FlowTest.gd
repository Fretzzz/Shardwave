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
	# tests write to a scratch save so a real daily/streak is never touched
	Save.save_path = "user://test-save.cfg"
	if FileAccess.file_exists(Save.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.save_path))
	Save.load_game()
	Save.save_game()

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
	check(cfg.load(Save.save_path) == OK, "run wrote a save file")
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
	menu = _scene()

	# 8b) the BEST panel opens stats; any tap closes
	menu._tap(Vector2(360, 412))
	check(menu.stats_open, "BEST opens the stats overlay")
	menu._tap(Vector2(360, 640))
	check(not menu.stats_open, "tap closes the stats overlay")

	# 9) Void Rush: a 90s clock, clears buy time, running out ends the run
	menu._tap(Vector2(360, 748))
	await _settle()
	game = _scene()
	check(game.scene_file_path.ends_with("Game.tscn") and Session.mode == "rush",
		"VOID RUSH opens a rush run")
	check(is_equal_approx(game.rush_time, ModeRules.RUSH_START), "rush clock starts at 90s")
	check(not game.rush_started, "rush clock waits for the first piece")
	var clear := ClearResult.new()
	clear.lines = 2
	clear.prisms = 1
	clear.score = 400
	game.rush_started = true
	game._on_cleared(clear)
	check(is_equal_approx(game.rush_time, ModeRules.RUSH_START + 7.0),
		"rush clear buys 1.5s per line + 4s per prism")
	game.rush_time = 0.05
	await get_tree().create_timer(0.3).timeout
	check(game.time_up and game.state.over, "empty clock ends the run")
	await get_tree().create_timer(1.2).timeout
	await _settle()
	results = _scene()
	check(results.scene_file_path.ends_with("Results.tscn"), "rush timeout opens Results")
	check(Session.last.get("mode") == "rush" and Session.last.has("time"),
		"rush results carry the survived time")

	# 10) Daily Shard: seeded by the date, locked once finished
	results._tap(Vector2(360, 1074))
	await _settle()
	menu = _scene()
	check(menu.scene_file_path.ends_with("Menu.tscn"), "MENU returns from rush results")
	menu._tap(Vector2(360, 864))
	await _settle()
	game = _scene()
	var today := ModeRules.date_key(ModeRules.today())
	check(game.scene_file_path.ends_with("Game.tscn") and Session.mode == "daily",
		"DAILY SHARD opens a daily run")
	check(Session.run_seed == ModeRules.daily_seed(ModeRules.today()) and Session.run_seed > 0,
		"daily uses the date as its seed")
	check(game.state.rng.seed == Session.run_seed, "the board deals from the daily seed")
	check(not Save.daily_played(today), "daily stays open while it is being played")
	# pretend yesterday was played so the finish has to advance the streak
	Save.daily_last = ModeRules.previous_day_key(today)
	Save.daily_streak = 4
	game._on_game_over()
	await get_tree().create_timer(1.2).timeout
	await _settle()
	results = _scene()
	check(Session.last.get("mode") == "daily" and
		int(Session.last.get("shard", 0)) == ModeRules.shard_number(ModeRules.today()),
		"daily results carry the shard number")
	check(Save.daily_played(today) and Save.daily_score == 0, "finishing the daily locks it")
	check(int(Session.last.get("streak", 0)) == 5, "daily advances a consecutive-day streak, got %d" %
		int(Session.last.get("streak", 0)))
	check(Save.daily_history.has(today), "daily history records the day")

	# the copy button gives feedback without leaving the screen
	results._tap(Vector2(360, 1178))
	check(results.copied > 0.0, "COPY SCORE gives feedback")
	check(_scene() == results and Session.mode == "daily", "copying does not start a run")

	# 11) a finished daily cannot be replayed from the menu
	results._tap(Vector2(360, 1074))
	await _settle()
	menu = _scene()
	menu._tap(Vector2(360, 864))
	await _settle()
	check(_scene().scene_file_path.ends_with("Menu.tscn"), "finished daily cannot be replayed")

	if failures.is_empty():
		print("PASS  %d checks" % checks)
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FAIL  " + f)
		printerr("%d of %d checks failed" % [failures.size(), checks])
		get_tree().quit(1)
