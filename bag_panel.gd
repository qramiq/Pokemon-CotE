extends Control


@onready var item_list: ItemList = $MarginContainer/VBoxContainer/ItemList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


var items: Array[Dictionary] = [
	{
		"name": "Trank",
		"amount": 3,
		"description": "Heilt einige KP."
	},
	{
		"name": "Pokéball",
		"amount": 5,
		"description": "Fängt wilde Pokémon."
	},
	{
		"name": "Heilitem",
		"amount": 1,
		"description": "Ein wichtiges Questobjekt."
	}
]


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh_items()


func _refresh_items() -> void:
	item_list.clear()

	for item in items:
		var text := "%s × %d" % [
			item["name"],
			item["amount"]
		]

		item_list.add_item(text)


func _on_back_pressed() -> void:
	var menu := get_parent()

	if menu.has_method("_close_submenu"):
		menu._close_submenu()
