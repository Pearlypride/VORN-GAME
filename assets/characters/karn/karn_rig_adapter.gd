class_name KarnRigAdapter
extends Node3D
## Model-only adapter. ActorPresentation calls this; gameplay never lives here.

const CLIP_BY_STATE := {
	ActorPresentation.VisualState.IDLE: "IDLE",
	ActorPresentation.VisualState.MOVE: "RUN",
	ActorPresentation.VisualState.ATTACK_WINDUP: "ATTACK_1",
	ActorPresentation.VisualState.ATTACK_RELEASE: "ATTACK_1",
	ActorPresentation.VisualState.ATTACK_RECOVERY: "ATTACK_1",
	ActorPresentation.VisualState.CAST: "CAST",
	ActorPresentation.VisualState.HIT: "HIT",
	ActorPresentation.VisualState.DEATH: "DEATH",
}

var animation_player: AnimationPlayer
var current_visual_state: int = ActorPresentation.VisualState.IDLE
var current_clip: StringName = &""

func validate_imported_rig() -> bool:
	var found_player := _find_animation_player(self)
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D
	var body_mesh := find_child("KARN_BodyMesh", true, false) as MeshInstance3D
	if found_player == null or skeleton == null or skeleton.get_bone_count() < 19 or body_mesh == null or body_mesh.skin == null:
		return false
	for clip_name in ["IDLE", "RUN", "ATTACK_1", "CAST", "HIT", "DEATH"]:
		if not found_player.has_animation(clip_name):
			return false
	return true

func _ready() -> void:
	animation_player = _find_animation_player(self)
	if not validate_imported_rig():
		push_error("KARN rig scene is incomplete; primitive fallback should be selected by ActorPresentation")
		return
	for clip_name in ["IDLE", "RUN"]:
		if animation_player.has_animation(clip_name):
			var clip := animation_player.get_animation(clip_name)
			clip.loop_mode = Animation.LOOP_LINEAR
	play_visual_state(ActorPresentation.VisualState.IDLE)

func play_visual_state(state: int, _detail: StringName = &"") -> void:
	current_visual_state = state
	if animation_player == null:
		return
	var clip_name: String = CLIP_BY_STATE.get(state, "IDLE")
	# One continuous ATTACK_1 clip spans windup, release and recovery. Do not
	# restart it as gameplay advances between those authoritative phases.
	if state in [ActorPresentation.VisualState.ATTACK_RELEASE, ActorPresentation.VisualState.ATTACK_RECOVERY] and current_clip == &"ATTACK_1":
		return
	if not animation_player.has_animation(clip_name):
		push_error("KARN rig is missing clip: " + clip_name)
		return
	current_clip = StringName(clip_name)
	animation_player.play(current_clip)

func has_clip(clip_name: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(clip_name)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
