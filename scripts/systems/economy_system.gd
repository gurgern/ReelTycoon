extends Node

var _algorithm: Node
var _trend_system: Node


func _ready() -> void:
	_algorithm = get_parent().get_node("AlgorithmSystem")
	_trend_system = get_parent().get_node("TrendSystem")


func publish_reel(job: ReelJob) -> void:
	var base_views := int(DataLoader.economy.get("base_views", 120))
	var algo_mult := _algorithm.get_multiplier()
	var market_mult := job.market_multiplier_at_commit
	var quality := job.quality_roll

	if get_parent().get_node("PipelineManager").has_method("get_quality_penalty"):
		quality *= get_parent().get_node("PipelineManager").get_quality_penalty()

	var view_mult := GameState.get_view_mult()
	var views := int(base_views * algo_mult * market_mult * quality * view_mult)

	# Flop toast for crashing trend commitment
	if market_mult < 0.7:
		EventBus.event_toast.emit("You Missed The Wave", "That trend was already tanking. Oof.")

	var event_views_bonus := 1.0
	# Views bonus from recent events could stack; MVP uses flat publish

	var final_views := maxi(1, int(views * event_views_bonus))
	var cpm := float(DataLoader.economy.get("cpm_rate", 0.002))
	var cash_gained := final_views * cpm
	var follower_conv := float(DataLoader.economy.get("follower_conversion", 0.08))
	var followers_gained := maxi(0, int(final_views * follower_conv))

	GameState.apply_publish_reward(final_views, cash_gained, followers_gained)
	EventBus.reel_published.emit(final_views, cash_gained, followers_gained)
	EventBus.float_text.emit("+%d views" % final_views, Color(0.4, 0.9, 0.5))

	if final_views >= 500:
		EventBus.float_text.emit("VIRAL?!", Color(1.0, 0.85, 0.2))
