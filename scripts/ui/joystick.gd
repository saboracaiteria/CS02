extends Control

@export var base_radius: float = 100.0
@export var stick_radius: float = 40.0
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_up"
@export var action_down: String = "move_down"
@export var is_floating: bool = true # CODM STYLE! 🏙️🎯🥇

# Referências aos novos nós visuais 🥋
@onready var base: Control = $Base
@onready var knob: Control = $Knob

var joystick_active: bool = false
var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO
var default_position: Vector2 # Para resetar no floating! 🏙️🚀

var _edit_touches: Dictionary = {}

func _ready():
	pivot_offset = size / 2 # Escala centralizada 💎
	default_position = global_position
	_reset_joystick()

func _input(event):
	if Global.is_editing_hud:
		if event is InputEventScreenTouch:
			if event.pressed:
				_edit_touches[event.index] = event.position
			else:
				_edit_touches.erase(event.index)
		elif event is InputEventScreenDrag:
			_edit_touches[event.index] = event.position
			
			if _edit_touches.size() == 1:
				# Trava de segurança para mover apenas no lado esquerdo
				if event.position.x < get_viewport_rect().size.x * 0.5:
					global_position += event.relative
					default_position = global_position # Salva a nova base! 🏙️🎯🥇
			elif _edit_touches.size() == 2:
				var touch_ids = _edit_touches.keys()
				var p1 = _edit_touches[touch_ids[0]]
				var p2 = _edit_touches[touch_ids[1]]
				
				var old_p1 = p1
				var old_p2 = p2
				if event.index == touch_ids[0]:
					old_p1 -= event.relative
				else:
					old_p2 -= event.relative
				
				var old_dist = old_p1.distance_to(old_p2)
				var new_dist = p1.distance_to(p2)
				
				if old_dist > 0:
					var scale_factor = new_dist / old_dist
					var new_scale = scale * scale_factor
					new_scale.x = clamp(new_scale.x, 0.8, 3.0)
					new_scale.y = clamp(new_scale.y, 0.8, 3.0)
					scale = new_scale
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			# PROTEÇÃO: Só ativa se for no lado esquerdo da tela! 🧱🥊
			if event.position.x > get_viewport_rect().size.x * 0.45:
				return
				
			if is_floating:
				global_position = event.position # MOVIMENTA O CENTRO DO JOYSTICK! 🏙️🎯🥇
			
			var touch_dist = (event.position - global_position).length()
			# Se for floating, a distância é 0 no início, então sempre entra!
			if touch_dist <= base_radius or is_floating:
				joystick_active = true
				touch_index = event.index
				_handle_drag(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == touch_index:
			_reset_joystick()
			get_viewport().set_input_as_handled()
			
	if event is InputEventScreenDrag:
		if event.index == touch_index:
			_handle_drag(event.position)
			get_viewport().set_input_as_handled()

func _process(_delta):
	# RESGATE DE EMERGÊNCIA V1060: 🛡️🏗️🎯
	# Se o joystick acha que está ativo, mas o mouse/toque não está pressionado, RESET!
	if joystick_active:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_index == -1:
			_reset_joystick()
		# Verificação extra para mobile
		elif touch_index != -1 and not DisplayServer.is_touchscreen_available():
			# No PC, se o mouse soltou, reseta independente do index
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_reset_joystick()

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
	if is_floating:
		global_position = default_position # VOLTA PARA A BASE! 🏙️🚀
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
