extends Control

@onready var menu_panel: Control = $MenuPanel
@onready var bag_panel: Control = $BagPanel
@onready var team_panel: Control = $TeamPanel
@onready var pokedex_panel: Control = $PokedexPanel
@onready var save_panel: Control = $SavePanel
@onready var options_panel: Control = $OptionsPanel
@onready var menu_open_sound: AudioStreamPlayer = get_node_or_null("MenuOpenSound") as AudioStreamPlayer

@onready var bag_button: Button = $MenuPanel/MainMenuContent/BagButton
@onready var team_button: Button = $MenuPanel/MainMenuContent/TeamButton
@onready var pokedex_button: Button = $MenuPanel/MainMenuContent/PokedexButton
@onready var save_button: Button = $MenuPanel/MainMenuContent/SaveButton
@onready var options_button: Button = $MenuPanel/MainMenuContent/OptionsButton
@onready var close_button: Button = $MenuPanel/MainMenuContent/CloseButton

var menu_open: bool = false
var active_submenu: Control = null

func _ready() -> void:
	# Das Menü und der Öffnungssound müssen trotz get_tree().paused funktionieren.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(menu_open_sound):
		menu_open_sound.process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false
	_hide_all_submenus()

	bag_button.pressed.connect(_open_bag)
	team_button.pressed.connect(_open_team)
	pokedex_button.pressed.connect(_open_pokedex)
	save_button.pressed.connect(_open_save)
	options_button.pressed.connect(_open_options)
	close_button.pressed.connect(close_menu)

func _unhandled_input(event: InputEvent) -> void:
	# Menü öffnen oder schließen.
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		if menu_open:
			close_menu()
		else:
			open_menu()
		return

	if not menu_open:
		return

	# Mit Escape aus einem Untermenü zurückgehen oder das komplette Menü schließen.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if active_submenu != null:
			_close_submenu()
		else:
			close_menu()

func open_menu() -> void:
	# Während ein Dialog läuft, darf das Menü nicht geöffnet werden.
	var dialogue_ui: Node = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui != null and dialogue_ui.has_method("is_dialogue_open"):
		if dialogue_ui.is_dialogue_open():
			return

	# Sound nur beim tatsächlichen Öffnen abspielen.
	if is_instance_valid(menu_open_sound):
		menu_open_sound.play()

	menu_open = true
	visible = true
	active_submenu = null
	_hide_all_submenus()
	menu_panel.visible = true

	# Welt pausieren.
	get_tree().paused = true

	# Ersten Menüpunkt auswählen.
	if is_instance_valid(bag_button):
		bag_button.grab_focus()

func close_menu() -> void:
	if not menu_open:
		return

	menu_open = false
	active_submenu = null
	visible = false
	_hide_all_submenus()

	# Welt wieder fortsetzen.
	get_tree().paused = false

func _open_bag() -> void:
	_open_submenu(bag_panel)

func _open_team() -> void:
	_open_submenu(team_panel)

func _open_pokedex() -> void:
	_open_submenu(pokedex_panel)

func _open_save() -> void:
	_open_submenu(save_panel)

func _open_options() -> void:
	_open_submenu(options_panel)

func _open_submenu(submenu: Control) -> void:
	if submenu == null:
		return

	menu_panel.visible = false
	_hide_all_submenus()
	submenu.visible = true
	active_submenu = submenu

	var first_button: Button = _find_first_button(submenu)
	if first_button != null:
		first_button.grab_focus()

func _close_submenu() -> void:
	if active_submenu != null:
		active_submenu.visible = false

	active_submenu = null
	menu_panel.visible = true

	if is_instance_valid(bag_button):
		bag_button.grab_focus()

func _hide_all_submenus() -> void:
	if is_instance_valid(bag_panel):
		bag_panel.visible = false
	if is_instance_valid(team_panel):
		team_panel.visible = false
	if is_instance_valid(pokedex_panel):
		pokedex_panel.visible = false
	if is_instance_valid(save_panel):
		save_panel.visible = false
	if is_instance_valid(options_panel):
		options_panel.visible = false

func _find_first_button(container: Node) -> Button:
	for child in container.get_children():
		if child is Button:
			return child as Button
		var result: Button = _find_first_button(child)
		if result != null:
			return result
	return null
