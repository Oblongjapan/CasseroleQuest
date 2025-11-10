extends Node
class_name TimerManager

## Manages the cook timer countdown during a round

var total_time: float = 15.0
var time_remaining: float = 15.0
var is_running: bool = false

## Start the countdown timer
func start_timer(duration: float = 15.0) -> void:
	total_time = duration
	time_remaining = duration
	is_running = true
	EventBus.timer_updated.emit(time_remaining)

## Update timer every frame
func update_timer(delta: float) -> void:
	if not is_running:
		return
	
	time_remaining -= delta
	time_remaining = maxf(time_remaining, 0.0)
	EventBus.timer_updated.emit(time_remaining)

## Stop the timer
func stop_timer() -> void:
	is_running = false

## Check if timer has reached zero (success condition if moisture > 0)
func check_complete() -> bool:
	return time_remaining <= 0.0

## Get formatted time string in MM:SS format
func get_formatted_time() -> String:
	var total_seconds = int(time_remaining)
	var minutes = total_seconds / 60  # Integer division is intentional
	var seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
