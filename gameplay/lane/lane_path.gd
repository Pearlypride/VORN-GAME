class_name LanePath
extends Node3D
## Deterministic straight-lane coordinate path, replaceable with curve navigation later.

@export var team_a_start: Vector3 = Vector3(-17.0, 0.0, 0.0)
@export var team_b_start: Vector3 = Vector3(17.0, 0.0, 0.0)

func length() -> float:
	return team_a_start.distance_to(team_b_start)

func position_for_team(team: int, distance_from_home: float) -> Vector3:
	var origin := team_a_start if team == TeamRules.Team.TEAM_A else team_b_start
	var destination := team_b_start if team == TeamRules.Team.TEAM_A else team_a_start
	var direction := (destination - origin).normalized()
	return origin + direction * clampf(distance_from_home, 0.0, length())

func direction_for_team(team: int) -> Vector3:
	return (team_b_start - team_a_start).normalized() if team == TeamRules.Team.TEAM_A else (team_a_start - team_b_start).normalized()
