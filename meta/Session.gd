extends Node
## Cross-scene run state: which mode is being played, what seed it uses, and
## the summary the results screen renders. Deliberately a plain dictionary, so
## Results never has to know about RunState or the board.

var mode := "classic"
var run_seed := 0
var daily_key := ""
var daily_shard := 0
var last: Dictionary = {}


func begin(mode_name: String) -> void:
	mode = mode_name
	last = {}
	run_seed = 0
	daily_key = ""
	daily_shard = 0
	if mode == "daily":
		var date := ModeRules.today()
		daily_key = ModeRules.date_key(date)
		daily_shard = ModeRules.shard_number(date)
		run_seed = ModeRules.daily_seed(date)


func finish(run_score: int, run_lines: int, run_prisms: int, run_placements: int,
		extra: Dictionary = {}) -> void:
	var is_best := Save.record_run(mode, run_score, run_lines, run_prisms)
	last = {
		"mode": mode,
		"score": run_score,
		"lines": run_lines,
		"prisms": run_prisms,
		"placements": run_placements,
		"best": Save.best_for(mode),
		"new_best": is_best,
	}
	if mode == "daily":
		Save.record_daily(daily_key, run_score)
		last["daily_key"] = daily_key
		last["shard"] = daily_shard
		last["streak"] = Save.daily_streak
	last.merge(extra)
