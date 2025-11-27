extends Node
class_name MoistureManager

## Manages moisture level and drain calculations during cooking

var current_moisture: float = 0.0
var max_moisture: float = 0.0
var bonus_moisture_total: float = 0.0  # Extra starting moisture that does not increase max_moisture
var base_drain_rate: float = 0.0  # Per second
var active_drain_modifiers: Array[Dictionary] = []  # {amount: float, duration: float}

## Initialize moisture system with selected ingredients
func setup(ingredient_1, ingredient_2 = null, difficulty = 1.0, inventory = null) -> void:
	# Use formula from game flow document:
	# - Starting moisture = SUM of water content
	# - Worst spice = MAX of volatility
	# - Best heat = MAX of heat resistance
	# - base_drain_rate = 5.0 + (worst_spice × 0.3) - (best_heat × 0.25)
	
	var total_water = ingredient_1.water_content
	if ingredient_2 != null:
		total_water += ingredient_2.water_content

	var worst_spice = ingredient_1.volatility
	if ingredient_2 != null:
		worst_spice = max(ingredient_1.volatility, ingredient_2.volatility)

	var best_heat = ingredient_1.heat_resistance
	if ingredient_2 != null:
		best_heat = max(ingredient_1.heat_resistance, ingredient_2.heat_resistance)

	# Apply bonus starting moisture from relics
	bonus_moisture_total = 0.0
	if inventory:
		bonus_moisture_total = inventory.get_total_bonus_moisture()

	# Set max moisture and current moisture
	max_moisture = total_water + bonus_moisture_total
	current_moisture = max_moisture
	active_drain_modifiers.clear()
	
	# Calculate drain rate using formula from document
	var drain = 5.0 + (worst_spice * 0.3) - (best_heat * 0.25)
	base_drain_rate = max(0.1, drain)  # Clamp to minimum
	
	# Debug output
	print("=== Moisture Setup ===")
	print("Ingredient 1: %s (Water: %d, Heat: %d, Spice: %d)" % [
		ingredient_1.name, ingredient_1.water_content, ingredient_1.heat_resistance, ingredient_1.volatility])
	if ingredient_2 != null:
		print("Ingredient 2: %s (Water: %d, Heat: %d, Spice: %d)" % [
			ingredient_2.name, ingredient_2.water_content, ingredient_2.heat_resistance, ingredient_2.volatility])
	else:
		print("Ingredient 2: None")
	print("Total Water: %d | Worst Spice: %d | Best Heat: %d" % [
		total_water, worst_spice, best_heat])
	print("Base drain rate: %.2f/sec" % base_drain_rate)
	
	# Apply relic drain reduction
	if inventory:
		var drain_reduction = inventory.get_total_drain_reduction()
		base_drain_rate *= (1.0 - drain_reduction)
		if drain_reduction > 0:
			print("After relic reduction (%.0f%%): %.2f/sec" % [drain_reduction * 100, base_drain_rate])
	
	print("FINAL drain rate: %.2f/sec" % base_drain_rate)
	print("Max moisture: %.2f | Starting moisture: %.2f | Bonus: %.2f" % [max_moisture, current_moisture, bonus_moisture_total])
	print("==================")

	EventBus.moisture_changed.emit(current_moisture, max_moisture, bonus_moisture_total)

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
	# Allow current moisture to fall from the bonus overflow down to 0; cap upper bound at max + bonus
	current_moisture = clampf(current_moisture, 0.0, max_moisture + bonus_moisture_total)
	
	EventBus.moisture_changed.emit(current_moisture, max_moisture, bonus_moisture_total)

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
	current_moisture = clampf(current_moisture, 0.0, max_moisture + bonus_moisture_total)
	EventBus.moisture_changed.emit(current_moisture)

## Check if moisture has reached zero (failure condition)
func check_failure() -> bool:
	return current_moisture <= 0.0
