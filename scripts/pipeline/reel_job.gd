class_name ReelJob
extends RefCounted

enum Stage { IDEA, FILM, EDIT, CAPTION, POST, DONE }

var id: int = 0
var current_stage: Stage = Stage.IDEA
var progress: float = 0.0
var assigned_trend_id: String = ""
var market_multiplier_at_commit: float = 1.0
var quality_roll: float = 1.0


func _init(job_id: int = 0) -> void:
	id = job_id
	quality_roll = randf_range(0.85, 1.15)


static func stage_name(stage: Stage) -> String:
	match stage:
		Stage.IDEA: return "idea"
		Stage.FILM: return "film"
		Stage.EDIT: return "edit"
		Stage.CAPTION: return "caption"
		Stage.POST: return "post"
		_: return "done"


func to_dict() -> Dictionary:
	return {
		"id": id,
		"current_stage": current_stage,
		"progress": progress,
		"assigned_trend_id": assigned_trend_id,
		"market_multiplier_at_commit": market_multiplier_at_commit,
		"quality_roll": quality_roll,
	}


static func from_dict(data: Dictionary) -> ReelJob:
	var job := ReelJob.new(int(data.get("id", 0)))
	job.current_stage = int(data.get("current_stage", Stage.IDEA))
	job.progress = float(data.get("progress", 0.0))
	job.assigned_trend_id = str(data.get("assigned_trend_id", ""))
	job.market_multiplier_at_commit = float(data.get("market_multiplier_at_commit", 1.0))
	job.quality_roll = float(data.get("quality_roll", 1.0))
	return job
