extends Control


signal dialogue_closed


@export_category("Textgeschwindigkeit")
@export var letters_per_second: float = 45.0


@onready var name_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/DialogueLabel
@onready var hint_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/HintLabel


var dialogue_lines: Array[String] = []
var current_line_index: int = 0

var dialogue_is_open: bool = false
var is_typing: bool = false

var text_tween: Tween


func _ready() -> void:
	add_to_group("dialogue_ui")

	# Die Dialogbox muss auch funktionieren,
	# wenn der Szenenbaum pausiert ist.
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false


func is_dialogue_open() -> bool:
	return dialogue_is_open


func show_dialogue(
	npc_name: String,
	lines: Array[String]
) -> void:
	if lines.is_empty():
		return

	# Falls bereits ein alter Schreib-Tween läuft,
	# wird dieser beendet.
	if text_tween != null and text_tween.is_valid():
		text_tween.kill()

	dialogue_lines.clear()

	for line in lines:
		var clean_line: String = line.strip_edges()

		if not clean_line.is_empty():
			dialogue_lines.append(clean_line)

	if dialogue_lines.is_empty():
		return

	name_label.text = npc_name
	current_line_index = 0
	dialogue_is_open = true
	is_typing = false
	visible = true

	get_tree().paused = true

	_display_current_line()


func _display_current_line() -> void:
	if current_line_index < 0:
		current_line_index = 0

	if current_line_index >= dialogue_lines.size():
		close_dialogue()
		return

	var current_text: String = dialogue_lines[current_line_index]

	dialogue_label.text = ""
	hint_label.text = "E zum Weiterlesen"

	is_typing = true

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()

	text_tween = create_tween()

	var safe_speed: float = max(letters_per_second, 1.0)

	var duration: float = max(
		float(current_text.length()) / safe_speed,
		0.05
	)

	text_tween.tween_method(
		_set_visible_characters,
		0.0,
		float(current_text.length()),
		duration
	)

	text_tween.finished.connect(_on_text_typing_finished)


func _set_visible_characters(amount: float) -> void:
	if not dialogue_is_open:
		return

	if current_line_index < 0:
		return

	if current_line_index >= dialogue_lines.size():
		return

	var current_text: String = dialogue_lines[current_line_index]
	var character_count: int = int(amount)

	dialogue_label.text = current_text.substr(
		0,
		character_count
	)


func _on_text_typing_finished() -> void:
	if not dialogue_is_open:
		return

	if current_line_index >= dialogue_lines.size():
		return

	is_typing = false
	dialogue_label.text = dialogue_lines[current_line_index]
	hint_label.text = "E zum Weiterlesen"


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_is_open:
		return

	if event.is_action_pressed("interact") \
	or event.is_action_pressed("ui_accept"):

		get_viewport().set_input_as_handled()

		# Während des Schreibens zeigt ein Tastendruck
		# sofort die komplette Textzeile.
		if is_typing:
			_finish_current_line()
			return

		# Nächste Dialogseite anzeigen.
		current_line_index += 1

		if current_line_index >= dialogue_lines.size():
			close_dialogue()
		else:
			_display_current_line()


func _finish_current_line() -> void:
	if not dialogue_is_open:
		return

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()

	is_typing = false

	if current_line_index >= 0 \
	and current_line_index < dialogue_lines.size():
		dialogue_label.text = dialogue_lines[current_line_index]

	hint_label.text = "E zum Weiterlesen"


func close_dialogue() -> void:
	if not dialogue_is_open:
		return

	if text_tween != null and text_tween.is_valid():
		text_tween.kill()

	dialogue_is_open = false
	is_typing = false
	visible = false

	dialogue_label.text = ""
	hint_label.text = ""

	get_tree().paused = false

	dialogue_closed.emit()
