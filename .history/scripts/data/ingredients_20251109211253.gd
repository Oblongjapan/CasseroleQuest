extends Node

## Central data repository for all available ingredients

const INGREDIENTS = {
	"chicken": {
		"name": "Chicken Breast",
		"water_content": 65,
		"heat_resistance": 55,
		"volatility": 10
	},
	"lettuce": {
		"name": "Lettuce",
		"water_content": 95,
		"heat_resistance": 20,
		"volatility": 5
	},
	"rice": {
		"name": "Rice",
		"water_content": 15,
		"heat_resistance": 70,
		"volatility": 8
	},
	"broccoli": {
		"name": "Broccoli",
		"water_content": 85,
		"heat_resistance": 40,
		"volatility": 12
	},
	"salmon": {
		"name": "Salmon",
		"water_content": 70,
		"heat_resistance": 50,
		"volatility": 8
	},
	"potato": {
		"name": "Potato",
		"water_content": 80,
		"heat_resistance": 60,
		"volatility": 6
	},
	"bread": {
		"name": "Bread",
		"water_content": 25,
		"heat_resistance": 45,
		"volatility": 5
	},
	"spinach": {
		"name": "Spinach",
		"water_content": 90,
		"heat_resistance": 30,
		"volatility": 7
	},
}

## Get a random pool of ingredients for selection
func get_random_ingredient_pool(count: int = 6) -> Array[IngredientModel]:
	var all_ingredients: Array[IngredientModel] = []
	
	# Convert dictionary to IngredientModel instances
	for key in INGREDIENTS.keys():
		var data = INGREDIENTS[key]
		var ingredient = IngredientModel.new(
			data.name,
			data.water_content,
			data.heat_resistance,
			data.volatility
		)
		all_ingredients.append(ingredient)
	
	# Shuffle and return subset
	all_ingredients.shuffle()
	var result: Array[IngredientModel] = []
	for i in range(min(count, all_ingredients.size())):
		result.append(all_ingredients[i])
	return result

## Get all ingredients as IngredientModel array
func get_all_ingredients() -> Array[IngredientModel]:
	return get_random_ingredient_pool(INGREDIENTS.size())
