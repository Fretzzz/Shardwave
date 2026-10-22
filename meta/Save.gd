extends Node
## Persistence. One ConfigFile at user://save.cfg, no node knowledge.
##
## Autoload order matters: Save is created before Audio, so settings are pushed
## out by apply_settings() (called from Boot) rather than in _ready().

const PATH := "user://save.cfg"
## Bump when the shape of the file changes; _migrate() brings old files forward.
const SCHEMA := 3

var schema := SCHEMA
var save_path := PATH

var best_classic := 0
var best_rush := 0
var best_daily := 0
var runs := 0
var lines := 0
var prisms := 0

## Daily Shard: the last day that was finished ("YYYY-MM-DD"), its score, and
## the run of consecutive days completed.
var daily_date := ""
var daily_score := 0
var daily_streak := 0
var daily_last := ""
## Completed daily date keys, oldest first, capped at 30 for the menu strip.
var daily_history: Array[String] = []

var haptics := true
var sound := true


func _ready() -> void:
	load_game()


func load_game() -> void:
	schema = SCHEMA
	best_classic = 0
	best_rush = 0
	best_daily = 0
	runs = 0
	lines = 0
	prisms = 0
	daily_date = ""
	daily_score = 0
	daily_streak = 0
	daily_last = ""
	daily_history.clear()
	haptics = true
	sound = true

	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	schema = maxi(0, int(cfg.get_value("meta", "schema", 0)))
	best_classic = cfg.get_value("scores", "best_classic", 0)
	best_rush = cfg.get_value("scores", "best_rush", 0)
	best_daily = cfg.get_value("scores", "best_daily", 0)
	runs = cfg.get_value("scores", "runs", 0)
	lines = cfg.get_value("scores", "lines", 0)
	prisms = cfg.get_value("scores", "prisms", 0)
	daily_date = cfg.get_value("daily", "date", "")
	daily_score = cfg.get_value("daily", "score", 0)
	daily_streak = cfg.get_value("daily", "streak", 0)
	daily_last = cfg.get_value("daily", "last", "")
	for key in cfg.get_value("daily", "history", []):
		daily_history.append(str(key))
	haptics = cfg.get_value("settings", "haptics", true)
	sound = cfg.get_value("settings", "sound", true)
	_migrate(schema)


## Brings an older save forward. Every step must be idempotent, because a
## crash mid-write leaves the file at the previous schema.
func _migrate(from_schema: int) -> void:
	if from_schema == SCHEMA:
		return
	if from_schema < 1:
		pass # schema 0 had no [meta] section; the defaults above cover it
	if from_schema < 2:
		pass # schema 2 added rush/daily scores; defaults are already correct
	if from_schema < 3:
		pass # schema 3 added the daily history strip; it starts empty
	schema = SCHEMA
	save_game()


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema", SCHEMA)
	cfg.set_value("scores", "best_classic", best_classic)
	cfg.set_value("scores", "best_rush", best_rush)
	cfg.set_value("scores", "best_daily", best_daily)
	cfg.set_value("scores", "runs", runs)
	cfg.set_value("scores", "lines", lines)
	cfg.set_value("scores", "prisms", prisms)
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "score", daily_score)
	cfg.set_value("daily", "streak", daily_streak)
	cfg.set_value("daily", "last", daily_last)
	cfg.set_value("daily", "history", daily_history)
	cfg.set_value("settings", "haptics", haptics)
	cfg.set_value("settings", "sound", sound)
	cfg.save(save_path)


## Records a finished run. Returns true when it set a new personal best.
func record_run(mode: String, run_score: int, run_lines: int, run_prisms: int) -> bool:
	runs += 1
	lines += run_lines
	prisms += run_prisms
	var is_best := false
	if mode == "rush":
		is_best = run_score > best_rush
		if is_best:
			best_rush = run_score
	elif mode == "daily":
		is_best = run_score > best_daily
		if is_best:
			best_daily = run_score
	else:
		is_best = run_score > best_classic
		if is_best:
			best_classic = run_score
	save_game()
	return is_best


func best_for(mode: String) -> int:
	if mode == "rush":
		return best_rush
	if mode == "daily":
		return best_daily
	return best_classic


func daily_played(key: String) -> bool:
	return daily_date == key


## Locks today's shard and advances the streak. Called once, on finishing.
func record_daily(key: String, run_score: int) -> void:
	if daily_last != key:
		if daily_last != "" and daily_last == ModeRules.previous_day_key(key):
			daily_streak += 1
		else:
			daily_streak = 1
	daily_last = key
	daily_date = key
	daily_score = run_score
	if not daily_history.has(key):
		daily_history.append(key)
		while daily_history.size() > 30:
			daily_history.remove_at(0)
	save_game()


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
