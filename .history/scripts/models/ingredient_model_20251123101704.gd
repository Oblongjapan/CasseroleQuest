class_name IngredientModel
extends RefCounted

## Model representing a food ingredient with stats that affect moisture drain

var name: String
var water_content: int  # 0-100, higher = more moisture
var heat_resistance: int  # 0-100, higher = resists drying
var volatility: int  # 0-100, higher = loses moisture faster

func _init(
	p_name: String = "",
	p_water_content: int = 50,
	p_heat_resistance: int = 50,
	p_volatility: int = 50
):
	name = p_name
	water_content = p_water_content
	heat_resistance = p_heat_resistance
	volatility = p_volatility

## Get a formatted description of the ingredient stats
func get_stats_description() -> String:
	# Use commas and plain labels (no symbols) per UI requirement
	return "Water: %d, Resist: %d, Volatility: %d" % [
		water_content, heat_resistance, volatility
	]

## Create a duplicate of this ingredient
func duplicate() -> IngredientModel:
	var copy = IngredientModel.new()
	copy.name = name
	copy.water_content = water_content
	copy.heat_resistance = heat_resistance
	copy.volatility = volatility
	
	# Copy all metadata
	for key in get_meta_list():
		copy.set_meta(key, get_meta(key))
	
	return copy
