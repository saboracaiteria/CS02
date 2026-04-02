extends Node

@onready var main_menu: PanelContainer = $Menu/MainMenu
@onready var options_menu: PanelContainer = $Menu/Options
@onready var pause_menu: PanelContainer = $Menu/PauseMenu
@onready var address_entry: LineEdit = %AddressEntry
@onready var menu_music: AudioStreamPlayer = %MenuMusic

const Player = preload("res://player.tscn")
const PORT = 9999
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var paused: bool = false
var options: bool = false
var controller: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("pause") and !main_menu.visible and !options_menu.visible:
		paused = !paused
	if event is InputEventJoypadMotion:
		controller = true
	elif event is InputEventMouseMotion:
		controller = false

func _process(_delta: float) -> void:
	if paused:
		$Menu/Blur.show()
		pause_menu.show()
		if !controller:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume_pressed() -> void:
	if !options:
		$Menu/Blur.hide()
	$Menu/PauseMenu.hide()
	if !controller:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	paused = false
	
func _on_options_pressed() -> void:
	_on_resume_pressed()
	$Menu/Options.show()
	$Menu/Blur.show()
	%Fullscreen.grab_focus()
	if !controller:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	options = true

func _on_back_pressed() -> void:
	if options:
		$Menu/Blur.hide()
		if !controller:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		options = false

#func _ready() -> void:
func _ready():
	_apply_premium_style()

func _apply_premium_style():
	# Estilização Glassmorphism para o Menu
	var panel = $Menu/MainMenu
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.4)
	style.border_width_right = 2
	style.border_color = Color(1, 1, 1, 0.1)
	style.set_corner_radius_all(0) # Mantém sidebar reta
	panel.add_theme_stylebox_override("panel", style)
	
	# Estilização dos Botões
	var buttons = [
		$Menu/MainMenu/MarginContainer/VBoxContainer/HostButton,
		$Menu/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/JoinButton,
		$Menu/MainMenu/MarginContainer/VBoxContainer/OptionsButton,
		$Menu/MainMenu/MarginContainer/VBoxContainer/Quit
	]
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 1, 1, 0.05)
	btn_style.set_corner_radius_all(8)
	btn_style.content_margin_left = 10
	btn_style.content_margin_top = 8
	btn_style.content_margin_right = 10
	btn_style.content_margin_bottom = 8
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0, 0.6, 1, 0.2)
	btn_hover.border_width_bottom = 2
	btn_hover.border_color = Color(0, 0.6, 1, 0.8)

	for btn in buttons:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_hover)
			btn.add_theme_stylebox_override("focus", btn_style)

func _on_host_button_pressed() -> void:
	main_menu.hide()
	$Menu/DollyCamera.hide()
	$Menu/Blur.hide()
	menu_music.stop()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	if options_menu.visible:
		options_menu.hide()

	add_player(multiplayer.get_unique_id())
	print("Player spawned as host. Touch controls should be active.")

	upnp_setup()

func _on_join_button_pressed() -> void:
	main_menu.hide()
	$Menu/Blur.hide()
	menu_music.stop()
	
	enet_peer.create_client(address_entry.text, PORT)
	if options_menu.visible:
		options_menu.hide()
	multiplayer.multiplayer_peer = enet_peer

func _on_options_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		options_menu.show()
	else:
		options_menu.hide()
		
func _on_music_toggle_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		menu_music.stop()
	else:
		menu_music.play()

func add_player(peer_id: int) -> void:
	var player: Node = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	# Ativa o HUD Mobile apenas quando o jogador spawnar 🥊
	if peer_id == multiplayer.get_unique_id() and Global.is_mobile:
		var touch_controls_scene = load("res://scenes/ui/touch_controls.tscn")
		if touch_controls_scene:
			var hud = touch_controls_scene.instantiate()
			add_child(hud)
			if hud.has_node("LookArea"):
				hud.get_node("LookArea").player_node = player
			print("HUD Mobile instantaneamente criado no Spawn! 🏙️🎯")

func remove_player(peer_id: int) -> void:
	var player: Node = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup() -> void:
	if OS.has_feature("web"):
		return
		
	var upnp: UPNP = UPNP.new()
	var error = upnp.discover()
	
	if error != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed! Error: %s" % error)
		return
		
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(PORT)
		print("UPNP Port mapping success!")

	var ip: String = upnp.query_external_address()
	if ip == "":
		print("Failed to establish upnp connection!")
	else:
		print("Success! Join Address: %s" % upnp.query_external_address())
