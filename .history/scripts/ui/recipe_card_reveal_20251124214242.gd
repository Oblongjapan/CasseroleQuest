extends Control

## Animated recipe card reveal - replaces the old recipe notification popup
## Shows the newly created recipe card springing into view, with hover and click-to-dismiss

signal reveal_completed

@onready var card_container: Control = $CardContainer
@onready var recipe_box_icon: Sprite2D = $RecipeBoxIcon

var revealed_card: IngredientCard = null
var is_hovering: bool = false
var is_dismissed: bool = false
var original_card_scale: Vector2 = Vector2.ONE
var original_card_position: Vector2 = Vector2.ZERO

const CARD_SCENE_PATH = "res://scenes/ingredient_card.tscn"
const CARD_HOVER_SCALE := 1.2
const CARD_NORMAL_SCALE := Vector2(1.0, 1.0)
const SPRING_POSITION := Vector2(960, 750)  # Center-bottom of screen (lower third)
const RECIPE_BOX_POSITION := Vector2(1700, 750)  # Right side where recipe box is
const FLIP_DURATION := 0.3
const SLIDE_DURATION := 0.5

func _ready():
	# Start hidden
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup recipe box icon (right side destination)
	if recipe_box_icon:
		recipe_box_icon.position = RECIPE_BOX_POSITION
		recipe_box_icon.modulate.a = 0.0  # Start invisible

## Show the recipe card reveal animation
func show_reveal(recipe_ingredient: IngredientModel) -> void:
	print("[RecipeCardReveal] Starting reveal for: %s" % recipe_ingredient.name)
	is_dismissed = false
	is_hovering = false
	
	# Clear any existing card
	if revealed_card and is_instance_valid(revealed_card):
		revealed_card.queue_free()
		revealed_card = null
	
	# Create the ingredient card
	var card_scene = preload(CARD_SCENE_PATH)
	revealed_card = card_scene.instantiate()
	card_container.add_child(revealed_card)
	
	# Wait a frame for _ready to complete
	await get_tree().process_frame
	
	# Setup the card with recipe data
	var _display_name = recipe_ingredient.get_meta("display_name", recipe_ingredient.name)
	revealed_card.setup(recipe_ingredient)
	
	# Position card off-screen (below) for spring animation
	# Use position (relative to card_container which fills screen)
	var start_position = SPRING_POSITION + Vector2(0, 600)
	revealed_card.position = start_position
	revealed_card.scale = Vector2(0.5, 0.5)  # Start small
	revealed_card.modulate.a = 0.0  # Start invisible
	
	# Store original position for hover effects
	original_card_position = SPRING_POSITION
	original_card_scale = CARD_NORMAL_SCALE
	
	# Connect hover and click signals
	revealed_card.mouse_entered.connect(_on_card_mouse_entered)
	revealed_card.mouse_exited.connect(_on_card_mouse_exited)
	revealed_card.gui_input.connect(_on_card_gui_input)
	
	# Show the overlay
	show()
	
	# Show recipe box icon fading in
	if recipe_box_icon:
		var box_tween = create_tween()
		box_tween.tween_property(recipe_box_icon, "modulate:a", 0.7, 0.3)
	
	# Animate card springing in
	await _animate_card_spring_in()
	
	print("[RecipeCardReveal] Card is now interactive - hover to scale, click to dismiss")

## Animate the card springing into view
func _animate_card_spring_in() -> void:
	if not revealed_card:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # Springy overshoot effect
	
	# Fade in
	tween.tween_property(revealed_card, "modulate:a", 1.0, 0.3)
	
	# Spring to center position
	tween.tween_property(revealed_card, "global_position", SPRING_POSITION, 0.5)
	
	# Scale up to normal size
	tween.tween_property(revealed_card, "scale", CARD_NORMAL_SCALE, 0.5)
	
	await tween.finished
	print("[RecipeCardReveal] Spring-in animation complete")

## Handle mouse entering the card
func _on_card_mouse_entered() -> void:
	if is_dismissed or not revealed_card:
		return
	
	is_hovering = true
	print("[RecipeCardReveal] Card hover started")
	
	# Scale up on hover (like hand selector)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(revealed_card, "scale", Vector2(CARD_HOVER_SCALE, CARD_HOVER_SCALE), 0.2)

## Handle mouse exiting the card
func _on_card_mouse_exited() -> void:
	if is_dismissed or not revealed_card:
		return
	
	is_hovering = false
	print("[RecipeCardReveal] Card hover ended")
	
	# Scale back to normal
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(revealed_card, "scale", CARD_NORMAL_SCALE, 0.2)

## Handle click on the card
func _on_card_gui_input(event: InputEvent) -> void:
	if is_dismissed:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[RecipeCardReveal] Card clicked - starting dismiss animation")
			is_dismissed = true
			await _animate_card_dismiss()

## Animate the card flipping and sliding to the recipe box
func _animate_card_dismiss() -> void:
	if not revealed_card:
		reveal_completed.emit()
		hide()
		return
	
	# Phase 1: Flip animation (scale X to 0, simulating a flip)
	var flip_tween = create_tween()
	flip_tween.set_ease(Tween.EASE_IN_OUT)
	flip_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Flip by scaling X to 0 then back (card turning)
	flip_tween.tween_property(revealed_card, "scale:x", 0.0, FLIP_DURATION / 2)
	flip_tween.tween_property(revealed_card, "scale:x", 1.0, FLIP_DURATION / 2)
	
	await flip_tween.finished
	print("[RecipeCardReveal] Flip complete, now sliding to recipe box")
	
	# Phase 2: Slide to recipe box and fade out
	var slide_tween = create_tween()
	slide_tween.set_parallel(true)
	slide_tween.set_ease(Tween.EASE_IN)
	slide_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Slide to the right (recipe box position)
	slide_tween.tween_property(revealed_card, "global_position", RECIPE_BOX_POSITION, SLIDE_DURATION)
	
	# Scale down as it approaches
	slide_tween.tween_property(revealed_card, "scale", Vector2(0.5, 0.5), SLIDE_DURATION)
	
	# Fade out
	slide_tween.tween_property(revealed_card, "modulate:a", 0.0, SLIDE_DURATION)
	
	# Also fade out the recipe box icon
	if recipe_box_icon:
		slide_tween.tween_property(recipe_box_icon, "modulate:a", 0.0, SLIDE_DURATION)
	
	await slide_tween.finished
	print("[RecipeCardReveal] Dismiss animation complete")
	
	# Cleanup
	if revealed_card and is_instance_valid(revealed_card):
		revealed_card.queue_free()
		revealed_card = null
	
	hide()
	reveal_completed.emit()

## Allow clicking anywhere outside the card to dismiss (optional)
func _gui_input(event: InputEvent) -> void:
	if is_dismissed:
		return
	
	# Only dismiss on click outside the card if we're visible and not hovering
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_hovering:
				print("[RecipeCardReveal] Clicked outside card - dismissing")
				is_dismissed = true
				await _animate_card_dismiss()
