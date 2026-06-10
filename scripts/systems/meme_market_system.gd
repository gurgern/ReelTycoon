extends Node

var _tick_timer: float = 0.0
var _trend_system: Node


func _ready() -> void:
	_trend_system = get_parent().get_node("TrendSystem")


func _process(delta: float) -> void:
	var tick_sec := float(DataLoader.trends_config.get("market_tick_sec", 5))
	_tick_timer += delta
	if _tick_timer >= tick_sec:
		_tick_timer = 0.0
		_market_tick()


func _market_tick() -> void:
	if _trend_system == null:
		return
	var min_mult := float(DataLoader.trends_config.get("multiplier_min", 0.3))
	var max_mult := float(DataLoader.trends_config.get("multiplier_max", 2.5))
	var reversion := float(DataLoader.trends_config.get("mean_reversion_rate", 0.08))

	for trend in _trend_system.active_trends:
		trend.previous_multiplier = trend.market_multiplier
		var delta_rand := randf_range(-1.0, 1.0) * trend.volatility
		delta_rand += trend.momentum
		var pull := (trend.base_bonus - trend.market_multiplier) * reversion
		trend.market_multiplier = clampf(
			trend.market_multiplier + delta_rand + pull,
			min_mult,
			max_mult
		)
	EventBus.trends_updated.emit()


func simulate_offline(elapsed_sec: int) -> void:
	var tick_sec := float(DataLoader.trends_config.get("market_tick_sec", 5))
	var ticks := int(elapsed_sec / tick_sec)
	for _i in ticks:
		_market_tick()


func boost_trend(trend_id: String, amount: float) -> void:
	for trend in _trend_system.active_trends:
		if trend.id == trend_id:
			trend.previous_multiplier = trend.market_multiplier
			trend.market_multiplier = clampf(
				trend.market_multiplier + amount,
				float(DataLoader.trends_config.get("multiplier_min", 0.3)),
				float(DataLoader.trends_config.get("multiplier_max", 2.5))
			)
			EventBus.trends_updated.emit()
			return


func crash_highest() -> void:
	if _trend_system.active_trends.is_empty():
		return
	var highest = _trend_system.get_best_trend()
	if highest:
		highest.previous_multiplier = highest.market_multiplier
		highest.market_multiplier = maxf(
			float(DataLoader.trends_config.get("multiplier_min", 0.3)),
			highest.market_multiplier * 0.4
		)
		EventBus.trends_updated.emit()


func revive_lowest() -> void:
	if _trend_system.active_trends.is_empty():
		return
	var lowest = _trend_system.active_trends[0]
	for t in _trend_system.active_trends:
		if t.market_multiplier < lowest.market_multiplier:
			lowest = t
	lowest.previous_multiplier = lowest.market_multiplier
	lowest.market_multiplier = clampf(
		lowest.market_multiplier + 0.8,
		float(DataLoader.trends_config.get("multiplier_min", 0.3)),
		float(DataLoader.trends_config.get("multiplier_max", 2.5))
	)
	EventBus.trends_updated.emit()


func moon_random() -> void:
	if _trend_system.active_trends.is_empty():
		return
	var pick = _trend_system.active_trends[randi() % _trend_system.active_trends.size()]
	boost_trend(pick.id, pick.market_multiplier * 0.5)


func serialize() -> Dictionary:
	return {"tick_timer": _tick_timer}


func deserialize(data: Dictionary) -> void:
	_tick_timer = float(data.get("tick_timer", 0.0))
