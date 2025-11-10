class_name IngredientModel
extends RefCounted

## Model representing a food ingredient with stats that affect moisture drain

var name: String
var water_content: int  # 0-100, higher = more moisture
var heat_resistance: int  # 0-100, higher = resists drying
var density: int  # 0-100, higher = holds moisture better
var spice_level: int  # 0-100, higher = dries faster

func _init(
	p_name: String = "",
	p_water_content: int = 50,
	p_heat_resistance: int = 50,
	p_density: int = 50,
	p_spice_level: int = 50
):
	name = p_name
	water_content = p_water_content
	heat_resistance = p_heat_resistance
	density = p_density
	spice_level = p_spice_level

## Calculate drain rate per second based on ingredient stats
## Formula: Base drain + (Spice × 0.1) - (Heat Resistance × 0.05) - (Density × 0.03)
## Returns: Moisture drain per second (positive = draining, always positive with this formula)
func calculate_drain_rate() -> float:
	# Base drain ensures moisture always decreases
	var base_drain = 2.0
	# Add spice, subtract resistance factors
	var drain = base_drain + (spice_level * 0.1) - (heat_resistance * 0.05) - (density * 0.03)
	# Ensure drain is always positive (minimum 0.5 per second)
	return maxf(drain, 0.5)

## Get a formatted description of the ingredient stats
func get_stats_description() -> String:
	return "Water: %d | Heat Res: %d | Density: %d | Spice: %d" % [
		water_content, heat_resistance, density, spice_level
	]
