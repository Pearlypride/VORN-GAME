extends Node3D
## Fixed-pitch orthographic MOBA camera. Pan and zoom are independent of actors.

@export_range(0.001, 0.2, 0.001) var pan_speed: float = 0.038
@export_range(2.0, 40.0, 0.5) var zoom_min: float = 18.0
@export_range(10.0, 80.0, 0.5) var zoom_max: float = 30.0
@export_range(0.25, 5.0, 0.25) var zoom_step: float = 1.5
@onready var _camera: Camera3D = $Camera3D as Camera3D
var _dragging: bool = false

func _ready() -> void:
	_camera.size = clampf(_camera.size, zoom_min, zoom_max)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_event.pressed
			get_viewport().set_input_as_handled()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom(_camera.size - zoom_step)
			get_viewport().set_input_as_handled()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(_camera.size + zoom_step)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		pan_by_screen_drag((event as InputEventMouseMotion).relative)
		get_viewport().set_input_as_handled()

func pan_by_screen_drag(screen_delta: Vector2) -> void:
	var camera_right := _camera.global_basis.x
	var camera_forward := -_camera.global_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0
	var ground_delta := -camera_right.normalized() * screen_delta.x + camera_forward.normalized() * screen_delta.y
	global_position += ground_delta * pan_speed

func set_zoom(requested_size: float) -> void:
	_camera.size = clampf(requested_size, zoom_min, zoom_max)
