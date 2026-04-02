extends Node

var sensitivity : float =  .005
var controller_sensitivity : float =  .010

# Detecção Simplificada - Menos é Mais 🥊🥇
var is_mobile : bool = true
var is_playing : bool = false

func _ready():
	# Se for Web ou Mobile, os controles devem aparecer sempre!
	is_mobile = OS.has_feature("mobile") or OS.has_feature("web") or DisplayServer.is_touchscreen_available()
	
	# Caso o detector falhe, forçamos para evitar que o usuário fique sem HUD 🏁
	if OS.get_name() in ["Android", "iOS"]:
		is_mobile = true
		
	print("HUD Mobile Ativado por padrão: ", is_mobile)
