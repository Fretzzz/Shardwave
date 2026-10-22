class_name ClearResult
extends RefCounted
## Everything the presentation layer needs to choreograph a clear.
## The resolver produces this; the FX director turns it into sound and light.

var cells: Array[Vector2i] = []      ## every cell removed
var lines: int = 0                   ## rows + cols completed by placement
var pure_lines: int = 0              ## lines that were >= 6 same color
var prisms: int = 0                  ## prisms detonated
var prisms_at: Array[Vector2i] = []  ## board positions that detonated, in wave order
var chain_depth: int = 0             ## prism-to-prism waves; 0 = no prism
var cell_count: int = 0
var score: int = 0

## Per-wave cell lists, so beams can be staggered 60ms apart instead of all at once.
var waves: Array = []                ## Array[Array[Vector2i]]
