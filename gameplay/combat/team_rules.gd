class_name TeamRules
extends RefCounted
## Shared faction rules; keep hostility policy centralized.

enum Team { NEUTRAL, TEAM_A, TEAM_B }

static func are_hostile(first_team: int, second_team: int) -> bool:
	return first_team != Team.NEUTRAL and second_team != Team.NEUTRAL and not same_team(first_team, second_team)

static func same_team(first_team: int, second_team: int) -> bool:
	return first_team == second_team
