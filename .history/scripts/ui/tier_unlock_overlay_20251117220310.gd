extends Panel
class_name TierUnlockOverlay

## Achievement notification for tier unlocks - shows in bottom right corner

@onready var tier_label: Label = $MarginContainer/VBoxContainer/TierLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const TIER_DESCRIPTIONS = {
	1: "Simple Combos Unlocked!",
	2: "Advanced Combos Unlocked!",
	3: "Expert Recipes Unlocked!",
	4: "Legendary Recipes Unlocked!"
}

const TIER_COLORS = {
	1: Color(0.3, 0.8, 0.3),  # Green
	2: Color(0.2, 0.6, 1.0),  # Blue
	3: Color(0.8, 0.3, 0.8),  # Purple
	4: Color(1.0, 0.7, 0.0)   # Gold
}

func _ready():
	hide()
	
	# Style the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style_box.border_color = Color(1.0, 1.0, 1.0, 0.8)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style_box)

func show_tier_unlock(tier_number: int) -> void:
	if not TIER_DESCRIPTIONS.has(tier_number):
		return
	
	# Set labels
	tier_label.text = "TIER %d" % tier_number
	description_label.text = TIER_DESCRIPTIONS[tier_number]
	
	# Set color based on tier
	if TIER_COLORS.has(tier_number):
		tier_label.add_theme_color_override("font_color", TIER_COLORS[tier_number])
	
	# Show and animate
	show()
	_animate_in()
	
	# Auto-hide after 4 seconds
	await get_tree().create_timer(4.0).timeout
	_animate_out()

func _animate_in() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Start from below and slide up
	position.y += 100
	modulate.a = 0.0
	
	tween.parallel().tween_property(self, "position:y", position.y - 100, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)

func _animate_out() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	hide()
