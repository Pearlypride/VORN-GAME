class_name ActorStats
extends Node
## Small authority-neutral collection of combat stats for an actor.

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal died
signal damage_received(event: DamageEvent)

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_mana: float = 0.0
@export_range(0.0, 1000.0, 0.1) var health_regeneration: float = 0.0
@export_range(0.0, 1000.0, 0.1) var mana_regeneration: float = 0.0
@export_range(0.0, 1000.0, 0.1) var movement_speed: float = 5.5
@export_range(0.0, 1000.0, 0.1) var attack_damage: float = 20.0
@export_range(0.0, 100.0, 0.1) var attack_range: float = 2.2
@export_range(0.05, 30.0, 0.05) var attack_cooldown: float = 0.8

var current_health: float
var current_mana: float
var last_damage_source: Node3D
var last_damage_category: StringName = &""
var last_damage_event: DamageEvent
var _movement_speed_multiplier: float = 1.0
var _attack_cooldown_multiplier: float = 1.0

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func _process(delta: float) -> void:
	if current_health <= 0.0:
		return
	if health_regeneration > 0.0 and current_health < max_health:
		var old_health := current_health
		current_health = minf(max_health, current_health + health_regeneration * delta)
		if current_health != old_health:
			health_changed.emit(current_health, max_health)
	if mana_regeneration > 0.0 and current_mana < max_mana:
		var old_mana := current_mana
		current_mana = minf(max_mana, current_mana + mana_regeneration * delta)
		if current_mana != old_mana:
			mana_changed.emit(current_mana, max_mana)

func configure_from_hero(definition: HeroDefinition) -> void:
	max_health = definition.max_health
	max_mana = definition.max_mana
	health_regeneration = definition.health_regeneration
	mana_regeneration = definition.mana_regeneration
	movement_speed = definition.movement_speed
	attack_damage = definition.attack_damage
	attack_range = definition.attack_range
	attack_cooldown = definition.attack_cooldown
	_movement_speed_multiplier = 1.0
	_attack_cooldown_multiplier = 1.0
	restore_full_resources()

func apply_damage(amount: float, source: Node3D = null, category: StringName = DamageEvent.BASIC_ATTACK) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return
	last_damage_source = source
	last_damage_category = category
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	last_damage_event = DamageEvent.new(source, get_parent() as Node3D, amount, category, current_health == 0.0)
	damage_received.emit(last_damage_event)
	if current_health == 0.0:
		died.emit()

func restore_full_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func spend_mana(amount: float) -> bool:
	if amount < 0.0 or current_mana < amount:
		return false
	current_mana = maxf(0.0, current_mana - amount)
	mana_changed.emit(current_mana, max_mana)
	return true

func restore_mana(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var previous_mana := current_mana
	current_mana = minf(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)
	return current_mana - previous_mana

func restore_full_resources() -> void:
	current_health = max_health
	current_mana = max_mana
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func apply_level_growth(health: float, mana: float, damage: float, health_regen: float = 0.0, mana_regen: float = 0.0) -> void:
	# Preserve current absolute HP/mana; growth increases maxima without a level-up heal.
	max_health += health
	max_mana += mana
	attack_damage += damage
	health_regeneration += health_regen
	mana_regeneration += mana_regen
	current_health = minf(current_health, max_health)
	current_mana = minf(current_mana, max_mana)
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func set_status_multipliers(movement_speed_multiplier: float, attack_cooldown_multiplier: float) -> void:
	_movement_speed_multiplier = maxf(0.0, movement_speed_multiplier)
	_attack_cooldown_multiplier = maxf(0.05, attack_cooldown_multiplier)

func get_effective_movement_speed() -> float:
	return movement_speed * _movement_speed_multiplier

func get_effective_attack_cooldown() -> float:
	return attack_cooldown * _attack_cooldown_multiplier
