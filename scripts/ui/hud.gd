extends Control

@onready var followers_label: Label = $Margin/VBox/Followers
@onready var cash_label: Label = $Margin/VBox/Cash
@onready var mood_label: Label = $Margin/VBox/MoodRow/Mood
@onready var mood_face: Label = $Margin/VBox/MoodRow/Face
@onready var drama_bar: ProgressBar = $Margin/VBox/DramaBar


func _ready() -> void:
	EventBus.stats_changed.connect(_refresh)
	EventBus.game_loaded.connect(_refresh)
	_refresh()


func _refresh() -> void:
	followers_label.text = "Followers: %s" % _fmt(GameState.followers)
	cash_label.text = "Cash: $%.2f" % GameState.cash
	mood_label.text = "Algo Mood: %d" % int(GameState.algorithm_mood)
	drama_bar.value = GameState.drama
	mood_face.text = _mood_emoji(GameState.algorithm_mood)


func _mood_emoji(mood: float) -> String:
	if mood >= 70:
		return "^^"
	if mood >= 40:
		return "--"
	return "xx"


func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
