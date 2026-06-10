extends Node

var _drift_timer: float = 0.0


func _process(delta: float) -> void:
	_drift_timer += delta
	if _drift_timer >= 60.0:
		_drift_timer = 0.0
		var drift := float(DataLoader.economy.get("algorithm_mood_drift_per_min", 3.0))
		GameState.modify_mood(randf_range(-drift, drift))


func get_multiplier() -> float:
	# 0 mood -> 0.5x, 100 mood -> 1.5x
	return 0.5 + (GameState.algorithm_mood / 100.0)


func apply_event_delta(delta: float, duration_sec: float = 0.0) -> void:
	GameState.modify_mood(delta)
	if duration_sec > 0.0:
		# Simple timed mood effect handled via immediate delta for MVP
		pass
