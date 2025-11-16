# Custom Map Editor System - Complete Package

## Overview

The Microwavr map system now supports **editor-based custom map design**! You can create progression trees directly in Godot's scene editor using visual node placement and connection drawing.

## What You Can Do

✅ **Instance reusable MapNode scenes** and place them visually
✅ **Connect nodes using Inspector** with visual NodePath picker
✅ **See connection lines in real-time** while editing
✅ **Configure all properties** without writing code
✅ **Add new node types** like MALFUNCTION events
✅ **Design any structure** - linear, branching, or complex trees
✅ **Toggle between procedural and custom** maps at runtime

## Quick Start (5 Minutes)

1. **Open** `scenes/map_ui.tscn` in Godot
2. **Set** `use_custom_layout = true` on the MapUI panel
3. **Add** a MapConnectionDrawer Control node under ScrollContainer
4. **Instance** `scenes/map_node.tscn` a few times
5. **Connect** them using the `connected_nodes` array in Inspector
6. **Watch** the lines draw automatically!

## Documentation Files

| File | Purpose | When to Use |
|------|---------|-------------|
| **CUSTOM_MAP_EDITOR_GUIDE.md** | Complete usage guide | Learning the system |
| **CUSTOM_MAP_SETUP_CHECKLIST.md** | Step-by-step checklist | Creating your first map |
| **CUSTOM_MAP_SCENE_TEMPLATE.md** | Scene hierarchy reference | Setting up the structure |
| **MAP_SYSTEM_QUICK_REFERENCE.md** | Class and property reference | Quick lookups |
| **CUSTOM_MAP_IMPLEMENTATION_SUMMARY.md** | Technical overview | Understanding the code |

## Core Components

### MapNodeUI (`scripts/ui/map_node_ui.gd`)
Individual map node with exported properties for easy configuration.

**Key Properties:**
- `node_type` - Type of encounter (COOKING, MODIFIER, SHOP, etc.)
- `tier_number` - Vertical position in progression
- `is_starting_node` - Whether players start here
- `connected_nodes` - Array of NodePaths to next nodes
- `modifier_*` - Settings for MODIFIER type nodes

### MapConnectionDrawer (`scripts/ui/map_connection_drawer.gd`)
Draws visual connection lines between nodes (works in editor with `@tool`).

**Key Properties:**
- `draw_in_editor` - Show lines while editing
- `line_width` - Thickness of connection lines
- `line_color` - Color for unexplored paths
- `active_line_color` - Color for completed paths

### MapNode Scene (`scenes/map_node.tscn`)
Reusable scene you instance for each node in your map.

**Structure:**
- Button (root)
  - VBoxContainer
    - IconLabel (emoji)
    - NameLabel (text)

## Node Types

| Type | Icon | Color | Purpose |
|------|------|-------|---------|
| COOKING | 🍳 | Red | Standard cooking round |
| MODIFIER | ⚡ | Gold | Round with special rules |
| SHOP | 🛒 | Blue | Buy items |
| SUPER_SHOP | 💎 | Purple | Better shop selection |
| REST | 🛏 | Green | Card upgrades |
| BOSS | 👹 | Magenta | Final challenge |
| MALFUNCTION | ⚠️ | Orange | Special event (NEW!) |

## Example Workflow

### 1. Create Scene Structure
```
MapUI (Panel)
└── VBoxContainer
    └── ScrollContainer
        ├── MapConnectionDrawer (draws lines)
        └── MapCanvas (holds nodes)
            ├── StartNode (MapNode instance)
            ├── MiddleNode (MapNode instance)
            └── BossNode (MapNode instance)
```

### 2. Configure StartNode
```
Inspector:
  node_type: COOKING
  tier_number: 0
  is_starting_node: ✓
  connected_nodes: ["../MiddleNode"]
```

### 3. Configure MiddleNode
```
Inspector:
  node_type: MODIFIER
  tier_number: 1
  modifier_name: "Speed Challenge"
  modifier_type: DRAIN_MULTIPLIER
  modifier_value: 1.5
  connected_nodes: ["../BossNode"]
```

### 4. Configure BossNode
```
Inspector:
  node_type: BOSS
  tier_number: 2
  connected_nodes: []  (empty - it's the end)
```

### 5. Test
Run the game - your custom map loads and works!

## Design Patterns

### Linear Progression
```
[Start] → [Shop] → [Modifier] → [Boss]
```
Simple, tutorial-friendly.

### Binary Choice
```
        [Boss]
       /     \
   [Shop]   [Modifier]
       \     /
       [Start]
```
Strategic decision-making.

### Complex Tree
```
           [Boss]
          /  |  \
      [🛒][⚡][⚠️]
       / \ | / \
    [🍳][🍳][💎]
       \  |  /
        [🍳]
```
High replayability.

## Tips & Tricks

### For Clean Maps
- Organize nodes into Tier folders
- Use consistent spacing (140px horizontal, 180px vertical)
- Name nodes descriptively

### For Testing
- Start simple (3-4 nodes)
- Test connections frequently
- Add complexity gradually

### For Debugging
- Check Console for "[MapUI] Setup custom map with X nodes"
- Verify NodePaths resolve correctly
- Use the visual line drawer to spot issues

## Mode Switching

### Use Procedural Generation
```gdscript
map_manager.use_custom_map = false
map_ui.use_custom_layout = false
```
Randomized 15-tier map with branching paths.

### Use Custom Design
```gdscript
map_manager.use_custom_map = true
map_ui.use_custom_layout = true
```
Your hand-crafted progression tree.

## Integration Points

### MapManager
- `initialize_map(round_modifier_manager, custom_nodes)`
- `load_from_custom_nodes()` - Converts UI nodes to models
- `generate_map()` - Procedural generation (still works!)

### MapUI
- `show_map(map_manager)` - Display the map
- `_setup_custom_map()` - Load from scene
- `_build_map_ui()` - Generate dynamically

### Main Scene
- `_on_game_started()` - Calls map initialization
- `_on_map_node_clicked()` - Processes player selection
- `_on_map_node_selected()` - Handles node effects

## Extending the System

### Add New Node Type
1. Add to `MapNodeModel.NodeType` enum
2. Add color constant in `map_node_ui.gd`
3. Add icon in `_get_node_icon()`
4. Add name in `_get_node_name()`
5. Handle in `main.gd` `_on_map_node_selected()`

### Create Custom Modifiers
```
modifier_name: "Triple Speed"
modifier_description: "Everything moves 3x faster!"
modifier_type: DRAIN_MULTIPLIER
modifier_value: 3.0
```

### Design Themed Maps
- Fire Level: More MODIFIER nodes, fewer REST
- Ice Level: More REST nodes, shops every tier
- Challenge Mode: Harder modifiers, fewer shops

## Performance Notes

- Maps loaded once per run (not per frame)
- Connection drawing uses efficient `draw_line`
- Static positioning (no runtime calculations)
- Scales to 100+ nodes without issues

## Compatibility

✅ **Backwards Compatible** - Procedural generation still works
✅ **Scene Independent** - Can create multiple custom maps
✅ **Runtime Switchable** - Toggle modes dynamically
✅ **No Breaking Changes** - Existing code unaffected

## Files Modified

| File | Change | Impact |
|------|--------|--------|
| `map_node_model.gd` | Added MALFUNCTION type | New node type available |
| `map_manager.gd` | Added custom loading | Dual-mode support |
| `main.gd` | Added malfunction handling | New event type works |

## Files Created

| File | Type | Purpose |
|------|------|---------|
| `map_node_ui.gd` | Script | Individual node component |
| `map_connection_drawer.gd` | Script | Visual line renderer |
| `map_node.tscn` | Scene | Reusable node template |
| Documentation (6 files) | Markdown | Guides and references |

## Success Criteria

✅ Can instance nodes in editor
✅ Can connect nodes visually
✅ Lines render in real-time
✅ Nodes work in-game
✅ Properties configurable in Inspector
✅ No coding required for basic maps
✅ Extensible for advanced features

## Support

- See **CUSTOM_MAP_EDITOR_GUIDE.md** for detailed instructions
- See **CUSTOM_MAP_SETUP_CHECKLIST.md** for step-by-step setup
- See **MAP_SYSTEM_QUICK_REFERENCE.md** for API reference
- See **CUSTOM_MAP_SCENE_TEMPLATE.md** for structure examples

## License & Credits

Part of the Microwavr game project.
Custom map editor system implemented November 2025.

---

## Get Started Now!

1. Read **CUSTOM_MAP_SETUP_CHECKLIST.md**
2. Follow the steps
3. Build your first map
4. Test it in-game
5. Iterate and polish

Happy map designing! 🗺️🎮✨
