extends Node

## Singleton storing all malfunction definitions

var malfunctions: Dictionary = {}

func _ready():
	_initialize_malfunctions()

func _initialize_malfunctions():
	# OVERHEAT - 1.5x base drain rate
	malfunctions["overheat"] = MalfunctionModel.new(
		"overheat",
		"OVERHEAT",
		"The microwave is overheating! Base moisture drains 1.5x faster!",
		MalfunctionModel.MalfunctionType.OVERHEAT,
		1.5,
		false,
		"Choose 1 of 3 Random Relics"
	)
	
	# BULB OUT - 0.5x drain rate
	malfunctions["bulb_out"] = MalfunctionModel.new(
		"bulb_out",
		"BULB OUT",
		"The microwave bulb is out! Moisture drains at half speed!",
		MalfunctionModel.MalfunctionType.BULB_OUT,
		0.5,
		false,
		"Access the Super Shop"
	)
	
	# MACROWAVE - 1 second per card
	malfunctions["macrowave"] = MalfunctionModel.new(
		"macrowave",
		"MACROWAVE",
		"Time is warped! Timer has 1 second per ingredient in your fridge!",
		MalfunctionModel.MalfunctionType.MACROWAVE,
		1.0,
		true,
		"Choose 1 of 3 Action Items & Compost up to 1 Ingredient"
	)

## Get a malfunction by ID
func get_malfunction(malfunction_id: String) -> MalfunctionModel:
	if malfunctions.has(malfunction_id):
		return malfunctions[malfunction_id]
	return null

## Get a random malfunction
func get_random_malfunction() -> MalfunctionModel:
	var malfunction_keys = malfunctions.keys()
	if malfunction_keys.size() == 0:
		return null
	var random_key = malfunction_keys[randi() % malfunction_keys.size()]
	return malfunctions[random_key]

## Get all malfunctions as an array
func get_all_malfunctions() -> Array[MalfunctionModel]:
	var result: Array[MalfunctionModel] = []
	for key in malfunctions.keys():
		result.append(malfunctions[key])
	return result
