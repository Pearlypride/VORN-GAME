extends CanvasLayer

@onready var _player_stats: ActorStats = get_node("../Player/Stats") as ActorStats
@onready var _combat: CombatComponent = get_node("../Player/Combat") as CombatComponent
@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _player_label: Label = $Panel/Margin/VBox/PlayerHealth
@onready var _selection_label: Label = $Panel/Margin/VBox/Selection
@onready var _target_label: Label = $Panel/Margin/VBox/TargetHealth
@onready var _command_label: Label = $Panel/Margin/VBox/CommandState
@onready var _combat_label: Label = $Panel/Margin/VBox/CombatState

func _ready() -> void:
	_player_stats.health_changed.connect(_on_player_health_changed)
	_combat.target_changed.connect(_refresh_target)
	_combat.attack_state_changed.connect(_on_attack_state_changed)
	_player.command_state_changed.connect(_on_command_state_changed)
	_on_player_health_changed(_player_stats.current_health, _player_stats.max_health)
	_refresh_target(_combat.target)
	_on_command_state_changed(_player.command_state)
	_on_attack_state_changed(0.0)

func _process(_delta: float) -> void:
	var target_stats := _combat.get_target_stats()
	if target_stats != null and target_stats.current_health > 0.0:
		_target_label.text = "Target HP: %d / %d" % [roundi(target_stats.current_health), roundi(target_stats.max_health)]
	elif _combat.target != null:
		_target_label.text = "Target: defeated (respawning)"
	if _combat.cooldown_remaining > 0.0:
		_combat_label.text = "Attack cooldown: %.1fs" % _combat.cooldown_remaining
	else:
		_combat_label.text = "Attack: ready"

func _on_player_health_changed(current: float, maximum: float) -> void:
	_player_label.text = "Player HP: %d / %d" % [roundi(current), roundi(maximum)]

func _refresh_target(target: Node3D) -> void:
	if target == null or _combat.get_target_stats() == null:
		_selection_label.text = "Selected: None"
		_target_label.text = "Target HP: —"
		return
	var target_type := "Enemy" if target.is_in_group("combat_target") else "Actor"
	_selection_label.text = "Selected: %s (%s)" % [target.name, target_type]
	var stats := _combat.get_target_stats()
	_target_label.text = "Target HP: %d / %d" % [roundi(stats.current_health), roundi(stats.max_health)]

func _on_command_state_changed(_state: int) -> void:
	_command_label.text = "Command: %s" % _player.get_command_state_name()

func _on_attack_state_changed(remaining: float) -> void:
	_combat_label.text = "Attack: ready" if remaining <= 0.0 else "Attack cooldown: %.1fs" % remaining
