extends Node
class_name FridgeManager

## Manages the fridge deck system - drawing, discarding, and reshuffling ingredients

var deck: Array[IngredientModel] = []
var discard_pile: Array[IngredientModel] = []
var ingredient_upgrades: Dictionary = {}  # ingredient_name -> {stat_name: upgrade_amount}

signal deck_shuffled()
signal ingredients_drawn(ingredients: Array[IngredientModel])

## Initialize fridge with starting 10 ingredients
func initialize_starting_deck() -> void:
	deck.clear()
	discard_pile.clear()
	ingredient_upgrades.clear()
	
	# Get all 8 base ingredients
	var all_ingredients = IngredientsData.get_all_ingredients()
	
	# Add 10 cards (some duplicates)
	# Using first 8 unique, then add 2 random duplicates
	for i in range(min(8, all_ingredients.size())):
		deck.append(all_ingredients[i].duplicate())
	
	# Add 2 more random cards from the pool
	all_ingredients.shuffle()
	for i in range(2):
		if i < all_ingredients.size():
			deck.append(all_ingredients[i].duplicate())
	
	# Shuffle the deck
	deck.shuffle()
	print("[FridgeManager] Initialized deck with %d cards" % deck.size())
	_emit_deck_changed()

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
			# Apply modifications with proper clamping
			if modifications.has("water"):
				card.water_content = clampi(card.water_content + modifications.water, 0, 20)
			
			if modifications.has("oil"):
				card.oil_content = clampi(card.oil_content + modifications.oil, 0, 20)
			
			if modifications.has("volatility"):
				# Volatility can't go below 0
				card.volatility = clampi(card.volatility + modifications.volatility, 0, 20)
			
			if modifications.has("cook_time"):
				# Cook time minimum is 1 second
				card.cook_time = maxi(card.cook_time + modifications.cook_time, 1)
			
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
