extends Node3D

func _ready() -> void:
	$CameraRig/Camera3D.look_at(Vector3(-10.0, 0.0, 0.0), Vector3.UP)
