extends Control
## Run results. Reads Session.last only — no board, no RunState, no rules.

const AGAIN_RECT := Rect2(130, 880, 460, 116)
const MENU_RECT := Rect2(130, 1026, 460, 96)
const COPY_RECT := Rect2(130, 1148, 460, 60)

var copied := 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()
	Transition.play()


func _process(delta: float) -> void:
	if copied > 0.0:
		copied = maxf(0.0, copied - delta)
		queue_redraw()


func _draw() -> void:
	var d := Session.last
	var mode := str(d.get("mode", "classic"))
	var score := int(d.get("score", 0))
	var lines := int(d.get("lines", 0))
	var prisms := int(d.get("prisms", 0))
	var places := int(d.get("placements", 0))
	var best := int(d.get("best", Save.best_classic))
	var new_best := bool(d.get("new_best", false))

	var title := "CLASSIC"
	if mode == "rush":
		title = "VOID RUSH"
	elif mode == "daily":
		title = "DAILY SHARD #%d" % int(d.get("shard", 0))

	draw_rect(Rect2(0, 0, 720, 1280), Color(Ui.BG, 0.58), true)

	Ui.label(self, Vector2(0, 240), title, 20, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)

	if new_best:
		Ui.panel(self, Rect2(270, 300, 180, 44), Color(Ui.MINT, 0.12), Ui.MINT, 1.5, false)
		Ui.label(self, Vector2(270, 329), "NEW BEST", 18, Ui.MINT, HORIZONTAL_ALIGNMENT_CENTER, 180)
	else:
		Ui.label(self, Vector2(0, 326), "RUN OVER", 20, Ui.DIM,
			HORIZONTAL_ALIGNMENT_CENTER, 720)

	Ui.label(self, Vector2(0, 452), Ui.thousands(score), 96, Ui.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, 720)
	Ui.label(self, Vector2(0, 496), "SCORE", 18, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)

	# stat rows
	var panel := Rect2(150, 566, 420, 220)
	Ui.panel(self, panel, Color(Ui.PANEL, 0.75), Color(1, 1, 1, 0.06), 2.0)
	_stat(panel, 0, "LINES", Ui.thousands(lines))
	_stat(panel, 1, "PRISMS", Ui.thousands(prisms))
	if mode == "rush":
		_stat(panel, 2, "SURVIVED", _clock(int(d.get("time", 0))))
	elif mode == "daily":
		_stat(panel, 2, "STREAK", "%d %s" % [int(d.get("streak", 1)),
			"day" if int(d.get("streak", 1)) == 1 else "days"])
	else:
		_stat(panel, 2, "PLACES", Ui.thousands(places))

	var best_line := "BEST  %s" % Ui.thousands(best)
	if not new_best and score < best:
		best_line = "BEST  %s   ·   %s TO GO" % [Ui.thousands(best), Ui.thousands(best - score)]

	Ui.label(self, Vector2(0, 838), best_line, 22, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, 720)

	var again_label := "PLAY CLASSIC" if mode == "daily" else "RUN AGAIN"
	Ui.panel(self, AGAIN_RECT, Ui.MINT, Ui.MINT.darkened(0.30), 2.0, false)
	Ui.label(self, Vector2(AGAIN_RECT.position.x, AGAIN_RECT.position.y + 76), again_label, 40,
		Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, AGAIN_RECT.size.x)

	Ui.panel(self, MENU_RECT, Color(Ui.PANEL, 0.60), Color(1, 1, 1, 0.10), 2.0)
	Ui.label(self, Vector2(MENU_RECT.position.x, MENU_RECT.position.y + 62), "MENU", 32,
		Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, MENU_RECT.size.x)

	Ui.panel(self, COPY_RECT, Color(Ui.PANEL, 0.55), Color(1, 1, 1, 0.08), 2.0)
	Ui.label(self, Vector2(COPY_RECT.position.x, COPY_RECT.position.y + 40),
		"COPIED" if copied > 0.0 else "COPY SCORE", 20,
		Ui.MINT if copied > 0.0 else Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, COPY_RECT.size.x)


func _clock(total: int) -> String:
	return "%d:%02d" % [total / 60, total % 60]


func _share_text() -> String:
	var d := Session.last
	var mode := str(d.get("mode", "classic"))
	var score := Ui.thousands(int(d.get("score", 0)))
	var lines := int(d.get("lines", 0))
	var prisms := int(d.get("prisms", 0))
	if mode == "daily":
		return "Shardwave Daily Shard #%d: %s points, %d lines, %d Prisms." % [
			int(d.get("shard", 0)), score, lines, prisms]
	if mode == "rush":
		return "Shardwave Void Rush: %s points in %s, %d lines, %d Prisms." % [
			score, _clock(int(d.get("time", 0))), lines, prisms]
	return "Shardwave Classic: %s points, %d lines, %d Prisms." % [score, lines, prisms]


func _stat(panel: Rect2, row: int, name: String, value: String) -> void:
	var y := panel.position.y + 54 + row * 62
	Ui.label(self, Vector2(panel.position.x + 40, y), name, 20, Ui.DIM)
	Ui.label(self, Vector2(panel.position.x, y), value, 28, Ui.TEXT,
		HORIZONTAL_ALIGNMENT_RIGHT, panel.size.x - 40)


# ---------------------------------------------------------------- input

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(event.position)


func _tap(pos: Vector2) -> void:
	if AGAIN_RECT.has_point(pos):
		Audio.ui()
		Haptics.pulse(20, 0.6)
		# a finished daily can't be replayed, so the button starts a Classic run
		Session.begin("classic" if Session.mode == "daily" else Session.mode)
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif MENU_RECT.has_point(pos):
		Audio.ui()
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	elif COPY_RECT.has_point(pos):
		Audio.ui()
		Haptics.pulse(15, 0.5)
		DisplayServer.clipboard_set(_share_text())
		copied = 1.6
		queue_redraw()
