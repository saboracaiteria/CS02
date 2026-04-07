extends Node3D
class_name WeaponBase

@export_category("Gabarito Info")
@export var view_model_offset: Vector3 = Vector3(0.5, -0.4, -0.6)
@export var view_model_rotation: Vector3 = Vector3(0, 0, 0)
@export var view_model_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var ads_offset: Vector3 = Vector3(0, -0.2, -0.4)

@export_category("Weapon Stats")
@export var damage: int = 1
@export var fire_rate: float = 0.1
@export var max_ammo: int = 30
@export var reload_time: float = 1.5

var animation_player: AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = find_child("GPUParticles3D*", true)
@onready var gunshot_sound: AudioStreamPlayer3D = find_child("GunshotSound*", true)

func _ready():
	animation_player = find_child("AnimationPlayer", true)
	# Apply gabarito transform
	transform.origin = view_model_offset
	rotation_degrees = view_model_rotation
	scale = view_model_scale
