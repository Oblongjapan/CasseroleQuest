extends Node
class_name RecipeBookManager

## Manages discovered recipes and persists them to disk
## Each user gets their own save file in user:// directory

const SAVE_FILE_PATH = "user://recipe_book.save"

# Dictionary mapping recipe identity (e.g., "Chicken Breast+Rice") to discovery status
var discovered_recipes: Dictionary = {}

signal recipe_discovered(recipe_identity: String, display_name: String)

func _ready():
	load_discoveries()

## Mark a recipe as discovered
func discover_recipe(recipe_identity: String, display_name: String = "") -> void:
	if not discovered_recipes.has(recipe_identity):
		discovered_recipes[recipe_identity] = {
			"identity": recipe_identity,
			"display_name": display_name,
			"discovered_at": Time.get_unix_time_from_system()
		}
		save_discoveries()
		recipe_discovered.emit(recipe_identity, display_name)
		print("[RecipeBookManager] New recipe discovered: %s (%s)" % [display_name, recipe_identity])

## Check if a recipe has been discovered
func is_discovered(recipe_identity: String) -> bool:
	return discovered_recipes.has(recipe_identity)

## Get all discovered recipe identities
func get_discovered_recipes() -> Array[String]:
	var result: Array[String] = []
	for key in discovered_recipes.keys():
		result.append(key)
	return result

## Get discovery count
func get_discovery_count() -> int:
	return discovered_recipes.size()

## Save discoveries to disk
func save_discoveries() -> void:
	var save_data = {
		"version": 1,
		"discovered_recipes": discovered_recipes
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("[RecipeBookManager] Saved %d discoveries to %s" % [discovered_recipes.size(), SAVE_FILE_PATH])
	else:
		push_error("[RecipeBookManager] Failed to save discoveries: " + str(FileAccess.get_open_error()))

## Load discoveries from disk
func load_discoveries() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[RecipeBookManager] No save file found, starting fresh")
		discovered_recipes = {}
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("discovered_recipes"):
				discovered_recipes = save_data["discovered_recipes"]
				print("[RecipeBookManager] Loaded %d discovered recipes" % discovered_recipes.size())
			else:
				push_error("[RecipeBookManager] Save file missing 'discovered_recipes' key")
				discovered_recipes = {}
		else:
			push_error("[RecipeBookManager] Failed to parse save file: " + json.get_error_message())
			discovered_recipes = {}
	else:
		push_error("[RecipeBookManager] Failed to load discoveries: " + str(FileAccess.get_open_error()))
		discovered_recipes = {}

## Clear all discoveries (for testing)
func clear_all_discoveries() -> void:
	discovered_recipes.clear()
	save_discoveries()
	print("[RecipeBookManager] Cleared all discoveries")
