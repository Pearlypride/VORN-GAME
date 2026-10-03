extends Node
## Selection adapter: actor-owned rings where present, one reusable ring for other actor types.

const RING_MATERIAL: Material = preload("res://gameplay/presentation/materials/selection_ring.tres")

@onready var _combat: CombatComponent = get_node("../Player/Combat") as CombatComponent
var _selected_actor: Node3D
var _fallback_ring: MeshInstance3D

func _ready() -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.72
	ring_mesh.outer_radius = 0.79
	_fallback_ring = MeshInstance3D.new()
	_fallback_ring.name = "GenericSelectionRing"
	_fallback_ring.mesh = ring_mesh
	_fallback_ring.material_override = RING_MATERIAL
	_fallback_ring.rotation_degrees.x = 90.0
	_fallback_ring.visible = false
	get_parent().call_deferred("add_child", _fallback_ring)
	_combat.target_changed.connect(_on_target_changed)

func _process(_delta: float) -> void:
	if _fallback_ring.visible and is_instance_valid(_selected_actor):
		_fallback_ring.global_position = Vector3(_selected_actor.global_position.x, 0.06, _selected_actor.global_position.z)

func _on_target_changed(target: Node3D) -> void:
	_set_ring_visible(_selected_actor, false)
	_selected_actor = target
	if not _set_ring_visible(_selected_actor, true) and is_instance_valid(_selected_actor):
		_fallback_ring.visible = true
		_fallback_ring.global_position = Vector3(_selected_actor.global_position.x, 0.06, _selected_actor.global_position.z)
	else:
		_fallback_ring.visible = false

func _set_ring_visible(actor: Node3D, ring_visible: bool) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	var ring := actor.get_node_or_null("SelectionRing") as Node3D
	if ring == null:
		return false
	ring.visible = ring_visible
	return true
