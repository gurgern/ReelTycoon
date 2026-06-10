extends Node

var economy: Dictionary = {}
var trends_config: Dictionary = {}
var events_config: Dictionary = {}
var upgrades_config: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	economy = _load_json("res://data/economy.json")
	trends_config = _load_json("res://data/trends.json")
	events_config = _load_json("res://data/events.json")
	upgrades_config = _load_json("res://data/upgrades.json")


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: failed to open %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("DataLoader: invalid JSON at %s" % path)
		return {}
	return parsed


func get_stage_duration(stage: String) -> float:
	var durations: Dictionary = economy.get("stage_durations_sec", {})
	return float(durations.get(stage, 3.0))


func get_upgrade_def(upgrade_id: String) -> Dictionary:
	for u in upgrades_config.get("upgrades", []):
		if u.get("id", "") == upgrade_id:
			return u
	return {}


func get_all_upgrades() -> Array:
	return upgrades_config.get("upgrades", [])


func get_all_trend_defs() -> Array:
	return trends_config.get("trends", [])


func get_all_events() -> Array:
	return events_config.get("events", [])
