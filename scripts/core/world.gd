extends Node

@onready var main_menu: PanelContainer = $Menu/MainMenu
@onready var options_menu: PanelContainer = $Menu/Options
@onready var pause_menu: PanelContainer = $Menu/PauseMenu
@onready var address_entry: LineEdit = %AddressEntry
@onready var menu_music: AudioStreamPlayer = %MenuMusic

const Player = preload("res://scenes/player.tscn")
const Bot    = preload("res://scenes/entities/bot.tscn")

# Modo de jogo selecionado pelo jogador
enum GameMode { SOLO, ONLINE_RENDER, LAN_HOST, LAN_JOIN }
const PORT        := 8080
var current_mode : GameMode = GameMode.SOLO
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
	Global.is_playing = false
	
	# PRÉ-AQUECIMENTO NO MENU V6.1 🔥🏙️🎯🥇
	# Roda enquanto o player está no menu — zero impacto no gameplay!
	if ShaderPrewarmer:
		ShaderPrewarmer.prewarm()

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

# ──────────────────────────────────────────────────────────
#  SOLO (sem rede — single player com bots)
# ──────────────────────────────────────────────────────────
func _on_host_button_pressed() -> void:
	current_mode = GameMode.SOLO
	_start_solo()

func _start_solo() -> void:
	Global.log_error("MODO: Solo com bots.")
	_clear_menu_visuals()
	
	# Mobile entra em tela cheia automático 📱🚀
	if OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
	add_player(1)  # ID fixo 1 em modo solo
	Global.is_playing = true
	spawn_bots.call_deferred(3)

# ──────────────────────────────────────────────────────────
#  ONLINE RENDER — conecta ao servidor WebSocket do Render
# ──────────────────────────────────────────────────────────
func start_online_render(custom_url: String = "") -> void:
	current_mode = GameMode.ONLINE_RENDER
	Global.log_error("MODO: Online (Render WebSocket)")
	_clear_menu_visuals()
	
	# Mobile entra em tela cheia automático 📱🚀
	if OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Conecta callbacks de rede
	NetworkManager.client_connected.connect(_on_online_connected, CONNECT_ONE_SHOT)
	NetworkManager.connection_failed.connect(_on_online_failed, CONNECT_ONE_SHOT)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	var err = NetworkManager.join_render(custom_url)
	if err != OK:
		Global.log_error("ERRO: Não foi possível conectar ao servidor Render.")
		main_menu.show()

func _on_online_connected() -> void:
	Global.log_error("ONLINE: Conectado! Aguardando servidor spawnar jogador...")
	Global.is_playing = true


func _on_online_failed() -> void:
	Global.log_error("ONLINE ERRO: Falha ao conectar. Verifique a URL do servidor.")
	main_menu.show()

# ──────────────────────────────────────────────────────────
#  LAN HOST (Desktop ENet)
# ──────────────────────────────────────────────────────────
func _join_server(ip: String):
	if Global.is_playing: return
	Global.log_error("LAN JOIN: Conectando a %s..." % ip)
	_clear_menu_visuals()
	if OS.has_feature("web"):
		# Na web, redireciona para o Render
		start_online_render()
		return
	current_mode = GameMode.LAN_JOIN
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	var err = NetworkManager.join_local(ip)
	if err != OK:
		Global.log_error("LAN ERRO: Falha ao conectar em %s" % ip)
		main_menu.show()
	else:
		Global.is_playing = true


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
	call_deferred("add_child", player) # CORREÇÃO V2390 ✨🎯🥇
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
		call_deferred("add_child", bot) # CORREÇÃO V2390 ✨🎯🥇
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
