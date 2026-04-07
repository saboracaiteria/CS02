extends HSlider

func _ready():
	value = Global.default_fov

func _on_value_changed(fov_value: float) -> void:
	Global.default_fov = fov_value
	# If ads fov scales with default, adjust it too. Let's keep it simple.
