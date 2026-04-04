extends Node

var sensitivity : float =  .005
var controller_sensitivity : float =  .010

# Detecção Simplificada - Menos é Mais 🥊🥇
var is_mobile : bool = true
var is_playing : bool = false

func _ready():
	# Detecção V1020: Mobile nativo OU Toucsscreen em qualquer plataforma! 🥊🥇
	is_mobile = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	
	# Caso o detector falhe, forçamos para evitar que o usuário fique sem HUD 🏁
	if OS.get_name() in ["Android", "iOS"]:
		is_mobile = true
		
	print("HUD Mobile Ativado por padrão: ", is_mobile)
