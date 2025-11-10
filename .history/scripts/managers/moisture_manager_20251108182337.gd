extends Node
class_name MoistureManager

## Manages moisture level and drain calculations during cooking

var current_moisture: float = 100.0
var max_moisture: float = 100.0
var base_drain_rate: float = 0.0  # Per second
var active_drain_modifiers: Array[Dictionary] = []  # {amount: float, duration: float}

## Initialize moisture system with selected ingredients
func setup(ingredient_1: IngredientModel, ingredient_2: IngredientModel, difficulty: float = 1.0, inventory: InventoryManager = null) -> void:
	# Apply bonus starting moisture from relics
	var bonus_moisture = 0.0
	if inventory:
		bonus_moisture = inventory.get_total_bonus_moisture()
	
	current_moisture = max_moisture + bonus_moisture
	max_moisture = max_moisture + bonus_moisture
	active_drain_modifiers.clear()
	
	# Calculate combined moisture stats from both ingredients
	# Both ingredients are fully added together (more food = more moisture capacity)
	var total_water = ingredient_1.water_content + ingredient_2.water_content
	var total_heat_resist = ingredient_1.heat_resistance + ingredient_2.heat_resistance
	var total_density = ingredient_1.density + ingredient_2.density
	var total_spice = ingredient_1.spice_level + ingredient_2.spice_level
	
	# Calculate drain using combined stats
	# Spice has increased impact with multiplier (0.15 instead of 0.25 to balance for 2x values)
	var base_drain = 5.0
	var drain = base_drain + (total_spice * 0.15) - (total_heat_resist * 0.01) - (total_density * 0.008)
	base_drain_rate = maxf(drain, 3.0)
	
	# Bonus: using same ingredient twice gives 5% drain reduction (mastery)
	var mastery_bonus = ""
	if ingredient_1 == ingredient_2:
		base_drain_rate *= 0.95
		mastery_bonus = " (5% mastery bonus)"
	
	# Debug output
	print("=== Moisture Setup ===")
	print("Ingredient 1: %s (Water: %d, Resist: %d, Density: %d, Spice: %d)" % [
		ingredient_1.name, ingredient_1.water_content, ingredient_1.heat_resistance, 
		ingredient_1.density, ingredient_1.spice_level])
	print("Ingredient 2: %s (Water: %d, Resist: %d, Density: %d, Spice: %d)" % [
		ingredient_2.name, ingredient_2.water_content, ingredient_2.heat_resistance, 
		ingredient_2.density, ingredient_2.spice_level])
	print("Total Stats - Water: %d, Resist: %d, Density: %d, Spice: %d" % [
		total_water, total_heat_resist, total_density, total_spice])
	print("Base drain rate: %.2f/sec%s" % [base_drain_rate, mastery_bonus])
	
	# Apply difficulty scaling to drain rate
	base_drain_rate *= difficulty
	
	print("After difficulty (%.2fx): %.2f/sec" % [difficulty, base_drain_rate])
	
	# Apply relic drain reduction
	if inventory:
		var drain_reduction = inventory.get_total_drain_reduction()
		base_drain_rate *= (1.0 - drain_reduction)
		if drain_reduction > 0:
			print("After relic reduction (%.0f%%): %.2f/sec" % [drain_reduction * 100, base_drain_rate])
	
	print("FINAL drain rate: %.2f/sec" % base_drain_rate)
	print("==================")
	
	EventBus.moisture_changed.emit(current_moisture)

## Update moisture every frame based on drain rate and active modifiers
func update_moisture(delta: float) -> void:
	var total_drain = base_drain_rate
	
	# Apply temporary drain modifiers
	var expired_modifiers: Array[int] = []
	for i in range(active_drain_modifiers.size()):
		var modifier = active_drain_modifiers[i]
		total_drain += modifier.amount
		modifier.duration -= delta
		
		if modifier.duration <= 0:
			expired_modifiers.append(i)
	
	# Remove expired modifiers (iterate backwards to avoid index issues)
	for i in range(expired_modifiers.size() - 1, -1, -1):
		active_drain_modifiers.remove_at(expired_modifiers[i])
	
	# Apply drain to moisture
	current_moisture -= total_drain * delta
	current_moisture = clampf(current_moisture, 0.0, max_moisture)
	
	EventBus.moisture_changed.emit(current_moisture)

## Add a temporary drain modifier (e.g., from Cover or Blow items)
## Amount is negative to reduce drain, positive to increase
func apply_drain_modifier(amount: float, duration: float) -> void:
	active_drain_modifiers.append({
		"amount": amount,
		"duration": duration
	})

## Restore moisture (e.g., from Stir item)
func restore_moisture(amount: float) -> void:
	current_moisture += amount
	current_moisture = clampf(current_moisture, 0.0, max_moisture)
	EventBus.moisture_changed.emit(current_moisture)

## Check if moisture has reached zero (failure condition)
func check_failure() -> bool:
	return current_moisture <= 0.0
