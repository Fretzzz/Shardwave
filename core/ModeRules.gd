class_name ModeRules
extends RefCounted
## Numbers and calendar math that differ per mode. Pure: no scene, no Save,
## no node. Kept here so the rules can be tested without a running game.

const RUSH_START := 90.0
const RUSH_PER_LINE := 1.5
const RUSH_PER_PRISM := 4.0
const RUSH_MAX := 999.0


## Seconds a clear gives back in Void Rush.
static func rush_bonus(result: ClearResult) -> float:
	return result.lines * RUSH_PER_LINE + result.prisms * RUSH_PER_PRISM


## Stable seed for a calendar day: 2026-10-22 -> 20261022.
static func daily_seed(date: Dictionary) -> int:
	return int(date.year) * 10000 + int(date.month) * 100 + int(date.day)


## "2026-10-22"
static func date_key(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]


## Menu label for the day's shard: Oct 22 -> 1022.
static func shard_number(date: Dictionary) -> int:
	return int(date.month) * 100 + int(date.day)


static func today() -> Dictionary:
	return Time.get_date_dict_from_system()


## Key for the day before, used for streaks. Noon UTC keeps DST out of it.
static func previous_day_key(key: String) -> String:
	var noon := Time.get_unix_time_from_datetime_string(key + "T12:00:00")
	return date_key(Time.get_datetime_dict_from_unix_time(int(noon) - 86400))
