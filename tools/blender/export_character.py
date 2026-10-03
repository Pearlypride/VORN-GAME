"""Reusable GLB export helper for VORN rigged characters."""

from pathlib import Path
import bpy


def export_character(output_path: Path) -> None:
	output_path = Path(output_path).resolve()
	output_path.parent.mkdir(parents=True, exist_ok=True)
	# Export only the tagged character hierarchy; generated Blender cameras and
	# lights are intentionally excluded. Blender's glTF exporter writes Y-up GLB.
	character_objects = [obj for obj in bpy.context.scene.objects if obj.get("vorn_character") == "KARN"]
	if not character_objects:
		raise RuntimeError("No KARN-tagged objects found to export")
	bpy.ops.object.select_all(action="DESELECT")
	for obj in character_objects:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = next((obj for obj in character_objects if obj.type == "ARMATURE"), character_objects[0])
	bpy.ops.export_scene.gltf(
		filepath=str(output_path),
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_yup=True,
		export_skins=True,
		export_animations=True,
		export_animation_mode="ACTIONS",
		export_frame_range=True,
	)
	if not output_path.is_file() or output_path.stat().st_size == 0:
		raise RuntimeError(f"GLB export failed: {output_path}")
	print(f"EXPORTED_KARN_GLB={output_path} ({output_path.stat().st_size} bytes)")
