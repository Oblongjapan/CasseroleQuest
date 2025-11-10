extends Node

## Central data repository for active items (tools)

## Predefined active items
const COVER_ITEM_DATA = {
	"type": ActiveItem.Type.COVER,
	"name": "Cover",
	"description": "Trap steam, reduce drain by 40% for 5s",
	"cooldown": 8.0
}

const STIR_ITEM_DATA = {
	"type": ActiveItem.Type.STIR,
	"name": "Stir",
	"description": "Add water, restore 20 moisture",
	"cooldown": 6.0
}

const BLOW_ITEM_DATA = {
	"type": ActiveItem.Type.BLOW,
	"name": "Blow",
	"description": "Cool the food, reduce drain by 60% for 3s",
	"cooldown": 10.0
}

## Get all active items as ActiveItem instances
func get_all_items() -> Array[ActiveItem]:
	var items: Array[ActiveItem] = []
	
	items.append(ActiveItem.new(
		COVER_ITEM_DATA.type,
		COVER_ITEM_DATA.name,
		COVER_ITEM_DATA.description,
		COVER_ITEM_DATA.cooldown
	))
	
	items.append(ActiveItem.new(
		STIR_ITEM_DATA.type,
		STIR_ITEM_DATA.name,
		STIR_ITEM_DATA.description,
		STIR_ITEM_DATA.cooldown
	))
	
	items.append(ActiveItem.new(
		BLOW_ITEM_DATA.type,
		BLOW_ITEM_DATA.name,
		BLOW_ITEM_DATA.description,
		BLOW_ITEM_DATA.cooldown
	))
	
	return items
