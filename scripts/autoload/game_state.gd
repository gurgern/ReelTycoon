extends Node

const SAVE_PATH := "user://save.json"
const SAVE_INTERVAL_SEC := 30.0

var followers: int = 0
var total_views: int = 0
var cash: float = 0.0
var algorithm_mood: float = 50.0
var drama: float = 0.0

var upgrade_levels: Dictionary = {}
var pending_trend_id: String = ""
var tutorial_step: int = 0
var tutorial_done: bool = false
var next_job_id: int = 1
var cancelled_until_ms: int = 0
var has_won: bool = false

var _save_timer: float = 0.0
var _last_save_unix: int = 0
var _pending_save: Dictionary = {}


func _ready() -> void:
	_init_upgrade_levels()
	if FileAccess.file_exists(SAVE_PATH):
		_load_save_into_state()
	else:
		_last_save_unix = int(Time.get_unix_time_from_system())


func finish_boot_from_main() -> void:
	if not _pending_save.is_empty():
		_deserialize_systems(_pending_save)
		_pending_save.clear()
	else:
		EventBus.game_loaded.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _process(delta: float) -> void:
	_save_timer += delta
	if _save_timer >= SAVE_INTERVAL_SEC:
		_save_timer = 0.0
		save_game()


func _init_upgrade_levels() -> void:
	for u in DataLoader.get_all_upgrades():
		var uid: String = u.get("id", "")
		if uid != "" and not upgrade_levels.has(uid):
			upgrade_levels[uid] = 0


func is_cancelled() -> bool:
	return Time.get_ticks_msec() < cancelled_until_ms


func trigger_cancelled() -> void:
	var duration := float(DataLoader.economy.get("drama_cancel_duration_sec", 30))
	cancelled_until_ms = Time.get_ticks_msec() + int(duration * 1000.0)
	drama = 0.0
	EventBus.cancelled_state_changed.emit(true)


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func get_upgrade_cost(upgrade_id: String) -> float:
	var def := DataLoader.get_upgrade_def(upgrade_id)
	if def.is_empty():
		return 999999.0
	var level := get_upgrade_level(upgrade_id)
	var max_level := int(def.get("max_level", 1))
	if level >= max_level:
		return -1.0
	var base := float(def.get("base_cost", 25))
	var growth := float(DataLoader.economy.get("upgrade_cost_growth", 1.15))
	return base * pow(growth, level)


func can_buy_upgrade(upgrade_id: String) -> bool:
	var def := DataLoader.get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	if followers < int(def.get("unlock_followers", 0)):
		return false
	var cost := get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false
	return cash >= cost


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost := get_upgrade_cost(upgrade_id)
	cash -= cost
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	EventBus.upgrade_purchased.emit(upgrade_id)
	EventBus.stats_changed.emit()
	save_game()
	return true


func get_stage_speed_mult(stage: String) -> float:
	var mult := 1.0
	for u in DataLoader.get_all_upgrades():
		if u.get("effect_type", "") != "stage_speed":
			continue
		if str(u.get("stage", "")) != stage:
			continue
		var level := get_upgrade_level(u.get("id", ""))
		mult += float(u.get("effect_per_level", 0)) * level

	if get_upgrade_level("cousin_iphone") > 0 and stage == "film":
		mult += 0.15

	var coffee_level := get_upgrade_level("coffee_machine")
	mult += float(DataLoader.get_upgrade_def("coffee_machine").get("effect_per_level", 0.05)) * coffee_level

	return mult


func get_global_speed_mult() -> float:
	return 1.0


func get_view_mult() -> float:
	var mult := 1.0
	var level := get_upgrade_level("view_boost")
	mult += float(DataLoader.get_upgrade_def("view_boost").get("effect_per_level", 0.05)) * level
	return mult


func get_idea_slot_count() -> int:
	return 1 + get_upgrade_level("idea_slot")


func has_auto_trend() -> bool:
	return get_upgrade_level("trend_stalker") > 0


func apply_publish_reward(views: int, cash_gained: float, followers_gained: int) -> void:
	total_views += views
	cash += cash_gained
	followers += followers_gained
	EventBus.stats_changed.emit()
	_check_win()


func add_cash(amount: float) -> void:
	cash += amount
	EventBus.stats_changed.emit()
	_check_win()


func modify_mood(delta: float) -> void:
	algorithm_mood = clampf(algorithm_mood + delta, 0.0, 100.0)
	EventBus.stats_changed.emit()


func modify_drama(delta: float) -> void:
	drama = clampf(drama + delta, 0.0, 100.0)
	EventBus.stats_changed.emit()
	var threshold := float(DataLoader.economy.get("drama_cancel_threshold", 100))
	if drama >= threshold:
		trigger_cancelled()


func _check_win() -> void:
	if has_won:
		return
	var win_followers := int(DataLoader.economy.get("win_followers", 10000))
	var win_cash := float(DataLoader.economy.get("win_cash", 1000))
	if followers >= win_followers or cash >= win_cash:
		has_won = true
		EventBus.win_condition_met.emit()


func save_game() -> void:
	_last_save_unix = int(Time.get_unix_time_from_system())
	var pipeline := get_node_or_null("/root/Main/GameSystems/PipelineManager")
	var trends := get_node_or_null("/root/Main/GameSystems/TrendSystem")
	var meme_market := get_node_or_null("/root/Main/GameSystems/MemeMarketSystem")

	var data := {
		"version": 1,
		"last_save_unix": _last_save_unix,
		"followers": followers,
		"total_views": total_views,
		"cash": cash,
		"algorithm_mood": algorithm_mood,
		"drama": drama,
		"upgrade_levels": upgrade_levels,
		"pending_trend_id": pending_trend_id,
		"tutorial_step": tutorial_step,
		"tutorial_done": tutorial_done,
		"next_job_id": next_job_id,
		"has_won": has_won,
	}

	if pipeline and pipeline.has_method("serialize"):
		data["pipeline"] = pipeline.serialize()
	if trends and trends.has_method("serialize"):
		data["trends"] = trends.serialize()
	if meme_market and meme_market.has_method("serialize"):
		data["meme_market"] = meme_market.serialize()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _load_save_into_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return

	followers = int(parsed.get("followers", 0))
	total_views = int(parsed.get("total_views", 0))
	cash = float(parsed.get("cash", 0))
	algorithm_mood = float(parsed.get("algorithm_mood", 50))
	drama = float(parsed.get("drama", 0))
	upgrade_levels = parsed.get("upgrade_levels", {})
	pending_trend_id = str(parsed.get("pending_trend_id", ""))
	tutorial_step = int(parsed.get("tutorial_step", 0))
	tutorial_done = bool(parsed.get("tutorial_done", false))
	next_job_id = int(parsed.get("next_job_id", 1))
	has_won = bool(parsed.get("has_won", false))
	_last_save_unix = int(parsed.get("last_save_unix", int(Time.get_unix_time_from_system())))
	_init_upgrade_levels()
	_pending_save = parsed


func _deserialize_systems(parsed: Dictionary) -> void:
	var pipeline := get_node_or_null("/root/Main/GameSystems/PipelineManager")
	var trends := get_node_or_null("/root/Main/GameSystems/TrendSystem")
	var meme_market := get_node_or_null("/root/Main/GameSystems/MemeMarketSystem")

	if pipeline and pipeline.has_method("deserialize") and parsed.has("pipeline"):
		pipeline.deserialize(parsed["pipeline"])
	if trends and trends.has_method("deserialize") and parsed.has("trends"):
		trends.deserialize(parsed["trends"])
	if meme_market and meme_market.has_method("deserialize") and parsed.has("meme_market"):
		meme_market.deserialize(parsed["meme_market"])

	var elapsed := clampi(
		int(Time.get_unix_time_from_system()) - _last_save_unix,
		0,
		int(DataLoader.economy.get("offline_cap_sec", 14400))
	)
	if elapsed > 5:
		_apply_offline(elapsed)

	EventBus.game_loaded.emit()


func _apply_offline(elapsed_sec: int) -> void:
	var efficiency := float(DataLoader.economy.get("offline_efficiency", 0.5))
	var pipeline := get_node_or_null("/root/Main/GameSystems/PipelineManager")
	var meme_market := get_node_or_null("/root/Main/GameSystems/MemeMarketSystem")
	var views_before := total_views
	var cash_before := cash
	var followers_before := followers

	if meme_market and meme_market.has_method("simulate_offline"):
		meme_market.simulate_offline(elapsed_sec)
	if pipeline and pipeline.has_method("simulate_offline"):
		pipeline.simulate_offline(float(elapsed_sec) * efficiency)

	EventBus.offline_summary.emit(
		total_views - views_before,
		cash - cash_before,
		followers - followers_before
	)


func get_last_save_unix() -> int:
	return _last_save_unix
