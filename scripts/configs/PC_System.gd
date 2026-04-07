extends Node

# --- SISTEMA DE CONFIGURAÇÃO PC V1200 💻🖱️🚀 ---
# Este arquivo concentra tudo que é exclusivo do Desktop/PC.

var sensitivity : float = 0.005          # Sensibilidade base do Mouse
var controller_sens : float = 0.010    # Sensibilidade do Gamepad
var ads_multiplier : float = 0.5    # Redução de sensibilidade no ADS
var default_fov : float = 85.0           # FOV padrão para monitor (Geralmente maior que mobile)
var ads_fov : float = 45.0               # FOV de mira (Zoom)
var speed : float = 5.5                  # Velocidade de movimento PC
var jump_velocity : float = 5.0          # Força do Salto PC

func setup():
	print("SISTEMA PC INICIALIZADO 💻🚀")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func get_config_name() -> String:
	return "PC / DESKTOP (V1200)"
