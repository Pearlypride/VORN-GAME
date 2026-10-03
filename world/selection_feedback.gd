extends Node
## Presentation adapter that shows the selected actor's primitive ring.

@onready var _combat: CombatComponent = get_node("../Player/Combat") as CombatComponent
var _selected_actor: Node3D

func _ready() -> void:
	_combat.target_changed.connect(_on_target_changed)

func _on_target_changed(target: Node3D) -> void:
	_set_ring_visible(_selected_actor, false)
	_selected_actor = target
	_set_ring_visible(_selected_actor, true)

func _set_ring_visible(actor: Node3D, visible: bool) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var ring := actor.get_node_or_null("SelectionRing") as Node3D
	if ring != null:
		ring.visible = visible
