"""Deterministically generate, rig, animate, save, and export prototype KARN."""

from pathlib import Path
import math
import sys

import bpy
from mathutils import Euler

TOOLS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = TOOLS_DIR.parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(TOOLS_DIR))
from export_character import export_character

SOURCE_PATH = PROJECT_ROOT / "art/blender/karn.blend"
EXPORT_PATH = PROJECT_ROOT / "art/exports/karn.glb"

MATERIALS = {
	"charcoal": ((0.075, 0.088, 0.105, 1.0), 0.72, 0.22),
	"warm_metal": ((0.31, 0.19, 0.105, 1.0), 0.62, 0.28),
	"ember": ((0.55, 0.055, 0.035, 1.0), 0.48, 0.22),
	"muted_cloth": ((0.16, 0.12, 0.105, 1.0), 0.9, 0.0),
}


def material(name):
	color, metallic, roughness = MATERIALS[name]
	mat = bpy.data.materials.new(f"KARN_{name}")
	mat.diffuse_color = color
	bsdf = mat.node_tree.nodes.get("Principled BSDF")
	bsdf.inputs["Base Color"].default_value = color
	bsdf.inputs["Metallic"].default_value = metallic
	bsdf.inputs["Roughness"].default_value = roughness
	return mat


def make_armature():
	arm_data = bpy.data.armatures.new("KARN_Rig")
	arm = bpy.data.objects.new("KARN_Armature", arm_data)
	bpy.context.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	arm.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	bones = {}
	def bone(name, head, tail, parent=None, connected=False):
		b = arm_data.edit_bones.new(name)
		b.head, b.tail = head, tail
		if parent:
			b.parent = bones[parent]
			b.use_connect = connected
		bones[name] = b
	bone("ROOT", (0, 0, 0), (0, 0, 0.22))
	bone("PELVIS", (0, 0, 0.22), (0, 0, 0.86), "ROOT")
	bone("SPINE", (0, 0, 0.86), (0, 0, 1.34), "PELVIS", True)
	bone("CHEST", (0, 0, 1.34), (0, 0, 1.82), "SPINE", True)
	bone("NECK", (0, 0, 1.82), (0, 0, 1.98), "CHEST", True)
	bone("HEAD", (0, 0, 1.98), (0, 0, 2.35), "NECK", True)
	for side, sign in (("L", -1), ("R", 1)):
		bone(f"UPPER_ARM_{side}", (sign * 0.36, 0, 1.66), (sign * 0.62, 0, 1.27), "CHEST")
		bone(f"FOREARM_{side}", (sign * 0.62, 0, 1.27), (sign * 0.76, -0.02, 0.91), f"UPPER_ARM_{side}", True)
		bone(f"HAND_{side}", (sign * 0.76, -0.02, 0.91), (sign * 0.78, -0.16, 0.72), f"FOREARM_{side}", True)
		bone(f"THIGH_{side}", (sign * 0.2, 0, 0.75), (sign * 0.23, 0, 0.40), "PELVIS")
		bone(f"SHIN_{side}", (sign * 0.23, 0, 0.40), (sign * 0.23, -0.02, 0.12), f"THIGH_{side}", True)
		bone(f"FOOT_{side}", (sign * 0.23, -0.02, 0.12), (sign * 0.23, -0.30, 0.08), f"SHIN_{side}", True)
	bone("WEAPON", (0.78, -0.16, 0.72), (1.03, -0.16, 1.22), "HAND_R")
	bpy.ops.object.mode_set(mode="OBJECT")
	arm.show_in_front = True
	arm.hide_render = True
	arm["vorn_character"] = "KARN"
	return arm


def add_piece(name, primitive, location, scale, mat, bone_name, parts, rotation=(0, 0, 0), subdivisions=1):
	if primitive == "cube":
		bpy.ops.mesh.primitive_cube_add(size=1, location=location)
		obj = bpy.context.object
		bevel = obj.modifiers.new("Soft low-poly edges", "BEVEL")
		bevel.width = 0.045
		bevel.segments = 1
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.modifier_apply(modifier=bevel.name)
	elif primitive == "ico":
		bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=location)
		obj = bpy.context.object
	elif primitive == "cylinder":
		bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=1, depth=1, location=location)
		obj = bpy.context.object
	elif primitive == "cone":
		bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=1, radius2=0.12, depth=1, location=location)
		obj = bpy.context.object
	else:
		raise ValueError(primitive)
	obj.name = name
	obj.rotation_euler = rotation
	obj.scale = scale
	obj.data.materials.append(mat)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	group = obj.vertex_groups.new(name=bone_name)
	if obj.data.vertices:
		group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
	parts.append(obj)
	return obj


def create_mesh(mats, arm):
	parts = []
	# In Blender local +Z is up and local -Y faces forward. Large forms first.
	add_piece("TorsoCore", "ico", (0, 0.0, 1.30), (0.56, 0.36, 0.72), mats["charcoal"], "SPINE", parts, subdivisions=2)
	add_piece("ChestMantle", "cube", (0, -0.005, 1.58), (1.12, 0.57, 0.48), mats["charcoal"], "CHEST", parts, rotation=(0.02, 0, 0),)
	add_piece("Breastplate", "ico", (0, -0.29, 1.54), (0.64, 0.18, 0.42), mats["warm_metal"], "CHEST", parts, subdivisions=1)
	add_piece("WaistSash", "cube", (0, 0, 0.89), (0.70, 0.44, 0.20), mats["muted_cloth"], "PELVIS", parts)
	add_piece("BeltClasp", "ico", (0, -0.238, 0.91), (0.17, 0.06, 0.16), mats["ember"], "PELVIS", parts, subdivisions=1)
	add_piece("NeckGuard", "cylinder", (0, 0.0, 1.87), (0.18, 0.18, 0.18), mats["warm_metal"], "NECK", parts)
	add_piece("Helmet", "ico", (0, 0.0, 2.08), (0.31, 0.29, 0.37), mats["charcoal"], "HEAD", parts, subdivisions=2)
	add_piece("FaceGuard", "cube", (0, -0.26, 2.03), (0.37, 0.13, 0.23), mats["warm_metal"], "HEAD", parts)
	add_piece("Visor", "cube", (0, -0.333, 2.11), (0.23, 0.035, 0.055), mats["ember"], "HEAD", parts)
	# One heavy asymmetrical pauldron, offset and readable at lane camera scale.
	add_piece("GreatPauldron", "ico", (-0.62, 0, 1.72), (0.45, 0.39, 0.38), mats["warm_metal"], "UPPER_ARM_L", parts, subdivisions=1)
	add_piece("PauldronRivet", "ico", (-0.62, -0.342, 1.74), (0.19, 0.07, 0.18), mats["ember"], "UPPER_ARM_L", parts, subdivisions=1)
	add_piece("ShoulderR", "ico", (0.45, 0, 1.62), (0.27, 0.31, 0.28), mats["charcoal"], "UPPER_ARM_R", parts, subdivisions=1)
	# Thick arms and oversized gauntlets.
	for side, x, bone_upper, bone_fore, bone_hand in (("L", -0.59, "UPPER_ARM_L", "FOREARM_L", "HAND_L"), ("R", 0.56, "UPPER_ARM_R", "FOREARM_R", "HAND_R")):
		add_piece(f"Bicep{side}", "ico", (x, 0, 1.34), (0.23, 0.24, 0.37), mats["charcoal"], bone_upper, parts, subdivisions=1)
		add_piece(f"Bracer{side}", "cylinder", (x * 1.18, -0.01, 1.03), (0.19, 0.21, 0.37), mats["warm_metal"], bone_fore, parts, rotation=(0, 0, 0.12 if side == "L" else -0.12))
		add_piece(f"Gauntlet{side}", "ico", (x * 1.24, -0.09, 0.82), (0.22, 0.25, 0.20), mats["charcoal"], bone_hand, parts, subdivisions=1)
	# Sturdy legs, separated by clear knee plates and broad boots.
	for side, x in (("L", -0.22), ("R", 0.22)):
		add_piece(f"Thigh{side}", "ico", (x, 0, 0.63), (0.23, 0.28, 0.39), mats["charcoal"], f"THIGH_{side}", parts, subdivisions=1)
		add_piece(f"Knee{side}", "cube", (x, -0.205, 0.40), (0.31, 0.13, 0.20), mats["warm_metal"], f"SHIN_{side}", parts)
		add_piece(f"Shin{side}", "cube", (x, 0.0, 0.25), (0.28, 0.32, 0.39), mats["charcoal"], f"SHIN_{side}", parts)
		add_piece(f"Boot{side}", "cube", (x, -0.14, 0.09), (0.32, 0.54, 0.20), mats["warm_metal"], f"FOOT_{side}", parts)
	# Oversized single cleaver: dark spine and warm edge mounted to WEAPON bone.
	add_piece("WeaponGrip", "cylinder", (0.90, -0.16, 0.98), (0.075, 0.075, 0.57), mats["muted_cloth"], "WEAPON", parts, rotation=(0, 0.47, 0))
	add_piece("CleaverBody", "cube", (1.16, -0.17, 1.48), (0.43, 0.13, 0.84), mats["charcoal"], "WEAPON", parts, rotation=(0, 0.47, -0.08))
	add_piece("CleaverEdge", "cube", (1.34, -0.245, 1.50), (0.12, 0.055, 0.75), mats["ember"], "WEAPON", parts, rotation=(0, 0.47, -0.08))
	add_piece("Pommel", "ico", (0.75, -0.16, 0.71), (0.14, 0.14, 0.15), mats["warm_metal"], "WEAPON", parts, subdivisions=1)

	bpy.ops.object.select_all(action="DESELECT")
	for part in parts:
		part.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	mesh = bpy.context.object
	mesh.name = "KARN_BodyMesh"
	mesh.data.name = "KARN_BodyMeshData"
	# The rigid low-poly pieces keep their explicit full-weight bone group when
	# joined. Armor overlaps the segment joints to avoid visible gaps.
	modifier = mesh.modifiers.new("KARN_Armature", "ARMATURE")
	modifier.object = arm
	mesh.parent = arm
	mesh["vorn_character"] = "KARN"
	arm["vorn_character"] = "KARN"
	return mesh


def key_pose(arm, frame, rotations):
	for pb in arm.pose.bones:
		pb.rotation_mode = "XYZ"
		pb.rotation_euler = Euler(rotations.get(pb.name, (0, 0, 0)), "XYZ")
		pb.keyframe_insert(data_path="rotation_euler", frame=frame, group=pb.name)


def add_animation(arm, name, frames, poses):
	action = bpy.data.actions.new(name)
	arm.animation_data_create()
	arm.animation_data.action = action
	for frame, pose in zip(frames, poses):
		key_pose(arm, frame, pose)
	action.use_fake_user = True
	return action


def create_animations(arm):
	# In-place clips. ATTACK_1 spans 0.533 s at 30 fps to mirror the current
	# prototype contract: windup 0.00–0.233 s, release 0.233–0.333 s,
	# recovery 0.333–0.533 s. Controller signals, never clip events, own release.
	add_animation(arm, "IDLE", [1, 16, 31], [
		{}, {"SPINE": (0.025, 0, 0), "CHEST": (-0.018, 0, 0)}, {},
	])
	add_animation(arm, "RUN", [1, 8, 16], [
		{}, {"UPPER_ARM_L": (0.42, 0, 0), "UPPER_ARM_R": (-0.42, 0, 0), "THIGH_L": (-0.48, 0, 0), "THIGH_R": (0.48, 0, 0), "SPINE": (0.04, 0, 0)},
		{},
	])
	add_animation(arm, "ATTACK_1", [1, 8, 11, 17], [
		{}, {"SPINE": (-0.16, 0, 0), "CHEST": (-0.18, 0, 0), "UPPER_ARM_R": (-0.42, 0, 0), "FOREARM_R": (-0.58, 0, 0), "WEAPON": (0, 0, -0.18)},
		{"SPINE": (0.22, 0, 0), "CHEST": (0.27, 0, 0), "UPPER_ARM_R": (0.38, 0, 0), "FOREARM_R": (0.24, 0, 0), "WEAPON": (0, 0, 0.22)},
		{},
	])
	add_animation(arm, "CAST", [1, 8, 20], [
		{}, {"SPINE": (-0.08, 0, 0), "UPPER_ARM_R": (-0.82, 0, 0), "FOREARM_R": (-0.55, 0, 0)}, {},
	])
	add_animation(arm, "HIT", [1, 4, 10], [
		{}, {"SPINE": (0.22, 0, 0.09), "CHEST": (0.12, 0, 0), "HEAD": (-0.12, 0, 0)}, {},
	])
	add_animation(arm, "DEATH", [1, 12, 24], [
		{}, {"SPINE": (0.22, 0, 0.22), "CHEST": (0.22, 0, 0), "UPPER_ARM_L": (0.4, 0, -0.4), "UPPER_ARM_R": (0.5, 0, 0.4)},
		{"SPINE": (0.9, 0, 0.18), "CHEST": (0.3, 0, 0), "HEAD": (0.16, 0, 0)},
	])
	for action in bpy.data.actions:
		if action.name in {"IDLE", "RUN", "ATTACK_1", "CAST", "HIT", "DEATH"}:
			for fcurve in getattr(action, "fcurves", []):
				for key in fcurve.keyframe_points:
					key.interpolation = "BEZIER"


def build():
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.context.preferences.filepaths.save_version = 0
	for name in MATERIALS:
		MATERIALS[name] = material(name)
	arm = make_armature()
	create_mesh(MATERIALS, arm)
	create_animations(arm)
	# Export and source files are produced from the same deterministic scene.
	Path(SOURCE_PATH).parent.mkdir(parents=True, exist_ok=True)
	bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH))
	export_character(EXPORT_PATH)
	print("KARN_BUILD_STATS", {
		"vertices": sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type == "MESH"),
		"triangles": sum(sum(max(0, len(p.vertices) - 2) for p in o.data.polygons) for o in bpy.context.scene.objects if o.type == "MESH"),
		"bones": len(arm.data.bones),
		"materials": len([m for m in bpy.data.materials if m.name.startswith("KARN_")]),
		"animations": [a.name for a in bpy.data.actions],
	})


if __name__ == "__main__":
	build()
