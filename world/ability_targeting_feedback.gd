extends Node3D
## Input-facing debug previews. Materials communicate valid/invalid aim; gameplay still validates casts.

@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _abilities: AbilityController = get_node("../Player/AbilityController") as AbilityController
@onready var _camera: Camera3D = get_viewport().get_camera_3d()
@onready var _range_ring: MeshInstance3D = $CastRangeRing as MeshInstance3D
@onready var _point_marker: MeshInstance3D = $CastPointMarker as MeshInstance3D
@onready var _area_ring: MeshInstance3D = $AreaRadiusRing as MeshInstance3D
@onready var _aim_line: MeshInstance3D = $AimLine as MeshInstance3D
@onready var _target_ring: MeshInstance3D = $CastTargetRing as MeshInstance3D

var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _range_material: StandardMaterial3D
var _last_hovered_target: Node3D
var _last_mouse := Vector2(-1.0, -1.0)
var _last_player_position := Vector3(INF, INF, INF)

func _ready() -> void:
	_valid_material = _make_material(Color(0.2, 1.0, 0.45, 0.9))
	_invalid_material = _make_material(Color(1.0, 0.22, 0.16, 0.9))
	_range_material = _make_material(Color(0.24, 0.7, 1.0, 0.8))
	_range_ring.material_override = _range_material
	_point_marker.material_override = _valid_material
	_area_ring.material_override = _valid_material
	_aim_line.material_override = _valid_material
	_target_ring.material_override = _valid_material
	_range_ring.rotation_degrees.x = 90.0
	_area_ring.rotation_degrees.x = 90.0
	_target_ring.rotation_degrees.x = 90.0
	_abilities.targeting_changed.connect(_on_targeting_changed)
	_hide_all()

func _process(_delta: float) -> void:
	_update_preview()

func _on_targeting_changed(_ability_id: StringName) -> void:
	_update_preview(true)

func _update_preview(force: bool = false) -> void:
	if not _abilities.is_targeting():
		_hide_all()
		return
	var mouse := get_viewport().get_mouse_position()
	var player_position := _player.global_position
	if not force and mouse == _last_mouse and player_position.distance_squared_to(_last_player_position) < 0.0025:
		return
	_last_mouse = mouse
	_last_player_position = player_position
	var definition := _abilities.get_ability_definition(_abilities.current_targeting_ability)
	if definition == null:
		_hide_all()
		return
	_range_ring.show()
	_range_ring.global_position = Vector3(player_position.x, 0.045, player_position.z)
	_range_ring.scale = Vector3(definition.cast_range, 1.0, definition.cast_range)
	var aim_point: Variant = _get_aim_point()
	if aim_point == null:
		_hide_aim_markers()
		return
	var ground_point: Vector3 = aim_point
	ground_point.y = 0.065
	var offset := ground_point - player_position
	offset.y = 0.0
	var aim_distance := offset.length()
	var in_range := aim_distance <= definition.cast_range
	var endpoint := ground_point
	if not in_range and aim_distance > 0.001:
		endpoint = player_position + offset.normalized() * definition.cast_range
		endpoint.y = 0.065
	var targeted := definition.cast_type == AbilityDefinition.CastType.TARGETED
	var valid_target := targeted and _abilities.is_valid_enemy_target(_last_hovered_target)
	var marker_material := (_valid_material if valid_target else _invalid_material) if targeted else (_valid_material if in_range else _invalid_material)
	_point_marker.material_override = marker_material
	_area_ring.material_override = marker_material
	_aim_line.material_override = marker_material
	_target_ring.material_override = _valid_material if valid_target else _invalid_material
	_point_marker.visible = not targeted or _last_hovered_target == null
	_point_marker.global_position = endpoint
	_target_ring.visible = targeted and _last_hovered_target != null
	if _target_ring.visible:
		_target_ring.global_position = Vector3(_last_hovered_target.global_position.x, 0.07, _last_hovered_target.global_position.z)
	_area_ring.visible = definition.cast_type == AbilityDefinition.CastType.AREA
	_aim_line.visible = definition.cast_type == AbilityDefinition.CastType.POINT
	if _area_ring.visible:
		var area_effect := definition.effect as AreaDamageEffect
		var radius := area_effect.radius if area_effect != null else 3.0
		_area_ring.global_position = endpoint
		_area_ring.scale = Vector3(radius, 1.0, radius)
	if _aim_line.visible and aim_distance > 0.01:
		var line_vector := endpoint - player_position
		var line_length := line_vector.length()
		_aim_line.global_position = player_position + line_vector * 0.5 + Vector3.UP * 0.075
		_aim_line.global_basis = Basis.looking_at(line_vector.normalized(), Vector3.UP)
		_aim_line.scale = Vector3(1.0, 1.0, line_length)

func _get_aim_point() -> Variant:
	_last_hovered_target = null
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return null
	var origin := _camera.project_ray_origin(get_viewport().get_mouse_position())
	var end := origin + _camera.project_ray_normal(get_viewport().get_mouse_position()) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector3(_player.global_position.x, 0.0, _player.global_position.z)
	var collider := hit.get("collider") as Node3D
	if collider != null and collider.is_in_group("combat_target"):
		_last_hovered_target = collider
	var point: Vector3 = hit["position"]
	point.y = 0.0
	return point

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _hide_all() -> void:
	_range_ring.hide()
	_hide_aim_markers()

func _hide_aim_markers() -> void:
	_point_marker.hide()
	_area_ring.hide()
	_aim_line.hide()
	_target_ring.hide()
