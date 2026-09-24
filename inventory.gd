extends Node

## Globaler Itembestand des Spielers. Der Autoload-Name ist "Inventory".
signal inventory_changed
signal item_used(item: Dictionary, result_text: String)

const DEFAULT_ITEMS: Array[Dictionary] = [
	{
		"id": "potion",
		"name": "Trank",
		"amount": 3,
		"pocket": "Items",
		"description": "Heilt 20 KP eines Pokémon.",
		"usable": true,
		"effect": "heal"
	},
	{
		"id": "pokeball",
		"name": "Pokéball",
		"amount": 5,
		"pocket": "Bälle",
		"description": "Ein Ball zum Fangen wilder Pokémon.",
		"usable": true,
		"effect": "catch"
	},
	{
		"id": "antidote",
		"name": "Gegengift",
		"amount": 2,
		"pocket": "Items",
		"description": "Heilt die Vergiftung eines Pokémon.",
		"usable": true,
		"effect": "cure_poison"
	},
	{
		"id": "town_map",
		"name": "Karte",
		"amount": 1,
		"pocket": "Basis-Items",
		"description": "Zeigt die wichtigsten Orte der Region.",
		"usable": false,
		"effect": "key_item"
	}
]

var items: Array[Dictionary] = []

func _ready() -> void:
	reset_to_defaults(false)

func reset_to_defaults(emit_change: bool = true) -> void:
	items = DEFAULT_ITEMS.duplicate(true)
	if emit_change:
		inventory_changed.emit()

func get_items(pocket: String = "") -> Array[Dictionary]:
	if pocket.is_empty():
		return items.duplicate(true)
	return items.filter(func(item: Dictionary) -> bool: return str(item.get("pocket", "Items")) == pocket).duplicate(true)

func add_item(item_id: String, item_name: String, amount: int = 1, description: String = "", pocket: String = "Items", usable: bool = true, effect: String = "none") -> void:
	if amount <= 0:
		return
	for item: Dictionary in items:
		if str(item.get("id")) == item_id:
			item["amount"] = int(item.get("amount", 0)) + amount
			inventory_changed.emit()
			return
	items.append({
		"id": item_id,
		"name": item_name,
		"amount": amount,
		"pocket": pocket,
		"description": description,
		"usable": usable,
		"effect": effect
	})
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	for index in items.size():
		if str(items[index].get("id")) == item_id and int(items[index].get("amount", 0)) >= amount:
			items[index]["amount"] = int(items[index]["amount"]) - amount
			if int(items[index]["amount"]) <= 0:
				items.remove_at(index)
			inventory_changed.emit()
			return true
	return false

func use_item(item_id: String) -> Dictionary:
	for item: Dictionary in items:
		if str(item.get("id")) != item_id:
			continue
		if not bool(item.get("usable", false)):
			return {"success": false, "result": "%s kann hier nicht benutzt werden." % item["name"]}
		var result_text := ""
		match str(item.get("effect", "none")):
			"heal":
				result_text = "%s wurde benutzt. Ein Pokémon kann geheilt werden." % item["name"]
			"catch":
				result_text = "%s ist bereit für den nächsten Fangversuch." % item["name"]
			"cure_poison":
				result_text = "%s kann eine Vergiftung heilen." % item["name"]
			_:
				result_text = "%s wurde benutzt." % item["name"]
		if not remove_item(item_id):
			return {"success": false, "result": "Dieses Item ist nicht mehr vorhanden."}
		item_used.emit(item.duplicate(true), result_text)
		return {"success": true, "result": result_text}
	return {"success": false, "result": "Dieses Item ist nicht mehr vorhanden."}

func serialize() -> Array[Dictionary]:
	return items.duplicate(true)

func restore(serialized_items: Variant) -> bool:
	if not serialized_items is Array:
		return false
	var restored: Array[Dictionary] = []
	for raw_item in serialized_items:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item.duplicate(true)
		if str(item.get("id", "")).is_empty() or int(item.get("amount", 0)) <= 0:
			continue
		item["amount"] = int(item["amount"])
		restored.append(item)
	if restored.is_empty() and not serialized_items.is_empty():
		return false
	items = restored
	inventory_changed.emit()
	return true
