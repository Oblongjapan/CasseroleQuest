class_name MalfunctionManager
extends Node

## Manages malfunction scheduling and tracking

signal malfunction_triggered(malfunction: MalfunctionModel)
signal malfunction_completed(malfunction: MalfunctionModel, success: bool)

var rounds_until_next_malfunction: int = 0
var current_malfunction: MalfunctionModel = null
var is_malfunction_active: bool = false
var malfunction_history: Array[String] = []

func _ready():
	# Schedule first malfunction for round 4-6
	schedule_first_malfunction()

## Schedule the first malfunction (rounds 4-6)
func schedule_first_malfunction():
	rounds_until_next_malfunction = randi_range(4, 6)
	print("[MalfunctionManager] First malfunction scheduled in %d rounds" % rounds_until_next_malfunction)

## Schedule the next malfunction (5-8 rounds after current)
func schedule_next_malfunction():
	rounds_until_next_malfunction = randi_range(5, 8)
	print("[MalfunctionManager] Next malfunction scheduled in %d rounds" % rounds_until_next_malfunction)

## Check if a malfunction should trigger this round
func should_trigger_malfunction() -> bool:
	if is_malfunction_active:
		return false
	
	rounds_until_next_malfunction -= 1
	
	if rounds_until_next_malfunction <= 0:
		return true
	
	return false

## Trigger a random malfunction
func trigger_malfunction() -> MalfunctionModel:
	current_malfunction = MalfunctionsData.get_random_malfunction()
	is_malfunction_active = true
	malfunction_history.append(current_malfunction.id)
	
	print("[MalfunctionManager] Malfunction triggered: %s" % current_malfunction.name)
	malfunction_triggered.emit(current_malfunction)
	
	return current_malfunction

## Get the current active malfunction
func get_current_malfunction() -> MalfunctionModel:
	return current_malfunction

## Complete the current malfunction
func complete_malfunction(success: bool):
	if current_malfunction == null:
		return
	
	print("[MalfunctionManager] Malfunction completed: %s (Success: %s)" % [current_malfunction.name, success])
	malfunction_completed.emit(current_malfunction, success)
	
	current_malfunction = null
	is_malfunction_active = false
	
	# Schedule next malfunction
	schedule_next_malfunction()

## Get the drain multiplier for the current malfunction (1.0 if none active)
func get_drain_multiplier() -> float:
	if is_malfunction_active and current_malfunction:
		return current_malfunction.drain_multiplier
	return 1.0

## Check if current malfunction uses timer per card logic
func is_timer_per_card_active() -> bool:
	if is_malfunction_active and current_malfunction:
		return current_malfunction.timer_per_card
	return false

## Get number of rounds until next malfunction
func get_rounds_until_next() -> int:
	return rounds_until_next_malfunction

## Reset the malfunction system
func reset():
	current_malfunction = null
	is_malfunction_active = false
	malfunction_history.clear()
	schedule_first_malfunction()
