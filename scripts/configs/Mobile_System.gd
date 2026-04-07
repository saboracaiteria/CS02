extends Node

# --- SISTEMA DE CONFIGURAÇÃO MOBILE V1200 📱🥊🥇 ---
# Este arquivo concentra tudo que é exclusivo de Android/iOS/Mobile.

var sensitivity : float = 0.02           # Sensibilidade de toque (TouchLookArea)
var controller_sens : float = 0.04     # Sensibilidade do Gamepad no celular
var ads_multiplier : float = 0.7   # Redução de sensibilidade no ADS
var default_fov : float = 75.0          # FOV menor para telas menores (Visibilidade melhor)
var ads_fov : float = 40.0              # FOV de mira (Maior Zoom)
var speed : float = 6.2                  # Velocidade de movimento Mobile (Levemente maior para dinamismo)
var jump_velocity : float = 6.0          # Força do Salto Mobile (Mais alto ajuda no toque)

func setup():
	print("SISTEMA MOBILE INICIALIZADO 📱🥊")
	# No mobile, o mouse-mode visibility deve ser livre para os controles de toque funcionarem!
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func get_config_name() -> String:
	return "MOBILE / TABLET (V1200)"
