class_name Ui
extends RefCounted
## Presentation tokens + draw helpers shared by Boot, Menu and Results.
## Pure static: no nodes, no state. Game.gd keeps its own copies deliberately,
## because the board needs per-frame constants and this is chrome.

const BG := Color("120A2A")
const PANEL := Color("1E1140")
const MINT := Color("5CF2C0")
const PINK := Color("FF5FA2")
const BUTTER := Color("FFD166")
const SKY := Color("5AC8FA")
const TEXT := Color("F4F0FF")
const DIM := Color("8A7AB8")
const INK := Color("0C0620")


## 12345 -> "12,345"
static func thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## Angular "shard" pill: fill, hairline border, mint corner notch.
static func panel(ci: CanvasItem, rect: Rect2, fill: Color, border: Color,
		border_width: float = 2.0, notch: bool = true) -> void:
	ci.draw_rect(rect, fill, true)
	ci.draw_rect(rect, border, false, border_width)
	if notch:
		var n := minf(18.0, rect.size.y * 0.22)
		ci.draw_rect(Rect2(rect.position + Vector2(rect.size.x - n, 0.0), Vector2(n, border_width)),
			Ui.MINT, true)


static func label(ci: CanvasItem, pos: Vector2, text: String, font_size: int,
		color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		width: float = -1.0) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, text, align, width, font_size, color)
