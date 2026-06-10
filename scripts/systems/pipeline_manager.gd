extends Node

## One job slot per pipeline stage (MVP default).

var stage_jobs: Array = [[], [], [], [], []]
var _economy: Node
var _trend_system: Node
var _next_job_id: int = 1


func _ready() -> void:
	_economy = get_parent().get_node("EconomySystem")
	_trend_system = get_parent().get_node("TrendSystem")
	_next_job_id = GameState.next_job_id


func _process(delta: float) -> void:
	if GameState.is_cancelled():
		return

	for stage_idx in range(ReelJob.Stage.POST + 1):
		var jobs: Array = stage_jobs[stage_idx]
		var max_slots := _get_slot_count(stage_idx)
		while jobs.size() > max_slots:
			jobs.pop_back()

		for job in jobs.duplicate():
			if job == null:
				continue
			var stage_name := ReelJob.stage_name(job.current_stage)
			var duration := DataLoader.get_stage_duration(stage_name)
			var speed := GameState.get_stage_speed_mult(stage_name) * GameState.get_global_speed_mult()
			job.progress += (delta * speed) / maxf(duration, 0.01)

			if job.progress >= 1.0:
				job.progress = 0.0
				_advance_job(job, stage_idx)


func _get_slot_count(stage_idx: int) -> int:
	if stage_idx == ReelJob.Stage.IDEA:
		return GameState.get_idea_slot_count()
	return int(DataLoader.economy.get("slots_per_stage", 1))


func get_quality_penalty() -> float:
	if GameState.get_upgrade_level("cousin_iphone") > 0:
		return 0.95
	return 1.0


func can_start_reel() -> bool:
	return stage_jobs[ReelJob.Stage.IDEA].size() < _get_slot_count(ReelJob.Stage.IDEA)


func start_new_reel() -> bool:
	if not can_start_reel():
		return false

	var job := ReelJob.new(_next_job_id)
	_next_job_id += 1
	GameState.next_job_id = _next_job_id

	var trend_id := GameState.pending_trend_id
	if trend_id == "" and GameState.has_auto_trend():
		var best = _trend_system.get_best_trend()
		if best:
			trend_id = best.id

	if trend_id != "":
		var trend = _trend_system.get_trend_by_id(trend_id)
		if trend:
			job.assigned_trend_id = trend.id
			job.market_multiplier_at_commit = trend.market_multiplier
		else:
			job.market_multiplier_at_commit = 0.6
			EventBus.event_toast.emit("Dead Trend", "That trend expired. Cringe incoming.")
	else:
		job.market_multiplier_at_commit = 0.8

	stage_jobs[ReelJob.Stage.IDEA].append(job)
	EventBus.pipeline_updated.emit()

	if not GameState.tutorial_done and GameState.tutorial_step == 0:
		GameState.tutorial_step = 1
		EventBus.tutorial_step.emit(1)

	return true


func _advance_job(job: ReelJob, from_stage_idx: int) -> void:
	stage_jobs[from_stage_idx].erase(job)

	if job.current_stage >= ReelJob.Stage.POST:
		_economy.publish_reel(job)
		EventBus.pipeline_updated.emit()
		return

	job.current_stage += 1
	stage_jobs[job.current_stage].append(job)
	EventBus.pipeline_updated.emit()


func simulate_offline(elapsed_sec: float) -> void:
	var step := 0.1
	var remaining := elapsed_sec
	while remaining > 0.0:
		var dt := minf(step, remaining)
		_process(dt)
		remaining -= dt


func serialize() -> Dictionary:
	var data: Array = []
	for stage in stage_jobs:
		var stage_data: Array = []
		for job in stage:
			if job is ReelJob:
				stage_data.append(job.to_dict())
		data.append(stage_data)
	return {"stages": data, "next_job_id": _next_job_id}


func deserialize(data: Dictionary) -> void:
	stage_jobs = [[], [], [], [], []]
	var stages: Array = data.get("stages", [])
	for i in range(mini(stages.size(), 5)):
		for job_data in stages[i]:
			stage_jobs[i].append(ReelJob.from_dict(job_data))
	_next_job_id = int(data.get("next_job_id", 1))
	GameState.next_job_id = _next_job_id
	EventBus.pipeline_updated.emit()
