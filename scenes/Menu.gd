extends Control
## Main menu. Custom-drawn so the chrome and the board share one language:
## angular shard pills, mint on deep violet, no theme resources to drift.

const PLAY_RECT := Rect2(130, 540, 460, 116)
const VOID_RECT := Rect2(130, 700, 460, 96)
const DAILY_RECT := Rect2(130, 816, 460, 96)
const HAPTICS_RECT := Rect2(130, 980, 220, 80)
const SOUND_RECT := Rect2(370, 980, 220, 80)
const BEST_RECT := Rect2(160, 356, 400, 112)
const STATS_RECT := Rect2(90, 280, 540, 660)

var _day_key := ""
var stats_open := false


func _ready() -> void:
	Session.last = {}
	_day_key = ModeRules.date_key(ModeRules.today())
	queue_redraw()
	Transition.play()


func _process(_delta: float) -> void:
	# unlock the daily at midnight without needing a restart
	var key := ModeRules.date_key(ModeRules.today())
	if key != _day_key:
		_day_key = key
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color(Ui.BG, 0.50), true)

	_diamond(Vector2(360, 120), 24.0)

	Ui.label(self, Vector2(0, 258), "SHARDWAVE", 72, Ui.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 720)
	Ui.label(self, Vector2(0, 300), "Every clear shatters.", 22, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)

	# best score
	var best := BEST_RECT
	Ui.panel(self, best, Ui.PANEL, Color(1, 1, 1, 0.07), 2.0)
	Ui.label(self, Vector2(best.position.x, best.position.y + 34), "BEST", 18, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, best.size.x)
	Ui.label(self, Vector2(best.position.x, best.position.y + 90), Ui.thousands(Save.best_classic),
		44, Ui.TEXT, HORIZONTAL_ALIGNMENT_CENTER, best.size.x)

	# play
	Ui.panel(self, PLAY_RECT, Ui.MINT, Ui.MINT.darkened(0.30), 2.0, false)
	Ui.label(self, Vector2(PLAY_RECT.position.x, PLAY_RECT.position.y + 76), "PLAY", 44, Ui.INK,
		HORIZONTAL_ALIGNMENT_CENTER, PLAY_RECT.size.x)

	var date := ModeRules.today()
	var today_key := ModeRules.date_key(date)
	var daily_done := Save.daily_played(today_key)

	var rush_badge := "90 SECONDS"
	if Save.best_rush > 0:
		rush_badge = "BEST %s" % Ui.thousands(Save.best_rush)
	_mode_row(VOID_RECT, "VOID RUSH", "BEAT THE CLOCK", rush_badge, true)

	var daily_badge := "SHARD #%d" % ModeRules.shard_number(date)
	if daily_done:
		daily_badge = "PLAYED  %s" % Ui.thousands(Save.daily_score)
	_mode_row(DAILY_RECT, "DAILY SHARD", "ONE RUN A DAY", daily_badge, not daily_done)

	_toggle(HAPTICS_RECT, "HAPTICS", Save.haptics)
	_toggle(SOUND_RECT, "SOUND", Save.sound)
	_daily_strip(today_key)

	Ui.label(self, Vector2(0, 1216), "v%s  ·  AT8 Studios" % ProjectSettings.get_setting(
		"application/config/version", "dev"), 18, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, 720)

	if stats_open:
		_draw_stats()


func _mode_row(rect: Rect2, title: String, subtitle: String, badge: String, active: bool) -> void:
	var border := Color(Ui.MINT, 0.55) if active else Color(1, 1, 1, 0.05)
	Ui.panel(self, rect, Color(Ui.PANEL, 0.70 if active else 0.50), border, 2.0, active)
	Ui.label(self, Vector2(rect.position.x + 34, rect.position.y + 44), title, 28,
		Ui.TEXT if active else Ui.DIM)
	Ui.label(self, Vector2(rect.position.x + 34, rect.position.y + 72), subtitle, 15,
		Ui.DIM.darkened(0.15) if not active else Ui.DIM)
	Ui.label(self, Vector2(rect.position.x, rect.position.y + 56), badge, 18,
		Ui.MINT if active else Ui.DIM, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 34)


func _daily_strip(today_key: String) -> void:
	var keys: Array[String] = []
	var key := today_key
	for i in 7:
		keys.push_front(key)
		key = ModeRules.previous_day_key(key)

	Ui.label(self, Vector2(130, 1104), "STREAK", 15, Ui.DIM)
	Ui.label(self, Vector2(130, 1138), str(Save.daily_streak), 30,
		Ui.MINT if Save.daily_streak > 0 else Ui.DIM)

	var x := 392.0
	for k in keys:
		var done := Save.daily_history.has(k)
		var c := Vector2(x, 1114)
		var r := 9.0
		var pts := PackedVector2Array([
			c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(0.0, r), c + Vector2(-r, 0.0),
		])
		draw_colored_polygon(pts, Ui.MINT if done else Color(1, 1, 1, 0.10))
		if k == today_key:
			pts.append(pts[0])
			draw_polyline(pts, Color(Ui.MINT, 0.55), 1.5, true)
		x += 34


func _draw_stats() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color(0.03, 0.02, 0.08, 0.90), true)
	var r := STATS_RECT
	Ui.panel(self, r, Color(Ui.PANEL, 0.97), Color(1, 1, 1, 0.10), 2.0)
	Ui.label(self, Vector2(r.position.x, r.position.y + 64), "STATS", 38, Ui.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Ui.label(self, Vector2(r.position.x, r.position.y + 96), "ON THIS DEVICE", 15, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

	var rows := [
		["RUNS", Ui.thousands(Save.runs)],
		["LINES", Ui.thousands(Save.lines)],
		["PRISMS", Ui.thousands(Save.prisms)],
		["CLASSIC BEST", Ui.thousands(Save.best_classic)],
		["VOID RUSH BEST", Ui.thousands(Save.best_rush)],
		["DAILY BEST", Ui.thousands(Save.best_daily)],
		["DAILY STREAK", "%d %s" % [Save.daily_streak,
			"day" if Save.daily_streak == 1 else "days"]],
	]
	var y := r.position.y + 168
	for row in rows:
		Ui.label(self, Vector2(r.position.x + 44, y), row[0], 20, Ui.DIM)
		Ui.label(self, Vector2(r.position.x, y), row[1], 24, Ui.TEXT,
			HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 44)
		y += 56

	Ui.label(self, Vector2(r.position.x, r.position.y + r.size.y - 36), "TAP ANYWHERE TO CLOSE",
		16, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


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
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_back()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_day_key = ModeRules.date_key(ModeRules.today())
			queue_redraw()


func _back() -> void:
	if stats_open:
		stats_open = false
		queue_redraw()
	else:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		return
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(event.position)


func _tap(pos: Vector2) -> void:
	if stats_open:
		stats_open = false
		queue_redraw()
		return
	if BEST_RECT.has_point(pos):
		Audio.ui()
		stats_open = true
		queue_redraw()
		return
	if PLAY_RECT.has_point(pos):
		Audio.ui()
		Haptics.pulse(20, 0.6)
		Session.begin("classic")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif VOID_RECT.has_point(pos):
		Audio.ui()
		Haptics.pulse(20, 0.6)
		Session.begin("rush")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif DAILY_RECT.has_point(pos):
		Audio.ui()
		if Save.daily_played(ModeRules.date_key(ModeRules.today())):
			return
		Haptics.pulse(20, 0.6)
		Session.begin("daily")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	elif HAPTICS_RECT.has_point(pos):
		Save.toggle_haptics()
		Haptics.pulse(30, 0.7)
		queue_redraw()
	elif SOUND_RECT.has_point(pos):
		Save.toggle_sound()
		queue_redraw()
