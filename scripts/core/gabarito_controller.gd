extends Node3D

@onready var ak = $CameraReference/WeaponRoot/AK_Gabarito
@onready var pistol = $CameraReference/WeaponRoot/Pistol_Gabarito
@onready var smg = $CameraReference/WeaponRoot/SMG_Gabarito

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_show_weapon(ak)
		if event.keycode == KEY_2:
			_show_weapon(pistol)
		if event.keycode == KEY_3:
			_show_weapon(smg)

func _show_weapon(node):
	ak.visible = false
	pistol.visible = false
	smg.visible = false
	node.visible = true
	print("Mostrando no Gabarito: ", node.name)
