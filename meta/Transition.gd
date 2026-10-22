extends CanvasLayer
## One-shot fade from the background colour whenever a scene becomes ready.
## Keeps scene changes from popping; no scene waits on it, so flow is unchanged.
## Scenes call Transition.play() at the end of their _ready().

var enabled := true

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.0705882, 0.0392157, 0.164706, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func play(duration: float = 0.28) -> void:
	if not enabled or _rect == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_rect.color.a = 1.0
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


## Jump straight to the visible scene. Used by screenshot harnesses.
func skip() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if _rect:
		_rect.color.a = 0.0
