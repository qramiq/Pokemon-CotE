extends Control

@onready var item_list: ItemList = $MarginContainer/VBoxContainer/ItemList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var use_button: Button = $MarginContainer/VBoxContainer/UseButton
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

var selected_item_id := ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	use_button.pressed.connect(_on_use_pressed)
	item_list.item_selected.connect(_on_item_selected)
	Inventory.inventory_changed.connect(_refresh_items)
	_refresh_items()

func _refresh_items() -> void:
	item_list.clear()
	selected_item_id = ""
	status_label.text = ""
	for item in Inventory.get_items():
		var text := "%s    × %d" % [item["name"], int(item["amount"])]
		var index := item_list.add_item(text)
		item_list.set_item_metadata(index, item["id"])
	if item_list.item_count == 0:
		description_label.text = "Der Beutel ist leer."
		use_button.disabled = true
		return
	item_list.select(0)
	_on_item_selected(0)

func _on_item_selected(index: int) -> void:
	selected_item_id = str(item_list.get_item_metadata(index))
	for item in Inventory.get_items():
		if str(item.get("id")) == selected_item_id:
			description_label.text = "%s\n\n%s" % [item["pocket"], item["description"]]
			use_button.disabled = not bool(item.get("usable", false))
			return

func _on_use_pressed() -> void:
	if selected_item_id.is_empty():
		return
	var result: Dictionary = Inventory.use_item(selected_item_id)
	status_label.text = str(result.get("result", ""))
	if bool(result.get("success", false)):
		status_label.modulate = Color("#2e7d32")
	else:
		status_label.modulate = Color("#b71c1c")

func _on_back_pressed() -> void:
	var menu := get_parent()

	if menu.has_method("_close_submenu"):
		menu._close_submenu()
