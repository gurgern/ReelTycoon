extends Node

var _timer: float = 0.0
var _next_event_sec: float = 45.0

var _pipeline: Node
var _meme_market: Node
var _algorithm: Node


func _ready() -> void:
	_schedule_next()
	_pipeline = get_parent().get_node("PipelineManager")
	_meme_market = get_parent().get_node("MemeMarketSystem")
	_algorithm = get_parent().get_node("AlgorithmSystem")


func _process(delta: float) -> void:
	if GameState.is_cancelled():
		return
	_timer += delta
	if _timer >= _next_event_sec:
		_timer = 0.0
		_trigger_random_event()
		_schedule_next()


func _schedule_next() -> void:
	var min_i := float(DataLoader.events_config.get("min_interval_sec", 30))
	var max_i := float(DataLoader.events_config.get("max_interval_sec", 90))
	_next_event_sec = randf_range(min_i, max_i)


func _trigger_random_event() -> void:
	var events: Array = DataLoader.get_all_events()
	if events.is_empty():
		return
	var ev: Dictionary = events[randi() % events.size()]
	var title: String = ev.get("title", "Something happened")
	var desc: String = ev.get("description", "")

	if ev.has("drama_delta"):
		GameState.modify_drama(float(ev["drama_delta"]))
	if ev.has("algorithm_mood_delta"):
		_algorithm.apply_event_delta(float(ev["algorithm_mood_delta"]), float(ev.get("duration_sec", 0)))
	if ev.has("cash_delta"):
		GameState.add_cash(float(ev["cash_delta"]))

	var market_event: String = ev.get("market_event", "")
	match market_event:
		"moon":
			_meme_market.moon_random()
		"burst":
			_meme_market.crash_highest()
		"revival":
			_meme_market.revive_lowest()

	EventBus.event_toast.emit(title, desc)
