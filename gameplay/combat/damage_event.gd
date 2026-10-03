class_name DamageEvent
extends RefCounted
## Lightweight combat fact; emitted once for each accepted health change.

const BASIC_ATTACK: StringName = &"BASIC_ATTACK"
const ABILITY: StringName = &"ABILITY"
const OTHER: StringName = &"OTHER"

var source: Node3D
var target: Node3D
var amount: float
var category: StringName
var killed: bool

func _init(source_actor: Node3D, target_actor: Node3D, damage_amount: float, damage_category: StringName, is_killing_blow: bool) -> void:
	source = source_actor
	target = target_actor
	amount = damage_amount
	category = damage_category
	killed = is_killing_blow
