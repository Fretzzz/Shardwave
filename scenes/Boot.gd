extends Control
## M0 smoke test: proves the APK launches, renders, and vibrates.
## This scene exists only to validate the pipeline and is replaced at M1.

@onready var title: Label = $Center/VBox/Title
@onready var status: Label = $Center/VBox/Status

var ripples: Array = []


func _ready() -> void:
	title.text = "SHARDWAVE"
	status.text = "AT8 Studios  ·  v%s\n%s / %s\n\ntap anywhere — render + haptics test" % [
		ProjectSettings.get_setting("application/config/version", "dev"),
		OS.get_name(),
		Engine.get_version_info().string,
	]
	Haptics.ready_pulse()
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	var pos := Vector2.ZERO

	if event is InputEventScreenTouch and event.pressed:
		tapped = true
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
		pos = event.position

	if tapped:
		_on_tap(pos)


func _on_tap(pos: Vector2) -> void:
	ripples.append({"pos": pos, "t": 0.0})
	Haptics.pulse(40, 0.8)
	status.text = "tap  %d, %d" % [int(pos.x), int(pos.y)]
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	for r in ripples:
		r.t += delta
	ripples = ripples.filter(func(r): return r.t < 0.7)
	if ripples.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	# Tap ripples — mint, matching the brand palette.
	for r in ripples:
		var k: float = r.t / 0.7
		draw_arc(r.pos, 24.0 + k * 170.0, 0.0, TAU, 64,
			Color(0.36, 0.95, 0.75, 1.0 - k), 7.0 * (1.0 - k), true)

	# The shard. Four facets, four beams' worth of attitude.
	var c := size * 0.5 + Vector2(0.0, -150.0)
	var shard := PackedVector2Array([
		c + Vector2(0.0, -78.0),
		c + Vector2(56.0, 0.0),
		c + Vector2(0.0, 78.0),
		c + Vector2(-56.0, 0.0),
	])
	draw_colored_polygon(shard, Color(0.957, 0.941, 1.0))
	draw_polyline(shard + PackedVector2Array([shard[0]]),
		Color(0.66, 0.55, 0.98, 0.9), 3.0, true)
