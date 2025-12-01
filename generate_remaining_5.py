from itertools import combinations
import random

ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

# Name templates for 5-ingredient recipes (more creative/absurdist)
prefixes = ["Spring", "Garden", "Fresh", "Hearty", "Light", "Power", "Premium", 
            "Ultimate", "Classic", "Rustic", "Gourmet", "Supreme", "Grand", 
            "Royal", "Noble", "Mighty", "Fusion", "Harmony", "Symphony", "Epic"]
            
middles = ["Protein", "Veggie", "Green", "Comfort", "Grain", "Fresh", "Power",
           "Omega", "Surf", "Garden", "Harvest", "Root", "Feast", "Bounty",
           "Medley", "Mix", "Fusion", "Blend", "Combo", "Special"]
           
endings = ["Bowl", "Plate", "Platter", "Dish", "Creation", "Delight", "Wonder",
           "Mix", "Fusion", "Spectacular", "Extravaganza", "Surprise", "Dream",
           "Fantasy", "Journey", "Adventure", "Experience", "Bonanza"]

# Get existing combos
existing_combos = set()
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line in f:
        if line.strip().startswith('"') and line.count('|') == 4:
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.add(key)

# Generate all missing 5-ingredient combos
missing_combos = []
for combo in combinations(ingredients, 5):
    key = "|".join(sorted(combo))
    if key not in existing_combos:
        missing_combos.append(key)

print(f"Generating names for {len(missing_combos)} missing combinations...")

# Generate names
output = []
for combo in sorted(missing_combos):
    parts = combo.split("|")
    
    # Create a somewhat descriptive name
    name_prefix = random.choice(prefixes)
    name_middle = random.choice(middles)
    name_ending = random.choice(endings)
    
    recipe_name = f"{name_prefix} {name_middle} {name_ending}"
    
    output.append(f'\t\t"{combo}": "{recipe_name}",')

# Write to file
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\remaining_5_recipes.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(output))

print(f"Generated {len(output)} recipe names to remaining_5_recipes.txt")
