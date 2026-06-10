extends Control

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var desc_label: Label = $Panel/Margin/VBox/Desc


func _ready() -> void:
	panel.visible = false
	EventBus.event_toast.connect(_show_toast)


func _show_toast(title: String, description: String) -> void:
	title_label.text = title
	desc_label.text = description
	panel.visible = true
	modulate.a = 1.0

	var tween := create_tween()
	tween.tween_interval(3.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): panel.visible = false; modulate.a = 1.0)
