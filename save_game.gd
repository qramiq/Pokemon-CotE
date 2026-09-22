extends Control


@onready var info_label: Label = $MarginContainer/VBoxContainer/SaveInfoLabel
@onready var save_button: Button = $MarginContainer/VBoxContainer/SaveButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


const SAVE_PATH := "user://savegame.json"


func _ready() -> void:
	save_button.pressed.connect(_save_game)
	back_button.pressed.connect(_on_back_pressed)


func _save_game() -> void:
	var save_data := {
		"player_position": _get_player_position(),
		"current_scene": get_tree().current_scene.scene_file_path,
		"play_time": Time.get_ticks_msec()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		info_label.text = "Speichern fehlgeschlagen."
		return

	file.store_string(JSON.stringify(save_data))
	file.close()

	info_label.text = "Spiel gespeichert!"


func _get_player_position() -> Array:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return [0.0, 0.0, 0.0]

	return [
		player.global_position.x,
		player.global_position.y,
		player.global_position.z
	]


func _on_back_pressed() -> void:
	var menu := get_parent()

	if menu.has_method("_close_submenu"):
		menu._close_submenu()
