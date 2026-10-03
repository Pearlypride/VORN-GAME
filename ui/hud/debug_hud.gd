extends CanvasLayer

@onready var _player_stats: ActorStats = get_node("../Player/Stats") as ActorStats
@onready var _combat: CombatComponent = get_node("../Player/Combat") as CombatComponent
@onready var _attacks: BasicAttackController = get_node("../Player/BasicAttackController") as BasicAttackController
@onready var _player: PlayerController = get_node("../Player") as PlayerController
@onready var _abilities: AbilityController = get_node("../Player/AbilityController") as AbilityController
@onready var _status_effects: StatusEffectController = get_node("../Player/StatusEffects") as StatusEffectController
@onready var _wallet: GoldWallet = get_node("../Player/GoldWallet") as GoldWallet
@onready var _progression: HeroProgression = get_node("../Player/Progression") as HeroProgression
@onready var _telemetry: PlaytestTelemetry = get_node("../Player/PlaytestTelemetry") as PlaytestTelemetry
@onready var _lane_world: LaneWorld = get_node("../LaneWorld") as LaneWorld
@onready var _player_label: Label = $Panel/Margin/VBox/PlayerHealth
@onready var _mana_label: Label = $Panel/Margin/VBox/PlayerMana
@onready var _selection_label: Label = $Panel/Margin/VBox/Selection
@onready var _target_label: Label = $Panel/Margin/VBox/TargetHealth
@onready var _command_label: Label = $Panel/Margin/VBox/CommandState
@onready var _combat_label: Label = $Panel/Margin/VBox/CombatState
@onready var _targeting_label: Label = $Panel/Margin/VBox/TargetingMode
@onready var _buff_label: Label = $Panel/Margin/VBox/RBuff
@onready var _economy_label: Label = $Panel/Margin/VBox/Economy
@onready var _progression_label: Label = $Panel/Margin/VBox/Progression
@onready var _lane_label: Label = $Panel/Margin/VBox/LaneStatus
@onready var _tower_label: Label = $Panel/Margin/VBox/TowerStatus
@onready var _telemetry_label: Label = $Panel/Margin/VBox/Telemetry
@onready var _update_left: float = 0.0
var _ability_labels: Dictionary = {}

func _ready() -> void:
	visible = false
	_ability_labels = {
		&"q": get_node_or_null("Panel/Margin/VBox/AbilityQ"),
		&"w": get_node_or_null("Panel/Margin/VBox/AbilityW"),
		&"e": get_node_or_null("Panel/Margin/VBox/AbilityE"),
		&"r": get_node_or_null("Panel/Margin/VBox/AbilityR"),
	}
	_player_stats.health_changed.connect(_on_player_health_changed)
	_combat.target_changed.connect(_refresh_target)
	_combat.attack_state_changed.connect(_on_attack_state_changed)
	_player.command_state_changed.connect(_on_command_state_changed)
	_player_stats.mana_changed.connect(_on_mana_changed)
	_on_player_health_changed(_player_stats.current_health, _player_stats.max_health)
	_on_mana_changed(_player_stats.current_mana, _player_stats.max_mana)
	_refresh_target(_combat.target)
	_on_command_state_changed(_player.command_state)
	_on_attack_state_changed(0.0)

func _process(delta: float) -> void:
	_update_left -= delta
	if _update_left > 0.0:
		return
	_update_left = 0.15
	var target_stats: ActorStats = _combat.get_target_stats()
	if target_stats != null and target_stats.current_health > 0.0:
		_target_label.text = "Target HP: %d / %d" % [roundi(target_stats.current_health), roundi(target_stats.max_health)]
	elif _combat.target != null:
		_target_label.text = "Target: defeated (respawning)"
	var attack_state := _attacks.get_attack_state_name()
	var attack_wait := _attacks.get_time_until_next_attack()
	var attack_target: String = _attacks.current_target.actor.name if is_instance_valid(_attacks.current_target) else "—"
	_combat_label.text = "Attack: %s %d%% → %s · next %.1fs" % [attack_state, roundi(_attacks.get_attack_point_progress() * 100.0), attack_target, attack_wait] if attack_wait > 0.0 else "Attack: IDLE · ready"
	_update_ability_labels()
	if _abilities.is_targeting():
		var definition := _abilities.get_ability_definition(_abilities.current_targeting_ability)
		_targeting_label.text = "Targeting: %s" % definition.display_name if definition != null else "Targeting: —"
	else:
		_targeting_label.text = "Targeting: None"
	var buff_remaining := _status_effects.get_remaining(&"r_surge")
	_buff_label.text = "R buff: %.1fs" % buff_remaining if buff_remaining > 0.0 else "R buff: inactive"
	_economy_label.text = "Gold: %d (earned %d)" % [_wallet.current_gold, _wallet.total_earned]
	_progression_label.text = "Level %d — XP %.0f / %.0f" % [_progression.level, _progression.current_xp, _progression.xp_required()]
	_lane_label.text = "Waves A/B: %d / %d" % [_lane_world.team_a_spawner.wave_number, _lane_world.team_b_spawner.wave_number]
	_tower_label.text = "Towers A/B: %s / %s" % [_tower_hp(_lane_world.team_a_tower), _tower_hp(_lane_world.team_b_tower)]
	_telemetry_label.text = _telemetry.get_summary()

func _on_player_health_changed(current: float, maximum: float) -> void:
	var hero_name := _player.hero_definition.hero_name if _player.hero_definition != null else "Hero"
	_player_label.text = "%s HP: %d / %d" % [hero_name, roundi(current), roundi(maximum)]

func _on_mana_changed(current: float, maximum: float) -> void:
	_mana_label.text = "Mana: %d / %d" % [roundi(current), roundi(maximum)]

func _refresh_target(target: Node3D) -> void:
	if target == null or _combat.get_target_stats() == null:
		_selection_label.text = "Selected: None"
		_target_label.text = "Target HP: —"
		return
	var identity := target.get_node_or_null("CombatActor") as CombatActor
	var target_type := String(identity.actor_kind).capitalize() if identity != null else "Actor"
	_selection_label.text = "Selected: %s (%s)" % [target.name, target_type]
	var stats: ActorStats = _combat.get_target_stats()
	_target_label.text = "Target HP: %d / %d" % [roundi(stats.current_health), roundi(stats.max_health)]

func _on_command_state_changed(_state: int) -> void:
	_command_label.text = "Command: %s" % _player.get_command_state_name()

func _on_attack_state_changed(remaining: float) -> void:
	_combat_label.text = "Attack: ready" if remaining <= 0.0 else "Attack cooldown: %.1fs" % remaining

func _update_ability_labels() -> void:
	for ability_id in _ability_labels:
		if not is_instance_valid(_ability_labels[ability_id]):
			continue
		var definition := _abilities.get_ability_definition(ability_id)
		if definition == null:
			_ability_labels[ability_id].text = "%s: unavailable" % String(ability_id).to_upper()
			continue
		var state: AbilityController.AbilityState = _abilities.get_ability_state(ability_id)
		var state_name: String = AbilityController.AbilityState.keys()[state]
		if state == AbilityController.AbilityState.COOLDOWN:
			state_name += " %.1fs" % _abilities.get_cooldown_remaining(ability_id)
		elif _player_stats.current_mana < definition.mana_cost:
			state_name = "NO MANA"
		_ability_labels[ability_id].text = "%s — %s: %s (%.0f mana)" % [String(ability_id).to_upper(), definition.display_name, state_name, definition.mana_cost]

func _tower_hp(tower: TowerActor) -> String:
	if tower == null or tower.destroyed:
		return "DESTROYED"
	var stats := tower.get_node("Stats") as ActorStats
	return "%d" % roundi(stats.current_health)
