extends Node
## Persistence. One ConfigFile at user://save.cfg, no node knowledge.
##
## Autoload order matters: Save is created before Audio, so settings are pushed
## out by apply_settings() (called from Boot) rather than in _ready().

const PATH := "user://save.cfg"

var best_classic := 0
var runs := 0
var lines := 0
var prisms := 0

var haptics := true
var sound := true


func _ready() -> void:
	load_game()


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	best_classic = cfg.get_value("scores", "best_classic", 0)
	runs = cfg.get_value("scores", "runs", 0)
	lines = cfg.get_value("scores", "lines", 0)
	prisms = cfg.get_value("scores", "prisms", 0)
	haptics = cfg.get_value("settings", "haptics", true)
	sound = cfg.get_value("settings", "sound", true)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best_classic", best_classic)
	cfg.set_value("scores", "runs", runs)
	cfg.set_value("scores", "lines", lines)
	cfg.set_value("scores", "prisms", prisms)
	cfg.set_value("settings", "haptics", haptics)
	cfg.set_value("settings", "sound", sound)
	cfg.save(PATH)


## Records a finished run. Returns true when it set a new personal best.
func record_run(run_score: int, run_lines: int, run_prisms: int) -> bool:
	runs += 1
	lines += run_lines
	prisms += run_prisms
	var is_best := run_score > best_classic
	if is_best:
		best_classic = run_score
	save_game()
	return is_best


func apply_settings() -> void:
	Haptics.enabled = haptics
	Audio.enabled = sound


func toggle_haptics() -> void:
	haptics = not haptics
	apply_settings()
	save_game()


func toggle_sound() -> void:
	sound = not sound
	apply_settings()
	save_game()
	if sound:
		Audio.ui()
