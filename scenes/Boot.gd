extends Control
## Boot: apply persisted settings, show the mark, hand off to the menu.
## Kept short on purpose — anything slow here is felt on every cold start.

const MENU := "res://scenes/Menu.tscn"
const HOLD := 0.7

@onready var title: Label = $Center/VBox/Title
@onready var status: Label = $Center/VBox/Status

var _t := 0.0


func _ready() -> void:
	title.text = "SHARDWAVE"
	status.text = "Every clear shatters.\n\nv%s  ·  AT8 Studios" % ProjectSettings.get_setting(
		"application/config/version", "dev")
	Save.apply_settings()
	set_process(true)
	await get_tree().create_timer(HOLD).timeout
	get_tree().change_scene_to_file(MENU)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5 + Vector2(0.0, -230.0)
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)

	# breathing halo behind the shard
	draw_circle(c, 84.0 + 14.0 * pulse, Color(0.36, 0.95, 0.75, 0.04 + 0.05 * pulse))

	var shard := PackedVector2Array([
		c + Vector2(0.0, -64.0),
		c + Vector2(46.0, 0.0),
		c + Vector2(0.0, 64.0),
		c + Vector2(-46.0, 0.0),
	])
	draw_colored_polygon(shard, Color(0.957, 0.941, 1.0))
	var outline := shard.duplicate()
	outline.append(shard[0])
	draw_polyline(outline, Color(0.66, 0.55, 0.98, 0.9), 3.0, true)
	draw_line(c + Vector2(-46.0, 0.0), c + Vector2(46.0, 0.0),
		Color(0.36, 0.95, 0.75, 0.55), 2.0, true)
