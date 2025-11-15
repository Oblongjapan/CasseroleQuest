# Map System Comparison

## BEFORE (Simple Grid)
```
Tier 8: [BOSS]
Tier 7: [Shop] [Super Shop] [Rest]
Tier 6: [Modifier] [Cook] [Cook]
Tier 5: [Cook] [Modifier] [Cook]
Tier 4: [Shop] [Super Shop] [Rest]
Tier 3: [Modifier] [Cook] [Modifier]
Tier 2: [Cook] [Cook] [Modifier]
Tier 1: [Shop] [Super Shop] [Rest]
Tier 0: [Cook] [Modifier] [Cook]
```
- Simple VBoxContainer/HBoxContainer grid layout
- No visual connections between nodes
- Fixed 3 nodes per tier
- Hard to see progression
- No branching path visualization

## AFTER (Slay the Spire Style)
```
                    [👹 BOSS]                    <- Tier 14
                   /    |    \
                  /     |     \
              [⚡]    [🍳]    [🛒]              <- Tier 13
              / \      |      / \
             /   \     |     /   \
         [🍳]   [⚡]  [🛏]  [💎]  [🍳]          <- Tier 12
          |      |     |     |     |
          |      |     |     |     |
         ...   ...   ...   ...   ...           <- More tiers
          |      |     |     |     |
           \     |     |     |    /
            \    |     |     |   /
           [🍳] [⚡]  [🍳]  [🛒]               <- Tier 2
              \   |    |   /
               \  |    |  /
                \ |    | /
                [🍳] [⚡]                      <- Tier 1
                  \   /
                   \ /
                  [🍳]                         <- Tier 0 (Start)
```
- Custom Control node positioning with absolute coordinates
- Visual connection lines between nodes (gray → green when completed)
- Variable 2-4 nodes per tier (creates interesting choices)
- Tree-like vertical progression
- Branching paths clearly visible
- Strategic tier placement (shops every 5 tiers)

## Visual Improvements

### Node Appearance
**BEFORE:**
- Simple colored buttons
- Text labels only
- No icons
- Basic styling

**AFTER:**
- Emoji icons (🍳⚡🛒💎🛏👹)
- Node name labels below icons
- Rounded corners (15px radius)
- 4px borders
- Color-coded by type
- White border for available nodes
- Gray border for locked nodes
- Yellow border on hover
- Completed nodes grayed out

### Connection Lines
**BEFORE:**
- None (implicit connections)

**AFTER:**
- 4px wide lines between connected nodes
- Gray (50% opacity) for unexplored paths
- Green (90% opacity) for completed active route
- Draws behind buttons
- Shows all possible paths at once

### Layout
**BEFORE:**
- Grid layout (VBoxContainer/HBoxContainer)
- Uniform spacing
- Top-to-bottom reading
- Compressed vertical space

**AFTER:**
- Dynamic positioning in Control canvas
- Centered horizontally per tier
- Bottom-to-top progression (like climbing)
- Generous spacing (180px vertical, 140px horizontal)
- Scrollable canvas (2800px tall)

## Gameplay Impact

### Player Choice
**BEFORE:**
- Pick from 3 nodes per tier
- All paths available each time
- Less strategic depth

**AFTER:**
- Pick from 1-3 connected nodes
- Choices lock out alternative branches
- Must plan ahead (can see future tiers)
- High replay value (different paths each run)

### Visual Clarity
**BEFORE:**
- Hard to see which tier you're on
- Unclear what's available
- No sense of progress

**AFTER:**
- Clear visual hierarchy (bottom → top)
- Available nodes highlighted with white borders
- Green path shows your journey
- Boss clearly visible at top as goal

### Pacing
**BEFORE:**
- 8 tiers total
- Fixed node distribution
- Predictable shops every 3 tiers

**AFTER:**
- 15 tiers total (longer runs)
- Variable encounters per tier
- Strategic placement (shops every 5 tiers, boss at 14)
- More interesting pacing curve

## Code Architecture

### BEFORE: map_ui.gd
```gdscript
extends Panel
- VBoxContainer for tiers
- HBoxContainer for nodes
- Simple button creation
- Rebuild entire UI on selection
- ~120 lines
```

### AFTER: map_ui.gd
```gdscript
extends Panel
- Control canvas for free positioning
- Custom line renderer (draw_line)
- Styled button creation with icons
- Refresh UI without rebuild
- ~260 lines
- Dictionary mapping nodes → buttons
- Line drawing with path highlighting
```

### BEFORE: map_manager.gd
```gdscript
- 8 tiers, 3 nodes each
- Simple tier progression
- Basic connection logic
- ~100 lines
```

### AFTER: map_manager.gd
```gdscript
- 15 tiers, 2-4 nodes each
- Branching path generation
- Path tracking (current_path array)
- Smart node distribution
- ~145 lines
```

## Performance Considerations
- Map generated once per run (not per frame)
- Line drawing uses Control.draw (efficient)
- Button state updates on selection only
- Canvas size scales with tier count
- Scrollable container for large maps
- No continuous redraws (only on node selection)
