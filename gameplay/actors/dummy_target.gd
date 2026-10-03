class_name DummyTarget
extends StaticBody3D

@export_range(0.1, 60.0, 0.1) var respawn_delay: float = 3.0
@onready var _stats: ActorStats = $Stats as ActorStats
@onready var _visual: Node3D = $Visual
@onready var _collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_stats.died.connect(_on_died)

func _on_died() -> void:
	_visual.hide()
	_collision.set_deferred("disabled", true)
	var timer := get_tree().create_timer(respawn_delay)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	_stats.restore_full_health()
	_visual.show()
	_collision.set_deferred("disabled", false)
