extends Node

## Active trend slots with meme market multipliers.

class ActiveTrend:
	var id: String
	var name: String
	var base_bonus: float
	var volatility: float
	var momentum: float
	var market_multiplier: float
	var lifespan_remaining: float
	var previous_multiplier: float

	func _init(def: Dictionary) -> void:
		id = def.get("id", "")
		name = def.get("name", "Trend")
		base_bonus = float(def.get("base_bonus", 1.0))
		volatility = float(def.get("volatility", 0.12))
		momentum = float(def.get("momentum", 0.0))
		market_multiplier = base_bonus
		previous_multiplier = base_bonus
		lifespan_remaining = float(DataLoader.trends_config.get("lifespan_sec", 120))

	func is_rising() -> bool:
		return market_multiplier > previous_multiplier

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"base_bonus": base_bonus,
			"volatility": volatility,
			"momentum": momentum,
			"market_multiplier": market_multiplier,
			"previous_multiplier": previous_multiplier,
			"lifespan_remaining": lifespan_remaining,
		}

	static func from_dict(data: Dictionary) -> ActiveTrend:
		var t := ActiveTrend.new(data)
		t.market_multiplier = float(data.get("market_multiplier", t.base_bonus))
		t.previous_multiplier = float(data.get("previous_multiplier", t.market_multiplier))
		t.lifespan_remaining = float(data.get("lifespan_remaining", 120))
		return t


var active_trends: Array[ActiveTrend] = []
var _used_ids: Array[String] = []


func _ready() -> void:
	if active_trends.is_empty():
		_fill_active_trends()


func _process(delta: float) -> void:
	for trend in active_trends:
		trend.lifespan_remaining -= delta
	_replace_expired()


func _fill_active_trends() -> void:
	var target := int(DataLoader.trends_config.get("active_count", 3))
	while active_trends.size() < target:
		_add_random_trend()


func _add_random_trend() -> void:
	var pool: Array = DataLoader.get_all_trend_defs()
	if pool.is_empty():
		return
	var candidates: Array = []
	for def in pool:
		var tid: String = def.get("id", "")
		if tid not in _used_ids or _used_ids.size() >= pool.size():
			candidates.append(def)
	if candidates.is_empty():
		_used_ids.clear()
		candidates = pool.duplicate()

	var pick: Dictionary = candidates[randi() % candidates.size()]
	var trend := ActiveTrend.new(pick)
	active_trends.append(trend)
	if pick.get("id", "") not in _used_ids:
		_used_ids.append(pick.get("id", ""))
	EventBus.trends_updated.emit()


func _replace_expired() -> void:
	var replaced := false
	for i in range(active_trends.size() - 1, -1, -1):
		if active_trends[i].lifespan_remaining <= 0.0:
			active_trends.remove_at(i)
			replaced = true
	if replaced:
		_fill_active_trends()
		EventBus.trends_updated.emit()


func get_trend_by_id(trend_id: String) -> ActiveTrend:
	for t in active_trends:
		if t.id == trend_id:
			return t
	return null


func get_best_trend() -> ActiveTrend:
	if active_trends.is_empty():
		return null
	var best: ActiveTrend = active_trends[0]
	for t in active_trends:
		if t.market_multiplier > best.market_multiplier:
			best = t
	return best


func serialize() -> Dictionary:
	var arr: Array = []
	for t in active_trends:
		arr.append(t.to_dict())
	return {"active": arr, "used_ids": _used_ids}


func deserialize(data: Dictionary) -> void:
	active_trends.clear()
	for item in data.get("active", []):
		active_trends.append(ActiveTrend.from_dict(item))
	_used_ids.assign(data.get("used_ids", []))
	if active_trends.is_empty():
		_fill_active_trends()
	EventBus.trends_updated.emit()
