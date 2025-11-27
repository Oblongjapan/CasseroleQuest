extends Node
class_name MoistureManager

## Manages moisture level and drain calculations during cooking

var current_moisture: float = 0.0
var max_moisture: float = 0.0
var bonus_moisture_total: float = 0.0  # Extra starting moisture that does not increase max_moisture
var base_drain_rate: float = 0.0  # Per second
var active_drain_modifiers: Array[Dictionary] = []  # {amount: float, duration: float}

## Initialize moisture system with selected ingredients
func setup(ingredient_1: IngredientModel, ingredient_2 = null, difficulty: float = 1.0, inventory: InventoryManager = null) -> void:
	# Combine ingredients using elegant rules:
	# - Water content: SUM (becomes max moisture)
	# - Heat resistance: MIN (weakest link)
	# - Volatility: MAX (most volatile ingredient dominates)
	var total_water = ingredient_1.water_content + (ingredient_2 != null ? ingredient_2.water_content : 0)
	var combined_heat_resist = ingredient_2 != null ? min(ingredient_1.heat_resistance, ingredient_2.heat_resistance) : ingredient_1.heat_resistance
	var combined_volatility = ingredient_2 != null ? max(ingredient_1.volatility, ingredient_2.volatility) : ingredient_1.volatility

	# Apply bonus starting moisture from relics (this is excess above max, not a new max)
	bonus_moisture_total = 0.0
	if inventory:
		bonus_moisture_total = inventory.get_total_bonus_moisture()

	# Set max moisture to the sum of ingredient water contents; current moisture includes the bonus overflow
	max_moisture = total_water
	# Start each round at 0 + ingredient moisture (do NOT add relic bonus to starting current moisture)
	current_moisture = total_water
	active_drain_modifiers.clear()
	
	# New elegant formula: base_drain (1.0 per round) + volatility - resistance
	# Volatility multiplier: 0.15 (moderate impact)
	# Resistance multiplier: 0.08 (strong protection)
	var base_drain_per_round = 3.0  # This scales with difficulty (rounds passed)
	var drain = (base_drain_per_round * difficulty) + (combined_volatility * 0.15) - (combined_heat_resist * 0.08)
	base_drain_rate = maxf(drain, 0.5)  # Minimum 0.5/sec to ensure game progresses
	
	# Apply synergy modifier only when two real ingredients are chosen
	var synergy_note = ""
	if ingredient_2 == null:
		synergy_note = " (single ingredient)"
	else:
		if ingredient_1.name == ingredient_2.name:
			base_drain_rate *= 1.25
			synergy_note = " (25% penalty - same ingredient)"
		else:
			base_drain_rate *= 0.85
			synergy_note = " (15% synergy bonus - mixed ingredients)"
	
	# Debug output
	print("=== Moisture Setup ===")
	print("Ingredient 1: %s (Water: %d, Resist: %d, Volatility: %d)" % [
		ingredient_1.name, ingredient_1.water_content, ingredient_1.heat_resistance, ingredient_1.volatility])
	print("Ingredient 2: %s (Water: %d, Resist: %d, Volatility: %d)" % [
		ingredient_2.name, ingredient_2.water_content, ingredient_2.heat_resistance, ingredient_2.volatility])
	print("Combined Stats - Water: %d (sum), Resist: %d (min), Volatility: %d (max)" % [
		total_water, combined_heat_resist, combined_volatility])
	print("Base drain rate: %.2f/sec%s" % [base_drain_rate, synergy_note])
	print("Difficulty multiplier: %.2fx (round scaling)" % difficulty)
	
	# Apply relic drain reduction
	if inventory:
		var drain_reduction = inventory.get_total_drain_reduction()
		base_drain_rate *= (1.0 - drain_reduction)
		if drain_reduction > 0:
			print("After relic reduction (%.0f%%): %.2f/sec" % [drain_reduction * 100, base_drain_rate])
	
	print("FINAL drain rate: %.2f/sec" % base_drain_rate)
	print("Max moisture: %.2f | Current (start): %.2f | Bonus (overflow): %.2f" % [max_moisture, current_moisture, bonus_moisture_total])
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
