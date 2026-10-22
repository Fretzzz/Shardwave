extends Node
## Central haptics gateway.
##
## Rule: nothing anywhere else may call Input.vibrate_handheld() directly.
## When we add amplitude patterns later (Android VibratorManager via plugin),
## only this file changes and the entire game inherits better haptics.

const MIN_MS := 10

## User-facing setting, wired to the settings menu later.
var enabled := true


func _ready() -> void:
	# Keep the service alive across every scene.
	process_mode = Node.PROCESS_MODE_ALWAYS


func pulse(duration_ms: int = 20, strength: float = 1.0) -> void:
	if not enabled:
		return
	if OS.get_name() != "Android":
		return
	Input.vibrate_handheld(maxi(MIN_MS, duration_ms), clampf(strength, 0.0, 1.0))


# --- Semantic events. Game code calls these, never raw durations. ---

func place() -> void:
	pulse(12, 0.5)


func line() -> void:
	pulse(25, 0.8)


func multi(line_count: int = 2) -> void:
	pulse(30 + 8 * line_count, 1.0)


## The money shot: a three-beat pattern that reads as "charge, hit, aftermath".
func prism() -> void:
	pulse(40, 1.0)
	await get_tree().create_timer(0.09).timeout
	pulse(60, 1.0)
	await get_tree().create_timer(0.14).timeout
	pulse(90, 0.7)


func ready_pulse() -> void:
	pulse(30, 0.4)
