extends Node
# --- SERVIDOR HEADLESS V7.0 🖥️🏙️🎯🥇 ---
# Este script roda APENAS no servidor Render (Linux headless).
# Gerencia: salas de jogo, spawns, bots, autoridade de rede.

const Player = preload("res://scenes/player.tscn")
const Bot    = preload("res://scenes/entities/bot.tscn")

var players_in_game : Dictionary = {}   # peer_id → Node
var bot_nodes       : Array       = []
var game_started    : bool        = false
var match_time      : float       = 300.0  # 5 min

# Spawns do servidor (mesmos do world.gd)
const PLAYER_SPAWNS := [
	Vector3(-18, 1, 0), Vector3(18, 1, 0),
	Vector3(-2.8, 1, -6), Vector3(-17, 1, 17),
]
const BOT_SPAWNS := [
	Vector3(15, 2, 10), Vector3(15, 2, -10),
	Vector3(20, 2, 0),  Vector3(10, 2, 15),
]

func _ready() -> void:
	# Só executa em modo servidor
	if not NetworkManager.is_server_mode: return
	
	NetworkManager.server_created.connect(_on_server_ready)
	multiplayer.peer_connected.connect(_on_player_joined)
	multiplayer.peer_disconnected.connect(_on_player_left)
	print("[SERVIDOR] Pronto para receber jogadores.")

func _on_server_ready() -> void:
	print("[SERVIDOR] ✅ Aceitando conexões...")

func _on_player_joined(peer_id: int) -> void:
	print("[SERVIDOR] Jogador %d entrou | Total: %d" % [peer_id, multiplayer.get_peers().size()])
	_spawn_player_on_server(peer_id)
	
	# Inicia a partida quando o primeiro jogador entrar
	if not game_started:
		game_started = true
		await get_tree().create_timer(1.0).timeout
		_spawn_bots_on_server(3)
		print("[SERVIDOR] Partida iniciada!")

func _on_player_left(peer_id: int) -> void:
	print("[SERVIDOR] Jogador %d saiu" % peer_id)
	if players_in_game.has(peer_id):
		var player_node = players_in_game[peer_id]
		if is_instance_valid(player_node):
			player_node.queue_free()
		players_in_game.erase(peer_id)
	
	# Se não há mais jogadores, reseta o servidor
	if multiplayer.get_peers().is_empty():
		game_started = false
		_cleanup_bots()
		print("[SERVIDOR] Sala vazia — aguardando novos jogadores...")

func _spawn_player_on_server(peer_id: int) -> void:
	var player : CSPlayer = Player.instantiate()
	player.name           = str(peer_id)
	player.team           = "Azul"
	add_child(player)
	player.global_position = PLAYER_SPAWNS[players_in_game.size() % PLAYER_SPAWNS.size()]
	players_in_game[peer_id] = player
	print("[SERVIDOR] Player %d spawnou em %s" % [peer_id, player.global_position])

func _spawn_bots_on_server(amount: int) -> void:
	for i in range(amount):
		var bot = Bot.instantiate()
		bot.name   = "ServerBot_%d" % i
		bot.team   = "Vermelho"
		add_child(bot)
		bot.global_position = BOT_SPAWNS[i % BOT_SPAWNS.size()]
		bot_nodes.append(bot)

func _cleanup_bots() -> void:
	for b in bot_nodes:
		if is_instance_valid(b): b.queue_free()
	bot_nodes.clear()

func _process(delta: float) -> void:
	if not NetworkManager.is_server_mode or not game_started: return
	match_time -= delta
	if match_time <= 0:
		match_time = 300.0
		_reset_match()

func _reset_match() -> void:
	print("[SERVIDOR] Tempo esgotado — resetando partida!")
	for id in players_in_game:
		var p = players_in_game[id]
		if is_instance_valid(p):
			p.global_position = PLAYER_SPAWNS[randi() % PLAYER_SPAWNS.size()]
			p.health = 100
