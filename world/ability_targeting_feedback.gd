extends Node3D
## Primitive world-space previews for ability range, aim, and area radius.

@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _abilities: AbilityController = get_node("../Player/AbilityController") as AbilityController
@onready var _camera: Camera3D = get_viewport().get_camera_3d()
@onready var _range_ring: MeshInstance3D = $CastRangeRing as MeshInstance3D
@onready var _point_marker: MeshInstance3D = $CastPointMarker as MeshInstance3D
@onready var _area_ring: MeshInstance3D = $AreaRadiusRing as MeshInstance3D
@onready var _aim_line: MeshInstance3D = $AimLine as MeshInstance3D

func _ready() -> void:
	_abilities.targeting_changed.connect(_on_targeting_changed)

func _process(_delta: float) -> void:
	_update_preview()

func _on_targeting_changed(_ability_id: StringName) -> void:
	_update_preview()

func _update_preview() -> void:
	if not _abilities.is_targeting():
		_hide_all()
		return
	var definition := _abilities.get_ability_definition(_abilities.current_targeting_ability)
	if definition == null:
		_hide_all()
		return
	_range_ring.show()
	_range_ring.global_position = Vector3(_player.global_position.x, 0.035, _player.global_position.z)
	_range_ring.scale = Vector3(definition.cast_range, 1.0, definition.cast_range)
	var aim_point: Variant = _get_aim_point()
	_point_marker.visible = aim_point != null
	_area_ring.visible = aim_point != null and definition.cast_type == AbilityDefinition.CastType.AREA
	_aim_line.visible = aim_point != null and definition.cast_type == AbilityDefinition.CastType.POINT
	if aim_point == null:
		return
	var ground_point: Vector3 = aim_point
	ground_point.y = 0.04
	_point_marker.global_position = ground_point
	if _area_ring.visible:
		var area_effect := definition.effect as AreaDamageEffect
		var radius := area_effect.radius if area_effect != null else 3.0
		_area_ring.global_position = ground_point
		_area_ring.scale = Vector3(radius, 1.0, radius)
	if _aim_line.visible:
		var direction := ground_point - _player.global_position
		direction.y = 0.0
		var line_length := minf(direction.length(), definition.cast_range)
		if line_length > 0.01:
			_aim_line.global_position = _player.global_position + direction.normalized() * (line_length * 0.5) + Vector3.UP * 0.06
			_aim_line.global_basis = Basis.looking_at(direction.normalized(), Vector3.UP)
			_aim_line.scale = Vector3(1.0, 1.0, line_length)

func _get_aim_point() -> Variant:
	if _camera == null:
		return null
	var mouse_position := get_viewport().get_mouse_position()
	var origin := _camera.project_ray_origin(mouse_position)
	var end := origin + _camera.project_ray_normal(mouse_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector3(_player.global_position.x, 0.0, _player.global_position.z)
	var point: Vector3 = hit["position"]
	point.y = 0.0
	return point

func _hide_all() -> void:
	_range_ring.hide()
	_point_marker.hide()
	_area_ring.hide()
	_aim_line.hide()
