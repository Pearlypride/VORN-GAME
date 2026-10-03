class_name LaneMinimap
extends Control
## Vector lane schematic; actor positions are projected from world coordinates, not a screenshot.

var arena_root: Node3D
var _refresh_left: float = 0.0
var _actors: Array[Dictionary] = []

func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 0.2
	_actors.clear()
	if arena_root != null:
		for node in arena_root.get_tree().get_nodes_in_group("combat_actor"):
			var actor := node as CombatActor
			if actor != null and actor.is_alive() and actor.actor != null and actor.actor_kind == &"minion":
				_actors.append({"actor": actor.actor, "team": actor.team})
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(9, 11), size - Vector2(18, 22))
	var mid_y := rect.position.y + rect.size.y * 0.5
	draw_line(Vector2(rect.position.x + 8, mid_y), Vector2(rect.end.x - 8, mid_y), Color("#84918c"), 5.0, true)
	draw_line(Vector2(rect.position.x + 8, mid_y), Vector2(rect.end.x - 8, mid_y), Color("#27383c"), 2.0, true)
	_draw_dot(Vector2(rect.position.x + 14, mid_y), VornUITheme.TEAM_A, 8.0)
	_draw_dot(Vector2(rect.end.x - 14, mid_y), VornUITheme.TEAM_B, 8.0)
	if arena_root != null:
		var player := arena_root.get_node_or_null("Player") as Node3D
		if player != null:
			_draw_dot(_world_to_minimap(player.global_position, rect), VornUITheme.EMBER, 5.5)
		var lane := arena_root.get_node_or_null("LaneWorld") as LaneWorld
		if lane != null:
			for tower in [lane.team_a_tower, lane.team_b_tower]:
				if tower != null:
					var color := VornUITheme.TEAM_A if tower.team == TeamRules.Team.TEAM_A else VornUITheme.TEAM_B
					_draw_dot(_world_to_minimap(tower.global_position, rect), color, 4.0)
		for entry in _actors:
			var actor := entry["actor"] as Node3D
			if is_instance_valid(actor):
				var team_color := VornUITheme.TEAM_A if entry["team"] == TeamRules.Team.TEAM_A else VornUITheme.TEAM_B
				_draw_dot(_world_to_minimap(actor.global_position, rect), team_color, 2.0)

func _world_to_minimap(world_position: Vector3, rect: Rect2) -> Vector2:
	return Vector2(lerpf(rect.position.x + 8, rect.end.x - 8, inverse_lerp(-32.0, 32.0, world_position.x)), rect.position.y + rect.size.y * 0.5 + world_position.z * 1.3)

func _draw_dot(point: Vector2, color: Color, radius: float) -> void:
	draw_circle(point, radius + 1.2, Color(0.035, 0.055, 0.065, 0.95))
	draw_circle(point, radius, color)
