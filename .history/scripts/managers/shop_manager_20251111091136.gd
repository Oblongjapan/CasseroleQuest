extends Node
class_name ShopManager

## Manages shop inventory and purchases

enum ShopItemType {
	INGREDIENT_UPGRADE,
	RELIC,
	NEW_INGREDIENT,
	ACTIVE_ITEM
}

var current_shop_items: Array[Dictionary] = []
var fridge_manager: FridgeManager
var currency_manager: CurrencyManager
var inventory_manager: InventoryManager

signal shop_refreshed(items: Array)
signal item_purchased(item: Dictionary)

## Initialize shop with managers
func setup(fridge: FridgeManager, currency: CurrencyManager, inventory: InventoryManager) -> void:
	fridge_manager = fridge
	currency_manager = currency
	inventory_manager = inventory

## Generate shop inventory for the current round
func refresh_shop(round_number: int) -> void:
	current_shop_items.clear()
	
	# Early rounds (1-2): Only ingredient upgrades and new ingredients (4 total)
	# Later rounds (3+): Mix of upgrades, relics, and active items (4 total)
	
	if round_number < 3:
		# Early rounds: 3 ingredient upgrades + 1 new ingredient
		_add_ingredient_upgrades(3)
		_add_new_ingredient()
	else:
		# Later rounds: 2 upgrades + 1 relic + 1 new ingredient
		_add_ingredient_upgrades(2)
		_add_relics(round_number)
		_add_new_ingredient()
	
	shop_refreshed.emit(current_shop_items)
	EventBus.shop_refreshed.emit(current_shop_items)

## Add ingredient upgrade options
func _add_ingredient_upgrades() -> void:
	# Get all possible ingredient names from the game
	var ingredient_names = ["Chicken Breast", "Lettuce", "Rice", "Broccoli", "Salmon", "Potato", "Bread", "Spinach"]
	
	# Shuffle and pick 4 random upgrades
	ingredient_names.shuffle()
	var stats = ["water", "heat", "spice"]
	
	for i in range(min(4, ingredient_names.size())):
		var ingredient_name = ingredient_names[i]
		var stat = stats[randi() % stats.size()]
		var amount = 20 if stat != "spice" else -20  # Reduce spice is good
		
		var cost = 40 if stat == "water" else 45 if stat == "heat" else 60
		
		current_shop_items.append({
			"type": ShopItemType.INGREDIENT_UPGRADE,
			"name": "%s +%d %s" % [ingredient_name, abs(amount), _stat_display_name(stat)],
			"description": _get_upgrade_description(stat, amount),
			"cost": cost,
			"ingredient_name": ingredient_name,
			"stat": stat,
			"amount": amount
		})

## Add relic options
func _add_relics(round_number: int) -> void:
	var relics = [
		{
			"name": "Plastic Wrap",
			"description": "All ingredients +10 Heat Resistance",
			"cost": 80,
			"effect_type": "heat_bonus",
			"effect_value": 10
		},
		{
			"name": "Damp Towel",
			"description": "Start each round with +15 max moisture",
			"cost": 75,
			"effect_type": "bonus_moisture",
			"effect_value": 15
		},
		{
			"name": "Aluminum Foil",
			"description": "Spice drain multiplier reduced by 25%",
			"cost": 90,
			"effect_type": "spice_reduction",
			"effect_value": 0.25
		}
	]
	
	# Show 2 random relics
	relics.shuffle()
	for i in range(min(2, relics.size())):
		var relic = relics[i].duplicate()
		relic["type"] = ShopItemType.RELIC
		current_shop_items.append(relic)

## Add new ingredient option
func _add_new_ingredient() -> void:
	var all_ingredients = IngredientsData.get_all_ingredients()
	all_ingredients.shuffle()
	
	if not all_ingredients.is_empty():
		var ingredient = all_ingredients[0]
		current_shop_items.append({
			"type": ShopItemType.NEW_INGREDIENT,
			"name": "Add %s to Fridge" % ingredient.name,
			"description": "Permanently add to your deck",
			"cost": 55,
			"ingredient": ingredient
		})

## Add active item upgrades
func _add_active_items() -> void:
	current_shop_items.append({
		"type": ShopItemType.ACTIVE_ITEM,
		"name": "Premium Cover",
		"description": "Reduce drain by 50% for 6 seconds (8s cooldown)",
		"cost": 50,
		"item_data": {
			"name": "Premium Cover",
			"cooldown": 8.0,
			"effect_duration": 6.0,
			"effect_multiplier": 0.5
		}
	})

## Purchase an item
func purchase_item(item: Dictionary) -> bool:
	if not currency_manager.can_afford(item.cost):
		print("[ShopManager] Cannot afford %s (cost: %d)" % [item.name, item.cost])
		return false
	
	# Deduct currency
	if not currency_manager.spend_currency(item.cost):
		return false
	
	# Apply the purchase
	match item.type:
		ShopItemType.INGREDIENT_UPGRADE:
			fridge_manager.upgrade_ingredient(item.ingredient_name, item.stat, item.amount)
		
		ShopItemType.RELIC:
			_apply_relic(item)
		
		ShopItemType.NEW_INGREDIENT:
			fridge_manager.add_ingredient_to_deck(item.ingredient)
		
		ShopItemType.ACTIVE_ITEM:
			# Add to inventory (simplified for now)
			print("[ShopManager] Active item purchase not fully implemented yet")
	
	item_purchased.emit(item)
	EventBus.item_purchased.emit(item)
	print("[ShopManager] Purchased: %s" % item.name)
	return true

## Apply relic effect
func _apply_relic(relic: Dictionary) -> void:
	# For now, create a simple RelicModel and add to inventory
	var relic_model = RelicModel.new()
	relic_model.name = relic.name
	relic_model.description = relic.description
	
	# Map effect types
	match relic.effect_type:
		"heat_bonus":
			relic_model.effect_type = RelicModel.EffectType.BONUS_STAT
		"bonus_moisture":
			relic_model.effect_type = RelicModel.EffectType.BONUS_MOISTURE
		"spice_reduction":
			relic_model.effect_type = RelicModel.EffectType.REDUCE_DRAIN
	
	relic_model.effect_value = relic.effect_value
	inventory_manager.add_relic(relic_model)

## Helper functions
func _stat_display_name(stat: String) -> String:
	match stat:
		"water": return "Water"
		"heat": return "Heat Resistance"
		"spice": return "Spice"
		_: return stat

func _get_upgrade_description(stat: String, amount: int) -> String:
	match stat:
		"water": return "Increase water content"
		"heat": return "Better heat tolerance"
		"spice": return "Reduce volatility" if amount < 0 else "Increase spice"
		_: return "Upgrade ingredient"

## Get current shop items
func get_shop_items() -> Array[Dictionary]:
	return current_shop_items
