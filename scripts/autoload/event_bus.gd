extends Node

signal stats_changed
signal reel_published(views: int, cash: float, followers_gained: int)
signal trends_updated
signal event_toast(title: String, description: String)
signal pipeline_updated
signal upgrade_purchased(upgrade_id: String)
signal win_condition_met
signal offline_summary(views: int, cash: float, followers: int)
signal cancelled_state_changed(active: bool)
signal float_text(text: String, color: Color)
signal tutorial_step(step: int)
signal game_loaded
