@tool
extends EditorScript

## Run this script in Godot Editor to automatically add RoundModifierLabel to main.tscn
## Tools → Run Script → Select this file

func _run():
	# Get the currently edited scene
	var edited_scene = get_scene()
	if not edited_scene:
		print("ERROR: No scene is currently open in the editor!")
		return
	
	# Find the UI node
	var ui_node = edited_scene.get_node_or_null("UI")
	if not ui_node:
		print("ERROR: Could not find UI node in the current scene!")
		print("Make sure main.tscn is open and has a UI node.")
		return
	
	# Check if label already exists
	var existing_label = ui_node.get_node_or_null("RoundModifierLabel")
	if existing_label:
		print("RoundModifierLabel already exists! Updating it instead...")
		existing_label.queue_free()
	
	# Create the label
	var label = Label.new()
	label.name = "RoundModifierLabel"
	
	# Load and attach the script
	var script_path = "res://scripts/ui/round_modifier_label.gd"
	var script = load(script_path)
	if script:
		label.set_script(script)
		print("Script attached: %s" % script_path)
	else:
		print("WARNING: Could not load script: %s" % script_path)
	
	# Configure properties
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Set anchors and position (top-right corner)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT, false)
	label.offset_left = -280
	label.offset_top = 10
	label.offset_right = -30
	label.offset_bottom = 40
	
	# Add theme overrides for font size
	label.add_theme_font_size_override("font_size", 18)
	
	# Add to scene
	ui_node.add_child(label)
	label.owner = edited_scene  # Important: Make it save with the scene
	
	print("✓ RoundModifierLabel created successfully!")
	print("  Position: Top-Right corner")
	print("  Size: 250x30")
	print("  Font Size: 18")
	print("")
	print("IMPORTANT: Save the scene now! (Ctrl+S)")
	print("Then run the game to see the round modifiers appear.")
