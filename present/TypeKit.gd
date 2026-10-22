class_name TypeKit
extends RefCounted
## Typography for the crystalline UI. One bundled variable font (Space Grotesk,
## SIL OFL) plus cached FontVariation weights. No theme resources: every screen
## draws text directly, so the whole type system is one lookup.

const FACE_PATH := "res://fonts/SpaceGrotesk-Variable.ttf"

static var _face: Font = null
static var _cache: Dictionary = {}
static var _wght_tag := -1


static func face() -> Font:
	if _face == null:
		var f = load(FACE_PATH)
		_face = f if f != null else ThemeDB.fallback_font
	return _face


static func _tag() -> int:
	if _wght_tag < 0:
		var ts := TextServerManager.get_primary_interface()
		_wght_tag = ts.name_to_tag("wght")
	return _wght_tag


## Builds and caches a variation. `tracking` is extra pixels between glyphs;
## `embolden` is a last-resort weight boost for fallback fonts.
static func _variant(weight: int, tracking: int = 0, embolden: float = 0.0) -> Font:
	var key := "%d:%d:%.2f" % [weight, tracking, embolden]
	if _cache.has(key):
		return _cache[key]
	var fv := FontVariation.new()
	fv.base_font = face()
	fv.variation_opentype = {_tag(): weight}
	fv.spacing_glyph = tracking
	fv.variation_embolden = embolden
	_cache[key] = fv
	return fv


static func body() -> Font:
	return _variant(400)


static func medium() -> Font:
	return _variant(500)


static func bold() -> Font:
	return _variant(650)


## Wide, confident display type for the wordmark and big scores.
static func display() -> Font:
	return _variant(600, 1)


## Tracked uppercase micro-labels ("SCORE", "GAME MODES").
static func micro() -> Font:
	return _variant(550, 3)


## Tabular figures keep live scores from shimmying as digits change.
static func number() -> Font:
	return _variant(600, 0, 0.0)
