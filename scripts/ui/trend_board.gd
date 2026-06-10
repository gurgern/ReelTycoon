extends Control

@onready var row: HBoxContainer = $Scroll/Row


func _ready() -> void:
	EventBus.trends_updated.connect(_refresh)
	EventBus.game_loaded.connect(func(): call_deferred("_refresh"))
	call_deferred("_refresh")


func _refresh() -> void:
	for child in row.get_children():
		child.queue_free()

	var trend_system := get_node("/root/Main/GameSystems/TrendSystem")
	if trend_system == null:
		return

	for trend in trend_system.active_trends:
		row.add_child(_make_trend_card(trend))


func _make_trend_card(trend) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 88)
	btn.toggle_mode = true
	btn.button_pressed = GameState.pending_trend_id == trend.id

	var arrow := "▲" if trend.is_rising() else "▼"
	var arrow_color := Color(0.3, 0.9, 0.4) if trend.is_rising() else Color(0.95, 0.35, 0.35)

	btn.text = "%s\n%.2fx %s" % [trend.name, trend.market_multiplier, arrow]
	btn.add_theme_font_size_override("font_size", 16)

	if trend.is_rising():
		btn.modulate = Color(0.85, 1.0, 0.85)
	else:
		btn.modulate = Color(1.0, 0.85, 0.85)

	btn.pressed.connect(func(): _select_trend(trend.id))
	return btn


func _select_trend(trend_id: String) -> void:
	if GameState.pending_trend_id == trend_id:
		GameState.pending_trend_id = ""
	else:
		GameState.pending_trend_id = trend_id

	if not GameState.tutorial_done and GameState.tutorial_step == 1:
		GameState.tutorial_step = 2
		EventBus.tutorial_step.emit(2)

	_refresh()
	EventBus.stats_changed.emit()
