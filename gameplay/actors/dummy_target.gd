class_name DummyTarget
extends StaticBody3D

const ARMOR: Material = preload("res://gameplay/presentation/materials/hero_iron.tres")
const TARGET: Material = preload("res://gameplay/presentation/materials/team_b.tres")
const METAL: Material = preload("res://gameplay/presentation/materials/hero_edge.tres")
const TARGET_GLOW: Material = preload("res://gameplay/presentation/materials/hero_glow.tres")

@export_range(0.1, 60.0, 0.1) var respawn_delay: float = 3.0
@onready var _stats: ActorStats = $Stats as ActorStats
@onready var _visual: Node3D = $Visual
@onready var _collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_build_training_armor()
	_stats.died.connect(_on_died)

func _build_training_armor() -> void:
	if not (_visual is MeshInstance3D):
		return
	(_visual as MeshInstance3D).mesh = null
	_add_shape("ArmorCore", _capsule(0.43, 1.28), Vector3(0.0, 0.0, 0.0), ARMOR)
	_add_shape("TargetPlate", _box(Vector3(0.62, 0.62, 0.18)), Vector3(0.0, 0.0, -0.48), TARGET)
	_add_shape("HeadGuard", _box(Vector3(0.42, 0.24, 0.42)), Vector3(0.0, 0.58, 0.0), METAL)
	_add_shape("CrownSpike", _cylinder(0.055, 0.45), Vector3(0.0, 0.9, 0.0), TARGET)
	_add_shape("ShoulderGuardL", _box(Vector3(0.24, 0.22, 0.26)), Vector3(-0.43, 0.35, 0.0), METAL)
	_add_shape("ShoulderGuardR", _box(Vector3(0.24, 0.22, 0.26)), Vector3(0.43, 0.35, 0.0), METAL)
	_add_shape("TargetCore", _sphere(0.105), Vector3(0.0, 0.0, -0.6), TARGET_GLOW)

func _add_shape(node_name: String, mesh: Mesh, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	_visual.add_child(instance)

func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh

func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh

func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh

func _on_died() -> void:
	_visual.hide()
	_collision.set_deferred("disabled", true)
	var timer := get_tree().create_timer(respawn_delay)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	_stats.restore_full_health()
	_visual.show()
	_collision.set_deferred("disabled", false)
