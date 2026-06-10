extends Control

@onready var list: VBoxContainer = $Panel/Margin/Tabs/List
@onready var tab_pipeline: Button = $Panel/Margin/Tabs/TabRow/TabPipeline
@onready var tab_staff: Button = $Panel/Margin/Tabs/TabRow/TabStaff
@onready var tab_global: Button = $Panel/Margin/Tabs/TabRow/TabGlobal
@onready var tab_chaos: Button = $Panel/Margin/Tabs/TabRow/TabChaos

var _current_tab: String = "pipeline"


func _ready() -> void:
	tab_pipeline.pressed.connect(func(): _set_tab("pipeline"))
	tab_staff.pressed.connect(func(): _set_tab("staff"))
	tab_global.pressed.connect(func(): _set_tab("global"))
	tab_chaos.pressed.connect(func(): _set_tab("chaos"))
	EventBus.stats_changed.connect(_refresh)
	EventBus.upgrade_purchased.connect(func(_id): _refresh())
	EventBus.game_loaded.connect(func(): call_deferred("_refresh"))
	call_deferred("_refresh")


func _set_tab(tab: String) -> void:
	_current_tab = tab
	_refresh()


func _refresh() -> void:
	for child in list.get_children():
		child.queue_free()

	for def in DataLoader.get_all_upgrades():
		if def.get("tab", "") != _current_tab:
			continue
		list.add_child(_make_upgrade_row(def))


func _make_upgrade_row(def: Dictionary) -> Control:
	var uid: String = def.get("id", "")
	var level := GameState.get_upgrade_level(uid)
	var max_level := int(def.get("max_level", 1))
	var cost := GameState.get_upgrade_cost(uid)
	var unlock := int(def.get("unlock_followers", 0))
	var can_buy := GameState.can_buy_upgrade(uid)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = "%s (Lv %d/%d)" % [def.get("name", ""), level, max_level]
	name_lbl.add_theme_font_size_override("font_size", 16)
	info.add_child(name_lbl)
	var desc := Label.new()
	desc.text = def.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.modulate = Color(0.75, 0.75, 0.8)
	info.add_child(desc)
	if followers_locked(unlock):
		var lock_lbl := Label.new()
		lock_lbl.text = "Unlock at %d followers" % unlock
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock_lbl.modulate = Color(1.0, 0.7, 0.3)
		info.add_child(lock_lbl)
	row.add_child(info)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(100, 48)
	if cost < 0:
		buy.text = "MAX"
		buy.disabled = true
	elif not can_buy:
		buy.text = "$%.0f" % cost
		buy.disabled = true
	else:
		buy.text = "$%.0f" % cost
		buy.pressed.connect(func(): _buy(uid))
	row.add_child(buy)

	return row


func followers_locked(unlock: int) -> bool:
	return GameState.followers < unlock


func _buy(upgrade_id: String) -> void:
	if GameState.buy_upgrade(upgrade_id):
		if not GameState.tutorial_done and GameState.tutorial_step == 2:
			GameState.tutorial_step = 3
			GameState.tutorial_done = true
			EventBus.tutorial_step.emit(3)
		_refresh()
