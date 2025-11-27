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
var pending_upgrade: Dictionary = {}  # Store upgrade until card is selected

signal shop_refreshed(items: Array)
signal item_purchased(item: Dictionary)
signal upgrade_needs_target(upgrade_data: Dictionary)  # Signal shop UI to open card selector

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

## Add ingredient upgrade options (now generic stat modifications)
func _add_ingredient_upgrades(count: int = 3) -> void:
	var upgrade_pool: Array[Dictionary] = []
	
	# Common upgrades (+1 to +5, -1 to -5)
	var common_stats = ["water", "heat_resistance", "volatility"]
	for stat in common_stats:
		for amount in range(1, 6):
			var sign = "+" if amount > 0 else ""
			upgrade_pool.append({
				"type": ShopItemType.INGREDIENT_UPGRADE,
				"name": "%s%d %s" % [sign, amount, _stat_display_name(stat)],
				"description": "Upgrade any card: %s%d %s" % [sign, amount, _stat_display_name(stat)],
				"cost": _calculate_upgrade_cost(amount),
				"rarity": "common",
				stat: amount
			})
			# Negative versions (good for volatility reduction)
			if stat == "volatility":
				upgrade_pool.append({
					"type": ShopItemType.INGREDIENT_UPGRADE,
					"name": "-%d %s" % [amount, _stat_display_name(stat)],
					"description": "Upgrade any card: -%d %s" % [amount, _stat_display_name(stat)],
					"cost": _calculate_upgrade_cost(amount) + 10,
					"rarity": "common",
					stat: -amount
				})
	
	# Uncommon upgrades (+6 to +10, -6 to -10)
	for stat in common_stats:
		for amount in range(6, 11):
			var sign = "+" if amount > 0 else ""
			upgrade_pool.append({
				"type": ShopItemType.INGREDIENT_UPGRADE,
				"name": "%s%d %s" % [sign, amount, _stat_display_name(stat)],
				"description": "Upgrade any card: %s%d %s" % [sign, amount, _stat_display_name(stat)],
				"cost": _calculate_upgrade_cost(amount),
				"rarity": "uncommon",
				stat: amount
			})
			if stat == "volatility" or stat == "cook_time":
				upgrade_pool.append({
					"type": ShopItemType.INGREDIENT_UPGRADE,
					"name": "-%d %s" % [amount, _stat_display_name(stat)],
					"description": "Upgrade any card: -%d %s" % [amount, _stat_display_name(stat)],
					"cost": _calculate_upgrade_cost(amount) + 10,
					"rarity": "uncommon",
					stat: -amount
				})
	
	# Rare upgrades (+11 to +15, -11 to -15)
	for stat in common_stats:
		for amount in range(11, 16):
			var sign = "+" if amount > 0 else ""
			upgrade_pool.append({
				"type": ShopItemType.INGREDIENT_UPGRADE,
				"name": "%s%d %s" % [sign, amount, _stat_display_name(stat)],
				"description": "Upgrade any card: %s%d %s" % [sign, amount, _stat_display_name(stat)],
				"cost": _calculate_upgrade_cost(amount),
				"rarity": "rare",
				stat: amount
			})
			if stat == "volatility" or stat == "cook_time":
				upgrade_pool.append({
					"type": ShopItemType.INGREDIENT_UPGRADE,
					"name": "-%d %s" % [amount, _stat_display_name(stat)],
					"description": "Upgrade any card: -%d %s" % [amount, _stat_display_name(stat)],
					"cost": _calculate_upgrade_cost(amount) + 15,
					"rarity": "rare",
					stat: -amount
				})
	
	# Epic upgrades (+16 to +20, -16 to -20)
	for stat in common_stats:
		for amount in range(16, 21):
			var sign = "+" if amount > 0 else ""
			upgrade_pool.append({
				"type": ShopItemType.INGREDIENT_UPGRADE,
				"name": "%s%d %s" % [sign, amount, _stat_display_name(stat)],
				"description": "Upgrade any card: %s%d %s" % [sign, amount, _stat_display_name(stat)],
				"cost": _calculate_upgrade_cost(amount),
				"rarity": "epic",
				stat: amount
			})
			if stat == "volatility" or stat == "cook_time":
				upgrade_pool.append({
					"type": ShopItemType.INGREDIENT_UPGRADE,
					"name": "-%d %s" % [amount, _stat_display_name(stat)],
					"description": "Upgrade any card: -%d %s" % [amount, _stat_display_name(stat)],
					"cost": _calculate_upgrade_cost(amount) + 20,
					"rarity": "epic",
					stat: -amount
				})
	
	# Select upgrades based on rarity weights
	for i in range(count):
		var selected = _pick_weighted_upgrade(upgrade_pool)
		if selected:
			current_shop_items.append(selected)

## Calculate cost based on upgrade magnitude
func _calculate_upgrade_cost(amount: int) -> int:
	var base_cost = 30
	return base_cost + (abs(amount) * 5)

## Pick upgrade based on rarity weights
func _pick_weighted_upgrade(pool: Array[Dictionary]) -> Dictionary:
	# Rarity weights: common 60%, uncommon 25%, rare 12%, epic 3%
	var roll = randf()
	var target_rarity = ""
	
	if roll < 0.60:
		target_rarity = "common"
	elif roll < 0.85:
		target_rarity = "uncommon"
	elif roll < 0.97:
		target_rarity = "rare"
	else:
		target_rarity = "epic"
	
	# Filter pool by rarity
	var filtered = pool.filter(func(item): return item.get("rarity", "common") == target_rarity)
	
	if filtered.is_empty():
		filtered = pool  # Fallback to full pool
	
	filtered.shuffle()
	return filtered[0] if filtered.size() > 0 else {}

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
	
	# Show 1 random relic (only in rounds 3+)
	relics.shuffle()
	if relics.size() > 0:
		var relic = relics[0].duplicate()
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
			# Store upgrade and signal UI to open card selector
			pending_upgrade = item.duplicate()
			upgrade_needs_target.emit(pending_upgrade)
			print("[ShopManager] Purchased upgrade: %s - waiting for card selection" % item.name)
		
		ShopItemType.RELIC:
			_apply_relic(item)
		
		ShopItemType.NEW_INGREDIENT:
			fridge_manager.add_ingredient_to_deck(item.ingredient)
		
		ShopItemType.ACTIVE_ITEM:
			# Add to inventory (simplified for now)
			print("[ShopManager] Active item purchase not fully implemented yet")
	
	item_purchased.emit(item)
	EventBus.item_purchased.emit(item)
	return true

## Apply upgrade to a specific card (called after card selection)
func apply_upgrade_to_card(ingredient_name: String) -> void:
	if pending_upgrade.is_empty():
		print("[ShopManager] Error: No pending upgrade")
		return
	
	# Extract stat modifications from pending upgrade
	var modifications: Dictionary = {}
	for key in ["water", "oil", "volatility", "cook_time"]:
		if pending_upgrade.has(key):
			modifications[key] = pending_upgrade[key]
	
	if modifications.is_empty():
		print("[ShopManager] Error: No valid stat modifications in upgrade")
		return
	
	# Apply upgrade via fridge manager
	fridge_manager.upgrade_ingredient_stats(ingredient_name, modifications)
	print("[ShopManager] Applied upgrade to %s: %s" % [ingredient_name, modifications])
	
	# Clear pending upgrade
	pending_upgrade.clear()


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
		"oil": return "Oil"
		"volatility": return "Vol"
		"cook_time": return "Time"
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
