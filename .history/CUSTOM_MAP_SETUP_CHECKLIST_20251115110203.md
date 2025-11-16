# Custom Map Editor - Setup Checklist

Use this checklist to create your first custom map from scratch.

## ✅ File Preparation

- [ ] `scripts/ui/map_node_ui.gd` exists
- [ ] `scripts/ui/map_connection_drawer.gd` exists
- [ ] `scenes/map_node.tscn` exists
- [ ] All files have no compile errors

## ✅ Scene Setup

### Create Base Scene
- [ ] New Scene created (type: Panel)
- [ ] Root node renamed to "MapUI"
- [ ] Script `res://scripts/ui/map_ui.gd` attached
- [ ] Export variable `use_custom_layout = true` set

### Build Container Hierarchy
- [ ] VBoxContainer added as child of MapUI
- [ ] ScrollContainer added as child of VBoxContainer
- [ ] Control node added as child of ScrollContainer (renamed "MapCanvas")
- [ ] Control node added as child of ScrollContainer (renamed "MapConnectionDrawer")
- [ ] MapConnectionDrawer is positioned ABOVE MapCanvas in tree

### Configure Connection Drawer
- [ ] Script `res://scripts/ui/map_connection_drawer.gd` attached
- [ ] `draw_in_editor = true`
- [ ] `line_width = 4.0` (or preferred value)
- [ ] `line_color` set to gray with 50% opacity
- [ ] `active_line_color` set to green with 90% opacity

## ✅ Node Creation

### First Node (Start)
- [ ] Instance `res://scenes/map_node.tscn` into MapCanvas
- [ ] Rename to "StartNode" or similar
- [ ] Position set (e.g., 400, 100)
- [ ] `node_type = COOKING` (or desired type)
- [ ] `tier_number = 0`
- [ ] `is_starting_node = true` ✓ CHECKED
- [ ] `connected_nodes` array prepared (leave empty for now)

### Second Node
- [ ] Instance another map_node.tscn
- [ ] Rename descriptively
- [ ] Position set (e.g., 400, 250)
- [ ] `node_type` configured
- [ ] `tier_number = 1`
- [ ] `is_starting_node = false`
- [ ] `connected_nodes` prepared

### Third Node (Boss)
- [ ] Instance another map_node.tscn
- [ ] Rename to "BossNode" or similar
- [ ] Position set (e.g., 400, 400)
- [ ] `node_type = BOSS`
- [ ] `tier_number = 2`
- [ ] `is_starting_node = false`
- [ ] `connected_nodes = []` (empty - it's the end)

## ✅ Connections

### Connect StartNode → SecondNode
- [ ] Select StartNode in scene tree
- [ ] In Inspector, find `connected_nodes` array
- [ ] Click `+` to add a slot
- [ ] Click the folder/picker icon
- [ ] Select SecondNode from tree
- [ ] NodePath auto-filled (e.g., `../SecondNode`)

### Connect SecondNode → BossNode
- [ ] Select SecondNode in scene tree
- [ ] In Inspector, find `connected_nodes` array
- [ ] Click `+` to add a slot
- [ ] Click the folder/picker icon
- [ ] Select BossNode from tree
- [ ] NodePath auto-filled (e.g., `../BossNode`)

### Verify Connections Visually
- [ ] Lines appear between nodes in editor
- [ ] Lines connect the correct nodes
- [ ] No error messages in Output panel

## ✅ Node Configuration (For Modifier Nodes)

If you added a MODIFIER type node:
- [ ] `modifier_name` filled (e.g., "Speed Challenge")
- [ ] `modifier_description` filled (e.g., "Timer runs 2x faster")
- [ ] `modifier_type` selected from dropdown
- [ ] `modifier_value` set appropriately

## ✅ MapManager Integration

- [ ] Open `scripts/managers/map_manager.gd` (just to verify)
- [ ] Confirm `use_custom_map` variable exists
- [ ] Confirm `load_from_custom_nodes()` function exists
- [ ] No changes needed if files were created correctly

## ✅ Main Scene Integration

If creating a new map scene from scratch:
- [ ] Save your map scene (e.g., `scenes/custom_map_1.tscn`)
- [ ] Open `scenes/main.tscn`
- [ ] Update MapUI reference to point to your custom scene
- [ ] OR: Replace the existing map_ui with your design

If editing existing map_ui.tscn:
- [ ] Just save - it's already referenced by main.tscn

## ✅ Testing

### Pre-Flight Check
- [ ] No errors in Output panel
- [ ] Connection lines visible in editor
- [ ] All NodePaths resolve correctly
- [ ] At least one node has `is_starting_node = true`

### Run Game Test
- [ ] Game starts without errors
- [ ] Map UI appears
- [ ] Custom nodes are visible
- [ ] Connection lines rendered
- [ ] Starting node(s) are clickable (white border)
- [ ] Other nodes are disabled (gray)

### Interaction Test
- [ ] Click starting node
- [ ] Connected nodes become available (white border)
- [ ] Game progresses correctly (cooking, shop, etc.)
- [ ] Return to map after node completion
- [ ] Completed nodes are grayed out
- [ ] Active path shows in green

### Full Progression Test
- [ ] Play through entire map
- [ ] Reach boss node
- [ ] Complete boss encounter
- [ ] Map completion detected
- [ ] Victory screen appears (or appropriate end state)

## ✅ Polish & Iteration

### Visual Polish
- [ ] Node spacing looks good
- [ ] Tier alignment is consistent
- [ ] Boss node clearly stands out
- [ ] No overlapping nodes

### Functional Polish
- [ ] All paths lead to boss
- [ ] No dead-end nodes
- [ ] Branching makes strategic sense
- [ ] Difficulty curve feels right

### Documentation
- [ ] Commented any complex connections
- [ ] Named nodes descriptively
- [ ] Organized into tier folders (optional)

## ✅ Advanced Features (Optional)

### Add More Node Types
- [ ] MALFUNCTION nodes configured
- [ ] SUPER_SHOP nodes placed
- [ ] REST nodes added
- [ ] Custom descriptions written

### Complex Branching
- [ ] Multiple starting nodes
- [ ] Converging paths
- [ ] Optional branches
- [ ] Secret nodes

### Theming
- [ ] Consistent positioning
- [ ] Logical tier progression
- [ ] Strategic placement of shops
- [ ] Boss at climactic position

## 🎉 Completion Checklist

- [ ] Map displays correctly in editor
- [ ] Map loads in-game without errors
- [ ] All nodes are reachable
- [ ] Progression works as designed
- [ ] Victory condition triggers properly
- [ ] Ready to share/use!

---

## Quick Reference Commands

### Instance Node
`Scene → Instance Child Scene → Select map_node.tscn`

### Connect Nodes
`Select Node → Inspector → connected_nodes → + → Pick target node`

### Refresh Connections
`Select MapConnectionDrawer → Call refresh() if needed`

### Test Mode Toggle
`MapUI → use_custom_layout = true/false`
`MapManager → use_custom_map = true/false`

---

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| No lines in editor | Check `draw_in_editor = true` on drawer |
| Lines go to wrong nodes | Verify NodePaths with picker |
| Nodes won't click | Ensure `is_starting_node = true` on start |
| Map doesn't load | Check `use_custom_layout = true` on MapUI |
| Errors on start | Verify all scripts attached correctly |

---

## Next Steps After Completion

1. **Save your map** - Give it a descriptive name
2. **Duplicate it** - Create variations
3. **Experiment** - Try different structures
4. **Share it** - Show your design!
5. **Iterate** - Based on playtesting feedback

Happy map building! 🗺️✨
