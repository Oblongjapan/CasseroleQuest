# Instructions to Add Round Modifier Label to main.tscn

## Option 1: Manual Method (Recommended)

1. Open `scenes/main.tscn` in Godot
2. In the Scene tree, find the `UI` node
3. Right-click on `UI` → Add Child Node
4. Search for "Label" and add it
5. Name the new node: `RoundModifierLabel`
6. In the Inspector panel, under "Script", click the folder icon
7. Navigate to and select: `res://scripts/ui/round_modifier_label.gd`
8. Configure the label properties:
   - **Text**: Leave blank (will be set by script)
   - **Position/Size**: 
     - Layout → Anchors Preset: Top Right
     - Position: X = -280, Y = 10
     - Size: X = 250, Y = 30
   - **Theme Overrides**:
     - Font Size: 18
   - **Horizontal Alignment**: Center
   - **Vertical Alignment**: Center
   - **Mouse Filter**: STOP (important for tooltip!)
9. Save the scene (Ctrl+S)

## Option 2: Script Method (Quick but less precise)

Run this in Godot's script editor on the main scene:

```gdscript
var label = Label.new()
label.name = "RoundModifierLabel"
label.set_script(load("res://scripts/ui/round_modifier_label.gd"))
label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
label.mouse_filter = Control.MOUSE_FILTER_STOP
label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
label.offset_left = -280
label.offset_top = 10
label.offset_right = -30
label.offset_bottom = 40
$UI.add_child(label)
label.owner = self  # Make sure it saves
```

Then save the scene.

## Verification

After adding the label:
1. Run the game
2. You should see a colored label in the top-right that says something like "⚡ Lucky Day"
3. Hover over it - a tooltip should appear with the description
4. Colors will change based on the modifier type (green=helpful, red=challenging, etc.)

## Position Suggestions

You can adjust the position to fit your UI:
- **Top Right** (recommended): X = -280, Y = 10
- **Below Currency**: Position it under your Currency label
- **Above Status**: Position it above your StatusLabel
