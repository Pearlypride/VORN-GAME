class_name MobaHUD
extends CanvasLayer
## Normal gameplay HUD. Debug presentation remains separately available with F3.

const HUD_FONT_SIZE := 15

var match_seconds: float = 0.0
var debug_hud: CanvasLayer
var match_clock: Label
var score_label: Label
var target_panel: PanelContainer
var target_name: Label
var target_health: ProgressBar
var target_meta: Label
var hero_health: ProgressBar
var hero_mana: ProgressBar
var hero_level: Label
var hero_gold: Label
var _player: PlayerController
var _stats: ActorStats
var _wallet: GoldWallet
var _progression: HeroProgression
var _combat: CombatComponent
var _abilities: AbilityController
var _lane: LaneWorld
var _button_texts: Dictionary = {}
var _cooldown_bars: Dictionary = {}
var _refresh_left: float = 0.0

func _ready() -> void:
	var arena := get_parent() as Node3D
	_player = arena.get_node("Player") as PlayerController
	_stats = _player.get_node("Stats") as ActorStats
	_wallet = _player.get_node("GoldWallet") as GoldWallet
	_progression = _player.get_node("Progression") as HeroProgression
	_combat = _player.get_node("Combat") as CombatComponent
	_abilities = _player.get_node("AbilityController") as AbilityController
	_lane = arena.get_node("LaneWorld") as LaneWorld
	debug_hud = arena.get_node("HUD") as CanvasLayer
	_build(arena)
	_combat.target_changed.connect(_on_target_changed)
	_refresh()

func _process(delta: float) -> void:
	match_seconds += delta
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 0.12
		_refresh()

func _build(arena: Node3D) -> void:
	var root := Control.new()
	root.name = "NormalHUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var map_panel := _panel(root, "MinimapPanel", Vector2(20, 18), Vector2(204, 136), Control.PRESET_TOP_LEFT)
	var map_title := _label("VORN  /  LANE", 11, VornUITheme.MUTED)
	_content(map_panel).add_child(map_title)
	var minimap := LaneMinimap.new()
	minimap.name = "LaneMinimap"
	minimap.arena_root = arena
	minimap.custom_minimum_size = Vector2(170, 74)
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content(map_panel).add_child(minimap)

	var score_panel := PanelContainer.new()
	score_panel.name = "Scoreboard"
	score_panel.theme = _make_theme()
	score_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	score_panel.position = Vector2(-166, 18)
	score_panel.size = Vector2(332, 58)
	root.add_child(score_panel)
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 18)
	score_panel.add_child(score_row)
	var team_a_score := _label("A  0", 17, VornUITheme.TEAM_A)
	team_a_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_row.add_child(team_a_score)
	match_clock = _label("00:00", 19, VornUITheme.TEXT)
	match_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_clock.custom_minimum_size.x = 82
	score_row.add_child(match_clock)
	var team_b_score := _label("0  B", 17, VornUITheme.TEAM_B)
	team_b_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_row.add_child(team_b_score)
	score_label = team_a_score

	var top_right := HBoxContainer.new()
	top_right.name = "SettingsDebug"
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-148, 18)
	top_right.size = Vector2(128, 48)
	top_right.add_theme_constant_override("separation", 6)
	root.add_child(top_right)
	var settings := _button("⋯", 36, "Settings placeholder")
	settings.custom_minimum_size = Vector2(42, 42)
	top_right.add_child(settings)
	var debug_toggle := _button("", 12, "Show development overlay")
	debug_toggle.custom_minimum_size = Vector2(78, 42)
	debug_toggle.pressed.connect(toggle_debug)
	top_right.add_child(debug_toggle)
	var debug_hint := _label("F3  DEV", 11, VornUITheme.TEXT)
	debug_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	debug_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_toggle.add_child(debug_hint)

	target_panel = _panel(root, "TargetPanel", Vector2(-146, 86), Vector2(292, 88), Control.PRESET_CENTER_TOP)
	target_panel.visible = false
	target_name = _label("TARGET", 14, VornUITheme.TEXT)
	_content(target_panel).add_child(target_name)
	target_meta = _label("Enemy unit", 11, VornUITheme.MUTED)
	_content(target_panel).add_child(target_meta)
	target_health = _bar(VornUITheme.TEAM_B, 9)
	_content(target_panel).add_child(target_health)

	var joystick := _panel(root, "MovementControlPlaceholder", Vector2(28, -154), Vector2(132, 132), Control.PRESET_BOTTOM_LEFT)
	joystick.modulate = Color(1, 1, 1, 0.48)
	var joystick_style := StyleBoxFlat.new()
	joystick_style.bg_color = Color(0.035, 0.065, 0.09, 0.36)
	joystick_style.border_color = Color(0.32, 0.5, 0.52, 0.52)
	joystick_style.set_border_width_all(1)
	joystick_style.set_corner_radius_all(72)
	joystick.add_theme_stylebox_override("panel", joystick_style)
	var joy_glyph := _label("MOVE", 10, VornUITheme.MUTED)
	joy_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joy_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	joy_glyph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	joystick.add_child(joy_glyph)

	var hero_panel := _panel(root, "HeroStatus", Vector2(-218, -104), Vector2(436, 82), Control.PRESET_CENTER_BOTTOM, true)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 10)
	_content(hero_panel).add_child(hero_row)
	var portrait := PanelContainer.new()
	portrait.name = "HeroPortrait"
	portrait.custom_minimum_size = Vector2(58, 58)
	portrait.add_theme_stylebox_override("panel", VornUITheme.panel_style(true))
	hero_row.add_child(portrait)
	var portrait_name := _label("K", 28, VornUITheme.EMBER)
	portrait_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(portrait_name)
	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 4)
	hero_row.add_child(bars)
	var identity_row := HBoxContainer.new()
	bars.add_child(identity_row)
	var name_label := _label("KARN", 13, VornUITheme.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(name_label)
	hero_level = _label("LV 1", 12, VornUITheme.TEAL)
	identity_row.add_child(hero_level)
	hero_health = _bar(VornUITheme.READY, 12)
	bars.add_child(hero_health)
	hero_mana = _bar(Color("#4ba8dc"), 8)
	bars.add_child(hero_mana)
	hero_gold = _label("◈  0", 13, Color("#ebc879"))
	hero_row.add_child(hero_gold)

	var ability_row := HBoxContainer.new()
	ability_row.name = "AbilityButtons"
	ability_row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ability_row.position = Vector2(-364, -102)
	ability_row.size = Vector2(344, 78)
	ability_row.add_theme_constant_override("separation", 6)
	root.add_child(ability_row)
	_add_ability_button(ability_row, &"q", "Q", "REND")
	_add_ability_button(ability_row, &"w", "W", "BREAK\nLINE")
	_add_ability_button(ability_row, &"e", "E", "WAR\nRING")
	_add_ability_button(ability_row, &"r", "R", "REDLINE")
	var attack_button := _button("ATK\nBASIC", 11, "Basic attack placeholder")
	attack_button.name = "AttackButton"
	attack_button.custom_minimum_size = Vector2(70, 72)
	ability_row.add_child(attack_button)

func _add_ability_button(parent: HBoxContainer, ability_id: StringName, key: String, ability_name: String) -> void:
	var button := _button("%s\n%s\nREADY" % [key, ability_name,], 10, "Ability %s placeholder" % ability_name)
	button.name = "Ability%s" % key.to_upper()
	button.custom_minimum_size = Vector2(62, 72)
	parent.add_child(button)
	_button_texts[ability_id] = button
	var cooldown_bar := ProgressBar.new()
	cooldown_bar.name = "CooldownOverlay"
	cooldown_bar.show_percentage = false
	cooldown_bar.max_value = 100.0
	cooldown_bar.value = 0.0
	cooldown_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cooldown_bar.offset_left = 7.0
	cooldown_bar.offset_right = -7.0
	cooldown_bar.offset_top = -6.0
	cooldown_bar.offset_bottom = -3.0
	var cooldown_background := StyleBoxFlat.new()
	cooldown_background.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	var cooldown_fill := StyleBoxFlat.new()
	cooldown_fill.bg_color = Color(0.75, 0.85, 0.82, 0.58)
	cooldown_fill.set_corner_radius_all(2)
	cooldown_bar.add_theme_stylebox_override("background", cooldown_background)
	cooldown_bar.add_theme_stylebox_override("fill", cooldown_fill)
	button.add_child(cooldown_bar)
	_cooldown_bars[ability_id] = cooldown_bar

func _panel(parent: Control, node_name: String, offset: Vector2, dimensions: Vector2, preset: Control.LayoutPreset, lifted: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.theme = _make_theme()
	panel.set_anchors_preset(preset)
	panel.position = offset
	panel.size = dimensions
	panel.add_theme_stylebox_override("panel", VornUITheme.panel_style(lifted))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	return _set_panel_content(panel, stack)

func _set_panel_content(panel: PanelContainer, stack: VBoxContainer) -> PanelContainer:
	panel.set_meta("content", stack)
	return panel

func _content(panel: PanelContainer) -> VBoxContainer:
	return panel.get_meta("content") as VBoxContainer

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", VornUITheme.INK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _button(text: String, font_size: int, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", VornUITheme.TEXT)
	button.add_theme_color_override("font_hover_color", VornUITheme.TEAL)
	button.add_theme_stylebox_override("normal", VornUITheme.button_style())
	button.add_theme_stylebox_override("hover", VornUITheme.button_style(&"ready"))
	button.add_theme_stylebox_override("pressed", VornUITheme.button_style(&"pressed"))
	return button

func _bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.add_theme_stylebox_override("background", VornUITheme.panel_style())
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", VornUITheme.TEXT)
	theme.set_font_size("font_size", "Label", HUD_FONT_SIZE)
	return theme

func _refresh() -> void:
	if not is_instance_valid(_player):
		return
	match_clock.text = "%02d:%02d" % [int(match_seconds) / 60, int(match_seconds) % 60]
	hero_health.value = 100.0 * _stats.current_health / maxf(1.0, _stats.max_health)
	hero_mana.value = 100.0 * _stats.current_mana / maxf(1.0, _stats.max_mana)
	hero_level.text = "LV %d" % _progression.level
	hero_gold.text = "◈  %d" % _wallet.current_gold
	for ability_id in _button_texts:
		var button := _button_texts[ability_id] as Button
		var definition := _abilities.get_ability_definition(ability_id)
		if definition == null:
			continue
		var ability_state: AbilityController.AbilityState = _abilities.get_ability_state(ability_id)
		var cooldown := _abilities.get_cooldown_remaining(ability_id)
		var detail := "READY" if ability_state == AbilityController.AbilityState.READY else ("AIM" if ability_state == AbilityController.AbilityState.TARGETING else "%.0f" % ceilf(cooldown))
		if _stats.current_mana < definition.mana_cost:
			detail = "NO MANA"
		button.text = "%s\n%s\n%s" % [String(ability_id).to_upper(), definition.display_name.to_upper(), detail]
		var has_mana := _stats.current_mana >= definition.mana_cost
		button.disabled = not has_mana
		button.modulate = Color.WHITE if has_mana else Color(0.72, 0.75, 0.76, 0.88)
		button.add_theme_stylebox_override("normal", VornUITheme.button_style(&"ready") if ability_state == AbilityController.AbilityState.READY and has_mana else VornUITheme.button_style())
		button.add_theme_stylebox_override("pressed", VornUITheme.button_style(&"active") if ability_state == AbilityController.AbilityState.TARGETING else VornUITheme.button_style(&"pressed"))
		var cooldown_bar := _cooldown_bars[ability_id] as ProgressBar
		cooldown_bar.value = 100.0 * cooldown / maxf(0.1, definition.cooldown)
	var target := _combat.target
	var target_stats := _combat.get_target_stats()
	target_panel.visible = target != null and target_stats != null
	if target_panel.visible:
		var identity := target.get_node_or_null("CombatActor") as CombatActor
		target_name.text = target.name.to_upper()
		target_meta.text = "%s  /  %s" % [String(identity.actor_kind).to_upper() if identity != null else "UNIT", "TEAM A" if identity != null and identity.team == TeamRules.Team.TEAM_A else "TEAM B"]
		target_health.value = 100.0 * target_stats.current_health / maxf(1.0, target_stats.max_health)

func _on_target_changed(target: Node3D) -> void:
	target_panel.visible = target != null
	_refresh()

func toggle_debug() -> void:
	if is_instance_valid(debug_hud):
		debug_hud.visible = not debug_hud.visible
