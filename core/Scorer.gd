class_name Scorer
extends RefCounted
## Single source of truth for score math. Tunable, unit tested, no side effects.

const POINTS_PER_CELL := 10
const COMBO_STEP := 0.25        ## each consecutive clear adds +25%
const SIMULTANEOUS_STEP := 0.5  ## each extra line in one placement adds +50%
const CHAIN_STEP := 1.5         ## each prism wave multiplies by 1.5


static func combo_multiplier(combo: int) -> float:
	return 1.0 + COMBO_STEP * maxf(0.0, float(combo - 1))


static func line_score(line_count: int, cell_count: int, combo: int, chain_depth: int) -> int:
	var simultaneous := 1.0 + SIMULTANEOUS_STEP * maxf(0.0, float(line_count - 1))
	var chain := pow(CHAIN_STEP, float(maxi(0, chain_depth)))
	return int(round(POINTS_PER_CELL * cell_count * combo_multiplier(combo) * simultaneous * chain))
