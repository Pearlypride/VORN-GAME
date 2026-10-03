class_name PlaceholderModels
extends RefCounted
## Cheap primitive model builders. All use shared materials and leave collision untouched.

const TEAM_A_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_a.tres")
const TEAM_B_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_b.tres")
const ACCENT_MATERIAL: Material = preload("res://gameplay/presentation/materials/team_accent.tres")
const TEAM_A_LIGHT: Material = preload("res://gameplay/presentation/materials/team_a_light.tres")
const TEAM_B_LIGHT: Material = preload("res://gameplay/presentation/materials/team_b_light.tres")

static func build_hero() -> Node3D:
	var root := Node3D.new()
	root.name = "CharacterModel"
	_add(root, "Torso", _capsule(0.28, 0.78), Vector3(0.0, 1.02, 0.0), TEAM_A_MATERIAL)
	_add(root, "Pelvis", _box(Vector3(0.48, 0.25, 0.3)), Vector3(0.0, 0.62, 0.0), TEAM_A_MATERIAL)
	_add(root, "Head", _sphere(0.22), Vector3(0.0, 1.57, 0.0), TEAM_A_LIGHT)
	_add(root, "Helmet", _sphere(0.25), Vector3(0.0, 1.69, 0.0), ACCENT_MATERIAL).scale = Vector3(1.0, 0.48, 1.0)
	_add(root, "ArmLeft", _capsule(0.105, 0.56), Vector3(-0.36, 1.0, 0.0), TEAM_A_LIGHT)
	_add(root, "ArmRight", _capsule(0.105, 0.56), Vector3(0.36, 1.0, 0.0), TEAM_A_LIGHT)
	_add(root, "LegLeft", _capsule(0.13, 0.58), Vector3(-0.15, 0.28, 0.0), TEAM_A_MATERIAL)
	_add(root, "LegRight", _capsule(0.13, 0.58), Vector3(0.15, 0.28, 0.0), TEAM_A_MATERIAL)
	_add(root, "WeaponGrip", _cylinder(0.045, 0.32), Vector3(0.52, 0.92, -0.04), ACCENT_MATERIAL).rotation.z = -0.35
	_add(root, "WeaponBlade", _box(Vector3(0.11, 0.62, 0.055)), Vector3(0.65, 1.35, -0.04), TEAM_A_LIGHT).rotation.z = -0.22
	return root

static func build_minion(minion_type: MinionDefinition.MinionType, team: TeamRules.Team) -> Node3D:
	var root := Node3D.new()
	root.name = "CharacterModel"
	var body_material := _team_material(team)
	var light_material := _team_light(team)
	if minion_type == MinionDefinition.MinionType.MELEE:
		_add(root, "Body", _capsule(0.34, 0.72), Vector3(0.0, 0.53, 0.0), body_material)
		_add(root, "ShoulderArmor", _box(Vector3(0.78, 0.22, 0.38)), Vector3(0.0, 0.76, 0.0), light_material)
		_add(root, "Helmet", _sphere(0.24), Vector3(0.0, 1.02, 0.0), ACCENT_MATERIAL).scale = Vector3(1.2, 0.65, 1.0)
		_add(root, "ShortBlade", _box(Vector3(0.09, 0.48, 0.07)), Vector3(0.48, 0.58, -0.04), ACCENT_MATERIAL).rotation.z = -0.3
		_add(root, "BladeGrip", _cylinder(0.035, 0.2), Vector3(0.45, 0.36, -0.04), body_material)
	else:
		_add(root, "Body", _capsule(0.23, 0.78), Vector3(0.0, 0.55, 0.0), body_material)
		_add(root, "Hood", _sphere(0.25), Vector3(0.0, 1.06, 0.0), light_material).scale = Vector3(0.9, 0.8, 1.0)
		_add(root, "Staff", _cylinder(0.045, 1.1), Vector3(0.43, 0.58, -0.04), ACCENT_MATERIAL)
		_add(root, "StaffCore", _sphere(0.14), Vector3(0.43, 1.18, -0.04), light_material)
	return root

static func build_tower(team: TeamRules.Team) -> Node3D:
	var root := Node3D.new()
	root.name = "TowerModel"
	var body_material := _team_material(team)
	var light_material := _team_light(team)
	_add(root, "Foundation", _cylinder(1.42, 0.5), Vector3(0.0, 0.25, 0.0), body_material)
	_add(root, "LowerBand", _cylinder(1.08, 0.42), Vector3(0.0, 0.68, 0.0), ACCENT_MATERIAL)
	_add(root, "Shaft", _cylinder(0.78, 2.0), Vector3(0.0, 1.85, 0.0), body_material)
	_add(root, "UpperPlatform", _cylinder(1.15, 0.38), Vector3(0.0, 2.94, 0.0), light_material)
	_add(root, "Crown", _cylinder(0.78, 0.68), Vector3(0.0, 3.45, 0.0), body_material)
	_add(root, "Emitter", _sphere(0.38), Vector3(0.0, 3.98, 0.0), light_material)
	return root

static func _add(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _team_material(team: TeamRules.Team) -> Material:
	return TEAM_A_MATERIAL if team == TeamRules.Team.TEAM_A else TEAM_B_MATERIAL

static func _team_light(team: TeamRules.Team) -> Material:
	return TEAM_A_LIGHT if team == TeamRules.Team.TEAM_A else TEAM_B_LIGHT

static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh

static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh

static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh
