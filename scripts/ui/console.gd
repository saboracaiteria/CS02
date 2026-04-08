extends CanvasLayer

@onready var log_label = $Control/Panel/ScrollContainer/VBoxContainer/LogLabel
@onready var panel = $Control

func _ready():
	Global.debug_console = self
	process_mode = Node.PROCESS_MODE_ALWAYS # Console funciona mesmo pausado
	panel.hide()
	log_msg("--- CONSOLE DE DEBUG V1675 ATIVO ---")
	log_msg("SISTEMA: " + OS.get_name() + " | MOBILE: " + str(Global.is_mobile))

func _input(event):
	# Tecla Aspas/Til no PC para abrir console
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_APOSTROPHE:
			toggle_console()

func toggle_console():
	panel.visible = !panel.visible
	if panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Global.is_playing and !Global.is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func log_msg(text: String):
	var time = Time.get_time_string_from_system()
	var new_text = "[%s] %s\n" % [time, text]
	log_label.text += new_text
	print(text) # Mantém no terminal do PC também
	
	# Auto-scroll para o final
	await get_tree().process_frame
	$Control/Panel/ScrollContainer.scroll_vertical = 99999

func _on_close_pressed():
	panel.hide()
