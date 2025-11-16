extends Node
class_name FridgeManager

## Manages the fridge deck system - drawing, discarding, and reshuffling ingredients

var deck: Array[IngredientModel] = []
var discard_pile: Array[IngredientModel] = []
var ingredient_upgrades: Dictionary = {}  # ingredient_name -> {stat_name: upgrade_amount}
var current_hand: Array[IngredientModel] = []  # Track the current hand for malfunction rewards
var wildcard_slots: int = 2  # Number of wildcard slots in the deck
var progression_manager: ProgressionManager = null  # Reference to progression manager

signal deck_shuffled()
signal ingredients_drawn(ingredients: Array[IngredientModel])

## Initialize fridge with starting 10 ingredients
func initialize_starting_deck() -> void:
	deck.clear()
	discard_pile.clear()
	ingredient_upgrades.clear()
	
	# Starting deck composition: 2 rice, 2 bread, 1 chicken breast, 2 broccoli, 2 potatoes, 1 steak, 2 peas (12 cards total)
	# Plus 2 wildcard slots (will be filled if new ingredients are unlocked)
	var starting_composition = {
		"Rice": 2,
		"Bread": 2,
		"Chicken Breast": 1,
		"Broccoli": 2,
		"Potato": 2,
		"Steak": 1,
		"Peas": 2
	}
	
	# Get all ingredients
	var all_ingredients = IngredientsData.get_all_ingredients()
	
	# Build the starting deck
	for ingredient in all_ingredients:
		if starting_composition.has(ingredient.name):
			var count = starting_composition[ingredient.name]
			for i in range(count):
				deck.append(ingredient.duplicate())
	
	# Add wildcards if progression manager is set and has unlocked ingredients
	if progression_manager:
		_add_wildcard_slots()
	
	# Shuffle the deck
	deck.shuffle()
	print("[FridgeManager] Starting deck created with %d cards" % deck.size())
	_emit_deck_changed()

## Add wildcard slots from newly unlocked ingredients
func _add_wildcard_slots() -> void:
	if not progression_manager:
		return
	
	var wildcard_ingredients = progression_manager.get_wildcard_ingredients()
	if wildcard_ingredients.is_empty():
		print("[FridgeManager] No wildcard ingredients available, skipping wildcard slots")
		return
	
	# Get all ingredients to find the wildcard ones
	var all_ingredients = IngredientsData.get_all_ingredients()
	
	# Add up to 2 wildcards from the newly unlocked pool
	var added_wildcards = 0
	for i in range(wildcard_slots):
		if wildcard_ingredients.is_empty():
			break
		
		# Pick a random wildcard ingredient
		var wildcard_name = wildcard_ingredients[randi() % wildcard_ingredients.size()]
		
		# Find the ingredient model
		for ingredient in all_ingredients:
			if ingredient.name == wildcard_name:
				deck.append(ingredient.duplicate())
				added_wildcards += 1
				print("[FridgeManager] Added wildcard slot: %s" % wildcard_name)
				break
	
	print("[FridgeManager] Added %d wildcard slots to deck" % added_wildcards)

## Draw N cards from the top of the deck
func draw_cards(count: int) -> Array[IngredientModel]:
	var drawn: Array[IngredientModel] = []
	
	print("[FridgeManager] draw_cards(%d) called - deck: %d, discard: %d" % [count, deck.size(), discard_pile.size()])
	
	for i in range(count):
		print("[FridgeManager]   Loop iteration %d: deck=%d, discard=%d, drawn so far=%d" % [i, deck.size(), discard_pile.size(), drawn.size()])
		if deck.is_empty():
			print("[FridgeManager]   Deck is empty at iteration %d, attempting reshuffle..." % i)
			_reshuffle_discard_into_deck()
			print("[FridgeManager]   After reshuffle: deck=%d, discard=%d" % [deck.size(), discard_pile.size()])
		
		if not deck.is_empty():
			var card = deck.pop_front()
			# Apply any upgrades to this card
			_apply_upgrades_to_card(card)
			drawn.append(card)
			print("[FridgeManager]   Drew card: %s (deck now: %d)" % [card.name, deck.size()])
		else:
			print("[FridgeManager]   WARNING: Could not draw card %d - deck is empty even after reshuffle attempt!" % i)
	
	ingredients_drawn.emit(drawn)
	print("[FridgeManager] Drew %d cards total, %d remaining in deck, %d in discard" % [drawn.size(), deck.size(), discard_pile.size()])
	_emit_deck_changed()
	
	# Store current hand for malfunction rewards
	current_hand = drawn.duplicate()
	
	return drawn

## Discard cards after use
func discard_cards(cards: Array[IngredientModel]) -> void:
	print("[FridgeManager] discard_cards() called with %d cards - before: deck=%d, discard=%d" % [cards.size(), deck.size(), discard_pile.size()])
	for card in cards:
		discard_pile.append(card)
		print("[FridgeManager]   Discarded: %s" % card.name)
	print("[FridgeManager] Discarded %d cards, discard pile now has %d (deck: %d)" % [cards.size(), discard_pile.size(), deck.size()])
	_emit_deck_changed()

## Reshuffle discard pile back into deck
func _reshuffle_discard_into_deck() -> void:
	if discard_pile.is_empty():
		print("[FridgeManager] WARNING: Both deck and discard pile are empty! Cannot reshuffle.")
		return
	
	print("[FridgeManager] ===== RESHUFFLING =====")
	print("[FridgeManager] Deck empty! Reshuffling discard pile (%d cards) into deck" % discard_pile.size())
	deck = discard_pile.duplicate()
	discard_pile.clear()
	deck.shuffle()
	print("[FridgeManager] Reshuffle complete - deck now: %d, discard now: %d" % [deck.size(), discard_pile.size()])
	print("[FridgeManager] ===== RESHUFFLE DONE =====")
	deck_shuffled.emit()

## Upgrade an ingredient permanently
## ingredient_name: e.g., "Chicken Breast"
## stat_name: "water", "heat", or "spice"
## amount: how much to add (can be negative)
func upgrade_ingredient(ingredient_name: String, stat_name: String, amount: int) -> void:
	if not ingredient_upgrades.has(ingredient_name):
		ingredient_upgrades[ingredient_name] = {}
	
	if not ingredient_upgrades[ingredient_name].has(stat_name):
		ingredient_upgrades[ingredient_name][stat_name] = 0
	
	ingredient_upgrades[ingredient_name][stat_name] += amount
	print("[FridgeManager] Upgraded %s: %s +%d (total: %d)" % [
		ingredient_name, 
		stat_name, 
		amount, 
		ingredient_upgrades[ingredient_name][stat_name]
	])

## Apply generic stat modifications to a specific ingredient (new system)
func upgrade_ingredient_stats(ingredient_name: String, modifications: Dictionary) -> void:
	# Find all instances of this ingredient in deck and discard pile
	var all_cards = deck + discard_pile
	var upgraded_count = 0
	
	for card in all_cards:
		if card.name == ingredient_name:
			# Apply modifications with proper clamping (0-100 range for all stats)
			if modifications.has("water"):
				card.water_content = clampi(card.water_content + modifications.water, 0, 100)
			
			if modifications.has("heat_resistance"):
				card.heat_resistance = clampi(card.heat_resistance + modifications.heat_resistance, 0, 100)
			
			if modifications.has("volatility"):
				# Volatility can't go below 0
				card.volatility = clampi(card.volatility + modifications.volatility, 0, 100)
			
			# Add "Organic" prefix if not already present
			if not card.name.begins_with("Organic "):
				card.name = "Organic " + card.name
			
			upgraded_count += 1
	
	print("[FridgeManager] Upgraded %d copies of %s with: %s" % [upgraded_count, ingredient_name, modifications])
	_emit_deck_changed()


## Apply all accumulated upgrades to a card
func _apply_upgrades_to_card(card: IngredientModel) -> void:
	if not ingredient_upgrades.has(card.name):
		return
	
	var upgrades = ingredient_upgrades[card.name]
	
	if upgrades.has("water"):
		card.water_content += upgrades["water"]
	if upgrades.has("heat"):
		card.heat_resistance += upgrades["heat"]
	if upgrades.has("spice"):
		card.volatility += upgrades["spice"]
	
	# Apply heat bonus from relics (like Plastic Wrap)
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager:
		var heat_bonus = inventory_manager.get_total_heat_bonus()
		if heat_bonus > 0:
			card.heat_resistance = clampi(card.heat_resistance + heat_bonus, 0, 100)
			# Mark the card so we can show the buff on the card
			card.set_meta("has_heat_buff", true)
			card.set_meta("heat_buff_amount", heat_bonus)

## Get upgrade tier for an ingredient (for display)
func get_upgrade_description(ingredient_name: String) -> String:
	if not ingredient_upgrades.has(ingredient_name):
		return ""
	
	var upgrades = ingredient_upgrades[ingredient_name]
	var parts: Array[String] = []
	
	if upgrades.has("water") and upgrades["water"] != 0:
		parts.append("Water %+d" % upgrades["water"])
	if upgrades.has("heat") and upgrades["heat"] != 0:
		parts.append("Heat %+d" % upgrades["heat"])
	if upgrades.has("spice") and upgrades["spice"] != 0:
		parts.append("Spice %+d" % upgrades["spice"])
	
	if parts.is_empty():
		return ""
	return "(" + ", ".join(parts) + ")"

## Add a new ingredient permanently to the deck
func add_ingredient_to_deck(ingredient: IngredientModel) -> void:
	deck.append(ingredient.duplicate())
	print("[FridgeManager] Added %s to deck" % ingredient.name)
	_emit_deck_changed()

## Emit signal for deck tracker UI
func _emit_deck_changed() -> void:
	var total = deck.size() + discard_pile.size()
	EventBus.deck_changed.emit(deck.size(), total)

## Get deck status for debugging
func get_status() -> String:
	return "Deck: %d | Discard: %d" % [deck.size(), discard_pile.size()]

## Get current hand (for malfunction rewards)
func get_current_hand() -> Array[IngredientModel]:
	return current_hand.duplicate()

## Get hand size
func get_hand_size() -> int:
	return current_hand.size()

## Get total deck size (deck + discard pile)
func get_total_deck_size() -> int:
	return deck.size() + discard_pile.size()

## Compost an ingredient (permanently remove from deck)
func compost_ingredient(ingredient: IngredientModel) -> void:
	# Remove from current hand
	var idx = current_hand.find(ingredient)
	if idx != -1:
		current_hand.remove_at(idx)
		print("[FridgeManager] Removed %s from current hand" % ingredient.name)
	
	# Remove one copy from deck or discard pile permanently
	var found = false
	for i in range(deck.size()):
		if deck[i].name == ingredient.name:
			deck.remove_at(i)
			found = true
			print("[FridgeManager] Composted %s from deck" % ingredient.name)
			break
	
	if not found:
		for i in range(discard_pile.size()):
			if discard_pile[i].name == ingredient.name:
				discard_pile.remove_at(i)
				print("[FridgeManager] Composted %s from discard pile" % ingredient.name)
				break
	
	_emit_deck_changed()
