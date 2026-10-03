class_name VornUITheme
extends RefCounted
## Shared VORN HUD color and spacing tokens plus reusable lightweight Control styles.

const INK := Color("#0b1118")
const PANEL := Color(0.035, 0.065, 0.09, 0.94)
const PANEL_LIFT := Color(0.075, 0.12, 0.15, 0.96)
const LINE := Color("#304751")
const TEXT := Color("#e7f1ed")
const MUTED := Color("#92a6a4")
const TEAL := Color("#50d7bd")
const EMBER := Color("#f07b55")
const TEAM_A := Color("#63bce7")
const TEAM_B := Color("#e47763")
const DANGER := Color("#eb5353")
const READY := Color("#79ddb4")
const DISABLED := Color("#58686b")
const GAP := 8
const CORNER := 9

static var _styles: Dictionary = {}

static func panel_style(lifted: bool = false) -> StyleBoxFlat:
	var key := "panel_lift" if lifted else "panel"
	if not _styles.has(key):
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL_LIFT if lifted else PANEL
		style.border_color = LINE
		style.set_border_width_all(1)
		style.set_corner_radius_all(CORNER)
		style.content_margin_left = 12
		style.content_margin_top = 9
		style.content_margin_right = 12
		style.content_margin_bottom = 9
		_styles[key] = style
	return _styles[key] as StyleBoxFlat

static func button_style(state: StringName = &"normal") -> StyleBoxFlat:
	var key := String(state)
	if not _styles.has(key):
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL_LIFT
		style.border_color = TEAL if state == &"ready" else LINE
		style.set_border_width_all(1 if state != &"ready" else 2)
		style.set_corner_radius_all(12)
		style.content_margin_left = 5
		style.content_margin_top = 5
		style.content_margin_right = 5
		style.content_margin_bottom = 5
		_styles[key] = style
	return _styles[key] as StyleBoxFlat
