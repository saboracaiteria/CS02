extends Node

# --- GESTOR DE PLATAFORMA V1200 🌍⛩️ ---
# Agora Mobile e PC possuem arquivos de configuração SEPARADOS! 🏙️🚀🥇

var is_mobile : bool = false
var is_playing : bool = false
var is_editing_hud : bool = false

# Variáveis globais (Sync com os scripts de config) 🏗️
var sensitivity : float = 0.005
var controller_sensitivity : float = 0.010
var ads_multiplier : float = 0.5
var default_fov : float = 75.0
var ads_fov : float = 40.0
var movement_speed : float = 5.5
var jump_strength : float = 4.5

func _ready():
	# NOVO SISTEMA RÍGIDO V1320 🌍⛩️🥇
	if OS.has_feature("web"):
		# No navegador: Feature tags são o único método confiável! 🚀
		is_mobile = OS.has_feature("web_android") or OS.has_feature("web_ios")
	else:
		is_mobile = OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]


	var platform = OS.get_name()
	print("--- PLATAFORMA SENSÍVEL V1320: ", "MOBILE" if is_mobile else "PC", " --- 🎮🚀")
	print("--- OS: ", platform, " | TOUCH: ", DisplayServer.is_touchscreen_available(), " ---")
	
	_initialize_system()

func _initialize_system():
	var pc_script = load("res://scripts/configs/PC_System.gd")
	var mob_script = load("res://scripts/configs/Mobile_System.gd")
	
	var config : Node = null
	if is_mobile:
		config = mob_script.new()
	else:
		config = pc_script.new()
	
	# SINCRONIZAÇÃO DAS CONFIGURAÇÕES 🏗️🏹🥋
	sensitivity = config.sensitivity
	controller_sensitivity = config.controller_sens
	ads_multiplier = config.ads_multiplier
	default_fov = config.default_fov
	ads_fov = config.ads_fov
	movement_speed = config.speed
	jump_strength = config.jump_velocity
	
	# config.setup() NO LONGER FORCES MOUSE CAPTURE HERE V1210
	# Queremos o mouse livre no MENU! 🖱️🎭💎
	print("SISTEMA ATIVO V1210: ", config.get_config_name())
	# Limpa a instância temporária
	config.free()
