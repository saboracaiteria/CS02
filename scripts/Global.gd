extends Node

var sensitivity : float =  .005
var controller_sensitivity : float =  .010

# Detecção de Mobile/PC
var is_mobile : bool = false

func _ready():
	# Detecção Robusta de Mobile (Android, iOS e Web Mobile) 🥊🏆
	is_mobile = OS.has_feature("mobile") or \
				OS.get_name() in ["Android", "iOS"] or \
				DisplayServer.is_touchscreen_available()
				
	# Se for Web, a chance de ser mobile é altíssima se tiver touchscreen
	if OS.has_feature("web"):
		is_mobile = DisplayServer.is_touchscreen_available()
		
	# LOG para Debug 🏁
	print("Detector de Mobile: ", is_mobile, " | OS: ", OS.get_name())
