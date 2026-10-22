extends Node
## Cross-scene run state: which mode is being played, and the summary the
## results screen renders. Deliberately a plain dictionary, so Results never
## has to know about RunState or the board.

var mode := "classic"
var last: Dictionary = {}


func begin(mode_name: String) -> void:
	mode = mode_name
	last = {}


func finish(run_score: int, run_lines: int, run_prisms: int, run_placements: int) -> void:
	var is_best := Save.record_run(run_score, run_lines, run_prisms)
	last = {
		"mode": mode,
		"score": run_score,
		"lines": run_lines,
		"prisms": run_prisms,
		"placements": run_placements,
		"best": Save.best_classic,
		"new_best": is_best,
	}
