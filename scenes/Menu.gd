extends Control
## Main menu. Custom-drawn so the chrome and the board share one language:
## angular shard pills, mint on deep violet, no theme resources to drift.

const PLAY_RECT := Rect2(130, 540, 460, 116)
const VOID_RECT := Rect2(130, 700, 460, 96)
const DAILY_RECT := Rect2(130, 816, 460, 96)
const HAPTICS_RECT := Rect2(130, 980, 220, 80)
const SOUND_RECT := Rect2(370, 980, 220, 80)


func _ready() -> void:
	Session.last = {}
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color(Ui.BG, 0.50), true)

	_diamond(Vector2(360, 120), 24.0)

	Ui.label(self, Vector2(0, 258), "SHARDWAVE", 72, Ui.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 720)
	Ui.label(self, Vector2(0, 300), "Every clear shatters.", 22, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)

	# best score
	var best := Rect2(160, 356, 400, 112)
	Ui.panel(self, best, Ui.PANEL, Color(1, 1, 1, 0.07), 2.0)
	Ui.label(self, Vector2(best.position.x, best.position.y + 34), "BEST", 18, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, best.size.x)
	Ui.label(self, Vector2(best.position.x, best.position.y + 90), Ui.thousands(Save.best_classic),
		44, Ui.TEXT, HORIZONTAL_ALIGNMENT_CENTER, best.size.x)

	# play
	Ui.panel(self, PLAY_RECT, Ui.MINT, Ui.MINT.darkened(0.30), 2.0, false)
	Ui.label(self, Vector2(PLAY_RECT.position.x, PLAY_RECT.position.y + 76), "PLAY", 44, Ui.INK,
		HORIZONTAL_ALIGNMENT_CENTER, PLAY_RECT.size.x)

	_mode_row(VOID_RECT, "VOID RUSH")
	_mode_row(DAILY_RECT, "DAILY SHARD")

	_toggle(HAPTICS_RECT, "HAPTICS", Save.haptics)
	_toggle(SOUND_RECT, "SOUND", Save.sound)

	Ui.label(self, Vector2(0, 1216), "v%s  ·  AT8 Studios" % ProjectSettings.get_setting(
		"application/config/version", "dev"), 18, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)


func _mode_row(rect: Rect2, name: String) -> void:
	Ui.panel(self, rect, Color(Ui.PANEL, 0.55), Color(1, 1, 1, 0.05), 2.0)
	Ui.label(self, Vector2(rect.position.x + 34, rect.position.y + 60), name, 30, Ui.DIM)
	Ui.label(self, Vector2(rect.position.x, rect.position.y + 58), "SOON", 18,
		Ui.DIM.darkened(0.15), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 34)


func _toggle(rect: Rect2, name: String, on: bool) -> void:
	var border := Ui.MINT if on else Color(1, 1, 1, 0.08)
	Ui.panel(self, rect, Color(Ui.PANEL, 0.70), border, 2.0, on)
	Ui.label(self, Vector2(rect.position.x, rect.position.y + 32), name, 16,
		Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	Ui.label(self, Vector2(rect.position.x, rect.position.y + 62), "ON" if on else "OFF", 22,
		Ui.MINT if on else Ui.DIM.darkened(0.2), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _diamond(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(0.0, r), c + Vector2(-r, 0.0),
	])
	draw_colored_polygon(pts, Color(0.957, 0.941, 1.0))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(0.66, 0.55, 0.98, 0.9), 2.0, true)


# ---------------------------------------------------------------- input

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(event.position)


func _tap(pos: Vector2) -> void:
	if PLAY_RECT.has_point(pos):
		Audio.ui()
		Haptics.pulse(20, 0.6)
		Session.begin("classic")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif HAPTICS_RECT.has_point(pos):
		Save.toggle_haptics()
		Haptics.pulse(30, 0.7)
		queue_redraw()
	elif SOUND_RECT.has_point(pos):
		Save.toggle_sound()
		queue_redraw()
	elif VOID_RECT.has_point(pos) or DAILY_RECT.has_point(pos):
		# locked for now; the row already says SOON
		Audio.ui()
