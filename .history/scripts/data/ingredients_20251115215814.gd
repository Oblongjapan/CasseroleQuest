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
		"water_content": 30,
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
	"steak": {
		"name": "Steak",
		"water_content": 55,
		"heat_resistance": 60,
		"volatility": 20
	},
	"peas": {
		"name": "Peas",
		"water_content": 70,
		"heat_resistance": 40,
		"volatility": 10
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

## Save a custom deck composition to a file
func save_custom_deck(deck_name: String, composition: Dictionary) -> bool:
	var save_path = "user://custom_decks/%s.json" % deck_name
	
	# Ensure directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("custom_decks"):
		dir.make_dir("custom_decks")
	
	# Convert composition to JSON
	var save_data = {
		"deck_name": deck_name,
		"composition": composition,
		"created_at": Time.get_datetime_string_from_system()
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	
	# Write to file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("[IngredientsData] ERROR: Could not open file for writing: %s" % save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("[IngredientsData] Saved deck '%s' to %s" % [deck_name, save_path])
	return true

## Load a custom deck composition from a file
func load_custom_deck(deck_name: String) -> Dictionary:
	var save_path = "user://custom_decks/%s.json" % deck_name
	
	# Check if file exists
	if not FileAccess.file_exists(save_path):
		print("[IngredientsData] ERROR: Deck file not found: %s" % save_path)
		return {}
	
	# Read file
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("[IngredientsData] ERROR: Could not open file for reading: %s" % save_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("[IngredientsData] ERROR: Failed to parse JSON from %s" % save_path)
		return {}
	
	var save_data = json.get_data()
	if not save_data.has("composition"):
		print("[IngredientsData] ERROR: Invalid save data format in %s" % save_path)
		return {}
	
	print("[IngredientsData] Loaded deck '%s' from %s" % [deck_name, save_path])
	return save_data["composition"]

## Get a list of all saved deck names
func get_saved_deck_names() -> Array[String]:
	var deck_names: Array[String] = []
	
	var dir = DirAccess.open("user://custom_decks")
	if dir == null:
		print("[IngredientsData] Custom decks directory does not exist")
		return deck_names
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var deck_name = file_name.trim_suffix(".json")
			deck_names.append(deck_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return deck_names

