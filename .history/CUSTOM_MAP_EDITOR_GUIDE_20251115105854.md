# Custom Map Editor Guide

## Overview
The map system now supports **manually-designed progression trees** that you can build directly in Godot's scene editor! This allows you to create custom map layouts, add new node types like malfunctions, and design unique branching paths.

## Quick Start

### 1. Create a Custom Map Scene

1. Open or create `scenes/map_ui.tscn` in Godot
2. Set the `use_custom_layout` export variable to `true` on the MapUI panel
3. Inside the ScrollContainer, add a Control node to hold your map nodes
4. Add a `MapConnectionDrawer` node (script: `scripts/ui/map_connection_drawer.gd`) to visualize connections

### 2. Instance Map Nodes

1. Drag `scenes/map_node.tscn` into your map canvas
2. Position it where you want (manually place nodes in the editor)
3. Repeat for all nodes in your progression tree

### 3. Configure Each Node

Select a MapNode instance and configure in the Inspector:

#### Node Configuration Group
- **Node Type**: Choose from:
  - `COOKING` 🍳 - Normal cooking round (no modifier)
  - `MODIFIER` ⚡ - Applies a round modifier
  - `SHOP` 🛒 - Regular shop
  - `SUPER_SHOP` 💎 - Better shop selection
  - `REST` 🛏 - Card upgrades (placeholder)
  - `BOSS` 👹 - Boss challenge (1.5x drain)
  - `MALFUNCTION` ⚠️ - Malfunction event (rewards/challenges)

- **Tier Number**: Which tier/row this node belongs to (0 = start, higher = later)
- **Is Starting Node**: Check this for the first node(s) players can select
- **Custom Description**: Override the default node name (optional)

#### Connections Group
- **Connected Nodes**: Array of NodePath pointing to the next nodes
  - Click `+` to add a connection
  - Click the picker icon and select a MapNode in the scene
  - Example: `../../MapNode2`, `../Tier2/MapNode5`
  - Connections create the branching paths

#### Modifier Settings (for MODIFIER type nodes)
- **Modifier Name**: Display name (e.g., "Double Time")
- **Modifier Description**: What it does (e.g., "Timer runs 2x speed")
- **Modifier Type**: Effect type (DRAIN_MULTIPLIER, TIMER_BONUS, etc.)
- **Modifier Value**: Effect strength (e.g., 2.0 for double)

### 4. Connect Nodes Visually

**Method 1: Inspector (Recommended)**
1. Select a MapNode
2. In Inspector → Connections → Connected Nodes
3. Click `+` to add a connection
4. Use the node picker to select the target node
5. The MapConnectionDrawer will draw lines automatically

**Method 2: Script**
You can also set connections programmatically, but the Inspector is easier for visual design.

### 5. Preview Connections in Editor

The `MapConnectionDrawer` script has `@tool` directive, so it draws lines in the editor:
- Gray lines show connections
- Lines update as you move nodes
- Set `draw_in_editor = true` to see connections while editing

### 6. Enable Custom Map in MapManager

In `main.gd` or your map initialization:
```gdscript
map_manager.use_custom_map = true
# Collect MapNodeUI nodes from your scene
var custom_nodes: Array[MapNodeUI] = []
# ... collect nodes ...
map_manager.initialize_map(round_modifier_manager, custom_nodes)
```

## Example Map Layout

```
Tier 3 (Boss)
    [👹 BOSS]
      /   \
Tier 2
   [🛒]  [⚠️]  [⚡]
     \    |    /
Tier 1
      [🍳]  [💎]
         \ /
Tier 0 (Start)
         [🍳]
```

### Scene Hierarchy
```
MapUI (Panel)
└── VBoxContainer
    └── ScrollContainer
        ├── MapConnectionDrawer
        └── MapCanvas (Control)
            ├── Tier0
            │   └── StartNode (MapNode) [is_starting_node = true]
            ├── Tier1
            │   ├── CookNode (MapNode)
            │   └── ShopNode (MapNode)
            ├── Tier2
            │   ├── ShopNode2 (MapNode)
            │   ├── MalfunctionNode (MapNode) [node_type = MALFUNCTION]
            │   └── ModifierNode (MapNode)
            └── Tier3
                └── BossNode (MapNode) [node_type = BOSS]
```

### Connection Setup Example

**StartNode** (Tier 0):
- `connected_nodes = [../Tier1/CookNode, ../Tier1/ShopNode]`

**CookNode** (Tier 1):
- `connected_nodes = [../../Tier2/ShopNode2, ../../Tier2/MalfunctionNode]`

**ShopNode** (Tier 1):
- `connected_nodes = [../../Tier2/MalfunctionNode, ../../Tier2/ModifierNode]`

**All Tier 2 nodes**:
- `connected_nodes = [../../Tier3/BossNode]`

## Node Type Behaviors

### COOKING 🍳
- Standard cooking round
- No modifier applied
- Player selects ingredients and cooks

### MODIFIER ⚡
- Applies the configured modifier to the cooking round
- Custom settings in Inspector:
  - `modifier_name = "Chaos Mode"`
  - `modifier_type = VOLATILITY_CHANGE`
  - `modifier_value = 2.0`

### SHOP 🛒 / SUPER_SHOP 💎
- Opens shop interface
- Super Shop has better selection
- Player can buy active items (Cover, Stir, Blow)

### REST 🛏
- Currently placeholder
- Intended for card upgrades
- Auto-advances after 1 second

### BOSS 👹
- Final challenge node
- Applies 1.5x drain multiplier automatically
- Typically placed at highest tier

### MALFUNCTION ⚠️ **NEW!**
- Triggers malfunction system
- Shows malfunction popup
- Can reward or challenge player
- Returns to map after event

## MapConnectionDrawer Properties

Select the MapConnectionDrawer node to configure:

- **Line Width**: Thickness of connection lines (default: 4.0)
- **Line Color**: Color for unexplored paths (default: gray with 50% opacity)
- **Active Line Color**: Color for completed paths (default: green with 90% opacity)
- **Draw In Editor**: Show lines while editing (default: true)

## Tips & Tricks

### Organizing Nodes
- Group nodes by tier in folders: `Tier0/`, `Tier1/`, etc.
- Name nodes descriptively: `StartCook`, `ShopBeforeBoss`, `MalfunctionBranch`
- Use even spacing for cleaner appearance (e.g., 140px horizontal, 180px vertical)

### Testing Your Map
1. Run the game from the main scene
2. Start a new game
3. Your custom map will load instead of procedural generation
4. Test all branching paths

### Switching Between Modes
- **Procedural**: Set `use_custom_layout = false` on MapUI
- **Custom**: Set `use_custom_layout = true` on MapUI
- Both modes use the same game logic

### Creating Branching Complexity
- Each node can connect to 1-3 nodes in the next tier
- More connections = more player choice
- Fewer connections = more linear progression
- Mix both for interesting pacing

### Debugging Connections
- Check Console for "[MapUI] Setup custom map with X nodes"
- If connections don't work, verify NodePaths are correct
- Use relative paths: `../NodeName` or `../../Folder/NodeName`
- Click "Refresh" on MapConnectionDrawer to update lines

## Color Coding

Node types automatically get these colors:

- 🍳 COOKING: Red (#D94040)
- ⚡ MODIFIER: Gold (#F2BF26)
- 🛒 SHOP: Blue (#408CF2)
- 💎 SUPER_SHOP: Purple (#8C40F2)
- 🛏 REST: Green (#40D959)
- 👹 BOSS: Magenta (#F226D9)
- ⚠️ MALFUNCTION: Orange (#F28C26) **NEW!**

## Advanced: Custom Modifier Presets

Create interesting modifier nodes:

**Speed Challenge**
- `modifier_name = "Speed Cook"`
- `modifier_type = TIMER_BONUS`
- `modifier_value = -15.0` (removes 15 seconds)

**Moisture Bonus**
- `modifier_name = "Extra Moisture"`
- `modifier_type = MOISTURE_BONUS`
- `modifier_value = 30.0` (adds 30 moisture)

**Shop Discount**
- `modifier_name = "Sale Day"`
- `modifier_type = SHOP_DISCOUNT`
- `modifier_value = 0.5` (50% discount)

**Harder Challenge**
- `modifier_name = "Chaos Kitchen"`
- `modifier_type = DRAIN_MULTIPLIER`
- `modifier_value = 2.0` (double drain rate)

## Troubleshooting

**Lines don't appear:**
- Check `draw_in_editor = true` on MapConnectionDrawer
- Make sure MapConnectionDrawer is a sibling or parent of MapNodes
- Try calling `refresh()` on the drawer

**Nodes not clickable:**
- Verify `is_starting_node = true` on at least one node
- Check that `connected_nodes` paths are correct
- Ensure nodes have proper tier numbers

**Connections go to wrong nodes:**
- Double-check NodePath values
- Use the node picker instead of typing paths
- Test with simple 2-node connection first

**Game uses procedural map instead:**
- Set `use_custom_layout = true` on MapUI panel
- Set `use_custom_map = true` on MapManager
- Make sure custom nodes are children of the MapUI scene

## Example: Adding a Malfunction Branch

1. Create a new MapNode instance
2. Set `node_type = MALFUNCTION`
3. Set `custom_description = "Mystery Event"`
4. Position it between two tiers
5. Connect previous nodes to it
6. Connect it to next tier nodes
7. Test: Selecting this node triggers malfunction popup!

## Converting from Procedural

If you want to recreate the procedural map manually:

1. Run the game with procedural generation
2. Note the tier structure (15 tiers total)
3. Create nodes matching that pattern:
   - Tier 0: 1 cooking node
   - Tier 1-13: 2-4 mixed nodes
   - Tier 14: 1 boss node
4. Set up connections with 1-3 paths per node
5. Test and adjust!

---

Happy map designing! You now have full control over the progression tree. Create linear paths, complex branching networks, or unique hybrid designs!
