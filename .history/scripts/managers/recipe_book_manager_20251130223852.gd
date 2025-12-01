extends Node
class_name RecipeBookManager

## Manages discovered recipes and persists them to disk
## Each user gets their own save file in user:// directory

const SAVE_FILE_PATH = "user://recipe_book.save"

# Dictionary mapping recipe identity (e.g., "Chicken Breast+Rice") to discovery status
var discovered_recipes: Dictionary = {}

# Track recipes discovered during current game session (for end-of-game reveal)
var session_discoveries: Array[Dictionary] = []

signal recipe_discovered(recipe_identity: String, display_name: String)

func _ready():
	load_discoveries()

## Mark a recipe as discovered
func discover_recipe(recipe_identity: String, display_name: String = "") -> void:
	print("[RecipeBookManager] discover_recipe() called for: %s (%s)" % [recipe_identity, display_name])
	print("[RecipeBookManager] Already discovered? %s" % discovered_recipes.has(recipe_identity))
	
	if not discovered_recipes.has(recipe_identity):
		var discovery_data = {
			"identity": recipe_identity,
			"display_name": display_name,
			"discovered_at": Time.get_unix_time_from_system()
		}
		discovered_recipes[recipe_identity] = discovery_data
		session_discoveries.append(discovery_data)
		print("[RecipeBookManager] Added to dictionary. Total discoveries: %d" % discovered_recipes.size())
		save_discoveries()
		recipe_discovered.emit(recipe_identity, display_name)
		print("[RecipeBookManager] New recipe discovered: %s (%s)" % [display_name, recipe_identity])
	else:
		print("[RecipeBookManager] Recipe already discovered, skipping")

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

## Get recipes discovered this session
func get_session_discoveries() -> Array[Dictionary]:
	return session_discoveries

## Clear session discoveries (call at start of new game)
func clear_session_discoveries() -> void:
	session_discoveries.clear()
	print("[RecipeBookManager] Cleared session discoveries")

## Clear all discoveries (for testing)
func clear_all_discoveries() -> void:
	discovered_recipes.clear()
	save_discoveries()
	print("[RecipeBookManager] Cleared all discoveries")
