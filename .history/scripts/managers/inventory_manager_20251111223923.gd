extends Node
class_name InventoryManager

## Manages the player's collection of ingredients, active items, and relics

signal inventory_updated()

var owned_ingredients: Array[IngredientModel] = []
var owned_active_items: Array[ActiveItem] = []
var owned_relics: Array[RelicModel] = []

const MAX_ACTIVE_ITEMS: int = 3
const MAX_INGREDIENTS: int = 6

## Reset inventory to empty state
func reset_inventory() -> void:
	owned_ingredients.clear()
	owned_active_items.clear()
	owned_relics.clear()
	inventory_updated.emit()

## Add an ingredient to inventory
func add_ingredient(ingredient: IngredientModel) -> bool:
	if owned_ingredients.size() >= MAX_INGREDIENTS:
		return false
	owned_ingredients.append(ingredient)
	inventory_updated.emit()
	return true

## Remove ingredients from inventory (after using them to cook)
func remove_ingredients(ingredient_1: IngredientModel, ingredient_2: IngredientModel = null) -> void:
	# Remove one or two ingredients. If ingredient_2 is null, only remove ingredient_1.
	owned_ingredients.erase(ingredient_1)
	if ingredient_2 != null and ingredient_1 != ingredient_2:
		owned_ingredients.erase(ingredient_2)
	inventory_updated.emit()

## Trade out an ingredient for a new one
func trade_ingredient(old_index: int, new_ingredient: IngredientModel) -> void:
	if old_index >= 0 and old_index < owned_ingredients.size():
		owned_ingredients[old_index] = new_ingredient
		inventory_updated.emit()

## Check if we can add more ingredients
func can_add_ingredient() -> bool:
	return owned_ingredients.size() < MAX_INGREDIENTS

## Add an active item to inventory (max 3)
func add_active_item(item: ActiveItem) -> bool:
	if owned_active_items.size() >= MAX_ACTIVE_ITEMS:
		return false
	owned_active_items.append(item)
	inventory_updated.emit()
	return true

## Trade out an active item for a new one
func trade_active_item(old_index: int, new_item: ActiveItem) -> void:
	if old_index >= 0 and old_index < owned_active_items.size():
		owned_active_items[old_index] = new_item
		inventory_updated.emit()

## Add a relic to inventory
func add_relic(relic: RelicModel) -> void:
	owned_relics.append(relic)
	inventory_updated.emit()

## Check if we can add more active items
func can_add_active_item() -> bool:
	return owned_active_items.size() < MAX_ACTIVE_ITEMS

## Get all owned ingredients
func get_ingredients() -> Array[IngredientModel]:
	return owned_ingredients

## Get all owned active items
func get_active_items() -> Array[ActiveItem]:
	return owned_active_items

## Get all owned relics
func get_relics() -> Array[RelicModel]:
	return owned_relics

## Calculate total drain reduction from all relics
func get_total_drain_reduction() -> float:
	var reduction = 0.0
	for relic in owned_relics:
		if relic.effect_type == RelicModel.EffectType.REDUCE_DRAIN:
			reduction += relic.effect_value
	return reduction

## Calculate total cooldown reduction from all relics
func get_total_cooldown_reduction() -> float:
	var reduction = 0.0
	for relic in owned_relics:
		if relic.effect_type == RelicModel.EffectType.REDUCE_COOLDOWN:
			reduction += relic.effect_value
	return reduction

## Calculate total bonus starting moisture from all relics
func get_total_bonus_moisture() -> float:
	var bonus = 0.0
	for relic in owned_relics:
		if relic.effect_type == RelicModel.EffectType.BONUS_MOISTURE:
			bonus += relic.effect_value
	return bonus

## Calculate difficulty scaling reduction from all relics
func get_difficulty_scaling_reduction() -> float:
	var reduction = 0.0
	for relic in owned_relics:
		if relic.effect_type == RelicModel.EffectType.SLOWER_DIFFICULTY:
			reduction += relic.effect_value
	return reduction

## Check if player already owns a relic by name
func has_relic(relic_name: String) -> bool:
	for relic in owned_relics:
		if relic.name == relic_name:
			return true
	return false

## Get list of owned relic names
func get_owned_relic_names() -> Array[String]:
	var names: Array[String] = []
	for relic in owned_relics:
		names.append(relic.name)
	return names
