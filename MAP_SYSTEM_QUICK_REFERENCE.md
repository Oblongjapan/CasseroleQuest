# Map System Quick Reference

## Files Created/Modified

### New Files
- `scripts/ui/map_node_ui.gd` - Individual node component with exported properties
- `scripts/ui/map_connection_drawer.gd` - @tool script to draw connection lines in editor
- `scenes/map_node.tscn` - Reusable map node scene
- `CUSTOM_MAP_EDITOR_GUIDE.md` - Comprehensive editor documentation

### Modified Files
- `scripts/models/map_node_model.gd` - Added `MALFUNCTION` node type
- `scripts/managers/map_manager.gd` - Added `load_from_custom_nodes()` and `use_custom_map` flag
- `scripts/main.gd` - Added malfunction event handling

## Class Reference

### MapNodeUI (extends Button)
**Purpose:** Individual editable map node for scene placement

**Exported Properties:**
```gdscript
@export var node_type: MapNodeModel.NodeType
@export var tier_number: int
@export var is_starting_node: bool
@export var custom_description: String
@export var connected_nodes: Array[NodePath]
@export var modifier_name: String
@export var modifier_description: String  
@export var modifier_type: RoundModifierModel.ModifierType
@export var modifier_value: float
```

**Key Methods:**
- `create_model(round_modifier_manager)` - Converts UI node to data model
- `update_from_model()` - Syncs visual state with model
- `_setup_visual_style()` - Applies color coding and styling

**Signals:**
- `node_selected(node: MapNodeUI)` - Emitted when player clicks

### MapConnectionDrawer (extends Control)
**Purpose:** Draws visual connection lines between nodes (works in editor!)

**Exported Properties:**
```gdscript
@export var line_width: float = 4.0
@export var line_color: Color = Color(0.5, 0.5, 0.5, 0.5)
@export var active_line_color: Color = Color(0.3, 0.9, 0.3, 0.9)
@export var draw_in_editor: bool = true
```

**Key Methods:**
- `refresh()` - Recollect nodes and redraw connections
- `_draw_connections()` - Draws lines between connected nodes
- `_collect_map_nodes()` - Finds all MapNodeUI instances

### MapManager
**New Properties:**
```gdscript
@export var use_custom_map: bool = false
var ui_nodes_map: Dictionary = {}  # Maps models to UI nodes
```

**New Methods:**
```gdscript
initialize_map(round_modifier_manager, custom_nodes=[])
load_from_custom_nodes(custom_nodes, round_modifier_manager)
```

### MapUI
**New Properties:**
```gdscript
@export var use_custom_layout: bool = false
var connection_drawer: MapConnectionDrawer = null
```

**New Methods:**
```gdscript
_setup_custom_map()  # Loads manually-designed tree
_collect_map_nodes(node, result)  # Recursively finds MapNodeUI
_on_custom_node_selected(ui_node)  # Handles custom node clicks
_refresh_custom_ui()  # Updates custom map display
```

## Node Type Enum

```gdscript
enum NodeType {
    COOKING,      # 🍳 Normal cooking round
    MODIFIER,     # ⚡ Round modifier
    SHOP,         # 🛒 Regular shop
    SUPER_SHOP,   # 💎 Better shop
    REST,         # 🛏 Card upgrades
    BOSS,         # 👹 Boss challenge
    MALFUNCTION   # ⚠️ Malfunction event (NEW!)
}
```

## Workflow Comparison

### Procedural Generation (Original)
```gdscript
# In main.gd
map_manager.use_custom_map = false
map_manager.generate_map(round_modifier_manager)
map_ui.use_custom_layout = false
map_ui.show_map(map_manager)
```

**Result:** 15 tiers, 2-4 nodes per tier, automatic branching

### Custom Editor Design (New!)
```gdscript
# In main.gd
map_manager.use_custom_map = true

# Collect MapNodeUI instances from scene
var custom_nodes: Array[MapNodeUI] = []
# ... collect from map_ui scene ...

map_manager.initialize_map(round_modifier_manager, custom_nodes)
map_ui.use_custom_layout = true
map_ui.show_map(map_manager)
```

**Result:** Your manually-designed tree with full control

## Inspector Setup Checklist

### MapUI Panel
- [ ] `use_custom_layout = true` (for custom maps)
- [ ] Has `VBoxContainer/ScrollContainer` hierarchy
- [ ] Has `MapConnectionDrawer` as child of ScrollContainer

### Each MapNode Instance
- [ ] `node_type` set (COOKING, MODIFIER, etc.)
- [ ] `tier_number` assigned (0 = start, higher = later)
- [ ] `is_starting_node = true` for first node(s)
- [ ] `connected_nodes` array filled with NodePaths
- [ ] For MODIFIER: Set modifier settings (name, type, value)
- [ ] Positioned visually in scene

### MapConnectionDrawer
- [ ] `draw_in_editor = true` (to see lines while editing)
- [ ] `line_width = 4.0` (adjust for visibility)
- [ ] Colors set for active/inactive paths

## Common Patterns

### Linear Path
```
[A] → [B] → [C] → [D]
```
Each node connects to exactly one next node

### Binary Branching
```
      [D]
     / \
   [B] [C]
     \ /
     [A]
```
Nodes split and rejoin

### Multi-Path
```
   [E] [F] [G]
    |  X  |
   [B][C][D]
      \|/
      [A]
```
Complex branching with crossing paths

### Boss Gauntlet
```
[BOSS] ← [Shop] ← [Cook] ← [Cook] ← [Start]
```
Linear progression to final boss

## Color Reference

| Type | Color | Hex | Usage |
|------|-------|-----|-------|
| COOKING | Red | `#D94040` | Standard rounds |
| MODIFIER | Gold | `#F2BF26` | Modifiers |
| SHOP | Blue | `#408CF2` | Normal shop |
| SUPER_SHOP | Purple | `#8C40F2` | Better shop |
| REST | Green | `#40D959` | Upgrades |
| BOSS | Magenta | `#F226D9` | Boss fights |
| MALFUNCTION | Orange | `#F28C26` | Special events |

## Testing Checklist

- [ ] All nodes have valid tier numbers
- [ ] At least one node has `is_starting_node = true`
- [ ] All `connected_nodes` paths resolve correctly
- [ ] Boss node exists (usually highest tier)
- [ ] Lines appear in editor (MapConnectionDrawer working)
- [ ] Nodes clickable in-game
- [ ] Branching paths work as expected
- [ ] Malfunction nodes trigger events
- [ ] Completed paths show in green
- [ ] Available nodes have white borders

## Performance Notes

- Custom maps load once at game start (no runtime generation cost)
- Connection drawing uses Godot's `draw_line` (very efficient)
- Node positioning is static (no per-frame calculations)
- Scales well to 50+ nodes per map

## Migration Path

**From Procedural to Custom:**
1. Set `use_custom_layout = true` on MapUI
2. Set `use_custom_map = true` on MapManager
3. Design your tree in the scene editor
4. Test and iterate

**From Custom to Procedural:**
1. Set `use_custom_layout = false` on MapUI
2. Set `use_custom_map = false` on MapManager
3. Old procedural generation resumes

**Hybrid Approach:**
- Use procedural for random runs
- Use custom for story/tutorial levels
- Toggle at runtime based on game mode!

---

## Quick Start Command List

```gdscript
# Create a node programmatically
var node = preload("res://scenes/map_node.tscn").instantiate()
node.node_type = MapNodeModel.NodeType.COOKING
node.tier_number = 0
node.is_starting_node = true
add_child(node)

# Connect nodes
node_a.connected_nodes = [node_b.get_path(), node_c.get_path()]

# Refresh connections
connection_drawer.refresh()
```

Ready to design custom progression trees! 🎨
