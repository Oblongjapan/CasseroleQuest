extends Node

## Central data repository for all available ingredients

const INGREDIENTS = {
	"chicken": {
		"name": "Chicken Breast",
		"water_content": 50,
		"heat_resistance": 55,
		"volatility": 15
	},
	"lettuce": {
		"name": "Lettuce",
		"water_content": 70,
		"heat_resistance": 20,
		"volatility": 10
	},
	"rice": {
		"name": "Rice",
		"water_content": 12,
		"heat_resistance": 70,
		"volatility": 4
	},
	"broccoli": {
		"name": "Broccoli",
		"water_content": 60,
		"heat_resistance": 40,
		"volatility": 18
	},
	"salmon": {
		"name": "Salmon",
		"water_content": 55,
		"heat_resistance": 50,
		"volatility": 12
	},
	"potato": {
		"name": "Potato",
		"water_content": 60,
		"heat_resistance": 60,
		"volatility": 10
	},
	"bread": {
		"name": "Bread",
		"water_content": 33,
		"heat_resistance": 45,
		"volatility": 8
	},
	"spinach": {
		"name": "Spinach",
		"water_content": 65,
		"heat_resistance": 30,
		"volatility": 12
	},
	"asparagus": {
		"name": "Asparagus",
		"water_content": 60,
		"heat_resistance": 35,
		"volatility": 14
	},
	"tofu": {
		"name": "Tofu",
		"water_content": 55,
		"heat_resistance": 40,
		"volatility": 10
	},
	"carrot": {
		"name": "Carrot",
		"water_content": 65,
		"heat_resistance": 50,
		"volatility": 10
	},
	"water_cup": {
		"name": "Water Cup",
		"water_content": 100,
	},
}

## Get a random pool of ingredients for selection
func get_random_ingredient_pool(count: int = 6) -> Array[IngredientModel]:
	var all_ingredients: Array[IngredientModel] = []
	
	# Convert dictionary to IngredientModel instances (exclude water_cup - it's special)
	for key in INGREDIENTS.keys():
		if key == "water_cup":
			continue  # Skip water cup - only obtained through first shop visit
		
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
