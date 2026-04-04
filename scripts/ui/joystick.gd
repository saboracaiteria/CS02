extends Control

@export var base_radius: float = 100.0
@export var stick_radius: float = 40.0
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_up"
@export var action_down: String = "move_down"

# Referências aos novos nós visuais 🥋
@onready var base: Control = $Base
@onready var knob: Control = $Knob

var joystick_active: bool = false
var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO

func _ready():
	# Garante que o HUD esteja no lugar certo e visível
	_reset_joystick()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_dist = (event.position - global_position).length()
			if touch_dist <= base_radius:
				joystick_active = true
				touch_index = event.index
				_handle_drag(event.position)
				get_viewport().set_input_as_handled() # BLOQUEIO FÍSICO CONTRA DRIFT 🧱🥊🎯
		elif event.index == touch_index:
			_reset_joystick()
			get_viewport().set_input_as_handled()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			_handle_drag(event.position)
			get_viewport().set_input_as_handled() # BLOQUEIO FÍSICO CONTRA DRIFT 🧱🥊🎯

func _handle_drag(touch_pos: Vector2):
	var center = global_position
	var vec = touch_pos - center
	if vec.length() > base_radius:
		vec = vec.normalized() * base_radius
	
	# No novo sistema visual, position Vector2.ZERO é o CENTRO 🎯
	knob.position = vec - knob.size / 2.0
	output_vector = vec / base_radius
	_update_input_map()

func _reset_joystick():
	joystick_active = false
	touch_index = -1
	output_vector = Vector2.ZERO
	if knob:
		knob.position = -knob.size / 2.0
	_update_input_map()

func _update_input_map():
	# Transmite o movimento para o jogador 🏎️💨
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
