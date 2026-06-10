extends Control

@onready var new_reel_btn: Button = $Layout/NewReelBtn
@onready var tutorial_label: Label = $Layout/TutorialLabel
@onready var cancelled_overlay: ColorRect = $CancelledOverlay
@onready var cancelled_label: Label = $CancelledOverlay/Label
@onready var offline_modal: PanelContainer = $OfflineModal
@onready var offline_text: Label = $OfflineModal/Margin/VBox/Text
@onready var offline_close: Button = $OfflineModal/Margin/VBox/Close
@onready var win_modal: PanelContainer = $WinModal
@onready var win_close: Button = $WinModal/Margin/VBox/Close
@onready var float_layer: Control = $FloatLayer


func _ready() -> void:
	new_reel_btn.pressed.connect(_on_new_reel)
	offline_close.pressed.connect(func(): offline_modal.visible = false)
	win_close.pressed.connect(func(): win_modal.visible = false)

	EventBus.reel_published.connect(_on_reel_published)
	EventBus.cancelled_state_changed.connect(_on_cancelled)
	EventBus.offline_summary.connect(_on_offline)
	EventBus.win_condition_met.connect(_on_win)
	EventBus.tutorial_step.connect(_on_tutorial)
	EventBus.float_text.connect(_spawn_float)

	cancelled_overlay.visible = false
	offline_modal.visible = false
	win_modal.visible = false

	GameState.finish_boot_from_main()
	_update_tutorial()
	call_deferred("_refresh_new_reel_btn")


func _process(_delta: float) -> void:
	cancelled_overlay.visible = GameState.is_cancelled()


func _on_new_reel() -> void:
	var pipeline := $GameSystems/PipelineManager
	if pipeline.start_new_reel():
		new_reel_btn.disabled = not pipeline.can_start_reel()
	else:
		new_reel_btn.disabled = true

	call_deferred("_refresh_new_reel_btn")


func _refresh_new_reel_btn() -> void:
	var pipeline := $GameSystems/PipelineManager
	new_reel_btn.disabled = not pipeline.can_start_reel() or GameState.is_cancelled()


func _on_reel_published(_views: int, _cash: float, _followers: int) -> void:
	call_deferred("_refresh_new_reel_btn")


func _on_cancelled(active: bool) -> void:
	cancelled_overlay.visible = active
	if active:
		cancelled_label.text = "CANCELLED\n(touch grass for 30s)"
		new_reel_btn.disabled = true


func _on_offline(views: int, cash: float, followers: int) -> void:
	if views == 0 and cash == 0.0 and followers == 0:
		return
	offline_text.text = "While you were gone...\n+%d views\n+$%.2f\n+%d followers" % [views, cash, followers]
	offline_modal.visible = true


func _on_win() -> void:
	win_modal.visible = true


func _on_tutorial(step: int) -> void:
	_update_tutorial_text(step)


func _update_tutorial() -> void:
	if GameState.tutorial_done:
		tutorial_label.visible = false
	else:
		_update_tutorial_text(GameState.tutorial_step)


func _update_tutorial_text(step: int) -> void:
	tutorial_label.visible = not GameState.tutorial_done
	match step:
		0:
			tutorial_label.text = "Tap NEW REEL IDEA to start your empire"
		1:
			tutorial_label.text = "Pick a RISING trend (▲) on the Meme Market"
		2:
			tutorial_label.text = "Buy an upgrade to speed up the pipeline"
		_:
			tutorial_label.visible = false


func _spawn_float(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(randf_range(180, 540), randf_range(400, 700))
	float_layer.add_child(lbl)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 80, 1.2)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(lbl.queue_free)

	# Screen shake on big publish
	if text.contains("VIRAL"):
		var root := $Layout
		var shake := create_tween()
		var orig := root.position
		for _i in 4:
			shake.tween_property(root, "position", orig + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.05)
		shake.tween_property(root, "position", orig, 0.05)
