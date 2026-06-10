extends Control

const STAGE_NAMES := ["IDEA", "FILM", "EDIT", "CAP", "POST"]

@onready var columns: HBoxContainer = $Scroll/Columns


var _refresh_cooldown: float = 0.0


func _ready() -> void:
	EventBus.pipeline_updated.connect(_refresh)
	EventBus.game_loaded.connect(func(): call_deferred("_refresh"))
	call_deferred("_refresh")


func _process(delta: float) -> void:
	_refresh_cooldown -= delta
	if _refresh_cooldown <= 0.0:
		_refresh_cooldown = 0.15
		_refresh()


func _refresh() -> void:
	var pipeline := get_node("/root/Main/GameSystems/PipelineManager")
	if pipeline == null:
		return

	for child in columns.get_children():
		child.queue_free()

	for stage_idx in range(5):
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)

		var header := Label.new()
		header.text = STAGE_NAMES[stage_idx]
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 14)
		col.add_child(header)

		var jobs: Array = pipeline.stage_jobs[stage_idx]
		if jobs.is_empty():
			var empty := Label.new()
			empty.text = "—"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.modulate = Color(0.5, 0.5, 0.55)
			col.add_child(empty)
		else:
			for job in jobs:
				col.add_child(_make_job_bar(job))

		columns.add_child(col)


func _make_job_bar(job: ReelJob) -> Control:
	var box := VBoxContainer.new()
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = job.progress * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 28)
	box.add_child(bar)

	if job.assigned_trend_id != "":
		var trend_lbl := Label.new()
		trend_lbl.text = job.assigned_trend_id.substr(0, 8)
		trend_lbl.add_theme_font_size_override("font_size", 11)
		trend_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(trend_lbl)

	return box
