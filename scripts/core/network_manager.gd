extends Node
# --- NETWORK MANAGER V7.0 🌐🏙️🎯🥇 ---
# Abstrai ENet (Desktop) vs WebSocket (Web/Render) automaticamente.
# Ponto único de controle de toda a rede do jogo.

signal server_created
signal client_connected
signal client_disconnected(id: int)
signal connection_failed

const MAX_PLAYERS := 4
const PORT        := 8080

# URL do servidor Render — atualizar após o deploy
var server_url : String = "wss://cs02-server.onrender.com"

# Detecta se estamos rodando como servidor headless (no Render)
var is_server_mode : bool = false

func _ready() -> void:
	# Detecta modo servidor pelos argumentos de linha de comando
	for arg in OS.get_cmdline_args():
		if arg == "--server" or arg == "--headless-server":
			is_server_mode = true
			break
	# Também detecta se não há display (Linux sem GPU = headless)
	if DisplayServer.get_name() == "headless":
		is_server_mode = true
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	if is_server_mode:
		print("[NET] Modo SERVIDOR detectado — iniciando servidor WebSocket...")
		start_dedicated_server()

# ─────────────────────────────────────────────
#  SERVIDOR
# ─────────────────────────────────────────────
func start_dedicated_server() -> void:
	var ws := WebSocketMultiplayerPeer.new()
	var render_port := int(OS.get_environment("PORT")) if OS.get_environment("PORT") != "" else PORT
	var err := ws.create_server(render_port)
	if err != OK:
		push_error("[NET] Falha ao criar servidor WebSocket na porta %d: %s" % [render_port, err])
		return
	multiplayer.multiplayer_peer = ws
	multiplayer.peer_connected.connect(func(id): print("[NET] Jogador conectado: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("[NET] Jogador desconectado: ", id))
	print("[NET] ✅ Servidor WebSocket na porta %d" % render_port)
	emit_signal("server_created")

# ─────────────────────────────────────────────
#  HOST LOCAL (Desktop ENet — LAN/testes)
# ─────────────────────────────────────────────
func host_local() -> Error:
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(PORT, MAX_PLAYERS)
	if err != OK: return err
	multiplayer.multiplayer_peer = enet
	emit_signal("server_created")
	return OK

# ─────────────────────────────────────────────
#  CONECTAR AO SERVIDOR RENDER (Web / Desktop)
# ─────────────────────────────────────────────
func join_render(custom_url: String = "") -> Error:
	var url := custom_url if custom_url != "" else server_url
	var ws := WebSocketMultiplayerPeer.new()
	var err := ws.create_client(url)
	if err != OK:
		push_error("[NET] Falha ao conectar em %s: %s" % [url, err])
		emit_signal("connection_failed")
		return err
	multiplayer.multiplayer_peer = ws
	print("[NET] Conectando ao servidor Render: ", url)
	return OK

# ─────────────────────────────────────────────
#  CONECTAR A IP LOCAL (Desktop ENet — LAN)
# ─────────────────────────────────────────────
func join_local(ip: String) -> Error:
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(ip, PORT)
	if err != OK:
		emit_signal("connection_failed")
		return err
	multiplayer.multiplayer_peer = enet
	return OK

# ─────────────────────────────────────────────
#  DESCONECTAR
# ─────────────────────────────────────────────
func disconnect_all() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

# ─────────────────────────────────────────────
#  CALLBACKS
# ─────────────────────────────────────────────
func _on_peer_connected(id: int) -> void:
	print("[NET] Peer conectado: ", id)
	emit_signal("client_connected")

func _on_peer_disconnected(id: int) -> void:
	print("[NET] Peer desconectado: ", id)
	emit_signal("client_disconnected", id)

func _on_connected_to_server() -> void:
	print("[NET] ✅ Conectado ao servidor! Meu ID: ", multiplayer.get_unique_id())
	emit_signal("client_connected")

func _on_connection_failed() -> void:
	push_error("[NET] ❌ Falha na conexão com o servidor!")
	emit_signal("connection_failed")

# Utilitário: retorna o número de jogadores conectados
func get_player_count() -> int:
	if not multiplayer.multiplayer_peer: return 1
	return multiplayer.get_peers().size() + 1  # +1 = host/autoridade

func is_full() -> bool:
	return get_player_count() >= MAX_PLAYERS
