extends Control


@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/VolumeSlider
@onready var fullscreen_check: CheckButton = $MarginContainer/VBoxContainer/FullscreenCheckButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = 1.0

	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _on_volume_changed(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")

	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(bus_index, value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


func _on_back_pressed() -> void:
	var menu := get_parent()

	if menu.has_method("_close_submenu"):
		menu._close_submenu()
