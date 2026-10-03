class_name ArenaInput
extends Node
## Right-click command adapter; other input sources can issue the same player orders.

@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _abilities: AbilityController = get_node("../Player/AbilityController") as AbilityController
@onready var _move_marker: Node3D = get_node("../MoveMarker") as Node3D
@onready var _move_marker_timer: Timer = get_node("../MoveMarkerTimer") as Timer

func _ready() -> void:
	_move_marker_timer.timeout.connect(_on_move_marker_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F3:
		var hud := get_node_or_null("../MobaHUD") as MobaHUD
		if hud != null:
			hud.toggle_debug()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("clear_command"):
		if _abilities.is_targeting():
			_abilities.cancel_targeting()
		else:
			_player.clear_command()
			_hide_move_marker()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("stop_command"):
		_abilities.cancel_targeting()
		_player.stop_command()
		_hide_move_marker()
		get_viewport().set_input_as_handled()
		return
	if _handle_ability_key(event):
		get_viewport().set_input_as_handled()
		return
	if _abilities.is_targeting():
		if event.is_action_pressed("issue_command"):
			_abilities.cancel_targeting()
			get_viewport().set_input_as_handled()
			return
		if not event.is_action_pressed("confirm_ability"):
			return
		_confirm_ability_from_pointer((event as InputEventMouseButton).position)
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("issue_command"):
		return
	var world_hit := _get_world_hit(event.position)
	if world_hit.is_empty():
		return
	var collider := world_hit["collider"] as Node3D
	if collider.is_in_group("combat_target"):
		_player.attack_target(collider)
		_hide_move_marker()
	else:
		var destination: Vector3 = world_hit["position"]
		_player.move_to(destination)
		_show_move_marker(destination)
	get_viewport().set_input_as_handled()

func _handle_ability_key(event: InputEvent) -> bool:
	var actions: Array[Dictionary] = [
		{"action": "cast_q", "id": &"q"},
		{"action": "cast_w", "id": &"w"},
		{"action": "cast_e", "id": &"e"},
		{"action": "cast_r", "id": &"r"},
	]
	for entry in actions:
		if event.is_action_pressed(entry["action"]):
			_abilities.request_cast(entry["id"])
			return true
	return false

func _confirm_ability_from_pointer(screen_position: Vector2) -> void:
	var hit := _get_world_hit(screen_position)
	if hit.is_empty():
		return
	var definition := _abilities.get_ability_definition(_abilities.current_targeting_ability)
	if definition == null:
		return
	if definition.cast_type == AbilityDefinition.CastType.TARGETED:
		var target := hit["collider"] as Node3D
		if target.is_in_group("combat_target"):
			_abilities.confirm_target(target)
	else:
		var point: Vector3 = hit["position"]
		point.y = 0.0
		_abilities.confirm_point(point)

func _get_world_hit(screen_position: Vector2) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player.get_rid()]
	return _player.get_world_3d().direct_space_state.intersect_ray(query)

func _show_move_marker(destination: Vector3) -> void:
	_move_marker.global_position = Vector3(destination.x, 0.025, destination.z)
	_move_marker.show()
	_move_marker_timer.start()

func _hide_move_marker() -> void:
	_move_marker_timer.stop()
	_move_marker.hide()

func _on_move_marker_timer_timeout() -> void:
	_move_marker.hide()
