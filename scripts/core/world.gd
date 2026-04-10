extends Node

@onready var main_menu: PanelContainer = $Menu/MainMenu
@onready var options_menu: PanelContainer = $Menu/Options
@onready var pause_menu: PanelContainer = $Menu/PauseMenu
@onready var address_entry: LineEdit = %AddressEntry
@onready var menu_music: AudioStreamPlayer = %MenuMusic

const Player = preload("res://scenes/player.tscn")
const Bot = preload("res://scenes/entities/bot.tscn")
const PORT = 9999
var enet_peer: ENetMultiplayerPeer
var paused: bool = false
var options: bool = false
var controller: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and !main_menu.visible and !options_menu.visible:
		paused = !paused
	if event is InputEventJoypadMotion:
		controller = true
	elif event is InputEventMouseMotion:
		controller = false


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

var udp_peer: PacketPeerUDP = PacketPeerUDP.new()
var broadcast_port: int = 9997
var is_broadcasting: bool = false
var discovery_timer: float = 0.0

func _ready():
	_apply_premium_style()
	
	# Configura UDP para o "Auto-Join" 🌐🚀
	if !OS.has_feature("web"):
		udp_peer.set_dest_address("255.255.255.255", broadcast_port)
		
	# CONEXÃO DE DOMINAÇÃO V1675 🏙️🚩🥇
	var gm = $GameManager
	var zones = [$CapturePoint_A, $CapturePoint_B, $CapturePoint_C]
	for zone in zones:
		if zone and gm:
			zone.zone_captured.connect(gm._on_zone_captured)
			$Debug.log_msg("SISTEMA: Zona %s conectada ao Game Manager!" % zone.zone_id)
		else:
			$Debug.log_msg("ERRO: Falha ao conectar zona ou Game Manager!")
	
	# MOUSE VISÍVEL NO MENU! V1210 🖱️🎭
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.is_playing = false # Começa em estado de menu!

func _process(delta: float) -> void:
	# Lógica de Broadcast do Host 📢
	if is_broadcasting:
		discovery_timer += delta
		if discovery_timer >= 1.0:
			udp_peer.put_packet("CS02_SERVER".to_utf8_buffer())
			discovery_timer = 0.0
	
	# Lógica de Escuta do Cliente 👂
	if !is_broadcasting and !Global.is_playing and !OS.has_feature("web"):
		if udp_peer.get_available_packet_count() > 0:
			var packet = udp_peer.get_packet().get_string_from_utf8()
			if packet == "CS02_SERVER":
				var server_ip = udp_peer.get_packet_ip()
				Global.log_error("AUTO-JOIN: Servidor encontrado em %s! Conectando..." % server_ip)
				_join_server(server_ip)

	if paused:
		$Menu/Blur.show()
		pause_menu.show()
		if !controller:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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

func get_local_ip() -> String:
	# Busca o IP real da rede local (WiFi/LAN) 🌐
	for ip in IP.get_local_addresses():
		if ip.split(".").size() == 4 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
	return "127.0.0.1"

func _clear_menu_visuals():
	main_menu.hide()
	options_menu.hide()
	$Menu/DollyCamera.hide()
	$Menu/DollyCamera.current = false
	$Menu/DollyCamera.set_process(false)
	$Menu/Blur.hide()
	$Menu/ColorRect_Bronze.hide()
	$Menu/Background.hide()
	$Menu/FallBackBG.hide()
	menu_music.stop()

func _on_host_button_pressed() -> void:
	_setup_host()

func _setup_host():
	Global.log_error("SISTEMA: Iniciando modo HOST automático...")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	_clear_menu_visuals()
	
	var host_err
	if OS.has_feature("web"):
		host_err = ERR_UNAVAILABLE
		Global.log_error("SISTEMA: WEB detectada. Pulando criação de servidor ENet.")
	else:
		enet_peer = ENetMultiplayerPeer.new()
		host_err = enet_peer.create_server(PORT)
	if host_err == OK:
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		
		# Inicia Broadcast para outros acharem a sala 📢
		is_broadcasting = true
		udp_peer.bind(broadcast_port)
		
		Global.log_error("AUTO-NET: Sala aberta e visível na rede local!")
	
	add_player(multiplayer.get_unique_id())
	Global.is_playing = true
	spawn_bots.call_deferred(3)
	
	if host_err == OK:
		upnp_setup()

func _on_join_button_pressed() -> void:
	_join_server(address_entry.text)

func _join_server(ip: String):
	if Global.is_playing: return
	
	Global.log_error("SISTEMA: Conectando a %s..." % ip)
	_clear_menu_visuals()
	
	if OS.has_feature("web"):
		Global.log_error("ERRO: Multiplayer ENet não suportado na Web.")
		main_menu.show()
		return

	enet_peer = ENetMultiplayerPeer.new()
	var err = enet_peer.create_client(ip, PORT)
	if err == OK:
		multiplayer.multiplayer_peer = enet_peer
		Global.is_playing = true
	else:
		Global.log_error("ERRO: Falha ao conectar em %s" % ip)
		main_menu.show()

	if options_menu.visible:
		options_menu.hide()

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
	Global.log_error("SISTEMA: Instanciando jogador %d..." % peer_id)
	var player: CSPlayer = Player.instantiate()
	player.name = str(peer_id)
	add_child.call_deferred(player) # CORREÇÃO V2340 🏙️🎯🥇
	Global.log_error("SISTEMA: Jogador %d adicionado à cena." % peer_id)
	
	# SPAWN DE ELITE V1460: Busca os spawns do jogador ✨🚀🎯
	player.global_position = player.spawns[randi() % player.spawns.size()]
	
	# Ativa o HUD Mobile V1440 (Agora embutido no Player) ✨🎯🥇
	if peer_id == multiplayer.get_unique_id():
		Global.is_playing = true

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

func spawn_bots(amount: int):
	Global.log_error("SISTEMA: Spawnando %d Bots Inimigos..." % amount)
	for i in range(amount):
		var bot = Bot.instantiate()
		bot.name = "Bot_" + str(i)
		bot.team = "Vermelho"
		add_child.call_deferred(bot) # CORREÇÃO V2340 🏙️🎯🥇
		# Spawns estratégicos para o time vermelho (Lado oposto do mapa)
		var bot_spawns = [
			Vector3(15, 2, 10),
			Vector3(15, 2, -10),
			Vector3(20, 2, 0),
			Vector3(10, 2, 15),
			Vector3(10, 2, -15)
		]
		bot.global_position = bot_spawns[i % bot_spawns.size()]
		Global.log_error("IA: Bot %d entrou no campo de batalha." % i)
