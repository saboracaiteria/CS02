extends Control

@export var base_radius: float = 100.0
@export var stick_radius: float = 40.0
@export var action_left: String = "left"
@export var action_right: String = "right"
@export var action_up: String = "up"
@export var action_down: String = "down"

@onready var base: Sprite2D = $Base
@onready var knob: Sprite2D = $Knob

var joystick_active: bool = false
var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO

func _ready():
	# Scale sprites based on radius
	if base and base.texture:
		base.scale = Vector2(base_radius * 2 / base.texture.get_width(), base_radius * 2 / base.texture.get_height())
	if knob and knob.texture:
		knob.scale = Vector2(stick_radius * 2 / knob.texture.get_width(), stick_radius * 2 / knob.texture.get_height())

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_dist = (event.position - global_position).length()
			if touch_dist <= base_radius:
				joystick_active = true
				touch_index = event.index
				_handle_drag(event.position)
		elif event.index == touch_index:
			_reset_joystick()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			_handle_drag(event.position)

func _handle_drag(touch_pos: Vector2):
	var center = global_position
	var vec = touch_pos - center
	if vec.length() > base_radius:
		vec = vec.normalized() * base_radius
	
	knob.position = vec
	output_vector = vec / base_radius
	_update_input_map()

func _reset_joystick():
	joystick_active = false
	touch_index = -1
	output_vector = Vector2.ZERO
	knob.position = Vector2.ZERO
	_update_input_map()

func _update_input_map():
	# Update Input Map for these actions
	_set_action(action_left, -output_vector.x if output_vector.x < 0 else 0.0)
	_set_action(action_right, output_vector.x if output_vector.x > 0 else 0.0)
	_set_action(action_up, -output_vector.y if output_vector.y < 0 else 0.0)
	_set_action(action_down, output_vector.y if output_vector.y > 0 else 0.0)

func _set_action(action_name: String, strength: float):
	if action_name == "": return
	if strength > 0.1:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)

func get_value() -> Vector2:
	return output_vector
