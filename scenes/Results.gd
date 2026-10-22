extends Control
## Run results. Reads Session.last only — no board, no RunState, no rules.

const AGAIN_RECT := Rect2(130, 880, 460, 116)
const MENU_RECT := Rect2(130, 1026, 460, 96)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var d := Session.last
	var score := int(d.get("score", 0))
	var lines := int(d.get("lines", 0))
	var prisms := int(d.get("prisms", 0))
	var places := int(d.get("placements", 0))
	var best := int(d.get("best", Save.best_classic))
	var new_best := bool(d.get("new_best", false))

	draw_rect(Rect2(0, 0, 720, 1280), Color(Ui.BG, 0.58), true)

	Ui.label(self, Vector2(0, 240), str(d.get("mode", "classic")).to_upper(), 20, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, 720)

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
	_stat(panel, 0, "LINES", lines)
	_stat(panel, 1, "PRISMS", prisms)
	_stat(panel, 2, "PLACES", places)

	Ui.label(self, Vector2(0, 838), "BEST  %s" % Ui.thousands(best), 22, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, 720)

	Ui.panel(self, AGAIN_RECT, Ui.MINT, Ui.MINT.darkened(0.30), 2.0, false)
	Ui.label(self, Vector2(AGAIN_RECT.position.x, AGAIN_RECT.position.y + 76), "RUN AGAIN", 40,
		Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, AGAIN_RECT.size.x)

	Ui.panel(self, MENU_RECT, Color(Ui.PANEL, 0.60), Color(1, 1, 1, 0.10), 2.0)
	Ui.label(self, Vector2(MENU_RECT.position.x, MENU_RECT.position.y + 62), "MENU", 32,
		Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, MENU_RECT.size.x)


func _stat(panel: Rect2, row: int, name: String, value: int) -> void:
	var y := panel.position.y + 54 + row * 62
	Ui.label(self, Vector2(panel.position.x + 40, y), name, 20, Ui.DIM)
	Ui.label(self, Vector2(panel.position.x, y), Ui.thousands(value), 28, Ui.TEXT,
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
		Session.begin("classic")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif MENU_RECT.has_point(pos):
		Audio.ui()
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
