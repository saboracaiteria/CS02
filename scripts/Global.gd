extends Node

var sensitivity : float =  .005
var controller_sensitivity : float =  .010

# Detecção de Mobile/PC
var is_mobile : bool = false

func _ready():
	# Detecta se é mobile ou se estamos emulando touch no editor
	if OS.get_name() in ["Android", "iOS"] or DisplayServer.is_touchscreen_available():
		is_mobile = true
	
	# Caso queira testar a UI no PC, você pode forçar is_mobile = true aqui
	# is_mobile = true
