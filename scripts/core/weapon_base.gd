# GABARITO SYSTEM V1460 🏙️🎯🥇
# Use este script em TODAS as novas armas para manter a escala e posição corretas.
# DICA: Para evitar que a arma atravesse a parede, mantenha o 'view_model_offset.z' próximo de -0.5.
# NOTA: Certifique-se de que a Camera3D do jogador tenha o 'Near' definido como 0.01 para evitar clipping.
extends Node3D
class_name WeaponBase

@export_category("Gabarito (Transform)")
@export var view_model_offset: Vector3 = Vector3(0.5, -0.4, -0.6) # Offset lateral/altura/profundidade
@export var view_model_rotation: Vector3 = Vector3(0, 0, 0)
@export var view_model_scale: Vector3 = Vector3(1.0, 1.0, 1.0) # ESCALA REAL: AK (1.2), Dual (0.02)
@export var ads_offset: Vector3 = Vector3(0, -0.25, -0.6)

@export_category("Weapon Stats")
@export var damage: int = 16
@export var fire_rate: float = 0.1
@export var max_ammo: int = 30
@export var reload_time: float = 1.5
@export var recoil_vertical: float = 0.07   # Recuo para cima ⬆️ (era 0.05)
@export var recoil_horizontal: float = 0.03 # Recuo lateral random ↔️ (era 0.02)

var animation_player: AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = find_child("GPUParticles3D*", true)
@onready var gunshot_sound: AudioStreamPlayer3D = find_child("GunshotSound*", true)

func _ready():
	animation_player = find_child("AnimationPlayer", true)
	# Aplica inicialmente
	_update_viewmodel_transform()

func _process(_delta):
	# Força a transformação a cada frame para vencer animações que resetam a escala 🔨
	_update_viewmodel_transform()

func _update_viewmodel_transform():
	transform.origin = view_model_offset
	rotation_degrees = view_model_rotation
	scale = view_model_scale
