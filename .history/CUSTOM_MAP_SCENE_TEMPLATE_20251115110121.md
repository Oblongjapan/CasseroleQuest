# Custom Map Scene Template

## Recommended Scene Hierarchy

```
MapUI (Panel) - Root node
│   [Script: res://scripts/ui/map_ui.gd]
│   [Export: use_custom_layout = true]
│
└── VBoxContainer
    │
    └── ScrollContainer
        │
        ├── MapConnectionDrawer (Control)
        │   │   [Script: res://scripts/ui/map_connection_drawer.gd]
        │   │   [Export: draw_in_editor = true]
        │   │   [Export: line_width = 4.0]
        │   │   [Export: line_color = (0.5, 0.5, 0.5, 0.5)]
        │   │   [Export: active_line_color = (0.3, 0.9, 0.3, 0.9)]
        │   
        └── MapCanvas (Control)
            │   [Purpose: Container for all map nodes]
            │
            ├── Tier0 (Node)  [Optional: for organization]
            │   │
            │   └── StartNode (MapNode instance)
            │       [Position: (400, 100)]
            │       [node_type: COOKING]
            │       [tier_number: 0]
            │       [is_starting_node: true]
            │       [connected_nodes: [../Tier1/CookNode1, ../Tier1/ShopNode1]]
            │
            ├── Tier1 (Node)
            │   │
            │   ├── CookNode1 (MapNode instance)
            │   │   [Position: (300, 250)]
            │   │   [node_type: COOKING]
            │   │   [tier_number: 1]
            │   │   [connected_nodes: [../../Tier2/ModifierNode1]]
            │   │
            │   └── ShopNode1 (MapNode instance)
            │       [Position: (500, 250)]
            │       [node_type: SHOP]
            │       [tier_number: 1]
            │       [connected_nodes: [../../Tier2/ModifierNode1, ../../Tier2/MalfunctionNode1]]
            │
            ├── Tier2 (Node)
            │   │
            │   ├── ModifierNode1 (MapNode instance)
            │   │   [Position: (350, 400)]
            │   │   [node_type: MODIFIER]
            │   │   [tier_number: 2]
            │   │   [modifier_name: "Speed Challenge"]
            │   │   [modifier_type: DRAIN_MULTIPLIER]
            │   │   [modifier_value: 1.5]
            │   │   [connected_nodes: [../../Tier3/BossNode1]]
            │   │
            │   └── MalfunctionNode1 (MapNode instance)
            │       [Position: (450, 400)]
            │       [node_type: MALFUNCTION]
            │       [tier_number: 2]
            │       [connected_nodes: [../../Tier3/BossNode1]]
            │
            └── Tier3 (Node)
                │
                └── BossNode1 (MapNode instance)
                    [Position: (400, 550)]
                    [node_type: BOSS]
                    [tier_number: 3]
                    [connected_nodes: []]
```

## Setup Instructions

### 1. Create the Base Scene
1. New Scene → Panel (rename to "MapUI")
2. Attach `res://scripts/ui/map_ui.gd`
3. In Inspector: `use_custom_layout = true`

### 2. Add Container Structure
1. Add VBoxContainer as child of MapUI
2. Add ScrollContainer as child of VBoxContainer
3. Add Control node as child of ScrollContainer (rename to "MapCanvas")

### 3. Add Connection Drawer
1. Add Control node as child of ScrollContainer (rename to "MapConnectionDrawer")
2. Attach `res://scripts/ui/map_connection_drawer.gd`
3. Move it ABOVE MapCanvas in the scene tree (so it draws in front)
4. In Inspector:
   - `draw_in_editor = true`
   - `line_width = 4.0`
   - Configure colors as desired

### 4. Organize Tiers (Optional but Recommended)
1. Add Node as child of MapCanvas (rename to "Tier0")
2. Repeat for each tier (Tier1, Tier2, etc.)
3. This keeps the scene tree organized

### 5. Instance Map Nodes
1. Drag `res://scenes/map_node.tscn` into a Tier folder
2. Position it visually where you want it
3. Configure in Inspector:
   - Set `node_type`
   - Set `tier_number`
   - Check `is_starting_node` if it's the first node
   - Fill `connected_nodes` array with NodePaths

### 6. Connect Nodes
For each node's `connected_nodes`:
1. Click the `+` button to add a slot
2. Click the node picker icon (folder icon)
3. Select the target node from the scene tree
4. The path will auto-fill (e.g., `../../Tier2/ModifierNode1`)

### 7. Verify Connections
- Look at the MapConnectionDrawer
- You should see lines connecting your nodes
- If not, check:
  - `draw_in_editor = true`
  - NodePaths are correct
  - MapConnectionDrawer is above MapCanvas in tree

### 8. Test In-Game
1. Save the scene
2. Run the game
3. Your custom map should load
4. Click nodes to progress

## Spacing Recommendations

| Element | Suggested Value | Purpose |
|---------|----------------|---------|
| Horizontal spacing | 140-180px | Comfortable visual separation |
| Vertical spacing | 150-200px | Clear tier distinction |
| Canvas size | 1000x2000+ | Room for 10+ tiers |
| Node size | 100x100 | Readable icons and labels |

## Common NodePath Patterns

```gdscript
# Sibling in same tier folder
"../SiblingNode"

# Node in next tier (one folder down)
"../../Tier2/TargetNode"

# Node in next tier (sibling folder)
"../../Tier1/TargetNode"

# Absolute path (not recommended)
"/root/MapUI/VBoxContainer/ScrollContainer/MapCanvas/Tier1/Node"
```

## Tips

### For Clean Organization
- Use Tier folders even if you have few nodes
- Name nodes descriptively: `SpeedChallenge`, `FirstShop`, `FinalBoss`
- Group related nodes spatially

### For Visual Clarity
- Align nodes horizontally within tiers
- Keep vertical spacing consistent
- Use even numbers for positioning (100, 200, 300)

### For Easy Editing
- Start simple (3-4 nodes)
- Test connections frequently
- Add complexity gradually

### For Debugging
- Check Console for "[MapUI] Setup custom map with X nodes"
- Verify all NodePaths resolve (no "not found" errors)
- Use `print()` in map_node_ui.gd if needed

## Example: Minimal 3-Node Map

```
MapUI
└── VBoxContainer
    └── ScrollContainer
        ├── MapConnectionDrawer
        └── MapCanvas
            ├── Start (MapNode)
            │   [tier: 0, is_starting_node: true]
            │   [connected_nodes: ["../Middle"]]
            ├── Middle (MapNode)
            │   [tier: 1]
            │   [connected_nodes: ["../End"]]
            └── End (MapNode)
                [tier: 2, node_type: BOSS]
                [connected_nodes: []]
```

Simple, linear progression. Perfect for testing!

## Example: Complex Branching Map

```
                    [Boss]
                   /  |  \
              [🛒] [⚡] [⚠️]
               / \ | / \
          [🍳] [🍳] [💎]
             \  |  /
             [🍳]
```

Implementation:
- StartNode connects to all Tier1 nodes
- Each Tier1 node connects to 2-3 Tier2 nodes
- All Tier2 nodes converge to Boss

## Troubleshooting

### Lines don't appear
- Ensure MapConnectionDrawer is a sibling of MapCanvas
- Check `draw_in_editor = true`
- Verify script is attached correctly

### "Cannot find node" errors
- NodePaths are case-sensitive
- Use relative paths (`../Node`) not absolute
- Check spelling and hierarchy

### Nodes won't click in-game
- Verify `is_starting_node = true` on at least one node
- Check that models are being created
- Ensure `use_custom_layout = true` on MapUI

### Connections go to wrong nodes
- Double-check the NodePath
- Use the node picker instead of typing
- Verify target node exists in scene

---

Ready to build your first custom map! 🗺️
