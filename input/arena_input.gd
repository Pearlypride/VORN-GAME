class_name ArenaInput
extends Node
## Right-click command adapter; other input sources can issue the same player orders.

@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _move_marker: Node3D = get_node("../MoveMarker") as Node3D
@onready var _move_marker_timer: Timer = get_node("../MoveMarkerTimer") as Timer

func _ready() -> void:
	_move_marker_timer.timeout.connect(_on_move_marker_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("clear_command"):
		_player.clear_command()
		_hide_move_marker()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("stop_command"):
		_player.stop_command()
		_hide_move_marker()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("issue_command"):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(event.position)
	var end := origin + camera.project_ray_normal(event.position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider := hit["collider"] as Node3D
	if collider.is_in_group("combat_target"):
		_player.attack_target(collider)
		_hide_move_marker()
	else:
		var destination: Vector3 = hit["position"]
		_player.move_to(destination)
		_show_move_marker(destination)
	get_viewport().set_input_as_handled()

func _show_move_marker(destination: Vector3) -> void:
	_move_marker.global_position = Vector3(destination.x, 0.025, destination.z)
	_move_marker.show()
	_move_marker_timer.start()

func _hide_move_marker() -> void:
	_move_marker_timer.stop()
	_move_marker.hide()

func _on_move_marker_timer_timeout() -> void:
	_move_marker.hide()
