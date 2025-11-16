extends Node
class_name ProgressionManager

## Manages game progression: ingredient unlocks, recipe tracking, and microwave power scaling

# Ingredient unlock tiers
var locked_ingredients: Array[String] = ["Spinach", "Salmon"]  # Start locked
var unlocked_new_ingredients: Array[String] = []  # Recently unlocked ingredients for wildcards

# Recipe tracking
var recipes_created: Dictionary = {}  # recipe_id -> count
var total_recipes_created: int = 0

# Microwave power scaling
var microwave_power: float = 1.0  # Starts at 1.0x, scales at milestones

signal ingredient_unlocked(ingredient_name: String)
signal recipe_created(recipe_name: String)
signal power_level_increased(new_power: float)

func _ready():
	print("[ProgressionManager] Initialized")

## Check if an ingredient is locked
func is_ingredient_locked(ingredient_name: String) -> bool:
	return locked_ingredients.has(ingredient_name)

## Unlock an ingredient (add to available pool)
func unlock_ingredient(ingredient_name: String) -> void:
	if locked_ingredients.has(ingredient_name):
		locked_ingredients.erase(ingredient_name)
		unlocked_new_ingredients.append(ingredient_name)
		ingredient_unlocked.emit(ingredient_name)
		print("[ProgressionManager] Unlocked ingredient: %s" % ingredient_name)

## Get newly unlocked ingredients for wildcard slots
func get_wildcard_ingredients() -> Array[String]:
	return unlocked_new_ingredients.duplicate()

## Clear wildcard pool (after they're integrated into base pool)
func clear_wildcard_pool() -> void:
	unlocked_new_ingredients.clear()

## Track recipe creation
func register_recipe(recipe_id: String, recipe_name: String) -> void:
	if not recipes_created.has(recipe_id):
		recipes_created[recipe_id] = 0
	
	recipes_created[recipe_id] += 1
	total_recipes_created += 1
	recipe_created.emit(recipe_name)
	
	print("[ProgressionManager] Recipe created: %s (Total: %d)" % [recipe_name, total_recipes_created])
	
	# Check for unlock milestones
	_check_milestones()

## Check progression milestones and unlock rewards
func _check_milestones() -> void:
	# Milestone 1: 5 recipes -> Unlock Spinach & Salmon, Power 1.3x
	if total_recipes_created >= 5 and microwave_power < 1.3:
		microwave_power = 1.3
		unlock_ingredient("Spinach")
		unlock_ingredient("Salmon")
		power_level_increased.emit(microwave_power)
		print("[ProgressionManager] MILESTONE: 5 recipes! Power -> 1.3x, Unlocked Spinach & Salmon")
	
	# Milestone 2: 10 recipes -> Power 1.6x
	elif total_recipes_created >= 10 and microwave_power < 1.6:
		microwave_power = 1.6
		# TODO: Unlock next tier of ingredients here
		power_level_increased.emit(microwave_power)
		print("[ProgressionManager] MILESTONE: 10 recipes! Power -> 1.6x")
	
	# Milestone 3: 15 recipes -> Power 2.0x
	elif total_recipes_created >= 15 and microwave_power < 2.0:
		microwave_power = 2.0
		power_level_increased.emit(microwave_power)
		print("[ProgressionManager] MILESTONE: 15 recipes! Power -> 2.0x")

## Get current microwave power multiplier
func get_microwave_power() -> float:
	return microwave_power

## Get total recipes created count
func get_total_recipes() -> int:
	return total_recipes_created

## Get recipe count for specific recipe
func get_recipe_count(recipe_id: String) -> int:
	return recipes_created.get(recipe_id, 0)

## Check if a specific recipe has been created
func has_created_recipe(recipe_id: String) -> bool:
	return recipes_created.has(recipe_id)
