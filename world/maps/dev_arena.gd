extends Node3D

func _ready() -> void:
	$CameraRig/Camera3D.look_at(Vector3.ZERO, Vector3.UP)
