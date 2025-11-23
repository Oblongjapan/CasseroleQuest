extends Node
class_name ProgressionManager

## Manages game progression: ingredient unlocks, recipe tracking, and microwave power scaling

# Ingredient unlock tiers
var locked_ingredients: Array[String] = ["Spinach", "Salmon"]  # Start locked
var unlocked_new_ingredients: Array[String] = []  # Recently unlocked ingredients for wildcards

# Recipe tracking
var recipes_created: Dictionary = {}  # recipe_id -> count
var unique_recipes_created: int = 0  # Number of unique recipes discovered this run

# Tier tracking
var current_tier: int = 0
var tier_1_unlocked: bool = false
var tier_2_unlocked: bool = false
var tier_3_unlocked: bool = false
var tier_4_unlocked: bool = false

# Microwave power scaling
var microwave_power: float = 1.0  # Starts at 1.0x, scales at milestones

signal ingredient_unlocked(ingredient_name: String)
signal recipe_created(recipe_name: String)
signal power_level_increased(new_power: float)
signal tier_unlocked(tier_number: int)

func _ready():
	print("[ProgressionManager] Initialized")
	# Start at Tier 0 - Tier 1 will unlock when first recipe is created
	current_tier = 0
	print("[ProgressionManager] Starting at Tier 0, Tier 1 will unlock with first recipe")

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
	# Check if this is a new unique recipe
	var is_new_recipe = not recipes_created.has(recipe_id)
	
	if not recipes_created.has(recipe_id):
		recipes_created[recipe_id] = 0
		unique_recipes_created += 1
	
	recipes_created[recipe_id] += 1
	recipe_created.emit(recipe_name)
	
	print("[ProgressionManager] Recipe created: %s (Unique: %d, Is New: %s)" % [recipe_name, unique_recipes_created, is_new_recipe])
	
	# Only check for tier unlocks if this is a new unique recipe
	if is_new_recipe:
		_check_tier_unlocks()
	
	# Check for unlock milestones
	_check_milestones()

## Check if new recipe tiers should be unlocked
func _check_tier_unlocks() -> void:
	var new_tier = RecipesData.get_unlocked_tier(unique_recipes_created)
	
	print("[ProgressionManager] _check_tier_unlocks: unique=%d, current_tier=%d, new_tier=%d" % [unique_recipes_created, current_tier, new_tier])
	
	if new_tier > current_tier:
		# Emit signals for each tier we just unlocked
		for tier in range(current_tier + 1, new_tier + 1):
			print("[ProgressionManager] Processing tier unlock: %d" % tier)
			match tier:
				1:
					tier_1_unlocked = true
					tier_unlocked.emit(1)
					print("[ProgressionManager] 🎉 TIER 1 UNLOCKED: Simple Combos!")
				2:
					tier_2_unlocked = true
					tier_unlocked.emit(2)
					print("[ProgressionManager] 🎉 TIER 2 UNLOCKED: Advanced Combos!")
				3:
					tier_3_unlocked = true
					tier_unlocked.emit(3)
					print("[ProgressionManager] 🎉 TIER 3 UNLOCKED: Expert Recipes!")
				4:
					tier_4_unlocked = true
					tier_unlocked.emit(4)
					print("[ProgressionManager] 🎉 TIER 4 UNLOCKED: Legendary Recipes!")
		
		# Update current tier after processing all unlocks
		current_tier = new_tier

## Get the number of unique recipes discovered this run
func get_unique_recipes_count() -> int:
	return unique_recipes_created

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

## Get the current unlocked tier
func get_current_tier() -> int:
	return current_tier

## Check if a specific tier is unlocked
func is_tier_unlocked(tier: int) -> bool:
	match tier:
		0:
			return true  # Tier 0 always unlocked
		1:
			return tier_1_unlocked
		2:
			return tier_2_unlocked
		3:
			return tier_3_unlocked
		4:
			return tier_4_unlocked
		_:
			return false
