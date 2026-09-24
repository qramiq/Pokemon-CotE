extends Control

@onready var info_label: Label = $MarginContainer/VBoxContainer/SaveInfoLabel
@onready var save_button: Button = $MarginContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $MarginContainer/VBoxContainer/LoadButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func _ready() -> void:
	save_button.pressed.connect(_save_game)
	load_button.pressed.connect(_load_game)
	back_button.pressed.connect(_on_back_pressed)
	_load_game(true)

func _save_game() -> void:
	var save_data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"player_position": _get_player_position(),
		"current_scene": get_tree().current_scene.scene_file_path,
		"inventory": Inventory.serialize()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		info_label.text = "Speichern fehlgeschlagen."
		return
	file.store_string(JSON.stringify(save_data))
	file.close()
	info_label.text = "Spiel gespeichert.\n%s" % save_data["saved_at"]

func _load_game(silent: bool = false) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		if not silent:
			info_label.text = "Kein Spielstand gefunden."
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		if not silent:
			info_label.text = "Laden fehlgeschlagen."
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) > SAVE_VERSION:
		if not silent:
			info_label.text = "Der Spielstand ist nicht kompatibel."
		return false
	var save_data: Dictionary = parsed
	var restored := Inventory.restore(save_data.get("inventory", []))
	if restored:
		_restore_player_position(save_data.get("player_position", []))
	if not silent:
		info_label.text = "Spielstand geladen." if restored else "Inventory konnte nicht geladen werden."
	return restored

func _get_player_position() -> Array:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return [0.0, 0.0, 0.0]
	return [player.global_position.x, player.global_position.y, player.global_position.z]

func _restore_player_position(raw_position: Variant) -> void:
	if not raw_position is Array or raw_position.size() < 3:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.global_position = Vector3(float(raw_position[0]), float(raw_position[1]), float(raw_position[2]))

func _on_back_pressed() -> void:
	var menu := get_parent()
	if menu.has_method("_close_submenu"):
		menu._close_submenu()
